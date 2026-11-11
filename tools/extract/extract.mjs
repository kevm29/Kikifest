// Extraction des ressources de Hammerfest (game.swf) vers un format web.
//
// Entrées : le dossier Hammerfest de motion-twin/WebGamesArchives.
// Sorties (dans assets/) :
//   gfx/library.json   symboles exportés, sprites (timelines), formes, textes
//   gfx/shapes.json    SVG de chaque forme / morph shape / texte statique, par id
//   gfx/images/        bitmaps
//   sfx/               sons exportés + musiques
//   data/              niveaux, langues, items (XML copiés tels quels)
//
// Usage : node extract.mjs <dossier Hammerfest> <dossier assets> <ffdec-cli.jar>

import { parseSwf } from "swf-parser";
import { execFileSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import os from "node:os";

const [srcDir, outDir, ffdecJar] = process.argv.slice(2);
if (!srcDir || !outDir || !ffdecJar) {
  console.error("usage: node extract.mjs <Hammerfest> <assets> <ffdec-cli.jar>");
  process.exit(1);
}

// Types de tags de swf-types (énumération propre à swf-parser, pas les codes SWF)
const T = {
  DefineButton: 6, DefineDynamicText: 11, DefineFont: 12, DefineMorphShape: 19,
  DefineShape: 22, DefineSound: 23, DefineSprite: 24, DefineText: 25,
  DefineBitmap: 5, DoAction: 31, DoInitAction: 32, ExportAssets: 35,
  FrameLabel: 38, PlaceObject: 49, RemoveObject: 54, ShowFrame: 58,
  StartSound: 61,
};

const swfPath = path.join(srcDir, "swf", "game.swf");
const swf = parseSwf(fs.readFileSync(swfPath));

const fx = (v) => (v && typeof v === "object" && "epsilons" in v ? v.epsilons : v);
const r4 = (n) => Math.round(n * 10000) / 10000;

// ---------------------------------------------------------------------------
// Bytecode AVM1 : on traduit les scripts de frame simples en opérations.
// Ce qui n'est pas reconnu est marqué "todo" (à porter à la main en Haxe).
// ---------------------------------------------------------------------------
function decodeActions(bytes) {
  const b = Uint8Array.from(Object.values(bytes));
  const ops = [];
  const stack = [];
  let i = 0;
  let ok = true;
  while (i < b.length) {
    const code = b[i++];
    if (code === 0) break;
    let len = 0;
    let body = null;
    if (code >= 0x80) {
      len = b[i] | (b[i + 1] << 8);
      i += 2;
      body = b.subarray(i, i + len);
      i += len;
    }
    switch (code) {
      case 0x06: ops.push(["play"]); break;
      case 0x07: ops.push(["stop"]); break;
      case 0x04: ops.push(["next"]); break;
      case 0x05: ops.push(["prev"]); break;
      case 0x81: { // GotoFrame (0-based)
        ops.push(["goto", (body[0] | (body[1] << 8)) + 1, false]);
        break;
      }
      case 0x8c: { // GotoLabel
        ops.push(["goto", new TextDecoder().decode(body.subarray(0, body.length - 1)), false]);
        break;
      }
      case 0x96: { // Push : on ne garde que les constantes simples
        let j = 0;
        while (j < body.length) {
          const t = body[j++];
          if (t === 0) { let e = j; while (body[e]) e++; stack.push(new TextDecoder().decode(body.subarray(j, e))); j = e + 1; }
          else if (t === 1) { stack.push(new DataView(body.buffer, body.byteOffset + j, 4).getFloat32(0, true)); j += 4; }
          else if (t === 6) { const dv = new DataView(body.buffer, body.byteOffset + j, 8); const hi = dv.getUint32(0, true), lo = dv.getUint32(4, true); const buf = new DataView(new ArrayBuffer(8)); buf.setUint32(0, lo, true); buf.setUint32(4, hi, true); stack.push(buf.getFloat64(0, true)); j += 8; }
          else if (t === 7) { stack.push(new DataView(body.buffer, body.byteOffset + j, 4).getInt32(0, true)); j += 4; }
          else { ok = false; j = body.length; }
        }
        break;
      }
      case 0x9f: { // GotoFrame2 (frame sur la pile)
        const play = (body[0] & 1) === 1;
        const target = stack.pop();
        if (target === undefined) { ok = false; break; }
        ops.push(["goto", typeof target === "number" ? target : String(target), play]);
        break;
      }
      default:
        ok = false;
    }
    if (!ok) break;
  }
  return ok ? ops : null;
}

// ---------------------------------------------------------------------------
// Timeline d'un sprite
// ---------------------------------------------------------------------------
function convertMatrix(m) {
  if (!m) return undefined;
  return [
    r4(fx(m.scaleX) / 65536), r4(fx(m.rotateSkew0) / 65536),
    r4(fx(m.rotateSkew1) / 65536), r4(fx(m.scaleY) / 65536),
    m.translateX / 20, m.translateY / 20,
  ];
}

function convertCx(c) {
  if (!c) return undefined;
  return [
    fx(c.redMult) / 256, fx(c.greenMult) / 256, fx(c.blueMult) / 256, fx(c.alphaMult ?? { epsilons: 256 }) / 256,
    c.redAdd, c.greenAdd, c.blueAdd, c.alphaAdd ?? 0,
  ];
}

const BLEND = { 0: undefined, 1: undefined, 2: "layer", 3: "multiply", 4: "screen", 5: "lighten", 6: "darken", 7: "add", 8: "subtract", 9: "difference", 10: "invert", 11: "alpha", 12: "erase", 13: "overlay", 14: "hardlight" };

function convertFilters(fs_) {
  if (!fs_ || !fs_.length) return undefined;
  return fs_.map((f) => {
    const out = { type: f.filter };
    for (const [k, v] of Object.entries(f)) {
      if (k === "filter") continue;
      out[k] = typeof v === "object" && v && "epsilons" in v ? fx(v) / (k.startsWith("blur") ? 65536 : 256) : v;
    }
    return out;
  });
}

const todoScripts = [];

function convertTimeline(ownerId, tags) {
  const frames = [];
  const labels = {};
  const actions = {};
  const sounds = {};
  let cur = [];
  let frame = 1;
  for (const t of tags) {
    switch (t.type) {
      case T.PlaceObject: {
        const op = { d: t.depth };
        if (!t.isUpdate) op.n = 1; // nouvelle instance
        if (t.characterId !== undefined) op.c = t.characterId;
        const m = convertMatrix(t.matrix); if (m) op.m = m;
        const cx = convertCx(t.colorTransform); if (cx) op.cx = cx;
        if (t.ratio !== undefined) op.r = t.ratio;
        if (t.name !== undefined) op.name = t.name;
        if (t.clipDepth !== undefined) op.clip = t.clipDepth;
        const bm = BLEND[t.blendMode]; if (bm) op.blend = bm;
        const fl = convertFilters(t.filters); if (fl) op.filters = fl;
        if (t.clipActions && t.clipActions.length) op.todoClipActions = true;
        cur.push(op);
        break;
      }
      case T.RemoveObject:
        cur.push({ d: t.depth, rm: 1 });
        break;
      case T.FrameLabel:
        labels[t.name] = frame;
        break;
      case T.DoAction: {
        const ops = decodeActions(t.actions);
        if (ops) actions[frame] = ops;
        else {
          actions[frame] = [["todo"]];
          todoScripts.push({ sprite: ownerId, frame });
        }
        break;
      }
      case T.StartSound:
        (sounds[frame] ??= []).push(t.soundId);
        break;
      case T.ShowFrame:
        frames.push(cur);
        cur = [];
        frame++;
        break;
    }
  }
  if (cur.length) frames.push(cur);
  const out = { frames };
  if (Object.keys(labels).length) out.labels = labels;
  if (Object.keys(actions).length) out.actions = actions;
  if (Object.keys(sounds).length) out.sounds = sounds;
  return out;
}

// ---------------------------------------------------------------------------
// Parcours des tags racine
// ---------------------------------------------------------------------------
const rect = (b) => [b.xMin / 20, b.yMin / 20, b.xMax / 20, b.yMax / 20];
const lib = {
  source: "motion-twin/WebGamesArchives Hammerfest/swf/game.swf",
  license: "CC BY-NC-SA 4.0, Motion Twin",
  frameRate: fx(swf.header.frameRate) / 256,
  stage: rect(swf.header.frameSize),
  exports: {},
  chars: {},
  sounds: {},
};

const shapeIds = [];
const morphIds = [];
const textIds = [];
for (const t of swf.tags) {
  switch (t.type) {
    case T.DefineShape:
      lib.chars[t.id] = { k: "shape", b: rect(t.bounds) };
      shapeIds.push(t.id);
      break;
    case T.DefineMorphShape:
      lib.chars[t.id] = { k: "morph", b: rect(t.bounds), b2: rect(t.morphBounds ?? t.bounds) };
      morphIds.push(t.id);
      break;
    case T.DefineText:
      lib.chars[t.id] = { k: "stext", b: rect(t.bounds), m: convertMatrix(t.matrix) };
      textIds.push(t.id);
      break;
    case T.DefineDynamicText: {
      const c = t.color;
      lib.chars[t.id] = {
        k: "etext", b: rect(t.bounds), font: t.fontId, size: t.fontSize / 20,
        color: c ? [c.r, c.g, c.b, c.a] : undefined, align: t.align, html: t.html,
        multiline: t.multiline, wordWrap: t.wordWrap, text: t.text, variable: t.variableName,
        leading: (t.leading ?? 0) / 20, useFont: t.useGlyphFont,
      };
      break;
    }
    case T.DefineFont:
      lib.chars[t.id] = { k: "font", name: t.fontName, bold: t.isBold, italic: t.isItalic };
      break;
    case T.DefineBitmap:
      lib.chars[t.id] = { k: "bitmap" };
      break;
    case T.DefineSound:
      lib.chars[t.id] = { k: "sound" };
      break;
    case T.DefineButton:
      lib.chars[t.id] = { k: "button", todo: true };
      break;
    case T.DefineSprite:
      lib.chars[t.id] = { k: "sprite", ...convertTimeline(t.id, t.tags) };
      break;
    case T.ExportAssets:
      for (const a of t.assets) lib.exports[a.name] = a.id;
      break;
  }
}
for (const [name, id] of Object.entries(lib.exports)) {
  if (lib.chars[id]?.k === "sound") lib.sounds[name] = id;
}

// ---------------------------------------------------------------------------
// Export JPEXS (formes en SVG, bitmaps, sons)
// ---------------------------------------------------------------------------
const tmp = fs.mkdtempSync(path.join(os.tmpdir(), "kiki-ffdec-"));
execFileSync("java", [
  "-jar", ffdecJar,
  "-format", "shape:svg,morphshape:svg,text:svg,image:png_gif_jpeg,sound:mp3_wav",
  "-export", "shape,morphshape,text,image,sound", tmp, swfPath,
], { stdio: "ignore" });

const fileById = (dir) => {
  const m = {};
  if (!fs.existsSync(dir)) return m;
  for (const f of fs.readdirSync(dir)) {
    const id = parseInt(f, 10);
    if (!Number.isNaN(id)) m[id] = path.join(dir, f);
  }
  return m;
};

const svgs = {};
// On retire tous les attributs ffdec:* (sinon le SVG est invalide sans la déclaration xmlns:ffdec
// et le navigateur refuse de l'afficher, ce qui cachait toutes les formes à remplissage bitmap).
const cleanSvg = (s) => s.replace(/<\?xml[^>]*>\s*/, "").replace(/\s*xmlns:ffdec="[^"]*"/g, "").replace(/\s*ffdec:[A-Za-z-]+="[^"]*"/g, "");
for (const [dir, ids] of [["shapes", shapeIds], ["morphshapes", morphIds], ["texts", textIds]]) {
  const files = fileById(path.join(tmp, dir));
  for (const id of ids) {
    if (files[id]) svgs[id] = cleanSvg(fs.readFileSync(files[id], "utf8"));
  }
}

fs.mkdirSync(path.join(outDir, "gfx", "images"), { recursive: true });
fs.mkdirSync(path.join(outDir, "sfx"), { recursive: true });
fs.mkdirSync(path.join(outDir, "data"), { recursive: true });

const images = fileById(path.join(tmp, "images"));
for (const [id, f] of Object.entries(images)) {
  const ext = path.extname(f);
  fs.copyFileSync(f, path.join(outDir, "gfx", "images", id + ext));
  if (lib.chars[id]) lib.chars[id].file = "images/" + id + ext;
}
const snd = fileById(path.join(tmp, "sounds"));
for (const [id, f] of Object.entries(snd)) {
  const ext = path.extname(f);
  fs.copyFileSync(f, path.join(outDir, "sfx", id + ext));
  if (lib.chars[id]) lib.chars[id].file = id + ext;
}
for (const f of fs.readdirSync(path.join(srcDir, "sfx"))) {
  fs.copyFileSync(path.join(srcDir, "sfx", f), path.join(outDir, "sfx", f));
}

fs.writeFileSync(path.join(outDir, "gfx", "library.json"), JSON.stringify(lib));
fs.writeFileSync(path.join(outDir, "gfx", "shapes.json"), JSON.stringify(svgs));
fs.writeFileSync(path.join(outDir, "gfx", "todo-scripts.json"), JSON.stringify(todoScripts, null, 1));

// Données de jeu (XML)
const copyDir = (a, b) => {
  fs.mkdirSync(b, { recursive: true });
  for (const f of fs.readdirSync(a)) {
    const p = path.join(a, f);
    if (fs.statSync(p).isDirectory()) copyDir(p, path.join(b, f));
    else fs.copyFileSync(p, path.join(b, f));
  }
};
copyDir(path.join(srcDir, "xml"), path.join(outDir, "data"));

fs.rmSync(tmp, { recursive: true, force: true });

const count = (k) => Object.values(lib.chars).filter((c) => c.k === k).length;
console.log(`exports: ${Object.keys(lib.exports).length}, sprites: ${count("sprite")}, shapes: ${shapeIds.length}, morphs: ${morphIds.length}, svg: ${Object.keys(svgs).length}, images: ${Object.keys(images).length}, sons: ${Object.keys(snd).length}, scripts à porter: ${todoScripts.length}`);

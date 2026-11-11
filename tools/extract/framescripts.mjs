// Traduit les scripts de frame AS2 de game.swf (ceux que extract.mjs n'a pas su traduire, "todo")
// en corps de fonctions JavaScript, exécutés à l'exécution dans la portée du clip (voir swf/FrameScripts.hx).
//
// Usage : node framescripts.mjs <export ffdec> <web/assets/gfx>
//   l'export ffdec s'obtient avec : ffdec-cli -export script <dossier> game.swf
// Produit gfx/framescripts.json : { "sprite:frame": "code JS" }.

import fs from "fs";
import path from "path";

const [exportDir, gfxDir] = process.argv.slice(2);
const todo = JSON.parse(fs.readFileSync(path.join(gfxDir, "todo-scripts.json"), "utf8"));
const root = path.join(exportDir, "scripts");
const dirs = fs.readdirSync(root);

function findScript(sprite, frame) {
  const d = dirs.find((n) => n === `DefineSprite_${sprite}` || n.startsWith(`DefineSprite_${sprite}_`));
  if (!d) return null;
  const fdir = path.join(root, d, `frame_${frame}`);
  if (!fs.existsSync(fdir)) return null;
  return fs.readdirSync(fdir).filter((f) => f.endsWith(".as")).map((f) => fs.readFileSync(path.join(fdir, f), "utf8")).join("\n");
}

function translate(as) {
  let s = as;
  // AS2 est insensible à la casse pour les propriétés de clip
  s = s.replace(/\b_X\b/g, "_x").replace(/\b_Y\b/g, "_y");
  s = s.replace(/\band\b/g, "&&").replace(/\bor\b/g, "||");
  // les fonctions définies sur la timeline deviennent des variables du clip
  s = s.replace(/^(\s*)function\s+([A-Za-z_$][\w$]*)\s*\(/gm, "$1$2 = function(");
  return s;
}

const out = {};
let missing = 0;
for (const t of todo) {
  const as = findScript(t.sprite, t.frame);
  if (as == null) { missing++; continue; }
  out[`${t.sprite}:${t.frame}`] = translate(as);
}
fs.writeFileSync(path.join(gfxDir, "framescripts.json"), JSON.stringify(out, null, 1));
console.log(`${Object.keys(out).length} scripts traduits, ${missing} introuvables`);

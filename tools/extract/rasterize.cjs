// Pré-pixellise toutes les formes (SVG) dans des planches PNG (atlas), pour un
// chargement rapide du jeu : décoder 3 000 SVG dans le navigateur prend trop de temps.
//
// Usage : node rasterize.cjs <web/assets/gfx>
// Produit atlas/atlas-N.png et atlas.json { id: [page, x, y, w, h, scale] }.
// Nécessite Playwright (Chromium).

const { chromium } = require("playwright");
const fs = require("fs");
const path = require("path");

const dir = process.argv[2];
const PAGE = 4096;
const PAD = 1;

(async () => {
  const lib = JSON.parse(fs.readFileSync(path.join(dir, "library.json"), "utf8"));
  const svgs = JSON.parse(fs.readFileSync(path.join(dir, "shapes.json"), "utf8"));

  // tailles et échelle (2x pour les petites formes, 1x pour les grandes)
  const items = [];
  for (const [id, svg] of Object.entries(svgs)) {
    const c = lib.chars[id];
    if (!c || !c.b) continue;
    const w = c.b[2] - c.b[0], h = c.b[3] - c.b[1];
    if (w <= 0 || h <= 0) continue;
    const scale = Math.max(w, h) <= 200 ? 2 : 1;
    items.push({ id, w: Math.ceil(w * scale), h: Math.ceil(h * scale), scale });
  }
  // rangement par étagères
  items.sort((a, b) => b.h - a.h);
  let page = 0, x = 0, y = 0, rowH = 0;
  for (const it of items) {
    if (x + it.w + PAD > PAGE) { x = 0; y += rowH + PAD; rowH = 0; }
    if (y + it.h + PAD > PAGE) { page++; x = 0; y = 0; rowH = 0; }
    it.page = page; it.x = x; it.y = y;
    x += it.w + PAD;
    rowH = Math.max(rowH, it.h);
  }
  const pages = page + 1;

  const browser = await chromium.launch();
  const p = await browser.newPage();
  fs.mkdirSync(path.join(dir, "atlas"), { recursive: true });
  for (let pg = 0; pg < pages; pg++) {
    const list = items.filter((it) => it.page === pg).map((it) => ({ ...it, svg: svgs[it.id] }));
    const png = await p.evaluate(async ({ list, PAGE }) => {
      const c = document.createElement("canvas");
      c.width = PAGE; c.height = PAGE;
      const g = c.getContext("2d");
      for (const it of list) {
        const url = URL.createObjectURL(new Blob([it.svg], { type: "image/svg+xml" }));
        const img = new Image();
        img.src = url;
        try { await img.decode(); } catch (e) { continue; }
        g.drawImage(img, it.x, it.y, it.w, it.h);
        URL.revokeObjectURL(url);
      }
      return c.toDataURL("image/webp", 0.92);
    }, { list, PAGE });
    fs.writeFileSync(path.join(dir, "atlas", `atlas-${pg}.webp`), Buffer.from(png.split(",")[1], "base64"));
    console.log(`planche ${pg + 1}/${pages} : ${list.length} formes`);
  }
  await browser.close();

  const map = {};
  for (const it of items) map[it.id] = [it.page, it.x, it.y, it.w, it.h, it.scale];
  fs.writeFileSync(path.join(dir, "atlas.json"), JSON.stringify({ pages, map }));
})();

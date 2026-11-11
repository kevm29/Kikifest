// Robot de test : parcourt les niveaux, joue au hasard (déplacements, sauts, bombes), fait apparaître
// des ennemis et tous les objets, et relève chaque erreur (message + pile) sans doublon.
//
// Usage : node tools/test/bot.cjs [url] [dimensions, ex. "0,1,2"] [niveaux max par dimension]
// Le serveur doit tourner (node server/serve.mjs 8080). Nécessite Playwright (Chromium).

const { chromium } = require("playwright");

const url = process.argv[2] || "http://localhost:8080/index.html";
const dims = (process.argv[3] || "0").split(",").map(Number);
const maxLevels = Number(process.argv[4] || 999);
const firstLevel = Number(process.argv[5] || 0);

(async () => {
  const browser = await chromium.launch();
  let page;
  const errors = new Map();
  const note = (msg, where) => {
    const key = msg.split("\n").slice(0, 3).join(" | ");
    if (!errors.has(key)) errors.set(key, { count: 0, where: [] });
    const e = errors.get(key);
    e.count++;
    if (e.where.length < 5) e.where.push(where);
  };
  let where = "chargement";
  async function openPage() {
  page = await browser.newPage({ viewport: { width: 500, height: 620 } });
  page.on("pageerror", (e) => note("PAGEERROR " + e.message + "\n" + (e.stack || "").split("\n").slice(1, 4).join("\n"), where));
  page.on("console", (m) => {
    if (m.type() === "error") note("CONSOLE " + m.text(), where);
  });
  await page.goto(url);
  await page.waitForFunction(() => window.kiki && window.kiki.manager && window.kiki.manager.current && window.kiki.manager.current.world, null, { timeout: 30000 });
  await page.waitForTimeout(1500);

  // fonctions d'aide dans la page
  await page.evaluate(() => {
    window.__errs = [];
    const K = { left: 37, up: 38, right: 39, down: 40, bomb: 13, l2: 68, u2: 82, r2: 71, d2: 70, b2: 65 };
    const press = (code, down) => {
      const ev = new KeyboardEvent(down ? "keydown" : "keyup", { bubbles: true });
      Object.defineProperty(ev, "keyCode", { get: () => code });
      window.dispatchEvent(ev);
    };
    let rnd = 1234567;
    const r = (n) => { rnd ^= rnd << 13; rnd ^= rnd >>> 17; rnd ^= rnd << 5; return Math.abs(rnd) % n; };
    const held = new Set();
    window.__step = (n, drawEvery) => {
      const B = window.kiki.boot;
      for (let i = 0; i < n; i++) {
        if (i % 6 === 0) {
          // entrées au hasard pour les deux joueurs
          for (const c of [K.left, K.right, K.up, K.down, K.bomb, K.l2, K.r2, K.u2, K.d2, K.b2]) {
            const want = r(100) < (c === K.bomb || c === K.b2 ? 20 : 35);
            if (want && !held.has(c)) { press(c, true); held.add(c); }
            else if (!want && held.has(c)) { press(c, false); held.delete(c); }
          }
        }
        try { B.tick(); } catch (e) { window.__errs.push("TICK " + e + "\n" + (e.stack || "").split("\n").slice(1, 4).join("\n")); }
        if (drawEvery && i % drawEvery === 0) {
          try { B.draw(); } catch (e) { window.__errs.push("DRAW " + e + "\n" + (e.stack || "").split("\n").slice(1, 4).join("\n")); }
        }
      }
      const out = window.__errs; window.__errs = []; return out;
    };
    window.__keepAlive = () => {
      const g = window.kiki.manager.current;
      if (!g || !g.getPlayerList) return;
      for (const p of g.getPlayerList()) { p.lives = 50; }
    };
    window.__spawn = (lid) => {
      const g = window.kiki.manager.current, out = [];
      const pl = g.getPlayerList();
      const p = pl[0];
      if (!p) return ["pas de joueur"];
      try {
        for (let k = 0; k < 2; k++) {
          const id = (lid * 3 + k * 7) % 21;
          g.attachBad(id, 40 + r(340), 40 + r(300));
        }
      } catch (e) { out.push("SPAWN BAD " + e + "\n" + (e.stack || "").split("\n").slice(1, 4).join("\n")); }
      try {
        for (let k = 0; k < 2; k++) {
          const sid = (lid * 2 + k) % 118;
          const it = window.kiki.SpecialItem.attach(g, p.x, p.y - 10, sid, 0);
          if (it && p.hit) p.hit(it);
        }
        for (let k = 0; k < 3; k++) {
          const id = (lid * 3 + k) % 239;
          const it = window.kiki.ScoreItem.attach(g, p.x, p.y - 10, id, 0);
          if (it && p.hit) p.hit(it);
        }
      } catch (e) { out.push("SPAWN ITEM " + e + "\n" + (e.stack || "").split("\n").slice(1, 4).join("\n")); }
      return out;
    };
    window.__bombBads = () => {
      // amène le joueur 1 contre un ennemi pour provoquer gel, coups, morts
      const g = window.kiki.manager.current; const b = g.getBadList()[0]; const p = g.getPlayerList()[0];
      if (b && p) p.moveTo(b.x - 15, b.y);
    };
  });
  }
  await openPage();

  // évaluation avec délai maximal : un jeu bloqué (boucle infinie) est signalé puis la page est recréée
  async function ev(fn, arg) {
    let timer;
    const res = await Promise.race([
      page.evaluate(fn, arg),
      new Promise((r) => { timer = setTimeout(() => r("__TIMEOUT__"), 20000); }),
    ]);
    clearTimeout(timer);
    if (res === "__TIMEOUT__") {
      // pile d'appels au moment du blocage, via le protocole de débogage de Chromium
      let stack = "";
      try {
        const cdp = await page.context().newCDPSession(page);
        await cdp.send("Debugger.enable");
        const paused = new Promise((r) => cdp.on("Debugger.paused", (ev) => r(ev)));
        await cdp.send("Debugger.pause");
        const ev = await Promise.race([paused, new Promise((r) => setTimeout(() => r(null), 5000))]);
        if (ev) stack = ev.callFrames.slice(0, 8).map((f) => f.functionName + ":" + (f.location.lineNumber + 1)).join(" < ");
      } catch (e) { stack = "(pile indisponible)"; }
      note("BLOCAGE : le jeu ne répond plus\n" + stack, where);
      const old = page;
      old.close().catch(() => {});
      await openPage();
      throw new Error("page recréée");
    }
    return res;
  }

  for (const d of dims) {
    const n = await ev((d) => { const g = window.kiki.manager.current; return g.dimensions && g.dimensions[d] ? g.dimensions[d].raw.length : 0; }, d);
    const count = Math.min(n, maxLevels);
    console.log(`dimension ${d} : ${n} niveaux, ${count} testés`);
    for (let lid = firstLevel; lid < count; lid++) {
      where = `dim ${d} niveau ${lid}`;
      const errs = [];
      try {
        errs.push(...(await ev(([d, lid]) => {
          const g = window.kiki.manager.current; const out = [];
          try {
            if (g.currentDim !== d) g.switchDimensionById(d, lid, 0); else g.forcedGoto(lid);
          } catch (e) { out.push("GOTO " + e + "\n" + (e.stack || "").split("\n").slice(1, 4).join("\n")); }
          return out;
        }, [d, lid])));
        await ev(() => window.__keepAlive());
        errs.push(...(await ev(() => window.__step(80, 10))));
        errs.push(...(await ev((lid) => window.__spawn(lid), lid)));
        for (let k = 0; k < 4; k++) {
          await ev(() => { window.__keepAlive(); window.__bombBads(); });
          errs.push(...(await ev(() => window.__step(60, 15))));
        }
      } catch (e) {
        errs.push("BOT " + e.message.split("\n")[0]);
        if (!String(e.message).includes("page recréée")) { await page.close().catch(() => {}); await openPage(); }
      }
      for (const e of errs) note(e, where);
      process.stdout.write(errs.length ? "x" : ".");
    }
    console.log();
  }

  // partie perdue (fin de partie)
  where = "fin de partie";
  await ev(() => { const g = window.kiki.manager.current; for (const p of g.getPlayerList()) { p.lives = 0; try { p.killHit(3); } catch (e) { window.__errs.push("KILL " + e); } } });
  for (const e of await ev(() => window.__step(400, 20))) note(e, where);

  console.log(`\n${errors.size} erreur(s) distincte(s)`);
  for (const [k, v] of errors) console.log(`\n[${v.count}x] ${k}\n   vu : ${v.where.join(", ")}`);
  await browser.close();
})();

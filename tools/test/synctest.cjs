// Test de déterminisme du rollback dans le vrai jeu (SyncTest de GGPO) :
// à chaque frame, on revient quelques frames en arrière et on rejoue ; l'empreinte doit être la même.
// Mesure aussi le coût d'une photo / restauration de l'état.
//
// Usage : node tools/test/synctest.cjs [url] [frames] [rollback]
// Le serveur doit tourner (node server/serve.mjs 8080).
const { chromium } = require("playwright");
const url = process.argv[2] || "http://localhost:8080/jeu.html?mode=multicoop&nosave";
const frames = Number(process.argv[3] || 3000);
const back = Number(process.argv[4] || 6);
(async () => {
  const b = await chromium.launch(); const p = await b.newPage();
  const errs = [];
  p.on("pageerror", (e) => errs.push(e.message));
  p.on("console", (m) => { if (m.type() === "error") errs.push(m.text()); });
  await p.goto(url);
  await p.waitForFunction(() => window.kiki && kiki.manager && kiki.manager.current, null, { timeout: 30000 });
  await p.waitForTimeout(300);
  const r = await p.evaluate(({ frames, back }) => {
    const N = kiki.net; N.init();
    // la boucle normale du jeu est arrêtée : on la remplace
    window.requestAnimationFrame = () => 0;
    const g = new N.NetGame();
    const st = new N.SyncTest(g, back);
    let rnd = 99, a = 0, c = 0;
    const r = (n) => { rnd ^= rnd << 13; rnd ^= rnd >>> 17; rnd ^= rnd << 5; return Math.abs(rnd) % n; };
    const next = (m) => (r(6) === 0 ? r(32) : m); // touches qui changent de temps en temps (sans pause ni carte)
    let saveMs = 0, saves = 0, t0 = performance.now();
    for (let i = 0; i < frames; i++) {
      a = next(a); c = next(c);
      if (!st.tick([a, c])) return { ok: false, frame: i, msg: st.errorMessage };
    }
    const total = performance.now() - t0;
    let t = performance.now(); const s = N.Snapshot.save(); saveMs = performance.now() - t;
    t = performance.now(); s.restore(); const restoreMs = performance.now() - t;
    const lvl = kiki.manager.current.world ? kiki.manager.current.world.currentId : String(kiki.manager.current.constructor.name);
    return { ok: true, frames, level: lvl, objects: s.objects.length, saveMs, restoreMs, msPerTick: total / frames };
  }, { frames, back });
  console.log(JSON.stringify(r));
  if (errs.length) console.log("Erreurs :\n" + errs.slice(0, 10).join("\n"));
  await b.close();
  process.exit(r.ok && !errs.length ? 0 : 1);
})();

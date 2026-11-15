// Régression « écran noir » : un retour en arrière du rollback par-dessus un changement de niveau
// faisait disparaître le décor (les caches bitmap du niveau précédent avaient été vidés).
// On photographie l'état au niveau 2, on passe au niveau 3, on restaure la photo : le décor du
// niveau 2 doit être intact.
//
// Usage : node tools/test/decor-rollback.cjs   (le serveur doit tourner : node server/serve.mjs 8080)
const { chromium } = require("playwright");
(async () => {
  const b = await chromium.launch(); const p = await b.newPage({ viewport: { width: 520, height: 700 } });
  p.on("pageerror", (e) => console.log("ERR", e.message));
  await p.goto("http://localhost:8080/jeu.html?mode=multicoop&nosave");
  await p.waitForFunction(() => window.kiki && kiki.manager && kiki.manager.current, null, { timeout: 30000 });
  await p.waitForTimeout(500);
  const r = await p.evaluate(() => {
    window.requestAnimationFrame = () => 0;
    const N = kiki.net; N.init();
    const B = kiki.boot, g = kiki.manager.current;
    g.forcedGoto(2); for (let k = 0; k < 300; k++) B.tick();
    const v = () => { const vw = g.world.view; return [g.world.currentId, vw.viewCache && vw.viewCache.canvas.width, vw.topCache && vw.topCache.canvas.width]; };
    const before = v();
    const s = N.Snapshot.save();
    g.forcedGoto(3);
    for (let k = 0; k < 300; k++) B.tick();
    const mid = v();
    s.restore();
    B.tick(); B.draw();
    return { before, mid, after: v() };
  });
  const ok = r.after[0] === r.before[0] && r.after[1] === r.before[1] && r.after[2] === r.before[2];
  console.log(JSON.stringify(r), ok ? "OK" : "ÉCHEC : décor vidé après le retour en arrière");
  await b.close();
  process.exit(ok ? 0 : 1);
})();

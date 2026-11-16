// Régression « écran noir, null item ID » : quand il ne reste plus aucun objet à tirer au sort
// (collection réduite, objets uniques déjà ramassés), le jeu s'arrêtait sur une erreur fatale.
// On vide les tables de tirage puis on change plusieurs fois de niveau : le jeu doit continuer.
//
// Usage : node tools/test/objets-epuises.cjs   (le serveur doit tourner : node server/serve.mjs 8080)
const { chromium } = require("playwright");
(async () => {
  const b = await chromium.launch(); const p = await b.newPage();
  const errs = [];
  p.on("pageerror", (e) => errs.push(e.message));
  p.on("console", (m) => { if (m.type() === "error") errs.push(m.text()); });
  await p.goto("http://localhost:8080/jeu.html?mode=multicoop&nosave");
  await p.waitForFunction(() => window.kiki && kiki.manager && kiki.manager.current && kiki.manager.current.world, null, { timeout: 30000 });
  const r = await p.evaluate(() => {
    window.requestAnimationFrame = () => 0;
    const g = kiki.manager.current, D = kiki.net.classes["Data"];
    for (const id of [D.RAND_ITEMS_ID, D.RAND_SCORES_ID]) { const t = g.randMan.bulks[id]; for (let i = 0; i < t.length; i++) t[i] = 0; g.randMan.computeSum(id); }
    for (let l = 1; l <= 6; l++) { g.forcedGoto(l); for (let k = 0; k < 400; k++) kiki.boot.step(); kiki.boot.draw(); }
    return { niveau: g.world.currentId, racine: !!kiki.manager.current && !!kiki.manager.root._parent || !!kiki.manager.root };
  });
  const fatal = errs.filter((e) => /fatale|null item/.test(e));
  console.log(JSON.stringify(r), fatal.length ? "ÉCHEC : " + fatal[0] : "OK");
  await b.close();
  process.exit(fatal.length ? 1 : 0);
})();

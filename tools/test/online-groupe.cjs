// Test de bout en bout du jeu à 3 ou 4 en ligne : l'hôte crée la partie, les invités ouvrent le lien,
// tout le monde se dit prêt, chacun joue au hasard ; on vérifie que les parties restent identiques
// (empreintes comparées, pas de désynchro, mêmes positions), puis qu'un départ ramène tout le monde au salon.
//
// Usage : node tools/test/online-groupe.cjs [joueurs=4] [secondes=20] [relay]
// Le serveur doit tourner (node server/serve.mjs 8080).
const { chromium } = require("playwright");
const n = Number(process.argv[2] || 4);
const secs = Number(process.argv[3] || 20);
const relay = process.argv[4] === "relay" ? "&relay=1" : "";
const base = "http://localhost:8080/";

(async () => {
  const browser = await chromium.launch();
  const errs = [];
  const open = async (who, url, name) => {
    const ctx = await browser.newContext({ viewport: { width: 520, height: 700 } });
    const p = await ctx.newPage();
    p.on("pageerror", (e) => errs.push(who + " : " + e.message));
    p.on("console", (m) => { if (m.type() === "error" || /Désynchro/.test(m.text())) errs.push(who + " : " + m.text()); });
    await ctx.addInitScript((nm) => localStorage.setItem("kikifest.name", nm), name);
    await p.goto(url);
    return p;
  };
  const names = ["Kevin", "Copain", "Cousine", "Voisin"].slice(0, n);
  const host = await open("hôte", base + "index.html?x=1" + relay + "#multi", names[0]);
  await host.getByText("Créer une partie et inviter quelqu'un").click();
  await host.waitForFunction(() => /Code : [A-Z0-9]{5}/.test(document.body.textContent), null, { timeout: 15000 });
  const code = await host.evaluate(() => document.body.textContent.match(/Code : ([A-Z0-9]{5})/)[1]);
  console.log("code", code);
  const pages = [host];
  for (let i = 1; i < n; i++) {
    const g = await open("invité " + i, base + "?code=" + code + relay, names[i]);
    pages.push(g);
    await g.waitForSelector("table.lobby", { timeout: 30000 });
  }
  // tout le monde voit les pseudos de tout le monde
  // (son propre pseudo est dans le champ de saisie, pas dans le texte)
  for (const [i, p] of pages.entries())
    await p.waitForFunction((others) => others.every((nm) => document.querySelector("table.lobby").textContent.includes(nm)),
      names.filter((_, j) => j !== i), { timeout: 10000 });
  console.log("salon : " + n + " joueurs, pseudos visibles partout");
  // un 5e joueur est refusé
  if (n === 4) {
    const extra = await open("5e", base + "?code=" + code + relay, "Intrus");
    await extra.waitForFunction(() => /complète/.test(document.body.textContent), null, { timeout: 10000 });
    console.log("5e joueur refusé : OK");
    await extra.context().close();
  }
  for (const p of pages) await p.getByText("Je suis prêt !").click();
  for (const p of pages)
    await p.waitForFunction(() => window.kiki && kiki.session && kiki.manager && kiki.manager.current, null, { timeout: 30000 });
  console.log("partie lancée chez les " + n);
  const keys = ["ArrowLeft", "ArrowRight", "ArrowUp", "ArrowDown", "Space"];
  let rnd = 7;
  const r = (k) => { rnd ^= rnd << 13; rnd ^= rnd >>> 17; rnd ^= rnd << 5; return Math.abs(rnd) % k; };
  const held = pages.map(() => new Set());
  const t0 = Date.now();
  while (Date.now() - t0 < secs * 1000) {
    for (const [i, p] of pages.entries())
      for (const k of keys) {
        const want = r(100) < (k === "Space" ? 15 : 30);
        if (want !== held[i].has(k)) {
          await p.evaluate(({ k, want }) => window.dispatchEvent(new KeyboardEvent(want ? "keydown" : "keyup", { code: k, bubbles: true })), { k, want });
          if (want) held[i].add(k); else held[i].delete(k);
        }
      }
    await host.waitForTimeout(120);
  }
  // on relâche tout et on laisse les touches arriver partout
  for (const [i, p] of pages.entries())
    for (const k of held[i]) await p.evaluate((k) => window.dispatchEvent(new KeyboardEvent("keyup", { code: k, bubbles: true })), k);
  const info = (p) => p.evaluate(() => {
    const s = kiki.session;
    if (!s) return { ended: true, status: (document.getElementById("status") || {}).textContent };
    const pl = kiki.manager.current.getPlayerList().map((x) => [x.pid, Math.round(x.x), Math.round(x.y)]);
    return { frame: s.currentFrame, rtt: Math.round(s.rttMs), desynced: s.desynced, rollbacks: s.stats.rollbacks, maxRollback: s.stats.maxRollback,
      checks: s.stats.checksumsCompared, players: pl, status: document.getElementById("status").textContent };
  });
  const res = [];
  for (const p of pages) res.push(await info(p));
  res.forEach((x, i) => console.log((i ? "invité " + i : "hôte    ") + " " + JSON.stringify(x)));
  const live = res.filter((x) => !x.ended);
  let ok = live.length === n && live.every((x) => !x.desynced && x.checks > 5 && x.players.length === n);
  // départ d'un invité : tout le monde revient au salon
  await pages[n - 1].context().close();
  for (const p of pages.slice(0, n - 1))
    await p.waitForSelector("table.lobby", { timeout: 20000 }).catch(() => { ok = false; console.log("pas de retour au salon"); });
  const msg = await host.evaluate(() => (document.querySelector(".result") || {}).textContent);
  console.log("après le départ du dernier invité, salon de l'hôte :", msg);
  // nouvelle partie avec ceux qui restent
  const rest = pages.slice(0, n - 1);
  for (const p of rest) await p.evaluate(() => { window.__old = kiki.session; });
  for (const p of rest) await p.getByText("Je suis prêt !").click();
  for (const p of rest)
    await p.waitForFunction(() => window.KIKI_NET && KIKI_NET.round === 2 && window.kiki && kiki.session && kiki.session !== window.__old && kiki.session.currentFrame > 100,
      null, { timeout: 30000 }).catch(() => { ok = false; });
  const again = [];
  for (const p of rest) again.push(await info(p));
  const ok2 = again.every((x) => !x.ended && !x.desynced && x.players.length === n - 1);
  console.log("nouvelle partie à " + (n - 1) + " :", ok2 ? "OK" : "ÉCHEC " + JSON.stringify(again));
  ok = ok && ok2;
  if (errs.length) console.log("Erreurs :\n" + errs.slice(0, 15).join("\n"));
  ok = ok && errs.length === 0;
  console.log(ok ? "OK" : "ÉCHEC");
  await browser.close();
  process.exit(ok ? 0 : 1);
})();

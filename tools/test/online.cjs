// Test de bout en bout du jeu à deux en ligne : un hôte crée la partie depuis l'onglet Multijoueur,
// un invité ouvre le lien, les deux jouent au hasard (chacun ses touches) pendant un moment ;
// on vérifie que les deux parties restent identiques (empreintes) et qu'il n'y a pas d'erreur.
//
// Usage : node tools/test/online.cjs [secondes] [relay|direct] [latence simulée en ms]
// Le serveur doit tourner (node server/serve.mjs 8080).
const { chromium } = require("playwright");
const secs = Number(process.argv[2] || 30);
const relay = (process.argv[3] === "relay" ? "&relay=1" : "") + (process.argv[4] ? "&lag=" + process.argv[4] : "");
const base = "http://localhost:8080/";

(async () => {
  const browser = await chromium.launch();
  const errs = [];
  const open = async (who, url) => {
    const ctx = await browser.newContext({ viewport: { width: 520, height: 700 } });
    const p = await ctx.newPage();
    p.on("pageerror", (e) => errs.push(who + " : " + e.message));
    p.on("console", (m) => { if (m.type() === "error" || /Désynchro/.test(m.text())) errs.push(who + " : " + m.text()); });
    await p.goto(url);
    return p;
  };
  const host = await open("hôte", base + "index.html?x=1" + relay + "#multi");
  await host.evaluate(() => localStorage.setItem("kikifest.name", "Kevin"));
  await host.getByText("Créer une partie et inviter quelqu'un").click();
  await host.waitForFunction(() => /Code : [A-Z0-9]{5}/.test(document.body.textContent), null, { timeout: 15000 });
  const code = (await host.evaluate(() => document.body.textContent.match(/Code : ([A-Z0-9]{5})/)[1]));
  console.log("code", code);
  const guest = await open("invité", base + "?code=" + code + relay);
  for (const p of [host, guest])
    await p.waitForFunction(() => window.kiki && kiki.session && kiki.manager && kiki.manager.current, null, { timeout: 30000 });
  console.log("partie lancée des deux côtés");
  // touches au hasard : l'hôte et l'invité utilisent tous deux les touches « Vous » (flèches + Espace)
  const keys = ["ArrowLeft", "ArrowRight", "ArrowUp", "ArrowDown", "Space"];
  let rnd = 7;
  const r = (n) => { rnd ^= rnd << 13; rnd ^= rnd >>> 17; rnd ^= rnd << 5; return Math.abs(rnd) % n; };
  const held = [new Set(), new Set()];
  const t0 = Date.now();
  while (Date.now() - t0 < secs * 1000) {
    for (const [i, p] of [host, guest].entries()) {
      for (const k of keys) {
        const want = r(100) < (k === "Space" ? 15 : 30);
        if (want !== held[i].has(k)) {
          await p.evaluate(({ k, want }) => window.dispatchEvent(new KeyboardEvent(want ? "keydown" : "keyup", { code: k, bubbles: true })), { k, want });
          if (want) held[i].add(k); else held[i].delete(k);
        }
      }
    }
    await host.waitForTimeout(120);
  }
  const info = async (p) => p.evaluate(() => {
    const s = kiki.session;
    const pl = kiki.manager.current.getPlayerList ? kiki.manager.current.getPlayerList().map((x) => [x.pid, Math.round(x.x), Math.round(x.y)]) : [];
    return { frame: s.currentFrame, confirmed: s.remoteConfirmedFrame, rtt: Math.round(s.rttMs), desynced: s.desynced, stats: s.stats, players: pl,
      status: document.getElementById("status").textContent };
  });
  const a = await info(host), b = await info(guest);
  console.log("hôte  ", JSON.stringify(a));
  console.log("invité", JSON.stringify(b));
  const ok = !a.desynced && !b.desynced && a.stats.checksumsCompared > 10 && b.stats.checksumsCompared > 10 && errs.length === 0;
  if (errs.length) console.log("Erreurs :\n" + errs.slice(0, 15).join("\n"));
  console.log(ok ? "OK" : "ÉCHEC");
  await browser.close();
  process.exit(ok ? 0 : 1);
})();

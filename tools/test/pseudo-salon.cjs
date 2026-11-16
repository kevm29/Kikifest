// Salon en ligne : l'invité tape son pseudo lettre par lettre (régression : le champ perdait le focus
// à chaque lettre). Usage : node tools/test/pseudo-salon.cjs (serveur lancé sur le port 8080).
const { chromium } = require("playwright");
(async () => {
  const b = await chromium.launch();
  const open = async (who, url) => { const c = await b.newContext({ viewport: { width: 900, height: 800 } }); const p = await c.newPage();
    p.on("pageerror", e => console.log(who, "ERR", e.message)); await p.goto(url); return p; };
  const host = await open("hote", "http://localhost:8080/index.html#multi");
  await host.getByText("Créer une partie et inviter quelqu'un").click();
  await host.waitForFunction(() => /Code : [A-Z0-9]{5}/.test(document.body.textContent));
  const code = await host.evaluate(() => document.body.textContent.match(/Code : ([A-Z0-9]{5})/)[1]);
  const guest = await open("invite", "http://localhost:8080/?code=" + code);
  await guest.waitForSelector("table.lobby input", { timeout: 20000 });
  await guest.click("table.lobby input");
  await guest.keyboard.press("Control+A"); await guest.keyboard.press("Backspace");
  for (const ch of "Copain") { await guest.keyboard.type(ch); await guest.waitForTimeout(150); console.log("val", await guest.evaluate(() => { const i = document.querySelector("table.lobby input"); return JSON.stringify([i && i.value, document.activeElement && document.activeElement.tagName, i === document.activeElement]); })); }
  await guest.keyboard.press("Tab");
  await guest.waitForTimeout(1500);
  console.log("invite input:", await guest.evaluate(() => { const i = document.querySelector("table.lobby input"); return i ? i.value : "PAS DE SALON: " + document.body.innerText.slice(0, 300); }));
  console.log("hote voit:", await host.evaluate(() => { const t = document.querySelector("table.lobby"); return t ? t.innerText : document.body.innerText.slice(0, 300); }));
  const ok = (await host.evaluate(() => document.querySelector("table.lobby td.other").textContent)) === "Copain";
  console.log(ok ? "OK" : "ÉCHEC");
  await b.close();
  process.exit(ok ? 0 : 1);
})();

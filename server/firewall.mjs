// Windows : autorise les connexions entrantes vers Kikifest dans le pare-feu.
// Sans cela, Windows ignore en silence les connexions de l'invité (« délai d'attente dépassé »),
// en particulier si le réseau est classé « public » ou si l'on a cliqué « Annuler » au premier lancement
// (Windows crée alors une règle qui BLOQUE Node.js, prioritaire sur toute autorisation).
//
// On passe par netsh plutôt que par les commandes PowerShell New-NetFirewallRule & co :
// celles-ci reposent sur WMI, qui échoue sur certains PC (« Classe non valide », 0x80041010),
// par exemple quand un antivirus remplace le pare-feu de Windows.
import { execFile } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";

function run(file, args) {
  return new Promise((resolve) => {
    execFile(file, args, { windowsHide: true, timeout: 120000 }, (err, stdout) =>
      resolve({ code: err ? (typeof err.code === "number" ? err.code : -1) : 0, out: String(stdout ?? "").trim() }));
  });
}

// Renvoie "ok" (déjà autorisé), "fixed" (règles ajoutées), "refused" (l'utilisateur a dit non),
// ou "failed" (netsh n'a pas pu modifier le pare-feu, par exemple s'il est géré par un antivirus).
export async function ensureWindowsFirewall(port) {
  if (process.platform !== "win32") return "ok";
  const name = `Kikifest (port ${port})`;
  // Vérification sans droits administrateur : notre règle existe-t-elle déjà ?
  const check = await run("netsh", ["advfirewall", "firewall", "show", "rule", `name=${name}`]);
  if (check.code === 0) return "ok";

  // Correction, en une seule demande d'autorisation administrateur (fenêtre Windows « Oui / Non ») :
  // on retire les règles entrantes de Node.js (dont celles qui bloquent), puis on autorise Node.js et le port.
  const node = process.execPath;
  const script = path.join(os.tmpdir(), `kikifest-parefeu-${port}.cmd`);
  fs.writeFileSync(script, [
    "@echo off",
    `netsh advfirewall firewall delete rule name=all dir=in program="${node}" >nul 2>nul`,
    `netsh advfirewall firewall add rule name="Kikifest (Node.js)" dir=in action=allow program="${node}" enable=yes profile=any || exit /b 1`,
    `netsh advfirewall firewall add rule name="${name}" dir=in action=allow protocol=TCP localport=${port} enable=yes profile=any || exit /b 1`,
    "exit /b 0",
    "",
  ].join("\r\n"));
  const res = await run("powershell.exe", [
    "-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass", "-Command",
    `try { $p = Start-Process -FilePath cmd.exe -ArgumentList '/c','"${script.replace(/'/g, "''")}"' ` +
    `-Verb RunAs -Wait -PassThru -WindowStyle Hidden; Write-Output $p.ExitCode } catch { Write-Output 'refused' }`,
  ]);
  try { fs.unlinkSync(script); } catch {}
  if (res.out === "refused") return "refused";
  if (res.out === "0") return "fixed";
  return "failed";
}

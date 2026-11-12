// Windows : autorise les connexions entrantes vers Kikifest dans le pare-feu.
// Sans cela, Windows ignore en silence les connexions de l'invité (« délai d'attente dépassé »),
// en particulier si le réseau est classé « public » ou si l'on a cliqué « Annuler » au premier lancement
// (Windows crée alors une règle qui BLOQUE Node.js, prioritaire sur toute autorisation).
import { execFile } from "node:child_process";

function ps(script) {
  return new Promise((resolve) => {
    execFile("powershell.exe", ["-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass", "-Command", script],
      { windowsHide: true, timeout: 60000 }, (err, stdout) => resolve(err ? null : String(stdout).trim()));
  });
}

// Renvoie "ok" (déjà autorisé), "fixed" (règle ajoutée), "refused" (l'utilisateur a refusé), ou null (inconnu).
export async function ensureWindowsFirewall(port) {
  if (process.platform !== "win32") return "ok";
  const node = process.execPath.replace(/'/g, "''");
  const name = `Kikifest (port ${port})`;
  // Vérification sans droits administrateur.
  const check = await ps(
    `$allow = @(Get-NetFirewallPortFilter -Protocol TCP -ErrorAction SilentlyContinue | Where-Object { $_.LocalPort -eq '${port}' } | Get-NetFirewallRule | Where-Object { $_.Enabled -eq 'True' -and $_.Direction -eq 'Inbound' -and $_.Action -eq 'Allow' }).Count;` +
    `$block = @(Get-NetFirewallApplicationFilter -Program '${node}' -ErrorAction SilentlyContinue | Get-NetFirewallRule | Where-Object { $_.Enabled -eq 'True' -and $_.Direction -eq 'Inbound' -and $_.Action -eq 'Block' }).Count;` +
    `Write-Output "$allow $block"`,
  );
  if (check === null) return null;
  const [allow, block] = check.split(/\s+/).map(Number);
  if (allow > 0 && block === 0) return "ok";
  // Correction : une seule demande d'autorisation administrateur (fenêtre Windows « Oui / Non »).
  const fix =
    `Get-NetFirewallApplicationFilter -Program '${node}' | Get-NetFirewallRule | Where-Object { $_.Direction -eq 'Inbound' -and $_.Action -eq 'Block' } | Disable-NetFirewallRule;` +
    `Remove-NetFirewallRule -DisplayName '${name}' -ErrorAction SilentlyContinue;` +
    `New-NetFirewallRule -DisplayName '${name}' -Direction Inbound -Protocol TCP -LocalPort ${port} -Action Allow -Profile Any | Out-Null`;
  const encoded = Buffer.from(fix, "utf16le").toString("base64");
  const res = await ps(
    `try { $p = Start-Process powershell.exe -Verb RunAs -Wait -PassThru -WindowStyle Hidden ` +
    `-ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-EncodedCommand','${encoded}'; Write-Output $p.ExitCode } catch { Write-Output 'refused' }`,
  );
  if (res === "refused") return "refused";
  return res === "0" ? "fixed" : null;
}

// Mode « sans toucher à la box » : un tunnel Cloudflare gratuit et temporaire
// (https://xxxx.trycloudflare.com) relie internet à ce serveur, sans redirection de port
// ni règle de pare-feu entrante. L'outil cloudflared est téléchargé une seule fois
// depuis les publications officielles de Cloudflare sur GitHub, dans server/bin/.
import fs from "node:fs";
import path from "node:path";
import { spawn, execFileSync } from "node:child_process";

const BASE = "https://github.com/cloudflare/cloudflared/releases/latest/download/";

function assetName() {
  const arch = process.arch === "arm64" ? "arm64" : process.arch === "x64" ? "amd64" : null;
  if (!arch) return null;
  if (process.platform === "win32") return arch === "amd64" ? "cloudflared-windows-amd64.exe" : null;
  if (process.platform === "darwin") return `cloudflared-darwin-${arch}.tgz`;
  if (process.platform === "linux") return `cloudflared-linux-${arch}`;
  return null;
}

async function ensureBinary(binDir, log) {
  const exe = path.join(binDir, process.platform === "win32" ? "cloudflared.exe" : "cloudflared");
  if (fs.existsSync(exe)) return exe;
  const asset = assetName();
  if (!asset) throw new Error("système non pris en charge par cloudflared");
  log("Téléchargement de l'outil de tunnel (cloudflared, une seule fois, environ 40 Mo)...");
  fs.mkdirSync(binDir, { recursive: true });
  const res = await fetch(BASE + asset, { signal: AbortSignal.timeout(180000) });
  if (!res.ok) throw new Error(`téléchargement impossible (HTTP ${res.status})`);
  const tmp = path.join(binDir, asset + ".part");
  fs.writeFileSync(tmp, Buffer.from(await res.arrayBuffer()));
  if (asset.endsWith(".tgz")) {
    execFileSync("tar", ["-xzf", tmp, "-C", binDir]);
    fs.unlinkSync(tmp);
  } else fs.renameSync(tmp, exe);
  fs.chmodSync(exe, 0o755);
  return exe;
}

// Démarre le tunnel. Renvoie { url, stop() } ; lève une erreur en cas d'échec.
export async function startTunnel(port, binDir, log = console.log) {
  const exe = await ensureBinary(binDir, log);
  log("Ouverture du tunnel...");
  const child = spawn(exe, ["tunnel", "--no-autoupdate", "--url", `http://localhost:${port}`], {
    stdio: ["ignore", "pipe", "pipe"], windowsHide: true,
  });
  const url = await new Promise((resolve, reject) => {
    let out = "";
    const timer = setTimeout(() => reject(new Error("le tunnel ne s'est pas ouvert à temps")), 45000);
    const onData = (d) => {
      out += d;
      const m = /https:\/\/[a-z0-9-]+\.trycloudflare\.com/.exec(out);
      if (m) { clearTimeout(timer); resolve(m[0]); }
    };
    child.stdout.on("data", onData);
    child.stderr.on("data", onData);
    child.on("error", (e) => { clearTimeout(timer); reject(e); });
    child.on("exit", (c) => { clearTimeout(timer); reject(new Error(`cloudflared s'est arrêté (code ${c})`)); });
  });
  return { url, stop: () => { try { child.kill(); } catch {} } };
}

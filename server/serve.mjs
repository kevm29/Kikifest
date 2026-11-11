// Serveur de l'hôte Kikifest : sert le jeu et met les deux joueurs en relation.
//
//   node server/serve.mjs [port] [--no-upnp] [--no-open]
//
// - Fichiers du jeu (dossier web/) en HTTP.
// - Salons : l'hôte crée une partie (code à 5 lettres), l'invité la rejoint par le code ou le lien.
// - Signalisation WebRTC sur WebSocket (/ws) : offres, réponses et candidats ICE sont relayés
//   entre les deux joueurs, qui se connectent ensuite en direct (pair à pair).
// - Repli : si la connexion directe échoue, les messages du jeu passent par ce WebSocket.
//   Comme ce serveur tourne chez l'hôte, le trajet reste direct invité -> hôte.
// - Au démarrage : ouverture automatique du port sur la box (UPnP) et affichage du lien à envoyer.
import http from "node:http";
import fs from "node:fs";
import path from "node:path";
import crypto from "node:crypto";
import { spawn } from "node:child_process";
import { fileURLToPath } from "node:url";
import { attachWebSocket } from "./ws.mjs";
import { lanAddresses, publicAddressViaStun, openPortUpnp, isPrivateIp } from "./nat.mjs";

const here = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(here, "..", "web");

// ---------- Réglages : server/config.json (facultatif), puis ligne de commande ----------
let config = {};
try { config = JSON.parse(fs.readFileSync(path.join(here, "config.json"), "utf8")); }
catch (e) { if (e.code !== "ENOENT") console.warn("server/config.json illisible :", e.message); }
const args = process.argv.slice(2);
const portArg = args.find((a) => /^\d+$/.test(a));
const port = Number(portArg ?? process.env.PORT ?? config.port ?? 8080);
const useUpnp = !args.includes("--no-upnp") && config.upnp !== false;
const openBrowser = !args.includes("--no-open") && config.openBrowser !== false;
// Serveurs STUN (découverte d'adresse publique) et TURN (relais, facultatif) donnés aux navigateurs.
const iceServers = config.iceServers ?? [
  { urls: ["stun:stun.l.google.com:19302", "stun:stun.cloudflare.com:3478"] },
];

const info = { port, lan: lanAddresses(), publicIp: null, upnp: null, iceServers };

// ---------- Fichiers statiques ----------
const types = {
  ".html": "text/html; charset=utf-8", ".js": "text/javascript; charset=utf-8", ".json": "application/json",
  ".png": "image/png", ".jpg": "image/jpeg", ".gif": "image/gif", ".svg": "image/svg+xml",
  ".mp3": "audio/mpeg", ".wav": "audio/wav", ".xml": "application/xml", ".css": "text/css",
  ".ico": "image/x-icon", ".wasm": "application/wasm",
};

function serveFile(req, res) {
  let p;
  try { p = decodeURIComponent(new URL(req.url, "http://x").pathname); }
  catch { res.writeHead(400); res.end(); return; }
  if (p === "/api/info") {
    res.writeHead(200, { "content-type": "application/json", "cache-control": "no-store" });
    res.end(JSON.stringify({ ...info, upnp: info.upnp && { ok: info.upnp.ok, reason: info.upnp.reason } }));
    return;
  }
  if (p.endsWith("/")) p += "index.html";
  const file = path.join(root, p);
  if (!file.startsWith(root + path.sep)) { res.writeHead(403); res.end(); return; }
  fs.readFile(file, (err, data) => {
    if (err) { res.writeHead(404); res.end("introuvable"); return; }
    res.writeHead(200, {
      "content-type": types[path.extname(file)] ?? "application/octet-stream",
      "cache-control": "no-cache",
    });
    res.end(data);
  });
}

// ---------- Salons ----------
// Un salon = un hôte + au plus un invité. Code sans lettres ambiguës (pas de O/0, I/1).
const ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
const rooms = new Map(); // code -> { host, guest }
const MAX_ROOMS = 50;

function newCode() {
  for (;;) {
    const code = Array.from(crypto.randomBytes(5), (b) => ALPHABET[b % ALPHABET.length]).join("");
    if (!rooms.has(code)) return code;
  }
}

function onClient(ws) {
  let room = null, role = null;
  const other = () => (room ? (role === "host" ? room.guest : room.host) : null);

  ws.on("text", (text) => {
    let msg;
    try { msg = JSON.parse(text); } catch { return; }
    if (msg.t === "create" && !room) {
      if (rooms.size >= MAX_ROOMS) return ws.sendJson({ t: "error", msg: "Trop de parties ouvertes sur ce serveur." });
      const code = newCode();
      room = { code, host: ws, guest: null };
      role = "host";
      rooms.set(code, room);
      ws.sendJson({ t: "created", code, iceServers });
      console.log(`Partie ${code} créée.`);
    } else if (msg.t === "join" && !room) {
      const code = String(msg.code ?? "").toUpperCase().replace(/[^A-Z0-9]/g, "");
      const r = rooms.get(code);
      if (!r) return ws.sendJson({ t: "error", msg: `Aucune partie avec le code ${code || "(vide)"}.` });
      if (r.guest) return ws.sendJson({ t: "error", msg: "Cette partie a déjà deux joueurs." });
      room = r; role = "guest"; r.guest = ws;
      ws.sendJson({ t: "joined", code, iceServers });
      r.host.sendJson({ t: "peer-joined" });
      console.log(`Un invité a rejoint la partie ${code}.`);
    } else if (msg.t === "signal" && other()) {
      // Offre/réponse/candidats WebRTC et messages de contrôle du salon : relayés tels quels.
      other().sendJson({ t: "signal", data: msg.data });
    }
  });

  // Repli : messages du jeu en binaire, relayés tels quels à l'autre joueur.
  ws.on("binary", (buf) => { const o = other(); if (o) o.send(buf); });

  ws.on("close", () => {
    if (!room) return;
    if (role === "host") {
      room.guest?.sendJson({ t: "peer-left", msg: "L'hôte a quitté la partie." });
      room.guest?.close();
      rooms.delete(room.code);
      console.log(`Partie ${room.code} fermée.`);
    } else {
      room.guest = null;
      room.host.sendJson({ t: "peer-left", msg: "L'invité a quitté la partie." });
      console.log(`L'invité a quitté la partie ${room.code}.`);
    }
  });
}

// ---------- Démarrage ----------
const server = http.createServer(serveFile);
attachWebSocket(server, "/ws", onClient);

server.on("error", (e) => {
  if (e.code === "EADDRINUSE") {
    console.error(`\nLe port ${port} est déjà utilisé (Kikifest est peut-être déjà lancé ?).`);
    console.error(`Fermez l'autre fenêtre, ou choisissez un autre port :  node server/serve.mjs ${port + 1}\n`);
  } else console.error(e);
  process.exit(1);
});

server.listen(port, async () => {
  const local = `http://localhost:${port}/`;
  console.log("\n=== Kikifest : serveur de l'hôte ===\n");
  console.log(`Ouvrez le jeu sur cet ordinateur :  ${local}`);
  if (openBrowser) openInBrowser(local);

  console.log("\nRecherche de votre adresse internet...");
  const [stunIp, upnp] = await Promise.all([
    publicAddressViaStun(),
    useUpnp ? openPortUpnp(port) : Promise.resolve({ ok: false, reason: "désactivé" }),
  ]);
  info.upnp = upnp;
  info.publicIp = stunIp ?? (upnp.externalIp && !isPrivateIp(upnp.externalIp) ? upnp.externalIp : null);

  for (const ip of info.lan) console.log(`Invité sur le même réseau (Wi-Fi) :  http://${ip}:${port}/`);
  if (info.publicIp) console.log(`Invité par internet :                http://${info.publicIp}:${port}/`);
  else console.log("Adresse internet introuvable (pas d'accès à internet ?).");

  if (upnp.ok) {
    console.log(`\nPort ${port} ouvert automatiquement sur votre box (UPnP).`);
    if (upnp.externalIp && isPrivateIp(upnp.externalIp)) {
      console.log("Attention : votre box n'a pas d'adresse publique (box derrière une autre box, 4G ou CGNAT).");
      console.log("L'invité ne pourra sans doute pas vous joindre par internet. Voir docs/HEBERGER.md.");
    }
  } else {
    console.log(`\nOuverture automatique du port impossible : ${upnp.reason}.`);
    console.log(`Pour jouer par internet, redirigez le port TCP ${port} de votre box vers cet ordinateur`);
    console.log(`(${info.lan[0] ?? "son adresse locale"}). Mode d'emploi : docs/HEBERGER.md.`);
  }
  console.log("\nLaissez cette fenêtre ouverte pendant la partie. Ctrl+C pour arrêter.\n");
});

function openInBrowser(url) {
  const cmd = process.platform === "win32" ? ["cmd", ["/c", "start", "", url]]
    : process.platform === "darwin" ? ["open", [url]] : ["xdg-open", [url]];
  try { spawn(cmd[0], cmd[1], { stdio: "ignore", detached: true }).on("error", () => {}).unref(); } catch {}
}

let stopping = false;
async function stop() {
  if (stopping) process.exit(0);
  stopping = true;
  if (info.upnp?.ok) {
    console.log("Fermeture du port sur la box...");
    await Promise.race([info.upnp.remove().catch(() => {}), new Promise((r) => setTimeout(r, 2000))]);
  }
  process.exit(0);
}
process.on("SIGINT", stop);
process.on("SIGTERM", stop);

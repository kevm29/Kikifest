// Serveur de l'hôte Kikifest : sert le jeu et met les deux joueurs en relation.
//
//   node server/serve.mjs [port] [--no-upnp] [--no-open] [--tunnel | --no-tunnel]
//
// - Fichiers du jeu (dossier web/) en HTTP.
// - Salons : l'hôte crée une partie (code à 5 lettres), l'invité la rejoint par le code ou le lien.
// - Signalisation WebRTC sur WebSocket (/ws) : offres, réponses et candidats ICE sont relayés
//   entre les deux joueurs, qui se connectent ensuite en direct (pair à pair).
// - Repli : si la connexion directe échoue, les messages du jeu passent par ce WebSocket.
//   Comme ce serveur tourne chez l'hôte, le trajet reste direct invité -> hôte.
// - Au démarrage : autorisation dans le pare-feu Windows, ouverture du port sur la box (UPnP),
//   vérification depuis internet que le port est vraiment joignable, et sinon tunnel gratuit
//   (https://xxxx.trycloudflare.com) qui marche sans rien régler sur la box. Puis lien à envoyer.
import http from "node:http";
import fs from "node:fs";
import path from "node:path";
import crypto from "node:crypto";
import { spawn } from "node:child_process";
import { fileURLToPath } from "node:url";
import { attachWebSocket } from "./ws.mjs";
import { lanAddresses, publicAddressViaStun, openPortUpnp, isPrivateIp, checkReachable } from "./nat.mjs";
import { ensureWindowsFirewall } from "./firewall.mjs";
import { startTunnel } from "./tunnel.mjs";

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
// Tunnel : "auto" (seulement si le port n'est pas joignable), true (toujours), false (jamais).
const tunnelMode = args.includes("--tunnel") ? true : args.includes("--no-tunnel") ? false : (config.tunnel ?? "auto");
// Serveurs STUN (découverte d'adresse publique) et TURN (relais, facultatif) donnés aux navigateurs.
const iceServers = config.iceServers ?? [
  { urls: ["stun:stun.l.google.com:19302", "stun:stun.cloudflare.com:3478"] },
];

// ready passe à true quand toutes les vérifications du démarrage sont finies.
// reachable : le port est-il joignable depuis internet (true / false / null = inconnu).
// tunnelUrl : adresse du tunnel, à donner à l'invité en priorité quand elle existe.
const info = { port, lan: lanAddresses(), publicIp: null, upnp: null, reachable: null, tunnelUrl: null, ready: false, iceServers };
let tunnel = null;

// ---------- Fichiers statiques ----------
const types = {
  ".html": "text/html; charset=utf-8", ".js": "text/javascript; charset=utf-8", ".json": "application/json",
  ".png": "image/png", ".jpg": "image/jpeg", ".gif": "image/gif", ".svg": "image/svg+xml",
  ".mp3": "audio/mpeg", ".wav": "audio/wav", ".xml": "application/xml", ".css": "text/css",
  ".ico": "image/x-icon", ".wasm": "application/wasm",
};

// ---------- Sauvegardes des joueurs ----------
// La collection (frigo, quêtes, classement) de chaque joueur est aussi gardée chez l'hôte, par pseudo :
// l'invité n'a pas le jeu, et l'adresse du lien change (tunnel), ce qui viderait la mémoire de son navigateur.
const savesDir = path.join(here, "..", "saves");
function saveFileOf(name) {
  const n = String(name ?? "").trim().toLowerCase().slice(0, 40);
  if (!n) return null;
  return path.join(savesDir, Buffer.from(n).toString("hex") + ".json");
}
function saveApi(req, res) {
  const url = new URL(req.url, "http://x");
  const file = saveFileOf(url.searchParams.get("name"));
  const reply = (code, body) => { res.writeHead(code, { "content-type": "application/json", "cache-control": "no-store" }); res.end(body ?? "null"); };
  if (!file) return reply(400);
  if (req.method === "GET") {
    fs.readFile(file, "utf8", (err, data) => reply(200, err ? "null" : data));
    return;
  }
  if (req.method !== "POST") return reply(405);
  let body = "";
  req.on("data", (c) => { body += c; if (body.length > 2_000_000) req.destroy(); });
  req.on("end", () => {
    try { JSON.parse(body); } catch { return reply(400); }
    fs.mkdir(savesDir, { recursive: true }, () => fs.writeFile(file, body, (err) => reply(err ? 500 : 200, "true")));
  });
}

function serveFile(req, res) {
  let p;
  try { p = decodeURIComponent(new URL(req.url, "http://x").pathname); }
  catch { res.writeHead(400); res.end(); return; }
  if (p === "/api/ping") { res.writeHead(200, { "cache-control": "no-store" }); res.end("kikifest"); return; }
  if (p === "/api/info") {
    res.writeHead(200, { "content-type": "application/json", "cache-control": "no-store" });
    res.end(JSON.stringify({ ...info, upnp: info.upnp && { ok: info.upnp.ok, reason: info.upnp.reason } }));
    return;
  }
  if (p === "/api/save") { saveApi(req, res); return; }
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
// Un salon = un hôte + jusqu'à 3 invités (partie à 4). Code sans lettres ambiguës (pas de O/0, I/1).
// Chaque invité a sa « place » (slot) : l'hôte ouvre pour lui une 2e connexion (« attach »), et le
// serveur relaie entre ces deux-là (signalisation WebRTC, puis repli binaire), comme à deux.
const ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
const rooms = new Map(); // code -> { code, host, key, slots: Map(slot -> { guest, hostSide }), next }
const MAX_ROOMS = 50;
const MAX_GUESTS = 3;

function newCode() {
  for (;;) {
    const code = Array.from(crypto.randomBytes(5), (b) => ALPHABET[b % ALPHABET.length]).join("");
    if (!rooms.has(code)) return code;
  }
}

function onClient(ws) {
  // role : "host" (connexion principale de l'hôte), "side" (connexion de l'hôte pour un invité), "guest"
  let room = null, role = null, slot = null;
  const pair = () => (room && slot != null ? room.slots.get(slot) : null);
  const other = () => {
    const p = pair();
    return p ? (role === "guest" ? p.hostSide : p.guest) : null;
  };

  ws.on("text", (text) => {
    let msg;
    try { msg = JSON.parse(text); } catch { return; }
    if (msg.t === "create" && !room) {
      if (rooms.size >= MAX_ROOMS) return ws.sendJson({ t: "error", msg: "Trop de parties ouvertes sur ce serveur." });
      const code = newCode();
      room = { code, host: ws, key: crypto.randomBytes(12).toString("hex"), slots: new Map(), next: 1 };
      role = "host";
      rooms.set(code, room);
      ws.sendJson({ t: "created", code, key: room.key, iceServers });
      console.log(`Partie ${code} créée.`);
    } else if (msg.t === "join" && !room) {
      const code = String(msg.code ?? "").toUpperCase().replace(/[^A-Z0-9]/g, "");
      const r = rooms.get(code);
      if (!r) return ws.sendJson({ t: "error", msg: `Aucune partie avec le code ${code || "(vide)"}.` });
      if (r.slots.size >= MAX_GUESTS) return ws.sendJson({ t: "error", msg: "Cette partie est complète (4 joueurs maximum)." });
      room = r; role = "guest"; slot = r.next++;
      r.slots.set(slot, { guest: ws, hostSide: null });
      ws.sendJson({ t: "joined", code, iceServers });
      r.host.sendJson({ t: "peer-joined", slot });
      console.log(`Un invité a rejoint la partie ${code} (${r.slots.size + 1} joueurs).`);
    } else if (msg.t === "attach" && !room) {
      const r = rooms.get(String(msg.code ?? ""));
      const p = r && r.key === msg.key ? r.slots.get(msg.slot) : null;
      if (!p || p.hostSide) return ws.sendJson({ t: "error", msg: "Cet invité n'est plus là." });
      room = r; role = "side"; slot = msg.slot; p.hostSide = ws;
      ws.sendJson({ t: "attached", slot });
    } else if (msg.t === "signal" && other()) {
      // Offre/réponse/candidats WebRTC et messages de contrôle du salon : relayés tels quels.
      other().sendJson({ t: "signal", data: msg.data });
    }
  });

  // Repli : messages du jeu en binaire, relayés tels quels entre l'invité et l'hôte.
  ws.on("binary", (buf) => { const o = other(); if (o) o.send(buf); });

  ws.on("close", () => {
    if (!room) return;
    if (role === "host") {
      for (const p of room.slots.values()) {
        p.guest.sendJson({ t: "peer-left", msg: "L'hôte a quitté la partie." });
        p.guest.close();
        p.hostSide?.close();
      }
      rooms.delete(room.code);
      console.log(`Partie ${room.code} fermée.`);
    } else if (role === "guest") {
      const p = pair();
      room.slots.delete(slot);
      p?.hostSide?.sendJson({ t: "peer-left", msg: "L'invité a quitté la partie." });
      room.host.sendJson({ t: "peer-left", slot, msg: "L'invité a quitté la partie." });
      console.log(`Un invité a quitté la partie ${room.code}.`);
    } else {
      // l'hôte a fermé sa liaison avec cet invité
      const p = pair();
      if (p && p.hostSide === ws) {
        p.guest.sendJson({ t: "peer-left", msg: "L'hôte a fermé la connexion." });
        p.guest.close();
      }
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

  console.log("\nPréparation de la connexion par internet (quelques secondes)...");
  if (process.platform === "win32") console.log("Si Windows demande l'autorisation de modifier le pare-feu, répondez « Oui ».");
  const [stunIp, upnp, firewall] = await Promise.all([
    publicAddressViaStun(),
    useUpnp ? openPortUpnp(port) : Promise.resolve({ ok: false, reason: "désactivé" }),
    ensureWindowsFirewall(port),
  ]);
  info.publicIp = stunIp ?? (upnp.externalIp && !isPrivateIp(upnp.externalIp) ? upnp.externalIp : null);
  if (firewall === "fixed") console.log("Pare-feu Windows : Kikifest est maintenant autorisé.");
  else if (firewall === "refused") console.log("Pare-feu Windows : autorisation refusée, l'invité risque d'être bloqué.");
  else if (firewall === "failed") {
    console.log("Pare-feu : impossible de le régler automatiquement. S'il est géré par un antivirus (Avast, Norton,");
    console.log("Kaspersky, Bitdefender...), autorisez Node.js dans les réglages de son pare-feu.");
  }
  if (upnp.ok) console.log(`Box : port ${port} ouvert automatiquement (UPnP).`);
  else console.log(`Box : ouverture automatique du port impossible (${upnp.reason}).`);

  info.reachable = info.publicIp ? await checkReachable(port, info.publicIp) : false;
  if (!info.publicIp) console.log("Adresse internet introuvable (pas d'accès à internet, ou STUN bloqué).");
  else if (info.reachable === true) console.log(`Vérification depuis internet : le port ${port} est bien joignable.`);
  else if (info.reachable === false) console.log(`Vérification depuis internet : le port ${port} n'est PAS joignable.`);
  else console.log("Vérification depuis internet impossible (service de test injoignable).");

  if (tunnelMode === true || (tunnelMode === "auto" && info.reachable !== true)) {
    if (tunnelMode === "auto") console.log("\nPassage en mode « sans toucher à la box » : ouverture d'un tunnel gratuit.");
    try {
      tunnel = await startTunnel(port, path.join(here, "bin"));
      info.tunnelUrl = tunnel.url;
    } catch (e) {
      console.log(`Tunnel impossible : ${e.message}.`);
    }
  }

  info.upnp = upnp;
  info.ready = true;

  console.log("\n--- Liens à envoyer à l'autre joueur (le menu Multijoueur les affiche aussi) ---");
  if (info.tunnelUrl) {
    console.log(`Par internet :              ${info.tunnelUrl}/`);
    if (info.publicIp) console.log(`Par internet, en direct :   http://${info.publicIp}:${port}/   (si votre port est ouvert)`);
  }
  else if (info.publicIp) console.log(`Par internet :              http://${info.publicIp}:${port}/${info.reachable ? "" : "   (risque de ne pas marcher, voir docs/HEBERGER.md)"}`);
  for (const ip of info.lan) console.log(`Chez vous (même Wi-Fi) :    http://${ip}:${port}/`);
  if (upnp.ok && upnp.externalIp && isPrivateIp(upnp.externalIp) && !info.tunnelUrl) {
    console.log("Attention : votre box n'a pas d'adresse publique (box derrière une autre box, 4G ou CGNAT).");
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
  tunnel?.stop();
  if (info.upnp?.ok) {
    console.log("Fermeture du port sur la box...");
    await Promise.race([info.upnp.remove().catch(() => {}), new Promise((r) => setTimeout(r, 2000))]);
  }
  process.exit(0);
}
process.on("SIGINT", stop);
process.on("SIGTERM", stop);

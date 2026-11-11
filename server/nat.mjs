// Outils réseau pour l'hôte : adresses locales, adresse publique (STUN),
// et ouverture automatique du port sur la box (UPnP), sans dépendance npm.
import dgram from "node:dgram";
import os from "node:os";
import crypto from "node:crypto";

// Adresses IPv4 de la machine sur le réseau local (Wi-Fi, Ethernet).
export function lanAddresses() {
  const out = [];
  for (const list of Object.values(os.networkInterfaces())) {
    for (const a of list ?? []) {
      if (a.family === "IPv4" && !a.internal) out.push(a.address);
    }
  }
  return out;
}

// Demande à un serveur STUN public quelle adresse il voit : c'est l'adresse publique de la box.
export function publicAddressViaStun(host = "stun.l.google.com", port = 19302, timeout = 2500) {
  return new Promise((resolve) => {
    const sock = dgram.createSocket("udp4");
    const tid = crypto.randomBytes(12);
    const done = (v) => { clearTimeout(timer); try { sock.close(); } catch {} resolve(v); };
    const timer = setTimeout(() => done(null), timeout);
    sock.on("error", () => done(null));
    sock.on("message", (m) => {
      if (m.length < 20 || m.readUInt16BE(0) !== 0x0101 || !m.subarray(8, 20).equals(tid)) return;
      let off = 20;
      while (off + 4 <= m.length) {
        const type = m.readUInt16BE(off), len = m.readUInt16BE(off + 2), v = off + 4;
        if ((type === 0x0020 || type === 0x0001) && m[v + 1] === 0x01) {
          const xor = type === 0x0020;
          const ip = [0, 1, 2, 3].map((i) => m[v + 4 + i] ^ (xor ? [0x21, 0x12, 0xa4, 0x42][i] : 0));
          return done(ip.join("."));
        }
        off = v + len + ((4 - (len % 4)) % 4);
      }
      done(null);
    });
    const req = Buffer.alloc(20);
    req.writeUInt16BE(0x0001, 0); // Binding Request
    req.writeUInt32BE(0x2112a442, 4); // magic cookie
    tid.copy(req, 8);
    sock.send(req, port, host, (err) => { if (err) done(null); });
  });
}

// ---------- UPnP (IGD) ----------

const SSDP_ADDR = "239.255.255.250";
const SEARCH_TARGETS = [
  "urn:schemas-upnp-org:device:InternetGatewayDevice:1",
  "urn:schemas-upnp-org:device:InternetGatewayDevice:2",
  "urn:schemas-upnp-org:service:WANIPConnection:1",
];
const SERVICE_TYPES = [
  "urn:schemas-upnp-org:service:WANIPConnection:2",
  "urn:schemas-upnp-org:service:WANIPConnection:1",
  "urn:schemas-upnp-org:service:WANPPPConnection:1",
];

function discoverGateway(timeout = 2500) {
  return new Promise((resolve) => {
    const sock = dgram.createSocket({ type: "udp4", reuseAddr: true });
    const done = (v) => { clearTimeout(timer); try { sock.close(); } catch {} resolve(v); };
    const timer = setTimeout(() => done(null), timeout);
    sock.on("error", () => done(null));
    sock.on("message", (msg) => {
      const m = /^location:\s*(\S+)/im.exec(msg.toString());
      if (m) done(m[1]);
    });
    sock.bind(() => {
      for (const st of SEARCH_TARGETS) {
        const q = `M-SEARCH * HTTP/1.1\r\nHOST: ${SSDP_ADDR}:1900\r\nMAN: "ssdp:discover"\r\nMX: 2\r\nST: ${st}\r\n\r\n`;
        sock.send(q, 1900, SSDP_ADDR, () => {});
      }
    });
  });
}

async function findControl(location) {
  const res = await fetch(location, { signal: AbortSignal.timeout(3000) });
  const xml = await res.text();
  for (const type of SERVICE_TYPES) {
    const i = xml.indexOf(`<serviceType>${type}</serviceType>`);
    if (i < 0) continue;
    const end = xml.indexOf("</service>", i);
    const m = /<controlURL>\s*([^<]+?)\s*<\/controlURL>/.exec(xml.slice(i, end));
    if (m) return { url: new URL(m[1], location).href, type };
  }
  return null;
}

async function soap(ctrl, action, args) {
  const body =
    `<?xml version="1.0"?><s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" ` +
    `s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"><s:Body><u:${action} xmlns:u="${ctrl.type}">` +
    Object.entries(args).map(([k, v]) => `<${k}>${v}</${k}>`).join("") +
    `</u:${action}></s:Body></s:Envelope>`;
  const res = await fetch(ctrl.url, {
    method: "POST",
    headers: { "content-type": 'text/xml; charset="utf-8"', soapaction: `"${ctrl.type}#${action}"` },
    body,
    signal: AbortSignal.timeout(4000),
  });
  const text = await res.text();
  if (!res.ok) {
    const code = /<errorCode>(\d+)<\/errorCode>/.exec(text)?.[1];
    throw new Error(`${action} refusé par la box (HTTP ${res.status}${code ? `, code ${code}` : ""})`);
  }
  return text;
}

// Adresse locale utilisée pour joindre la box (celle à donner dans la redirection de port).
function localAddressToward(host) {
  return new Promise((resolve) => {
    const s = dgram.createSocket("udp4");
    s.on("error", () => { try { s.close(); } catch {} resolve(lanAddresses()[0] ?? null); });
    s.connect(1900, host, () => { const a = s.address().address; s.close(); resolve(a); });
  });
}

// Ouvre le port TCP `port` sur la box. Renvoie { ok, externalIp, internalIp, remove() } ou { ok:false, reason }.
export async function openPortUpnp(port, knownLocation = null) {
  try {
    const location = knownLocation ?? await discoverGateway();
    if (!location) return { ok: false, reason: "aucune box compatible UPnP n'a répondu" };
    const ctrl = await findControl(location);
    if (!ctrl) return { ok: false, reason: "la box ne propose pas l'ouverture de port UPnP" };
    const internalIp = await localAddressToward(new URL(location).hostname);
    const args = (lease) => ({
      NewRemoteHost: "", NewExternalPort: port, NewProtocol: "TCP", NewInternalPort: port,
      NewInternalClient: internalIp, NewEnabled: 1, NewPortMappingDescription: "Kikifest",
      NewLeaseDuration: lease,
    });
    try { await soap(ctrl, "AddPortMapping", args(0)); } // 0 = sans limite (certaines box le refusent)
    catch { await soap(ctrl, "AddPortMapping", args(86400)); }
    let externalIp = null;
    try {
      const xml = await soap(ctrl, "GetExternalIPAddress", {});
      externalIp = /<NewExternalIPAddress>([^<]*)</.exec(xml)?.[1] || null;
    } catch {}
    const remove = () => soap(ctrl, "DeletePortMapping", { NewRemoteHost: "", NewExternalPort: port, NewProtocol: "TCP" });
    return { ok: true, externalIp, internalIp, remove };
  } catch (e) {
    return { ok: false, reason: e.message };
  }
}

// Une adresse privée (box en cascade, 4G, fibre partagée "CGNAT") ne peut pas recevoir de connexion entrante.
export function isPrivateIp(ip) {
  const [a, b] = ip.split(".").map(Number);
  return a === 10 || a === 127 || (a === 172 && b >= 16 && b < 32) || (a === 192 && b === 168) ||
    (a === 100 && b >= 64 && b < 128) || (a === 169 && b === 254);
}

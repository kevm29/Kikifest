// WebSocket minimal (RFC 6455) côté serveur, sans dépendance npm.
// Gère : poignée de main, trames texte et binaires, fragmentation, ping/pong, fermeture.
import crypto from "node:crypto";
import { EventEmitter } from "node:events";

const GUID = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11";
const MAX_MESSAGE = 256 * 1024;

export class WsClient extends EventEmitter {
  constructor(socket) {
    super();
    this.socket = socket;
    this.open = true;
    this.buf = Buffer.alloc(0);
    this.frags = null; // { opcode, parts, size }
    socket.setNoDelay(true); // pas d'attente de Nagle : chaque message part tout de suite
    socket.on("data", (d) => this.#onData(d));
    socket.on("close", () => this.#closed());
    socket.on("error", () => this.#closed());
    this.alive = true;
    this.pinger = setInterval(() => {
      if (!this.alive) return this.terminate();
      this.alive = false;
      this.#frame(0x9, Buffer.alloc(0));
    }, 20000);
  }

  send(data) {
    if (!this.open) return;
    if (typeof data === "string") this.#frame(0x1, Buffer.from(data));
    else this.#frame(0x2, Buffer.isBuffer(data) ? data : Buffer.from(data));
  }

  sendJson(obj) { this.send(JSON.stringify(obj)); }

  close(code = 1000) {
    if (!this.open) return;
    const b = Buffer.alloc(2); b.writeUInt16BE(code);
    this.#frame(0x8, b);
    this.socket.end();
    this.#closed();
  }

  terminate() { this.socket.destroy(); this.#closed(); }

  #closed() {
    if (!this.open) return;
    this.open = false;
    clearInterval(this.pinger);
    this.emit("close");
  }

  #frame(opcode, payload) {
    if (!this.open || this.socket.destroyed) return;
    const n = payload.length;
    let head;
    if (n < 126) { head = Buffer.alloc(2); head[1] = n; }
    else if (n < 65536) { head = Buffer.alloc(4); head[1] = 126; head.writeUInt16BE(n, 2); }
    else { head = Buffer.alloc(10); head[1] = 127; head.writeBigUInt64BE(BigInt(n), 2); }
    head[0] = 0x80 | opcode;
    this.socket.write(Buffer.concat([head, payload]));
  }

  #onData(d) {
    this.buf = this.buf.length ? Buffer.concat([this.buf, d]) : d;
    for (;;) {
      const b = this.buf;
      if (b.length < 2) return;
      const fin = (b[0] & 0x80) !== 0, opcode = b[0] & 0x0f, masked = (b[1] & 0x80) !== 0;
      let len = b[1] & 0x7f, off = 2;
      if (len === 126) { if (b.length < 4) return; len = b.readUInt16BE(2); off = 4; }
      else if (len === 127) {
        if (b.length < 10) return;
        const big = b.readBigUInt64BE(2);
        if (big > BigInt(MAX_MESSAGE)) return this.close(1009);
        len = Number(big); off = 10;
      }
      if (len > MAX_MESSAGE) return this.close(1009);
      if (!masked) return this.close(1002); // un client doit masquer ses trames
      if (b.length < off + 4 + len) return;
      const mask = b.subarray(off, off + 4);
      const payload = Buffer.from(b.subarray(off + 4, off + 4 + len));
      for (let i = 0; i < len; i++) payload[i] ^= mask[i & 3];
      this.buf = b.subarray(off + 4 + len);
      this.#onFrame(fin, opcode, payload);
      if (!this.open) return;
    }
  }

  #onFrame(fin, opcode, payload) {
    this.alive = true;
    if (opcode === 0x8) return this.close();
    if (opcode === 0x9) return this.#frame(0xa, payload);
    if (opcode === 0xa) return;
    if (opcode === 0x0) {
      if (!this.frags) return this.close(1002);
      this.frags.parts.push(payload);
      this.frags.size += payload.length;
      if (this.frags.size > MAX_MESSAGE) return this.close(1009);
      if (!fin) return;
      const { opcode: op, parts } = this.frags;
      this.frags = null;
      return this.#deliver(op, Buffer.concat(parts));
    }
    if (opcode !== 0x1 && opcode !== 0x2) return this.close(1003);
    if (!fin) { this.frags = { opcode, parts: [payload], size: payload.length }; return; }
    this.#deliver(opcode, payload);
  }

  #deliver(opcode, payload) {
    if (opcode === 0x1) this.emit("text", payload.toString("utf8"));
    else this.emit("binary", payload);
  }
}

// Branche le WebSocket sur un serveur HTTP Node : onClient(ws, req) est appelé à chaque connexion.
export function attachWebSocket(server, pathname, onClient) {
  server.on("upgrade", (req, socket) => {
    const url = new URL(req.url, "http://x");
    const key = req.headers["sec-websocket-key"];
    if (url.pathname !== pathname || !key || (req.headers.upgrade || "").toLowerCase() !== "websocket") {
      socket.end("HTTP/1.1 400 Bad Request\r\n\r\n");
      return;
    }
    const accept = crypto.createHash("sha1").update(key + GUID).digest("base64");
    socket.write(
      "HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n" +
      `Sec-WebSocket-Accept: ${accept}\r\n\r\n`,
    );
    onClient(new WsClient(socket), req);
  });
}

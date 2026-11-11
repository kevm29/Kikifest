// KikiNet : mise en relation des deux joueurs (script classique, expose window.KikiNet).
//
//   KikiNet.host({ onCode(code), onStatus(texte) })  -> Promise<Peer>   (crée une partie)
//   KikiNet.join(code, { onStatus(texte) })          -> Promise<Peer>   (rejoint une partie)
//
// Peer :
//   role        "host" | "guest"
//   seed        entier 32 bits non signé, tiré par l'hôte, identique des deux côtés
//   transport   "webrtc" (pair à pair direct) | "relay" (via le serveur de l'hôte)
//   rtt         aller-retour en millisecondes (mis à jour chaque seconde)
//   send(data)          rapide : non fiable, non ordonné (pour les entrées du rollback)
//   sendReliable(data)  fiable et ordonné (pour les messages qui ne doivent pas se perdre)
//   onmessage = (data, reliable) => {}   data : string ou ArrayBuffer (comme envoyé) ;
//               réaffectable ; les messages arrivés avant l'affectation sont gardés en file
//   onclose   = (raison) => {}
//   close()
//
// Options de test dans l'URL de la page : ?relay=1 force le repli par le serveur.
(function () {
  "use strict";

  const RTC_TIMEOUT = 10000; // au-delà, on passe par le serveur de l'hôte
  const DEAD_AFTER = 8000;   // sans nouvelles de l'autre pendant ce temps : connexion perdue
  const FLAG_RELIABLE = 1, FLAG_STRING = 2, FLAG_CTL = 4;
  const enc = new TextEncoder(), dec = new TextDecoder();
  const forceRelay = new URLSearchParams(location.search).has("relay");

  function openSignal() {
    return new Promise((resolve, reject) => {
      const ws = new WebSocket((location.protocol === "https:" ? "wss://" : "ws://") + location.host + "/ws");
      ws.binaryType = "arraybuffer";
      ws.onopen = () => resolve(ws);
      ws.onerror = () => reject(new Error("Impossible de joindre le serveur de l'hôte."));
    });
  }

  function wait(ms) { return new Promise((r) => setTimeout(r, ms)); }

  class Peer {
    constructor(role, seed, ws) {
      this.role = role;
      this.seed = seed;
      this.ws = ws;
      this.transport = null;
      this.rtt = 0;
      this._onmessage = null;
      this._queue = []; // messages reçus avant que onmessage soit affecté
      this.onclose = null;
      this.closed = false;
      this.lastSeen = performance.now();
      this.pc = null;
      this.ch = null; // { fast, sure, ctl }
    }

    _useWebrtc(pc, ch) {
      this.transport = "webrtc";
      this.pc = pc;
      this.ch = ch;
      ch.fast.onmessage = (e) => this._receive(e.data, false);
      ch.sure.onmessage = (e) => this._receive(e.data, true);
      ch.ctl.onmessage = (e) => this._control(e.data);
      for (const c of Object.values(ch)) c.onclose = () => this._end("La connexion directe s'est fermée.");
      pc.onconnectionstatechange = () => {
        if (pc.connectionState === "failed" || pc.connectionState === "closed") this._end("Connexion directe perdue.");
      };
      this._start();
    }

    _useRelay() {
      this.transport = "relay";
      this._start();
    }

    _start() {
      this.lastSeen = performance.now();
      this.timer = setInterval(() => {
        if (performance.now() - this.lastSeen > DEAD_AFTER) return this._end("L'autre joueur ne répond plus.");
        this._sendCtl("p" + performance.now());
      }, 1000);
      this.ws.addEventListener("message", (e) => {
        if (typeof e.data === "string") {
          const msg = JSON.parse(e.data);
          if (msg.t === "peer-left") this._end(msg.msg);
          return;
        }
        if (this.transport !== "relay") return;
        const u = new Uint8Array(e.data), flags = u[0], body = u.subarray(1);
        if (flags & FLAG_CTL) return this._control(dec.decode(body));
        const data = flags & FLAG_STRING ? dec.decode(body) : body.slice().buffer;
        this._receive(data, (flags & FLAG_RELIABLE) !== 0);
      });
      this.ws.addEventListener("close", () => {
        // En direct, la partie peut continuer sans le serveur ; en relais, c'est la fin.
        if (this.transport === "relay") this._end("Le serveur de l'hôte s'est arrêté.");
      });
    }

    get onmessage() { return this._onmessage; }
    set onmessage(fn) {
      this._onmessage = fn;
      while (fn && this._queue.length && this._onmessage === fn) fn(...this._queue.shift());
    }

    _receive(data, reliable) {
      this.lastSeen = performance.now();
      if (this._onmessage) this._onmessage(data, reliable);
      else if (this._queue.length < 10000) this._queue.push([data, reliable]);
    }

    _control(s) {
      this.lastSeen = performance.now();
      if (s[0] === "p") this._sendCtl("q" + s.slice(1));
      else if (s[0] === "q") {
        const sample = performance.now() - Number(s.slice(1));
        this.rtt = this.rtt ? this.rtt * 0.8 + sample * 0.2 : sample;
      } else if (s === "bye") this._end("L'autre joueur a quitté la partie.");
    }

    _relay(flags, data) {
      if (this.ws.readyState !== WebSocket.OPEN) return;
      let body;
      if (typeof data === "string") { body = enc.encode(data); flags |= FLAG_STRING; }
      else body = data instanceof ArrayBuffer ? new Uint8Array(data)
        : new Uint8Array(data.buffer, data.byteOffset, data.byteLength);
      const out = new Uint8Array(body.length + 1);
      out[0] = flags;
      out.set(body, 1);
      this.ws.send(out);
    }

    _sendCtl(s) {
      if (this.closed) return;
      if (this.transport === "webrtc") { if (this.ch.ctl.readyState === "open") this.ch.ctl.send(s); }
      else this._relay(FLAG_CTL, s);
    }

    send(data) {
      if (this.closed) return;
      if (this.transport === "webrtc") { if (this.ch.fast.readyState === "open") this.ch.fast.send(data); }
      else this._relay(0, data);
    }

    sendReliable(data) {
      if (this.closed) return;
      if (this.transport === "webrtc") { if (this.ch.sure.readyState === "open") this.ch.sure.send(data); }
      else this._relay(FLAG_RELIABLE, data);
    }

    close() {
      if (this.closed) return;
      this._sendCtl("bye");
      this._end(null);
    }

    _end(reason) {
      if (this.closed) return;
      this.closed = true;
      clearInterval(this.timer);
      setTimeout(() => { try { this.pc && this.pc.close(); } catch (e) {} try { this.ws.close(); } catch (e) {} }, 100);
      if (this.onclose) this.onclose(reason);
    }
  }

  // Connexion WebRTC : trois canaux pré-négociés (mêmes identifiants des deux côtés).
  function makeRtc(iceServers, signal) {
    const pc = new RTCPeerConnection({ iceServers });
    const ch = {
      fast: pc.createDataChannel("fast", { negotiated: true, id: 0, ordered: false, maxRetransmits: 0 }),
      sure: pc.createDataChannel("sure", { negotiated: true, id: 1, ordered: true }),
      ctl: pc.createDataChannel("ctl", { negotiated: true, id: 2, ordered: false, maxRetransmits: 0 }),
    };
    for (const c of Object.values(ch)) c.binaryType = "arraybuffer";
    pc.onicecandidate = (e) => { if (e.candidate) signal({ type: "ice", c: e.candidate }); };
    const pending = [];
    const opened = new Promise((resolve, reject) => {
      let n = 0;
      for (const c of Object.values(ch)) c.onopen = () => { if (++n === 3) resolve(); };
      pc.onconnectionstatechange = () => { if (pc.connectionState === "failed") reject(new Error("échec ICE")); };
    });
    opened.catch(() => {});
    return {
      pc, ch, opened,
      async onSignal(d) {
        if (d.type === "sdp") {
          await pc.setRemoteDescription(d.sdp);
          for (const c of pending.splice(0)) await pc.addIceCandidate(c).catch(() => {});
          if (d.sdp.type === "offer") {
            await pc.setLocalDescription(await pc.createAnswer());
            signal({ type: "sdp", sdp: pc.localDescription });
          }
        } else if (d.type === "ice") {
          if (pc.remoteDescription) await pc.addIceCandidate(d.c).catch(() => {});
          else pending.push(d.c);
        }
      },
    };
  }

  function timeout(p, ms) {
    return Promise.race([p.then(() => true), wait(ms).then(() => false)]).catch(() => false);
  }

  async function host(opts = {}) {
    const status = opts.onStatus || (() => {});
    status("Connexion au serveur...");
    const ws = await openSignal();
    const signal = (data) => ws.send(JSON.stringify({ t: "signal", data }));
    return new Promise((resolve, reject) => {
      let rtc = null, peer = null, ackWaiter = null;
      const onMsg = async (e) => {
        if (typeof e.data !== "string") return;
        const msg = JSON.parse(e.data);
        if (msg.t === "error") { reject(new Error(msg.msg)); ws.close(); }
        else if (msg.t === "created") { opts.iceServers = msg.iceServers; opts.onCode && opts.onCode(msg.code); status("En attente de l'autre joueur..."); }
        else if (msg.t === "peer-joined" && !peer) {
          status("L'autre joueur arrive, connexion directe en cours...");
          const seed = crypto.getRandomValues(new Uint32Array(1))[0];
          rtc = makeRtc(opts.iceServers, signal);
          let ok = false;
          if (!forceRelay) {
            await rtc.pc.setLocalDescription(await rtc.pc.createOffer());
            signal({ type: "sdp", sdp: rtc.pc.localDescription });
            ok = await timeout(rtc.opened, RTC_TIMEOUT);
          }
          const ack = new Promise((r) => (ackWaiter = r));
          signal({ type: "ready", transport: ok ? "webrtc" : "relay", seed });
          const guestTransport = await ack;
          peer = new Peer("host", seed, ws);
          ws.removeEventListener("message", onMsg);
          if (ok && guestTransport === "webrtc") peer._useWebrtc(rtc.pc, rtc.ch);
          else { rtc.pc.close(); peer._useRelay(); }
          resolve(peer);
        } else if (msg.t === "peer-left" && !peer) {
          if (rtc) { rtc.pc.close(); rtc = null; }
          if (ackWaiter) ackWaiter("relay");
          status("L'autre joueur est parti. En attente d'un nouvel invité...");
        } else if (msg.t === "signal") {
          if (msg.data.type === "ack") ackWaiter && ackWaiter(msg.data.transport);
          else if (rtc) rtc.onSignal(msg.data);
        }
      };
      ws.addEventListener("message", onMsg);
      ws.addEventListener("close", () => { if (!peer) reject(new Error("Le serveur a fermé la connexion.")); });
      ws.send(JSON.stringify({ t: "create" }));
    });
  }

  async function join(code, opts = {}) {
    const status = opts.onStatus || (() => {});
    status("Connexion au serveur de l'hôte...");
    const ws = await openSignal();
    const signal = (data) => ws.send(JSON.stringify({ t: "signal", data }));
    return new Promise((resolve, reject) => {
      let rtc = null, iceServers = [], done = false;
      const onMsg = async (e) => {
        if (typeof e.data !== "string") return;
        const msg = JSON.parse(e.data);
        if (msg.t === "error") { done = true; reject(new Error(msg.msg)); ws.close(); }
        else if (msg.t === "joined") { iceServers = msg.iceServers; status("Connexion directe en cours..."); }
        else if (msg.t === "peer-left") { done = true; reject(new Error(msg.msg)); }
        else if (msg.t === "signal") {
          const d = msg.data;
          if (d.type === "sdp" || d.type === "ice") {
            if (!rtc) rtc = makeRtc(iceServers, signal);
            rtc.onSignal(d);
          } else if (d.type === "ready") {
            let ok = d.transport === "webrtc" && rtc && await timeout(rtc.opened, 3000);
            signal({ type: "ack", transport: ok ? "webrtc" : "relay" });
            const peer = new Peer("guest", d.seed >>> 0, ws);
            ws.removeEventListener("message", onMsg);
            done = true;
            if (ok) peer._useWebrtc(rtc.pc, rtc.ch);
            else { if (rtc) rtc.pc.close(); peer._useRelay(); }
            resolve(peer);
          }
        }
      };
      ws.addEventListener("message", onMsg);
      ws.addEventListener("close", () => { if (!done) reject(new Error("Le serveur de l'hôte a fermé la connexion.")); });
      ws.send(JSON.stringify({ t: "join", code }));
    });
  }

  window.KikiNet = { host, join };
})();

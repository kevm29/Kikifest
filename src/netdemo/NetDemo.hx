package netdemo;

import js.Browser.document;
import js.Browser.window;
import js.html.CanvasElement;
import js.html.CanvasRenderingContext2D;
import net.rollback.RollbackSession;
import net.transport.DirectTransport;
import net.transport.KikiNetTransport;
import net.transport.LagTransport;

/**
	Démo du rollback dans le navigateur (web/netdemo.html).

	- Mode local (par défaut) : les deux joueurs tournent dans la même page,
	  reliés par un réseau simulé réglable. Chaque canevas montre la partie
	  telle que la voit chaque joueur.
	- Mode en ligne (?online) : utilise le salon `KikiNet` (web/js/kikinet.js).
**/
class NetDemo {
	static inline var FRAME_MS = 25.;

	static var keys = new Map<String, Bool>();
	static var bot = 0;
	static var botRng = 99;

	static function main() {
		window.addEventListener("keydown", e -> {
			keys.set(e.code, true);
			if (e.code.indexOf("Arrow") == 0 || e.code == "Space")
				e.preventDefault();
		});
		window.addEventListener("keyup", e -> keys.remove(e.code));
		window.addEventListener("blur", _ -> keys.clear());
		if (window.location.search.indexOf("online") >= 0)
			startOnline();
		else
			startLocal();
	}

	// --- Mode local : deux sessions dans la page -------------------------

	static function startLocal() {
		var now = () -> window.performance.now();
		var pipes = DirectTransport.pair();
		var lagA = new LagTransport(pipes[0], 0, 0, 0, 0, 1);
		var lagB = new LagTransport(pipes[1], 0, 0, 0, 0, 2);
		var seed = 20261111;
		var gameA = new DemoGame(seed), gameB = new DemoGame(seed);
		var a = new RollbackSession(gameA, lagA, {localPlayer: 0, now: now});
		var b = new RollbackSession(gameB, lagB, {localPlayer: 1, now: now});
		var desync = "";
		a.onDesync = (f, l, r) -> desync = 'DÉSYNCHRO à la frame $f';

		var ctxA = canvas("viewA"), ctxB = canvas("viewB");
		var stats = document.getElementById("stats");

		function readNumber(id:String):Float {
			var v = Std.parseFloat((cast document.getElementById(id) : js.html.InputElement).value);
			return Math.isNaN(v) ? 0 : v;
		}
		function applySettings() {
			for (l in [lagA, lagB]) {
				l.latencyMs = readNumber("latency") / 2; // réglage = aller-retour
				l.jitterMs = readNumber("jitter");
				l.lossRate = readNumber("loss") / 100;
			}
			a.inputDelay = b.inputDelay = Std.int(readNumber("delay"));
			for (id in ["latency", "jitter", "loss", "delay"])
				document.getElementById(id + "Value").textContent = Std.string(readNumber(id));
		}
		for (id in ["latency", "jitter", "loss", "delay"])
			document.getElementById(id).addEventListener("input", applySettings);
		applySettings();

		loop(() -> {
			var t = now();
			lagA.update(t);
			lagB.update(t);
			var botOn = (cast document.getElementById("bot") : js.html.InputElement).checked;
			a.tick(read(["KeyA"], ["KeyD"], ["KeyW"], ["KeyS"], ["KeyF", "Space"]));
			b.tick(botOn ? botInput() : read(["ArrowLeft"], ["ArrowRight"], ["ArrowUp"], ["ArrowDown"], ["Enter", "ShiftRight"]));
		}, () -> {
			draw(ctxA, gameA, 0, "Joueur 1 (ZQSD/WASD + F)");
			draw(ctxB, gameB, 1, "Joueur 2 (flèches + Entrée)");
			stats.textContent = describe("J1", a) + "\n" + describe("J2", b) + (desync != "" ? "\n" + desync : "");
		});
	}

	// --- Mode en ligne : salon KikiNet ------------------------------------

	static function startOnline() {
		var status = document.getElementById("stats");
		document.body.classList.add("online");
		var kikinet:Dynamic = untyped window.KikiNet;
		if (kikinet == null) {
			status.textContent = "Le salon (js/kikinet.js) n'est pas disponible.";
			return;
		}
		status.textContent = "Connexion au salon...";
		var promise:js.lib.Promise<Dynamic> = kikinet.connect();
		promise.then(peer -> {
			var transport = new KikiNetTransport(peer);
			var game = new DemoGame(peer.seed);
			var session = new RollbackSession(game, transport, {
				localPlayer: transport.localPlayer,
				now: () -> window.performance.now(),
				inputDelay: 2
			});
			var desync = "";
			session.onDesync = (f, _, _) -> desync = 'DÉSYNCHRO à la frame $f';
			var ctx = canvas("viewA");
			var me = transport.localPlayer;
			loop(() -> {
				session.tick(read(["ArrowLeft", "KeyA"], ["ArrowRight", "KeyD"], ["ArrowUp", "KeyW"], ["ArrowDown", "KeyS"], ["Space", "KeyF", "Enter"]));
			}, () -> {
				draw(ctx, game, me, me == 0 ? "Vous êtes le joueur 1 (hôte)" : "Vous êtes le joueur 2 (invité)");
				var silence = session.silenceMs();
				status.textContent = describe("Vous", session) + " · transport " + peer.transport
					+ (silence > 1000 ? '\nPlus de nouvelles de l\'autre joueur depuis ${Math.round(silence / 1000)} s' : "")
					+ (desync != "" ? "\n" + desync : "");
			});
		}, err -> status.textContent = "Échec de connexion : " + err);
	}

	// --- Commun ---------------------------------------------------------

	/** Pas fixe de 25 ms, indépendant de la fréquence d'affichage. **/
	static function loop(step:Void->Void, render:Void->Void) {
		var last = window.performance.now();
		var acc = 0.;
		function frame(t:Float) {
			acc += t - last;
			last = t;
			if (acc > FRAME_MS * 8)
				acc = FRAME_MS * 8; // onglet en arrière-plan : on ne rattrape pas tout
			while (acc >= FRAME_MS) {
				step();
				acc -= FRAME_MS;
			}
			render();
			window.requestAnimationFrame(frame);
		}
		window.requestAnimationFrame(frame);
	}

	static function read(left:Array<String>, right:Array<String>, up:Array<String>, down:Array<String>, action:Array<String>):Int {
		inline function any(codes:Array<String>) {
			var r = false;
			for (c in codes)
				if (keys.exists(c))
					r = true;
			return r;
		}
		var v = 0;
		if (any(left)) v |= DemoGame.LEFT;
		if (any(right)) v |= DemoGame.RIGHT;
		if (any(up)) v |= DemoGame.JUMP;
		if (any(down)) v |= DemoGame.DOWN;
		if (any(action)) v |= DemoGame.ACTION;
		return v;
	}

	static function botInput():Int {
		botRng ^= botRng << 13;
		botRng ^= botRng >>> 17;
		botRng ^= botRng << 5;
		if ((botRng & 15) == 0)
			bot = (botRng >>> 8) & 31;
		return bot;
	}

	static function describe(name:String, s:RollbackSession<Array<Int>>):String {
		var st = s.stats;
		return '$name : frame ${s.currentFrame} · ping ${Math.round(s.rttMs)} ms · délai ${s.inputDelay} · '
			+ 'rollbacks ${st.rollbacks} (max ${st.maxRollback} frames) · attentes ${st.waitingTicks} · '
			+ 'empreintes vérifiées ${st.checksumsCompared}';
	}

	static function canvas(id:String):CanvasRenderingContext2D {
		var c:CanvasElement = cast document.getElementById(id);
		c.width = DemoGame.WIDTH;
		c.height = DemoGame.HEIGHT;
		return c.getContext2d();
	}

	static final COLORS = ["#f28c28", "#3a8fd9"];

	static function draw(ctx:CanvasRenderingContext2D, g:DemoGame, me:Int, title:String) {
		ctx.fillStyle = "#1d2433";
		ctx.fillRect(0, 0, DemoGame.WIDTH, DemoGame.HEIGHT);
		ctx.fillStyle = "#e8e2c8";
		for (b in 0...DemoGame.BALLS) {
			ctx.beginPath();
			var r = DemoGame.BALL_SIZE / 2;
			ctx.arc(g.ballX(b) + r, g.ballY(b) + r, r, 0, Math.PI * 2);
			ctx.fill();
		}
		for (p in 0...2) {
			ctx.fillStyle = COLORS[p];
			ctx.fillRect(g.playerX(p), g.playerY(p), DemoGame.PLAYER_SIZE, DemoGame.PLAYER_SIZE);
			if (p == me) {
				ctx.strokeStyle = "#fff";
				ctx.lineWidth = 2;
				ctx.strokeRect(g.playerX(p) - 1, g.playerY(p) - 1, DemoGame.PLAYER_SIZE + 2, DemoGame.PLAYER_SIZE + 2);
			}
		}
		ctx.fillStyle = "#fff";
		ctx.font = "14px system-ui, sans-serif";
		ctx.fillText(title, 10, 20);
		ctx.fillStyle = COLORS[0];
		ctx.fillText('J1 : ${g.score(0)}', 10, 40);
		ctx.fillStyle = COLORS[1];
		ctx.fillText('J2 : ${g.score(1)}', 80, 40);
		ctx.fillStyle = "#8892a6";
		ctx.fillText('frame ${g.frame}', DemoGame.WIDTH - 90, 20);
	}
}

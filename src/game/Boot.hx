package;

import js.Browser;
import swf.Library;
import mtlib.ArrayExt;
import swf.MovieClip;
import swf.Renderer;
import mtlib.*;

/**
	Point d'entrée du jeu : charge les ressources, prépare la racine Flash
	simulée (variables $mode, xml_*), crée le GameManager et fait tourner la
	boucle à pas fixe (40 i/s).
**/
class Boot {
	static var root:MovieClip;
	static var manager:GameManager;
	static var renderer:Renderer;

	static var SETS = [
		"adventure", "tutorial", "shareware", "timeAttack", "multiTime", "soccer", "hof",
		"deepnight", "hiko", "ayame", "hk"
	];
	static var SET_VARS = [
		"adventure" => "xml_adventure", "tutorial" => "xml_tutorial", "shareware" => "xml_shareware",
		"timeAttack" => "xml_time", "multiTime" => "xml_multitime", "soccer" => "xml_soccer",
		"hof" => "xml_hof", "deepnight" => "xml_deepnight", "hiko" => "xml_hiko", "ayame" => "xml_ayame",
		"hk" => "xml_hk"
	];

	static function main() {
		Library.load("assets", lib -> lib.preloadAll(r -> status("Chargement des graphismes : " + Math.round(r * 100) + " %"), loadData), e -> status("Erreur : " + e));
	}

	static function status(s:String) {
		var el = Browser.document.getElementById("status");
		if (el != null)
			el.textContent = s;
	}

	static function fetchText(url:String):js.lib.Promise<String> {
		return Browser.window.fetch(url).then(r -> r.text());
	}

	static function loadData() {
		root = new MovieClip(-1);
		root.__isRoot = true;
		MtStd.root = root;
		// fonctions que la page Flash d'origine fournissait au jeu (envoi du score, sortie)
		MtStd.setGlobal("gameOver", function(score:Dynamic, ?a:Dynamic, ?data:Dynamic) {
			status("Partie terminée ! " + endHint() + "");
			if (!gameEnded)
				recordGame(score, data);
			gameEnded = true;
		});
		MtStd.setGlobal("exitGame", function(?url:Dynamic, ?params:Dynamic) {
			if (!gameEnded) // garde le message de fin de partie (quêtes, Panthéon)
				status("Partie terminée ! " + endHint() + "");
			gameEnded = true;
		});
		swf.FrameScripts.MtStdRoot.root = root;
		var jobs:Array<js.lib.Promise<Dynamic>> = [];
		for (s in SETS)
			jobs.push(fetchText("assets/data/levels/" + s + ".xml").then(t -> Reflect.setField(root, SET_VARS.get(s), StringTools.trim(t))));
		var xmls = ["specialItems" => "xml_specialItems", "scoreItems" => "xml_scoreItems", "quests" => "xml_quests", "portalLinks" => "xml_portalLinks"];
		for (k => v in xmls)
			jobs.push(fetchText("assets/data/" + k + ".xml").then(t -> Reflect.setField(root, v, t)));
		var lang:String = null;
		jobs.push(fetchText("assets/data/lang/fr.xml").then(t -> lang = t));
		// les quêtes ont besoin des listes d'objets (familles) en plus de quests.xml
		for (k in ["specialItems", "scoreItems", "quests"])
			jobs.push(fetchText("assets/data/" + k + ".xml").then(t -> rawData.set(k, t)));
		js.lib.Promise.all(jobs).then(_ -> {
			start(lang);
			return null;
		}, e -> status("Erreur : " + e));
	}

	static function start(lang:String) {
		status("");
		var params = new js.html.URLSearchParams(Browser.location.search);
		netCfg = untyped js.Browser.window.KIKI_NET;
		var mode = netCfg != null ? netCfg.mode : params.get("mode");
		Reflect.setField(root, "$mode", mode != null ? mode : "solo"); // sans précision : Aventure en solo, sans Sandy
		Reflect.setField(root, "$version", "WIN 8,0,0,0");
		// options que le chargeur Flash d'origine fixait (son, musique, détails, tremblements)
		for (kv in [["$options", ""], ["$lang", "fr"], ["$shake", "1"], ["$detail", "1"], ["$sound", "1"], ["$music", "1"], ["$volume", "100"]])
			if (Reflect.field(root, kv[0]) == null)
				Reflect.setField(root, kv[0], params.get(kv[0].substr(1)) != null ? params.get(kv[0].substr(1)) : kv[1]);
		Rand.setSeed(netCfg != null ? Std.int(netCfg.seed) : params.get("seed") != null ? Std.parseInt(params.get("seed")) : 12345);
		settings = meta.Settings.load();
		SoundBank.musicVolume = settings.music / 100;
		SoundBank.sfxVolume = settings.sfx / 100;

		var canvas:js.html.CanvasElement = cast Browser.document.getElementById("game");
		renderer = new Renderer(canvas);
		renderer.background = "#000";

		var init:Dynamic = {
			fl_local: true,
			musics: [for (f in ["music.mp3", "boss.mp3", "hurryUp.mp3"]) {
				var m = new mtlib.Sound();
				m.loadSound(f, false);
				m;
			}],
			rawLang: lang,
			// en réseau, la partie démarre avec les familles (bonus) et options de l'hôte
			families: netCfg != null ? (families(params) != null ? netCfg.families : "") : families(params),
			options: netCfg != null ? netCfg.options : params.get("options") != null ? params.get("options") : "",
		};
		untyped js.Browser.window.kiki = {root: root, boot: Boot, Data: Data, SpecialItem: entity.item.SpecialItem, ScoreItem: entity.item.ScoreItem}; // accès pour les tests automatiques
		manager = new GameManager(root, init);
		untyped js.Browser.window.kiki.manager = manager;
		// pour les tests automatiques du rollback (tools/test/synctest.cjs)
		untyped js.Browser.window.kiki.net = {
			Snapshot: net.Snapshot,
			SyncTest: net.rollback.SyncTest,
			NetGame: NetGame,
			classes: js.Syntax.code("$hxClasses"),
			init: () -> net.Snapshot.init(([manager, root] : Array<Dynamic>))
		};

		Browser.window.addEventListener("keydown", (e:js.html.KeyboardEvent) -> {
			pressed.set(e.code, true);
			if (gameEnded && e.code == "Escape")
				leave();
			mtlib.SoundBank.unlock();
			if (e.keyCode >= 32 && e.keyCode <= 40 && !isTyping(e))
				e.preventDefault();
		});
		Browser.window.addEventListener("keyup", (e:js.html.KeyboardEvent) -> pressed.remove(e.code));
		Browser.window.addEventListener("blur", _ -> pressed = new haxe.ds.StringMap());

		if (netCfg != null)
			startNet();

		var step = 1000 / Timer.SIM_FPS;
		var last = Browser.window.performance.now();
		var acc = 0.0;
		function loop(t:Float) {
			acc += t - last;
			last = t;
			if (acc > 250)
				acc = 250;
			// la boucle continue même si une image du jeu lève une erreur (sinon tout se fige)
			Browser.window.requestAnimationFrame(loop);
			while (acc >= step) {
				acc -= step;
				if (session != null)
					netStep();
				else
					localStep();
			}
			try {
				draw();
			} catch (e:Dynamic) {
				reportError(e);
			}
		}
		Browser.window.requestAnimationFrame(loop);
	}

	// ---------------------------------------------------------------- touches

	public static var settings:meta.Settings.SettingsData;
	static var pressed = new haxe.ds.StringMap<Bool>();

	static function isTyping(e:js.html.KeyboardEvent):Bool {
		var t:Dynamic = e.target;
		return t != null && (t.tagName == "INPUT" || t.tagName == "TEXTAREA");
	}

	/** Touches de ce clavier : joueur 1 (ou le joueur local en réseau), et le 2e joueur sur le même clavier. **/
	static function localMask(second:Bool):Int {
		var m = meta.Settings.mask(second ? settings.keys2 : settings.keys, pressed);
		if (!second && pressed.exists("Escape"))
			m |= meta.Settings.QUIT;
		return m;
	}

	/** Codes virtuels donnés aux contrôleurs des joueurs (aucun conflit avec les raccourcis du jeu). **/
	static inline var VKEY = 1000;

	/**
		Traduit les masques d'actions des joueurs en touches du clavier virtuel (mtlib.Key),
		le seul que lit le jeu. Le joueur i (pid) reçoit inputs[i].
	**/
	public static function applyInputs(inputs:Array<Int>) {
		Key.clear();
		var all = 0;
		for (m in inputs)
			all |= m;
		if (all & meta.Settings.PAUSE != 0)
			Key.set(80, true);
		if (all & meta.Settings.MAP != 0)
			Key.set(67, true);
		if (all & meta.Settings.QUIT != 0)
			Key.set(Key.ESCAPE, true);
		var g:Dynamic = manager != null ? manager.current : null;
		var players:Array<Dynamic> = g != null && g.getPlayerList != null ? g.getPlayerList() : null;
		if (players == null)
			return;
		for (p in players) {
			var c:Dynamic = p.ctrl;
			var pid:Int = p.pid;
			if (c == null || pid == null || pid < 0 || pid > 1)
				continue;
			var base = VKEY + pid * 10;
			if (c.jump != base + 1)
				c.setKeys(base + 1, base + 2, base + 3, base + 4, base + 5);
			var m = inputs[pid];
			if (m & meta.Settings.UP != 0)
				Key.set(base + 1, true);
			if (m & meta.Settings.DOWN != 0)
				Key.set(base + 2, true);
			if (m & meta.Settings.LEFT != 0)
				Key.set(base + 3, true);
			if (m & meta.Settings.RIGHT != 0)
				Key.set(base + 4, true);
			if (m & meta.Settings.BOMB != 0)
				Key.set(base + 5, true);
		}
	}

	static var localInputs = [0, 0];

	static function localStep() {
		try {
			step();
		} catch (e:Dynamic) {
			reportError(e);
		}
	}

	/** Une frame en local : touches de ce clavier, puis simulation (le robot de test l'appelle aussi). **/
	public static function step() {
		localInputs[0] = localMask(false);
		var mode:String = Reflect.field(root, "$mode");
		localInputs[1] = netCfg == null && (mode == "multicoop" || mode == "soccer" || mode == "multitime") ? localMask(true) : 0;
		if (netLost)
			localInputs = netPlayer == 0 ? [localMask(false) & ~meta.Settings.QUIT, 0] : [0, localMask(false) & ~meta.Settings.QUIT];
		applyInputs(localInputs);
		tick();
	}

	// ---------------------------------------------------------------- réseau

	/** Configuration d'une partie en réseau, posée par le menu (window.KIKI_NET) : peer, mode, options, families, seed, names. **/
	static var netCfg:Dynamic = null;
	static var session:net.rollback.RollbackSession<net.Snapshot> = null;
	static var netPlayer = 0;
	static var netLost = false;
	static var netGame:NetGame;
	static var lastNetInfo = 0.0;

	static function startNet() {
		var peer:Dynamic = netCfg.peer;
		netPlayer = peer.role == "host" ? 0 : 1;
		net.Snapshot.init(([manager, root] : Array<Dynamic>));
		netGame = new NetGame();
		var kt = new net.transport.KikiNetTransport(peer);
		kt.onReliable = (msg:Dynamic) -> {};
		var transport:net.transport.Transport = kt;
		// test : ?lag=80 ajoute 80 ms de latence (et un peu de pertes) dans chaque sens
		var lag = Std.parseInt(new js.html.URLSearchParams(Browser.location.search).get("lag"));
		if (lag != null && lag > 0) {
			var lt = new net.transport.LagTransport(kt, lag, lag / 4, 0.03, 0.01, netPlayer + 1);
			lagTransport = lt;
			transport = lt;
		}
		session = new net.rollback.RollbackSession(netGame, transport, {
			localPlayer: netPlayer,
			now: () -> Browser.window.performance.now(),
			inputDelay: 2,
			maxPrediction: 8,
			saveEvery: 4,
		});
		netGame.session = session;
		session.onDesync = (f, a, b) -> {
			Browser.console.warn('Désynchronisation à la frame $f ($a / $b)');
			netWarning = "Attention : les deux parties se sont désynchronisées (frame " + f + "). Merci de le signaler !";
		};
		peer.onclose = (reason:Dynamic) -> {
			if (session == null)
				return;
			session = null;
			netLost = true;
			SoundBank.muted = false;
			status("L'autre joueur est parti" + (reason != null ? " (" + reason + ")" : "") + " : tu continues seul.");
		};
		untyped js.Browser.window.kiki.session = session;
	}

	static var netWarning:String = null;

	static var lagTransport:net.transport.LagTransport = null;

	static function netStep() {
		if (lagTransport != null)
			lagTransport.update(Browser.window.performance.now());
		var m = localMask(false) & ~meta.Settings.QUIT; // Échap ne quitte pas une partie à deux
		var r = session.tick(m);
		var now = Browser.window.performance.now();
		if (now - lastNetInfo > 1000 && !gameEnded) {
			lastNetInfo = now;
			var peer:Dynamic = netCfg.peer;
			var info = (peer.transport == "webrtc" ? "Liaison directe" : "Liaison par le serveur de l'hôte") + " · ping " + Math.round(session.rttMs) + " ms";
			if (r == WaitingForRemote && session.silenceMs() > 1000)
				info = "En attente de l'autre joueur…";
			status(netWarning != null ? netWarning : info);
		}
	}

	/** Somme de contrôle de l'état : de quoi repérer vite une désynchronisation. **/
	public static function checksum():Int {
		var h = net.rollback.Checksum.START;
		h = net.rollback.Checksum.addInt(h, Timer.frameCount);
		h = net.rollback.Checksum.addInt(h, Rand.seed);
		var g:Dynamic = manager != null ? manager.current : null;
		var lists:Array<Array<Dynamic>> = g != null ? g.lists : null;
		if (lists != null)
			for (l in lists) {
				if (l == null)
					continue;
				h = net.rollback.Checksum.addInt(h, l.length);
				for (e in l) {
					var x:Dynamic = e.x, y:Dynamic = e.y;
					if (x != null)
						h = net.rollback.Checksum.addFloat(h, x);
					if (y != null)
						h = net.rollback.Checksum.addFloat(h, y);
				}
			}
		if (g != null && g.getPlayerList != null)
			for (p in (g.getPlayerList() : Array<Dynamic>)) {
				h = net.rollback.Checksum.addInt(h, Std.int(p.score));
				h = net.rollback.Checksum.addInt(h, Std.int(p.lives));
			}
		return h;
	}

	/** Fin de partie : retour au menu (en réseau, la connexion se ferme). **/
	static function leave() {
		if (netCfg != null)
			Browser.location.href = "index.html#multi";
		else
			Browser.location.reload();
	}

	static var rawData = new Map<String, String>();
	static var quests:meta.Quests;

	/**
		Familles d'objets débloquées, que le serveur Motion Twin envoyait au chargeur (`$families`).
		Elles viennent des quêtes terminées (sauvegarde locale), ou de l'adresse : `?families=0,7,1000`.
	**/
	static function families(params:js.html.URLSearchParams):String {
		quests = new meta.Quests(rawData.get("quests"), [rawData.get("specialItems"), rawData.get("scoreItems")]);
		// sans adresse de serveur, GameManager remplace les familles par sa liste de secours
		Loader.BASE_SCRIPT_URL = "local";
		if (params.get("families") != null)
			return params.get("families");
		return quests.compute(meta.Save.load().items).families.join(",");
	}

	/** Fin de partie : ajoute les objets ramassés à la collection et la partie au classement (ce que faisait le serveur). */
	static function recordGame(score:Dynamic, data:Dynamic) {
		if (data == null || Browser.location.search.indexOf("nosave") >= 0)
			return;
		var picks:Array<Null<Int>> = Reflect.field(data, "__S_item2");
		if (picks == null)
			return;
		var save = meta.Save.load();
		var before = quests.compute(save.items).done;
		save.addPicks(picks);
		save.games++;

		// classement : une ligne par joueur (en coop, le score de chacun est dans $data)
		var mode:String = Reflect.field(root, "$mode");
		var level = toInt(Reflect.field(data, "__S_reachedLevel"));
		var date = DateTools.format(Date.now(), "%Y-%m-%d");
		var heroes = [];
		var scores:Array<Int> = [toInt(score)];
		var sub:Dynamic = Reflect.field(data, "__S_data");
		if (mode == "multicoop" && sub != null)
			scores = [toInt(Reflect.field(sub, "__S_s0")), toInt(Reflect.field(sub, "__S_s1"))];
		if (mode != "solo" && mode != "multicoop")
			scores = []; // seuls l'Aventure et l'Aventure à deux comptent au classement
		for (i in 0...scores.length) {
			var name = netCfg != null && netCfg.names != null ? Std.string(netCfg.names[i]) : pref(i == 0 ? "name" : "name2", i == 0 ? "Igor" : "Sandy");
			if (save.addRecord({d: date, mode: mode, name: name, score: scores[i], level: level}))
				heroes.push(name);
		}
		save.store();

		var msg = "Partie terminée !";
		var fresh = quests.compute(save.items).done.filter(q -> before.indexOf(q) < 0);
		if (fresh.length > 0)
			msg += " Nouvelle quête accomplie (" + fresh.length + ") !";
		if (heroes.length > 0)
			msg += " " + heroes.join(" et ") + " entre" + (heroes.length > 1 ? "nt" : "") + " au Panthéon : va écrire ta phrase dans le menu !";
		status(msg + " " + endHint());
	}

	static function endHint():String
		return netCfg != null ? "Échap pour revenir au menu." : "Échap pour rejouer.";

	static function toInt(v:Dynamic):Int {
		var n = Std.parseInt(Std.string(v));
		return n == null || n < 0 ? 0 : n;
	}

	static function pref(k:String, def:String):String {
		try {
			var v = Browser.window.localStorage.getItem("kikifest." + k);
			return v != null && v != "" ? v : def;
		} catch (e:Dynamic) {
			return def;
		}
	}

	static var errors = 0;
	static var gameEnded = false;

	static function reportError(e:Dynamic) {
		if (errors++ < 5) {
			Browser.console.error(e);
			var stack:String = untyped e != null && e.stack != null ? e.stack : "";
			status("Erreur du jeu (merci de la signaler) : " + Std.string(e) + " " + stack.split("\n").slice(1, 3).join(" "));
		}
	}

	public static function tick() {
		manager.main();
		MovieClip.tick(root);
	}

	public static function draw() {
		var canvas = renderer.canvas;
		var dpr = Browser.window.devicePixelRatio;
		var w = Std.int(canvas.clientWidth * dpr);
		var h = Std.int(canvas.clientHeight * dpr);
		if (canvas.width != w || canvas.height != h) {
			canvas.width = w;
			canvas.height = h;
		}
		renderer.scale = w / Data.DOC_WIDTH;
		renderer.render(root);
	}
}

/** Le jeu vu par le rollback : avancer d'une frame, photographier, restaurer. **/
class NetGame implements net.rollback.RollbackGame<net.Snapshot> {
	public var session:net.rollback.RollbackSession<net.Snapshot>;

	public function new() {}

	public function advance(inputs:Array<Int>) {
		// pendant les frames rejouées, les bruitages ont déjà été entendus
		SoundBank.muted = session != null && session.resimulating;
		try {
			Boot.applyInputs(inputs);
			Boot.tick();
		} catch (e:Dynamic) {
			js.Browser.console.error(e);
		}
		SoundBank.muted = false;
	}

	public function save():net.Snapshot
		return net.Snapshot.save();

	public function load(s:net.Snapshot)
		s.restore();

	public function checksum():Int
		return Boot.checksum();
}

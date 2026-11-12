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
			if (!gameEnded) {
				endMessage = "Partie terminée !";
				try
					recordGame(score, data)
				catch (e:Dynamic)
					reportError(e);
				gameEnded = true;
				scheduleReturn();
			}
		});
		MtStd.setGlobal("exitGame", function(?url:Dynamic, ?params:Dynamic) {
			if (!gameEnded) {
				endMessage = "Partie terminée !";
				gameEnded = true;
				scheduleReturn();
			}
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
		// morceaux ajoutés (dossier web/assets/musiques/, listé par le serveur de l'hôte) : facultatif
		jobs.push(Browser.window.fetch("api/musiques").then(r -> r.ok ? r.json() : null).then(list -> {
			meta.Jukebox.setFiles(Std.isOfType(list, Array) ? list : null);
			return null;
		}).catchError(_ -> null));
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
		// étude 3-4 joueurs : nombre de joueurs en Coop (?joueurs=3 ou 4 ; les joueurs 3 et 4 sont des robots en local)
		var nj = netCfg != null && netCfg.players != null ? Std.int(netCfg.players) : Std.parseInt(params.get("joueurs"));
		Reflect.setField(root, "$joueurs", nj != null ? "" + nj : "2");
		// options que le chargeur Flash d'origine fixait (son, musique, détails, tremblements)
		for (kv in [["$options", ""], ["$lang", "fr"], ["$shake", "1"], ["$detail", "1"], ["$sound", "1"], ["$music", "1"], ["$volume", "100"]])
			if (Reflect.field(root, kv[0]) == null)
				Reflect.setField(root, kv[0], params.get(kv[0].substr(1)) != null ? params.get(kv[0].substr(1)) : kv[1]);
		Rand.setSeed(netCfg != null ? Std.int(netCfg.seed) : params.get("seed") != null ? Std.parseInt(params.get("seed")) : 12345);
		settings = meta.Settings.load();
		SoundBank.musicVolume = settings.music / 100;
		SoundBank.sfxVolume = settings.sfx / 100;
		// musique tirée au hasard ; en réseau avec la graine commune, pour que les deux entendent la même
		meta.Jukebox.pick(netCfg != null ? Std.int(netCfg.seed) : Std.random(1000000));

		var canvas:js.html.CanvasElement = cast Browser.document.getElementById("game");
		if (nj != null && nj > 2) {
			// étude 3-4 joueurs : une 2e barre de scores sous le jeu, le canevas s'allonge d'autant
			var hh = Data.DOC_HEIGHT + gui.GameInterface.ROW2_DY;
			canvas.style.setProperty("aspect-ratio", '${Data.DOC_WIDTH} / $hh');
			canvas.style.height = 'min(92vh, calc(96vw * $hh / ${Data.DOC_WIDTH}))';
		}
		renderer = new Renderer(canvas);
		renderer.background = "#000";

		var init:Dynamic = {
			fl_local: true,
			musics: meta.Jukebox.sounds = [for (i => f in ["music.mp3", "boss.mp3", "hurryUp.mp3"]) {
				var m = new mtlib.Sound();
				m.loadSound(f, false);
				m.jukeboxSlot = i;
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

		var onDown = (e:js.html.KeyboardEvent) -> {
			pressed.set(e.code, true);
			if (e.code == "KeyM" && !e.repeat && !isTyping(e) && !isBound("KeyM"))
				musicKey();
			onKey(e.code);
			mtlib.SoundBank.unlock();
			if (e.keyCode >= 32 && e.keyCode <= 40 && !isTyping(e))
				e.preventDefault();
		};
		var onUp = (e:js.html.KeyboardEvent) -> pressed.remove(e.code);
		var onBlur = (_) -> pressed = new haxe.ds.StringMap();
		Browser.window.addEventListener("keydown", onDown);
		Browser.window.addEventListener("keyup", onUp);
		Browser.window.addEventListener("blur", onBlur);
		// « Rejouer ensemble » recharge le jeu dans la même page : on arrête proprement celui-ci
		untyped js.Browser.window.kikiStop = () -> {
			stopped = true;
			session = null;
			Browser.window.removeEventListener("keydown", onDown);
			Browser.window.removeEventListener("keyup", onUp);
			Browser.window.removeEventListener("blur", onBlur);
			SoundBank.shutdown();
			untyped js.Browser.window.kikiStop = null;
		};

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
			if (stopped)
				return;
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
			if (c == null || pid == null || pid < 0 || pid > 3)
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

	static var localInputs = [0, 0, 0, 0];

	/** Étude 3-4 joueurs, en local : les joueurs 3 et 4 se promènent au hasard (robots). **/
	static var robots = [{seed: 0x2545F49, mask: 0, until: 0}, {seed: 0x3C6EF37, mask: 0, until: 0}];

	static function robotMask(k:Int):Int {
		var r = robots[k];
		inline function rnd(n:Int):Int {
			r.seed ^= r.seed << 13;
			r.seed ^= r.seed >>> 17;
			r.seed ^= r.seed << 5;
			return (r.seed & 0x7fffffff) % n;
		}
		if (--r.until <= 0) {
			r.until = 10 + rnd(40);
			r.mask = [0, meta.Settings.LEFT, meta.Settings.RIGHT, meta.Settings.LEFT, meta.Settings.RIGHT, meta.Settings.UP][rnd(6)];
			if (rnd(3) == 0)
				r.mask |= meta.Settings.BOMB;
		}
		var m = r.mask;
		if (rnd(8) == 0)
			r.mask &= ~meta.Settings.BOMB; // relâche la bombe pour pouvoir en reposer une
		return m;
	}

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
		localInputs[2] = netCfg == null && mode == "multicoop" ? robotMask(0) : 0;
		localInputs[3] = netCfg == null && mode == "multicoop" ? robotMask(1) : 0;
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
		kt.onReliable = (msg:Dynamic) -> {
			// choix de musique de l'hôte : le reste va au salon (rejouer, départ...)
			var m:Dynamic = Std.isOfType(msg, String) && StringTools.startsWith(msg, '{"t":"music"') ? (try haxe.Json.parse(msg) catch (e:Dynamic) null) : null;
			if (m != null) {
				var i = meta.Jukebox.tracks.indexOf(Std.string(m.f));
				meta.Jukebox.set(i < 0 ? 0 : i, m.off == true);
				notice("Musique (choisie par l'hôte) : " + meta.Jukebox.label());
			} else if (netCfg.onReliable != null)
				netCfg.onReliable(msg);
		};
		// chaque partie (« Rejouer ensemble ») a son numéro : les messages en retard de la précédente sont ignorés
		var transport:net.transport.Transport = new RoundTransport(kt, Std.int(netCfg.round));
		// test : ?lag=80 ajoute 80 ms de latence (et un peu de pertes) dans chaque sens
		var lag = Std.parseInt(new js.html.URLSearchParams(Browser.location.search).get("lag"));
		if (lag != null && lag > 0) {
			var lt = new net.transport.LagTransport(transport, lag, lag / 4, 0.03, 0.01, netPlayer + 1);
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
			status("L'autre joueur est parti" + (reason != null ? " (" + reason + ")" : "") + " : tu continues seul. Échap deux fois : menu.");
		};
		status("C'est parti ! Vous jouez " + (netPlayer == 0 ? "Igor" : "Sandy") + ".");
		lastNetInfo = Browser.window.performance.now() + 3000;
		untyped js.Browser.window.kiki.session = session;
	}

	static var netWarning:String = null;
	static var lastDelayCheck = 0.0;

	static var lagTransport:net.transport.LagTransport = null;

	/** Mesures (tests) : nombre de pas, temps total et maximal en ms, pas de plus de 20 ms. **/
	public static var perf = {ticks: 0, total: 0.0, max: 0.0, slow: 0, saves: 0, saveMax: 0.0};

	static function netStep() {
		if (lagTransport != null)
			lagTransport.update(Browser.window.performance.now());
		var m = localMask(false) & ~meta.Settings.QUIT; // Échap ne quitte pas une partie à deux
		var t0 = Browser.window.performance.now();
		var r = session.tick(m);
		var dt = Browser.window.performance.now() - t0;
		perf.ticks++;
		perf.total += dt;
		if (dt > perf.max)
			perf.max = dt;
		if (dt > 20)
			perf.slow++;
		var now = Browser.window.performance.now();
		// délai des touches adapté au ping : assez pour couvrir le trajet aller (moins de corrections
		// visibles, donc moins de saccades), sans dépasser 4 frames (100 ms) pour garder des commandes vives
		if (now - lastDelayCheck > 2000 && session.rttMs > 0) {
			lastDelayCheck = now;
			var want = Std.int(Math.max(2, Math.min(4, Math.ceil((session.rttMs / 2 - 10) / 25))));
			if (want > session.inputDelay)
				session.inputDelay++;
			else if (want < session.inputDelay)
				session.inputDelay--;
		}
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

	// ---------------------------------------------------------------- musique

	static function isBound(code:String):Bool {
		for (k in [settings.keys, settings.keys2])
			for (a in meta.Settings.ACTIONS)
				if (Reflect.field(k, a.id) == code)
					return true;
		return false;
	}

	/** Touche M : morceau suivant ou musique coupée (en réseau, seul l'hôte choisit). **/
	static function musicKey() {
		if (session != null && netPlayer != 0) {
			notice("C'est l'hôte qui choisit la musique (touche M).");
			return;
		}
		meta.Jukebox.next();
		notice("Musique : " + meta.Jukebox.label() + " (M : changer)");
		if (session != null) {
			var peer:Dynamic = netCfg.peer;
			try
				peer.sendReliable('{"t":"music","f":' + haxe.Json.stringify(meta.Jukebox.tracks[meta.Jukebox.current]) + ',"off":' + meta.Jukebox.off + '}')
			catch (e:Dynamic) {}
		}
	}

	static var noticeTimer = -1;

	/** Message affiché quelques secondes sous le jeu. **/
	static function notice(s:String) {
		status(s);
		lastNetInfo = Browser.window.performance.now() + 2500;
		if (noticeTimer >= 0)
			Browser.window.clearTimeout(noticeTimer);
		if (netCfg == null)
			noticeTimer = Browser.window.setTimeout(() -> {
				noticeTimer = -1;
				if (!gameEnded)
					status("");
			}, 2500);
	}

	static var stopped = false;
	static var lastEscape = -1e9;
	static var wantAgain = false;

	/** Touches hors du jeu : fin de partie, quitter. **/
	static function onKey(code:String) {
		var now = Browser.window.performance.now();
		if (gameEnded) {
			if (code == "Escape")
				leave();
			return;
		}
		// en réseau, Échap ne met pas fin à la partie des deux : il faut l'appuyer deux fois pour quitter
		if (netCfg != null && code == "Escape") {
			if (now - lastEscape < 2000)
				leave();
			else {
				lastEscape = now;
				status("Appuyez encore sur Échap pour quitter la partie.");
				lastNetInfo = now + 1000;
			}
		}
	}

	/** Fin de partie : retour au menu (en réseau, la connexion se ferme). **/
	static function leave() {
		if (stopped)
			return;
		if (returnTimer >= 0)
			Browser.window.clearTimeout(returnTimer);
		// en ligne, on revient au salon sans couper la connexion (si l'autre est encore là)
		if (netCfg != null && !netLost && netCfg.backToLobby != null) {
			var msg = gameEnded ? endMessage : null;
			var stop:Dynamic = untyped js.Browser.window.kikiStop;
			if (stop != null)
				stop();
			netCfg.backToLobby(msg);
			return;
		}
		Browser.location.href = netCfg != null ? "index.html#multi" : "index.html";
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

		// classement : une ligne par partie ; à deux, « Igor et Sandy » (ou leurs pseudos) avec le score commun
		var mode:String = Reflect.field(root, "$mode");
		var level = toInt(Reflect.field(data, "__S_reachedLevel"));
		var date = DateTools.format(Date.now(), "%Y-%m-%d");
		var total = toInt(score);
		var name = netCfg != null && netCfg.names != null ? Std.string(netCfg.names[0]) : pref("name", "Igor");
		var sub:Dynamic = Reflect.field(data, "__S_data");
		if (mode == "multicoop") {
			if (sub != null)
				total = toInt(Reflect.field(sub, "__S_s0")) + toInt(Reflect.field(sub, "__S_s1"));
			name += " et " + (netCfg != null && netCfg.names != null ? Std.string(netCfg.names[1]) : pref("name2", "Sandy"));
		}
		var hero = false;
		if (mode == "solo" || mode == "multicoop") // seuls l'Aventure et l'Aventure à deux comptent au classement
			hero = save.addRecord({d: date, mode: mode, name: name, score: total, level: level});
		save.store();
		meta.Save.push(save);

		var msg = "Partie terminée ! Score : " + total + ", niveau " + level + ".";
		var fresh = quests.compute(save.items).done.filter(q -> before.indexOf(q) < 0);
		if (fresh.length > 0)
			msg += " Nouvelle quête accomplie (" + fresh.length + ") !";
		if (hero)
			msg += " " + name + " entre" + (mode == "multicoop" ? "nt" : "") + " au Panthéon : écrivez votre phrase dans le menu !";
		endMessage = msg;
	}

	static var endMessage = "";
	static var returnTimer = -1;

	/** Fin de partie : on montre le résultat quelques secondes, puis retour au menu (au salon en ligne). **/
	static function scheduleReturn() {
		var left = 6;
		function tickDown() {
			if (stopped)
				return;
			if (left <= 0) {
				leave();
				return;
			}
			status(endMessage + " Retour au " + (netCfg != null && !netLost ? "salon" : "menu") + " dans " + left + " s (Échap : tout de suite).");
			left--;
			returnTimer = Browser.window.setTimeout(tickDown, 1000);
		}
		tickDown();
	}


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

	public function save():net.Snapshot {
		var t0 = js.Browser.window.performance.now();
		var s = net.Snapshot.save();
		var dt = js.Browser.window.performance.now() - t0;
		Boot.perf.saves++;
		if (dt > Boot.perf.saveMax)
			Boot.perf.saveMax = dt;
		return s;
	}

	public function load(s:net.Snapshot)
		s.restore();

	public function checksum():Int
		return Boot.checksum();
}

/** Préfixe chaque message du rollback par le numéro de la partie, et ignore ceux d'une autre partie. **/
class RoundTransport implements net.transport.Transport {
	public var onMessage:haxe.io.Bytes->Void;

	var inner:net.transport.Transport;
	var round:Int;

	public function new(inner:net.transport.Transport, round:Int) {
		this.inner = inner;
		this.round = round & 0xff;
		inner.onMessage = b -> {
			if (b.length > 0 && b.get(0) == this.round && onMessage != null)
				onMessage(b.sub(1, b.length - 1));
		};
	}

	public function send(data:haxe.io.Bytes) {
		var b = haxe.io.Bytes.alloc(data.length + 1);
		b.set(0, round);
		b.blit(1, data, 0, data.length);
		inner.send(b);
	}
}

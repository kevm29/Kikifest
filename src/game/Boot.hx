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
			status("Partie terminée ! Appuie sur Échap pour rejouer.");
			gameEnded = true;
		});
		MtStd.setGlobal("exitGame", function(?url:Dynamic, ?params:Dynamic) {
			status("Partie terminée ! Appuie sur Échap pour rejouer.");
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
		js.lib.Promise.all(jobs).then(_ -> {
			start(lang);
			return null;
		}, e -> status("Erreur : " + e));
	}

	static function start(lang:String) {
		status("");
		var params = new js.html.URLSearchParams(Browser.location.search);
		var mode = params.get("mode");
		Reflect.setField(root, "$mode", mode != null ? mode : "multicoop");
		Reflect.setField(root, "$version", "WIN 8,0,0,0");
		// options que le chargeur Flash d'origine fixait (son, musique, détails, tremblements)
		for (kv in [["$options", ""], ["$lang", "fr"], ["$shake", "1"], ["$detail", "1"], ["$sound", "1"], ["$music", "1"], ["$volume", "100"]])
			if (Reflect.field(root, kv[0]) == null)
				Reflect.setField(root, kv[0], params.get(kv[0].substr(1)) != null ? params.get(kv[0].substr(1)) : kv[1]);
		Rand.setSeed(params.get("seed") != null ? Std.parseInt(params.get("seed")) : 12345);

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
			families: null,
			options: params.get("options") != null ? params.get("options") : "",
		};
		untyped js.Browser.window.kiki = {root: root, boot: Boot};
		manager = new GameManager(root, init);
		untyped js.Browser.window.kiki.manager = manager;

		Browser.window.addEventListener("keydown", (e:js.html.KeyboardEvent) -> {
			Key.set(e.keyCode, true);
			if (gameEnded && e.keyCode == 27)
				Browser.location.reload();
			mtlib.SoundBank.unlock();
			if (e.keyCode >= 32 && e.keyCode <= 40)
				e.preventDefault();
		});
		Browser.window.addEventListener("keyup", (e:js.html.KeyboardEvent) -> Key.set(e.keyCode, false));

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
				try {
					tick();
				} catch (e:Dynamic) {
					reportError(e);
				}
			}
			try {
				draw();
			} catch (e:Dynamic) {
				reportError(e);
			}
		}
		Browser.window.requestAnimationFrame(loop);
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

	static function draw() {
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

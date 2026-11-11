package meta;

import js.Browser;

/**
	Collection d'objets du joueur, gardée dans le navigateur (localStorage).

	Format : { "v": 1, "items": { "36": 5, "1000": 412, ... }, "games": 3, "best": 125000 }
	Les ids >= 1000 sont les objets à points, comme dans `getPicks2()` du jeu.
**/
class Save {
	static inline var KEY = "kikifest.collection";

	public var items:Map<Int, Int> = new Map();
	public var games:Int = 0;
	public var best:Int = 0;

	public function new() {}

	public static function load():Save {
		var s = new Save();
		try {
			var raw = Browser.window.localStorage.getItem(KEY);
			if (raw != null) {
				var d:Dynamic = haxe.Json.parse(raw);
				var it:haxe.DynamicAccess<Int> = d.items;
				if (it != null)
					for (k => v in it)
						s.items.set(Std.parseInt(k), v);
				if (d.games != null)
					s.games = d.games;
				if (d.best != null)
					s.best = d.best;
			}
		} catch (e:Dynamic) {
			Browser.console.warn("Sauvegarde illisible", e);
		}
		return s;
	}

	public function store() {
		var it = new haxe.DynamicAccess<Int>();
		for (k => v in items)
			it.set(Std.string(k), v);
		try {
			Browser.window.localStorage.setItem(KEY, haxe.Json.stringify({v: 1, items: it, games: games, best: best}));
		} catch (e:Dynamic) {
			Browser.console.warn("Sauvegarde impossible", e);
		}
	}

	/** Ajoute les objets d'une partie (tableau creux id -> nombre, renvoyé par `getPicks2()`). */
	public function addPicks(picks:Array<Null<Int>>) {
		if (picks == null)
			return;
		for (i in 0...picks.length) {
			var n = picks[i];
			if (n != null && n > 0)
				items.set(i, Quests.count(items, i) + n);
		}
	}

	public function totalItems():Int {
		var t = 0;
		for (v in items)
			t += v;
		return t;
	}
}

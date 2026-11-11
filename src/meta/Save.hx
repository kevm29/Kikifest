package meta;

import js.Browser;

/**
	Collection d'objets du joueur, gardée dans le navigateur (localStorage).

	Format : { "v": 1, "items": { "36": 5, "1000": 412, ... }, "games": 3, "best": 125000,
	           "history": [ {d, mode, name, score, level} ], "heroes": [ {d, name, score, msg} ] }
	Les ids >= 1000 sont les objets à points, comme dans `getPicks2()` du jeu.
**/
typedef GameRecord = {d:String, mode:String, name:String, score:Int, level:Int};
typedef Hero = {d:String, name:String, score:Int, ?msg:String};

class Save {
	static inline var KEY = "kikifest.collection";

	public var items:Map<Int, Int> = new Map();
	public var games:Int = 0;
	public var best:Int = 0;
	/** parties terminées (une ligne par joueur), pour le classement par étage */
	public var history:Array<GameRecord> = [];
	/** entrées au Panthéon ; msg est null tant que le héros n'a pas écrit sa phrase */
	public var heroes:Array<Hero> = [];

	/** Seuils de montée d'un étage à l'autre (étage 4 → 3 → 2 → 1 → Panthéon), repris du site d'origine. */
	public static var FLOORS = [369920, 737965, 3508030, 11152196];

	/** Étage d'un score : 4 (le plus bas) à 1, ou 0 pour le Panthéon. */
	public static function floorOf(score:Int):Int {
		var f = 4;
		for (t in FLOORS)
			if (score >= t)
				f--;
		return f;
	}

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
				if (d.history != null)
					s.history = d.history;
				if (d.heroes != null)
					s.heroes = d.heroes;
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
			Browser.window.localStorage.setItem(KEY, haxe.Json.stringify({v: 1, items: it, games: games, best: best, history: history, heroes: heroes}));
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

	/** Ajoute une partie au classement ; renvoie true si le joueur entre au Panthéon. */
	public function addRecord(r:GameRecord):Bool {
		history.push(r);
		if (r.score > best)
			best = r.score;
		if (floorOf(r.score) == 0 && heroes.filter(h -> h.name == r.name).length == 0) {
			heroes.push({d: r.d, name: r.name, score: r.score});
			return true;
		}
		return false;
	}

	public function totalItems():Int {
		var t = 0;
		for (v in items)
			t += v;
		return t;
	}
}

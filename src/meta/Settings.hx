package meta;

import js.Browser;

typedef KeyMap = {
	up:String,
	down:String,
	left:String,
	right:String,
	bomb:String,
	pause:String,
	map:String
};

typedef SettingsData = {
	/** volume de la musique, 0 à 100 **/
	music:Int,
	/** volume des bruitages, 0 à 100 **/
	sfx:Int,
	/** touches du joueur de ce clavier (seul ou en ligne) **/
	keys:KeyMap,
	/** touches du deuxième joueur sur le même clavier **/
	keys2:KeyMap,
	/** noms des touches tels qu'affichés au moment du choix (claviers AZERTY...) **/
	labels:Dynamic
};

/**
	Paramètres du joueur, gardés dans le navigateur (localStorage, clé `kikifest.settings`).
	Le pseudo reste dans `kikifest.name` (déjà utilisé par le menu et le classement).

	Les touches sont des `KeyboardEvent.code` (position physique sur le clavier).
	Le jeu ne lit jamais le clavier directement : `mask` transforme les touches enfoncées
	en un masque d'actions, qui passe par le réseau en multijoueur.
**/
class Settings {
	public static inline var UP = 1;
	public static inline var DOWN = 2;
	public static inline var LEFT = 4;
	public static inline var RIGHT = 8;
	public static inline var BOMB = 16;
	public static inline var PAUSE = 32;
	public static inline var MAP = 64;
	public static inline var QUIT = 128;

	public static var ACTIONS:Array<{id:String, name:String, bit:Int}> = [
		{id: "up", name: "Sauter", bit: UP},
		{id: "down", name: "Descendre", bit: DOWN},
		{id: "left", name: "Gauche", bit: LEFT},
		{id: "right", name: "Droite", bit: RIGHT},
		{id: "bomb", name: "Poser une bombe", bit: BOMB},
		{id: "pause", name: "Pause", bit: PAUSE},
		{id: "map", name: "Carte", bit: MAP},
	];

	public static function defaultKeys():KeyMap
		return {up: "ArrowUp", down: "ArrowDown", left: "ArrowLeft", right: "ArrowRight", bomb: "Space", pause: "KeyP", map: "KeyC"};

	public static function defaultKeys2():KeyMap
		return {up: "KeyR", down: "KeyF", left: "KeyD", right: "KeyG", bomb: "KeyQ", pause: "KeyP", map: "KeyC"};

	public static function defaults():SettingsData
		return {music: 70, sfx: 100, keys: defaultKeys(), keys2: defaultKeys2(), labels: {}};

	public static function load():SettingsData {
		var d = defaults();
		try {
			var raw = Browser.window.localStorage.getItem("kikifest.settings");
			if (raw != null) {
				var s:Dynamic = haxe.Json.parse(raw);
				if (s.music != null)
					d.music = clamp(s.music);
				if (s.sfx != null)
					d.sfx = clamp(s.sfx);
				for (k in ["keys", "keys2"]) {
					var src:Dynamic = Reflect.field(s, k);
					if (src != null)
						for (a in ACTIONS)
							if (Reflect.field(src, a.id) != null)
								Reflect.setField(Reflect.field(d, k), a.id, Reflect.field(src, a.id));
				}
				if (s.labels != null)
					d.labels = s.labels;
			}
		} catch (e:Dynamic) {}
		return d;
	}

	public static function store(d:SettingsData) {
		try {
			Browser.window.localStorage.setItem("kikifest.settings", haxe.Json.stringify(d));
		} catch (e:Dynamic) {}
	}

	static function clamp(v:Dynamic):Int {
		var n = Std.parseInt(Std.string(v));
		return n == null ? 100 : (n < 0 ? 0 : (n > 100 ? 100 : n));
	}

	public static function name():String {
		try {
			var v = Browser.window.localStorage.getItem("kikifest.name");
			return v != null && StringTools.trim(v) != "" ? StringTools.trim(v) : "Igor";
		} catch (e:Dynamic) {
			return "Igor";
		}
	}

	public static function setName(v:String) {
		try {
			Browser.window.localStorage.setItem("kikifest.name", StringTools.trim(v));
		} catch (e:Dynamic) {}
	}

	/** Masque d'actions pour un jeu de touches, d'après les touches enfoncées. **/
	public static function mask(keys:KeyMap, pressed:haxe.ds.StringMap<Bool>):Int {
		var m = 0;
		for (a in ACTIONS)
			if (pressed.exists(Reflect.field(keys, a.id)))
				m |= a.bit;
		return m;
	}

	/** Clavier français probable (les noms de touches AZERTY diffèrent de leur position QWERTY). **/
	static function azerty():Bool {
		var l = Browser.navigator.language;
		return l == "fr" || l == "fr-FR" || l == "fr-BE";
	}

	/** Nom lisible d'une touche (« Espace », « Flèche gauche », « A »...). **/
	public static function label(d:SettingsData, code:String):String {
		var l:String = d.labels != null ? Reflect.field(d.labels, code) : null;
		if (l != null)
			return l;
		var fixed = [
			"Space" => "Espace", "ArrowUp" => "Flèche haut", "ArrowDown" => "Flèche bas", "ArrowLeft" => "Flèche gauche",
			"ArrowRight" => "Flèche droite", "Enter" => "Entrée", "NumpadEnter" => "Entrée (pavé)", "ShiftLeft" => "Maj gauche",
			"ShiftRight" => "Maj droite", "ControlLeft" => "Ctrl gauche", "ControlRight" => "Ctrl droit", "AltLeft" => "Alt",
			"Escape" => "Échap", "Backspace" => "Retour arrière", "Tab" => "Tab"
		];
		if (fixed.exists(code))
			return fixed.get(code);
		if (azerty()) {
			var fr = ["KeyQ" => "A", "KeyA" => "Q", "KeyW" => "Z", "KeyZ" => "W", "Semicolon" => "M", "KeyM" => ","];
			if (fr.exists(code))
				return fr.get(code);
		}
		if (StringTools.startsWith(code, "Key"))
			return code.substr(3);
		if (StringTools.startsWith(code, "Digit"))
			return code.substr(5);
		if (StringTools.startsWith(code, "Numpad"))
			return code.substr(6) + " (pavé)";
		return code;
	}
}

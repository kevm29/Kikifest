package mtlib;

/**
	Clavier virtuel. Le jeu lit Key.isDown(code) ; en réseau, l'état des
	touches de chaque joueur est reconstruit à partir de ses entrées
	(masques de bits), jamais lu directement sur le vrai clavier.
**/
class Key {
	public static inline var BACKSPACE = 8;
	public static inline var TAB = 9;
	public static inline var ENTER = 13;
	public static inline var SHIFT = 16;
	public static inline var CONTROL = 17;
	public static inline var ALT = 18;
	public static inline var CAPSLOCK = 20;
	public static inline var ESCAPE = 27;
	public static inline var SPACE = 32;
	public static inline var PGUP = 33;
	public static inline var PGDN = 34;
	public static inline var END = 35;
	public static inline var HOME = 36;
	public static inline var LEFT = 37;
	public static inline var UP = 38;
	public static inline var RIGHT = 39;
	public static inline var DOWN = 40;
	public static inline var INSERT = 45;
	public static inline var DELETEKEY = 46;

	static var down:Map<Int, Bool> = new Map();

	public static function isDown(code:Int):Bool return down.get(code) == true;

	public static function isToggled(code:Int):Bool return false;

	public static function set(code:Int, v:Bool) {
		if (v)
			down.set(code, true);
		else
			down.remove(code);
	}

	public static function clear() down = new Map();

	public static function getCode():Int return 0;

	public static function getAscii():Int return 0;

	public static function addListener(l:Dynamic) {}

	public static function removeListener(l:Dynamic) {}
}

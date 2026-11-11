package mtlib;

/**
	Générateur pseudo-aléatoire déterministe (xorshift32) qui remplace
	Std.random : les deux joueurs doivent tirer exactement les mêmes nombres.
**/
class Rand {
	public static var seed:Int = 0x2545F491;

	public static function setSeed(s:Int) {
		seed = s == 0 ? 0x2545F491 : s;
	}

	public static function next():Int {
		var x = seed;
		x ^= x << 13;
		x ^= x >>> 17;
		x ^= x << 5;
		seed = x;
		return x >>> 0;
	}

	/** Entier dans [0, n[ (comme Std.random de Flash). */
	public static function random(n:Int):Int {
		if (n <= 0)
			return 0;
		var r:Float = (next() >>> 1);
		return Std.int(r % n);
	}
}

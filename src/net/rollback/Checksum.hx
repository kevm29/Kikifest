package net.rollback;

import haxe.io.Bytes;

/**
	Empreinte FNV-1a sur 32 bits, identique sur toutes les cibles.
	Usage : `var h = Checksum.START; h = Checksum.addInt(h, x); ...`
**/
class Checksum {
	public static inline var START:Int = 0x811c9dc5;

	public static function addInt(h:Int, v:Int):Int {
		h = mul((h ^ (v & 0xff)), 0x01000193);
		h = mul((h ^ ((v >>> 8) & 0xff)), 0x01000193);
		h = mul((h ^ ((v >>> 16) & 0xff)), 0x01000193);
		h = mul((h ^ ((v >>> 24) & 0xff)), 0x01000193);
		return h;
	}

	/** Les flottants sont hachés bit à bit (deux valeurs égales donnent la même empreinte). **/
	public static function addFloat(h:Int, v:Float):Int {
		var b = haxe.io.FPHelper.doubleToI64(v);
		return addInt(addInt(h, b.low), b.high);
	}

	public static function ofBytes(b:Bytes, h:Int = START):Int {
		for (i in 0...b.length)
			h = mul(h ^ b.get(i), 0x01000193);
		return h;
	}

	public static function ofInts(a:Array<Int>, h:Int = START):Int {
		for (v in a)
			h = addInt(h, v);
		return h;
	}

	/** Multiplication 32 bits avec débordement, comme en C. **/
	public static inline function mul(a:Int, b:Int):Int {
		#if js
		return js.Syntax.code("Math.imul({0}, {1})", a, b);
		#else
		return haxe.Int32.ofInt(a) * haxe.Int32.ofInt(b);
		#end
	}
}

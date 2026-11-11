package mtlib;

import swf.MovieClip;
import swf.TextField;

/** Équivalent du Std de MotionTypes (fonctions natives Flash). */
class MtStd {
	public static var root:MovieClip;
	public static var globals:Dynamic = {
		parseFloat: js.Lib.global.parseFloat,
		setInterval: js.Lib.global.setInterval,
		clearInterval: js.Lib.global.clearInterval
	};

	public static function attachMC(mc:MovieClip, link:String, depth:Int):MovieClip {
		return mc.attachMovie(link, "mc" + depth, depth);
	}

	public static function createEmptyMC(mc:MovieClip, depth:Int):MovieClip {
		return mc.createEmptyMovieClip("empty" + depth, depth);
	}

	public static function duplicateMC(mc:MovieClip, depth:Int):MovieClip {
		return mc.duplicateMovieClip("dup" + depth, depth);
	}

	public static function getVar(o:Dynamic, v:String):Dynamic return Reflect.field(o, v);

	public static function setVar(o:Dynamic, v:String, val:Dynamic):Void Reflect.setField(o, v, val);

	public static function getGlobal(v:String):Dynamic return Reflect.field(globals, v);

	public static function setGlobal(v:String, val:Dynamic):Void Reflect.setField(globals, v, val);

	public static function getRoot():MovieClip return root;

	public static function createTextField(mc:MovieClip, depth:Int):TextField {
		return mc.createTextField("tf" + depth, depth, 0, 0, 100, 20);
	}

	/** Temps simulé (ms) : dérivé du compteur de frames pour rester déterministe. */
	public static function getTimer():Int return Std.int(Timer.frameCount * 1000 / 40);

	public static function hitTest(a:MovieClip, b:MovieClip):Bool return a.hitTest(b);

	public static function random(x:Int):Int return Rand.random(x);

	public static function xmouse():Float return root == null ? 0 : root._xmouse;

	public static function ymouse():Float return root == null ? 0 : root._ymouse;

	public static function escape(x:String):String return StringTools.urlEncode(x);

	public static function unescape(x:String):String return StringTools.urlDecode(x);

	public static function parseInt(x:Dynamic, ?n:Int):Int {
		if (x == null)
			return cast Math.NaN; // Flash : parseInt(undefined) = NaN
		var r:Dynamic = js.Syntax.code("parseInt({0}, {1})", x, n == null ? 10 : n);
		return r;
	}

	public static function toString(n:Dynamic):String return Std.string(n);

	public static function toStringBase(x:Int, n:Int):String return js.Syntax.code("({0}).toString({1})", x, n);

	public static function isNaN(n:Dynamic):Bool return n == null || js.Syntax.code("isNaN({0})", n); // Flash 7 : Number(undefined) = NaN

	public static function registerClass(link:String, cls:Dynamic):Void MovieClip.registerClass(link, cls);

	public static function deleteField(x:Dynamic, f:String):Void Reflect.deleteField(x, f);

	public static function fscommand(c:String, a:String):Void {}

	/** o[k], ou null si o est null (AVM1 tolérait undefined[k]). */
	public static inline function ix(o:Dynamic, k:Dynamic):Dynamic return o == null ? null : o[k];

	// natifs utilisés par PersistCodec
	public static var infinity:Float = Math.POSITIVE_INFINITY;

	public static function _instanceof(o:Dynamic, c:Dynamic):Bool return js.Syntax.code("({0} instanceof {1})", o, c);

	public static function _typeof(o:Dynamic):String return js.Syntax.code("typeof({0})", o);

	public static function forin(o:Dynamic, f:Dynamic->Void):Void {
		js.Syntax.code("for (var k in {0}) {1}(k)", o, f);
	}
}

package mtlib;

/** Méthodes des chaînes Flash absentes de Haxe. */
class StringExt {
	public static inline function slice(s:String, start:Int, ?end:Int):String {
		return js.Syntax.code("{0}.slice({1}, {2})", s, start, end);
	}

	public static inline function concat(s:String, o:Dynamic):String return s + o;
}

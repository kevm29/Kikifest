package mtlib;

class Log {
	public static var tprint:Dynamic = {};

	public static function setColor(c:Int) {}

	public static function trace(v:Dynamic) js.Browser.console.log(Std.string(v));

	public static function print(v:Dynamic) js.Browser.console.log(Std.string(v));

	public static function clear() {}
}

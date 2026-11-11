package mtlib;

class SharedObject {
	public var data:Dynamic = {};

	function new() {}

	public static function getLocal(name:String):SharedObject return new SharedObject();

	public function flush():Bool return true;

	public function clear() data = {};
}

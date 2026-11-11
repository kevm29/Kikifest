package mtlib;

class Hash<T> {
	var h:haxe.ds.StringMap<T> = new haxe.ds.StringMap();

	public function new() {}

	public function get(k:String):T return h.get(k);

	public function set(k:String, v:T):Void h.set(k, v);

	public function remove(k:String):Bool return h.remove(k);

	public function exists(k:String):Bool return h.exists(k);

	public function iter(f:String->T->Void):Void {
		for (k in h.keys())
			f(k, h.get(k));
	}
}

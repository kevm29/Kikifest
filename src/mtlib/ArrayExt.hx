package mtlib;

/**
	Méthodes ajoutées par MotionTypes aux tableaux Flash (insert, remove, duplicate).
	Le code du jeu les appelle souvent sur des valeurs non typées : on les pose sur Array.prototype.
**/
@:keep class ArrayExt {
	static function __init__() {
		js.Syntax.code("
			var def = function(n, f) { if (!Array.prototype[n]) Object.defineProperty(Array.prototype, n, { value: f, writable: true, configurable: true, enumerable: false }); };
			def('insert', function(i, x) { this.splice(i, 0, x); });
			def('remove', function(x) { var i = this.indexOf(x); if (i < 0) return false; this.splice(i, 1); return true; });
			def('duplicate', function() { return this.slice(); });
			def('copy', function() { return this.slice(); });
		");
	}
}

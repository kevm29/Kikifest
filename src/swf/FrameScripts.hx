package swf;

/**
	Scripts de frame AS2 traduits au moment de l'extraction (gfx/framescripts.json).

	Chaque script s'exécute dans la portée du clip, comme en AS2 : un nom libre (gotoAndStop, _parent,
	compt…) désigne une propriété du clip. On l'obtient avec `with` sur un Proxy qui revendique tous
	les noms sauf quelques globales. Comme en AVM1, une erreur (accès à undefined) est ignorée.
**/
class FrameScripts {
	static var GLOBALS = ["Math", "random", "_global", "_root", "undefined", "NaN", "Infinity", "Number", "String", "Array",
		"Boolean", "Object", "isNaN", "parseInt", "parseFloat", "int", "trace", "console", "eval"];

	public static function register(scripts:Dynamic) {
		for (key in Reflect.fields(scripts)) {
			var body:String = Reflect.field(scripts, key);
			var f:Dynamic = null;
			try {
				f = js.Syntax.code("new Function('__s', 'random', '_global', '_root', 'int', 'trace', {0})", "with (__s) {\n" + body + "\n}");
			} catch (e:Dynamic) {
				js.Browser.console.warn("script de frame " + key + " non traduit : " + e);
				continue;
			}
			MovieClip.frameScripts.set(key, mc -> run(f, mc));
		}
	}

	static function run(f:Dynamic, mc:MovieClip) {
		try {
			f.call(mc, scope(mc), random, global, MtStdRoot.get(), (v:Dynamic) -> Std.int(v), (_:Dynamic) -> {});
		} catch (e:Dynamic) {
			// AVM1 ignorait silencieusement ces erreurs
		}
	}

	static function random(n:Dynamic):Int {
		var k = Std.int(n);
		return k <= 0 ? 0 : mtlib.Rand.random(k);
	}

	static var global:Dynamic = js.Syntax.code("{ get tmod() { return {0}.tmod; } }", mtlib.Timer);

	static function scope(mc:MovieClip):Dynamic {
		var s:Dynamic = untyped mc.__scope;
		if (s != null)
			return s;
		var globals = GLOBALS;
		s = js.Syntax.code("new Proxy({0}, {
			has: function(t, k) { return typeof k === 'string' && {1}.indexOf(k) < 0; },
			get: function(t, k) {
				if (k === Symbol.unscopables) return undefined;
				var v = t[k];
				return typeof v === 'function' ? v.bind(t) : v;
			},
			set: function(t, k, v) { t[k] = v; return true; }
		})", mc, globals);
		untyped mc.__scope = s;
		return s;
	}
}

/** Accès à la racine (_root) sans dépendre du code du jeu. */
class MtStdRoot {
	public static var root:Dynamic;

	public static function get():Dynamic return root;
}

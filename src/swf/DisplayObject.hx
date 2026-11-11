package swf;

/**
	Objet affichable, avec les propriétés AS2 (_x, _y, _xscale, _rotation...).
	La matrice est stockée décomposée comme dans Flash : échelles, rotation et
	biais, ce qui permet de modifier _rotation sans perdre l'échelle.
**/
class DisplayObject {
	public var __charId:Int;
	public var __depth:Int;
	public var _parent:MovieClip;
	public var _name:String = "";

	// transformation décomposée
	var __tx:Float = 0;
	var __ty:Float = 0;
	var __sx:Float = 1;
	var __sy:Float = 1;
	var __rotX:Float = 0; // radians
	var __rotY:Float = 0;

	/** Couleur : [rMul, gMul, bMul, aMul, rAdd, gAdd, bAdd, aAdd] */
	public var __cx:Null<Array<Float>> = null;

	public var __blend:Null<String> = null;
	public var __filters:Null<Array<Dynamic>> = null;
	public var __clipDepth:Int = 0;
	public var __ratio:Int = 0;

	/** Vrai dès qu'un script a touché la transformation : la timeline ne la modifie plus. */
	public var __scripted:Bool = false;

	/** Placé par la timeline (et non par attachMovie / createEmptyMovieClip). */
	public var __fromTimeline:Bool = false;

	public var _visible(default, set):Bool = true;

	public function new(__charId:Int) {
		this.__charId = __charId;
	}

	// --- matrice ---------------------------------------------------------

	public function __setMatrix(m:Array<Float>) {
		var a = m[0], b = m[1], c = m[2], d = m[3];
		__tx = m[4];
		__ty = m[5];
		__sx = Math.sqrt(a * a + b * b);
		__sy = Math.sqrt(c * c + d * d);
		if (a * d - b * c < 0)
			__sy = -__sy;
		__rotX = Math.atan2(b, a);
		__rotY = Math.atan2(-c, d);
		if (__sy < 0) {
			// garde une décomposition stable quand la matrice est retournée
			__rotY = Math.atan2(c, -d);
		}
	}

	public inline function __ma():Float return __sx * Math.cos(__rotX);
	public inline function __mb():Float return __sx * Math.sin(__rotX);
	public inline function __mc():Float return -__sy * Math.sin(__rotY);
	public inline function __md():Float return __sy * Math.cos(__rotY);
	public inline function __mtx():Float return __tx;
	public inline function __mty():Float return __ty;

	// --- propriétés AS2 --------------------------------------------------

	/**
		Le code du jeu manipule souvent les clips en Dynamic (mc._x = 3) : Haxe écrit alors le champ
		directement, sans passer par set__x. On déclare donc de vrais accesseurs JS sur le prototype.
	**/
	public static function __exposeProps(cls:Dynamic, names:Array<String>) {
		for (n in names)
			__expose(cls, n);
	}

	static function __expose(cls:Dynamic, n:String) {
		var get = "get_" + n, set = "set_" + n;
		js.Syntax.code("Object.defineProperty({0}.prototype, {1}, {get: function() { return this[{2}](); }, set: function(v) { var f = this[{3}]; if (f) f.call(this, v); }, configurable: true})", cls, n, get, set);
	}

	static function __init__() {
		__exposeProps(DisplayObject, ["_x", "_y", "_xscale", "_yscale", "_rotation", "_alpha", "_width", "_height", "filters", "blendMode"]);
	}

	public var _x(get, set):Float;
	public var _y(get, set):Float;
	public var _xscale(get, set):Float;
	public var _yscale(get, set):Float;
	public var _rotation(get, set):Float;
	public var _alpha(get, set):Float;

	function get__x() return __tx;
	function set__x(v:Float) {
		__scripted = true;
		return __tx = v;
	}

	function get__y() return __ty;
	function set__y(v:Float) {
		__scripted = true;
		return __ty = v;
	}

	function get__xscale() return __sx * 100;
	function set__xscale(v:Float) {
		__scripted = true;
		__sx = v / 100;
		return v;
	}

	function get__yscale() return __sy * 100;
	function set__yscale(v:Float) {
		__scripted = true;
		__sy = v / 100;
		return v;
	}

	function get__rotation() {
		var r = __rotX * 180 / Math.PI;
		return r;
	}

	function set__rotation(v:Float) {
		__scripted = true;
		var nr = v * Math.PI / 180;
		var delta = nr - __rotX;
		__rotX = nr;
		__rotY += delta;
		return v;
	}

	function get__alpha() return __cx == null ? 100 : __cx[3] * 100;

	function set__alpha(v:Float) {
		__scripted = true;
		if (__cx == null)
			__cx = [1, 1, 1, 1, 0, 0, 0, 0];
		else
			__cx = __cx.copy();
		__cx[3] = v / 100;
		return v;
	}

	function set__visible(v:Bool) {
		return _visible = v;
	}

	// --- dimensions -------------------------------------------------------

	/** Boîte englobante dans l'espace local. */
	public function __localBounds():Null<Rect> {
		var c:Dynamic = Library.inst.char(__charId);
		if (c == null || c.b == null)
			return null;
		var b:Array<Float> = c.b;
		return new Rect(b[0], b[1], b[2], b[3]);
	}

	public inline function __matrix():Array<Float> return [__ma(), __mb(), __mc(), __md(), __tx, __ty];

	public function __boundsInParent():Null<Rect> {
		var r = __localBounds();
		return r == null ? null : Rect.transform(r, __matrix());
	}

	/** Matrice locale -> racine. */
	public function __globalMatrix():Array<Float> {
		var m = __matrix();
		var p = _parent;
		while (p != null) {
			m = mul(p.__matrix(), m);
			p = p._parent;
		}
		return m;
	}

	static function mul(p:Array<Float>, m:Array<Float>):Array<Float> {
		return [
			p[0] * m[0] + p[2] * m[1], p[1] * m[0] + p[3] * m[1],
			p[0] * m[2] + p[2] * m[3], p[1] * m[2] + p[3] * m[3],
			p[0] * m[4] + p[2] * m[5] + p[4], p[1] * m[4] + p[3] * m[5] + p[5]
		];
	}

	static function invert(m:Array<Float>):Array<Float> {
		var det = m[0] * m[3] - m[1] * m[2];
		if (det == 0)
			return [1, 0, 0, 1, 0, 0];
		var a = m[3] / det, b = -m[1] / det, c = -m[2] / det, d = m[0] / det;
		return [a, b, c, d, -(a * m[4] + c * m[5]), -(b * m[4] + d * m[5])];
	}

	public function getBounds(?target:DisplayObject):Dynamic {
		var r = __localBounds();
		if (r == null) {
			var g = __globalMatrix();
			r = new Rect(0, 0, 0, 0);
			r = Rect.transform(r, g);
			if (target != null)
				r = Rect.transform(r, invert(target.__globalMatrix()));
			return r;
		}
		var m = __globalMatrix();
		if (target != null)
			m = mul(invert(target.__globalMatrix()), m);
		return Rect.transform(r, m);
	}

	public function localToGlobal(pt:Dynamic) {
		var m = __globalMatrix();
		var x:Float = pt.x, y:Float = pt.y;
		pt.x = m[0] * x + m[2] * y + m[4];
		pt.y = m[1] * x + m[3] * y + m[5];
	}

	public function globalToLocal(pt:Dynamic) {
		var m = invert(__globalMatrix());
		var x:Float = pt.x, y:Float = pt.y;
		pt.x = m[0] * x + m[2] * y + m[4];
		pt.y = m[1] * x + m[3] * y + m[5];
	}

	public var _width(get, set):Float;
	public var _height(get, set):Float;

	function get__width():Float {
		var r = __boundsInParent();
		return r == null ? 0 : r.xMax - r.xMin;
	}

	function set__width(v:Float):Float {
		var r = __localBounds();
		if (r != null && r.xMax > r.xMin) {
			__scripted = true;
			__sx = v / (r.xMax - r.xMin);
		}
		return v;
	}

	function get__height():Float {
		var r = __boundsInParent();
		return r == null ? 0 : r.yMax - r.yMin;
	}

	function set__height(v:Float):Float {
		var r = __localBounds();
		if (r != null && r.yMax > r.yMin) {
			__scripted = true;
			__sy = v / (r.yMax - r.yMin);
		}
		return v;
	}

	/** filters AS2 : liste de GlowFilter / BlurFilter (copiée, comme dans Flash). */
	public var filters(get, set):Array<Dynamic>;

	function get_filters():Array<Dynamic> return __filters == null ? [] : __filters.copy();

	function set_filters(v:Array<Dynamic>):Array<Dynamic> {
		__filters = v == null || v.length == 0 ? null : v.copy();
		return v;
	}

	static var BLENDS = [null, null, "layer", "multiply", "screen", "lighten", "darken", "add", "subtract", "difference", "invert", "alpha", "erase", "overlay", "hardlight"];

	public var blendMode(get, set):Dynamic;

	function get_blendMode():Dynamic {
		var i = BLENDS.indexOf(__blend);
		return i < 0 ? 1 : i;
	}

	function set_blendMode(v:Dynamic):Dynamic {
		if (Std.isOfType(v, Int))
			__blend = BLENDS[v];
		else
			__blend = v == "normal" ? null : v;
		return v;
	}

	/**
		En Flash, un clip retiré devient une référence morte : _name vaut undefined, pour lui et
		ses descendants. Le jeu s'en sert pour savoir si un clip existe encore (mc._name != null).
	**/
	public function __kill() {
		_name = null;
		var ch:Array<DisplayObject> = untyped this.__children;
		if (ch != null)
			for (c in ch)
				c.__kill();
	}

	public function removeMovieClip() {
		if (_parent != null)
			_parent.__removeChild(this);
	}

	/** Avance d'une image (rien pour un objet statique). */
	public function __advance(queue:Array<Void->Void>) {}
}

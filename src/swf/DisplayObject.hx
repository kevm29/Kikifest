package swf;

/**
	Objet affichable, avec les propriétés AS2 (_x, _y, _xscale, _rotation...).
	La matrice est stockée décomposée comme dans Flash : échelles, rotation et
	biais, ce qui permet de modifier _rotation sans perdre l'échelle.
**/
class DisplayObject {
	public var charId:Int;
	public var depth:Int;
	public var _parent:MovieClip;
	public var _name:String = "";

	// transformation décomposée
	var tx:Float = 0;
	var ty:Float = 0;
	var sx:Float = 1;
	var sy:Float = 1;
	var rotX:Float = 0; // radians
	var rotY:Float = 0;

	/** Couleur : [rMul, gMul, bMul, aMul, rAdd, gAdd, bAdd, aAdd] */
	public var cx:Null<Array<Float>> = null;

	public var blend:Null<String> = null;
	public var filters:Null<Array<Dynamic>> = null;
	public var clipDepth:Int = 0;
	public var ratio:Int = 0;

	/** Vrai dès qu'un script a touché la transformation : la timeline ne la modifie plus. */
	public var scripted:Bool = false;

	/** Placé par la timeline (et non par attachMovie / createEmptyMovieClip). */
	public var fromTimeline:Bool = false;

	public var _visible(default, set):Bool = true;

	public function new(charId:Int) {
		this.charId = charId;
	}

	// --- matrice ---------------------------------------------------------

	public function setMatrix(m:Array<Float>) {
		var a = m[0], b = m[1], c = m[2], d = m[3];
		tx = m[4];
		ty = m[5];
		sx = Math.sqrt(a * a + b * b);
		sy = Math.sqrt(c * c + d * d);
		if (a * d - b * c < 0)
			sy = -sy;
		rotX = Math.atan2(b, a);
		rotY = Math.atan2(-c, d);
		if (sy < 0) {
			// garde une décomposition stable quand la matrice est retournée
			rotY = Math.atan2(c, -d);
		}
	}

	public inline function ma():Float return sx * Math.cos(rotX);
	public inline function mb():Float return sx * Math.sin(rotX);
	public inline function mc():Float return -sy * Math.sin(rotY);
	public inline function md():Float return sy * Math.cos(rotY);
	public inline function mtx():Float return tx;
	public inline function mty():Float return ty;

	// --- propriétés AS2 --------------------------------------------------

	public var _x(get, set):Float;
	public var _y(get, set):Float;
	public var _xscale(get, set):Float;
	public var _yscale(get, set):Float;
	public var _rotation(get, set):Float;
	public var _alpha(get, set):Float;

	function get__x() return tx;
	function set__x(v:Float) {
		scripted = true;
		return tx = v;
	}

	function get__y() return ty;
	function set__y(v:Float) {
		scripted = true;
		return ty = v;
	}

	function get__xscale() return sx * 100;
	function set__xscale(v:Float) {
		scripted = true;
		sx = v / 100;
		return v;
	}

	function get__yscale() return sy * 100;
	function set__yscale(v:Float) {
		scripted = true;
		sy = v / 100;
		return v;
	}

	function get__rotation() {
		var r = rotX * 180 / Math.PI;
		return r;
	}

	function set__rotation(v:Float) {
		scripted = true;
		var nr = v * Math.PI / 180;
		var delta = nr - rotX;
		rotX = nr;
		rotY += delta;
		return v;
	}

	function get__alpha() return cx == null ? 100 : cx[3] * 100;

	function set__alpha(v:Float) {
		scripted = true;
		if (cx == null)
			cx = [1, 1, 1, 1, 0, 0, 0, 0];
		else
			cx = cx.copy();
		cx[3] = v / 100;
		return v;
	}

	function set__visible(v:Bool) {
		return _visible = v;
	}

	public function removeMovieClip() {
		if (_parent != null)
			_parent.removeChild(this);
	}

	/** Avance d'une image (rien pour un objet statique). */
	public function advance(queue:Array<Void->Void>) {}
}

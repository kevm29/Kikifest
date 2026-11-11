package swf;

class Rect {
	public var xMin:Float;
	public var yMin:Float;
	public var xMax:Float;
	public var yMax:Float;

	public function new(x0:Float, y0:Float, x1:Float, y1:Float) {
		xMin = x0;
		yMin = y0;
		xMax = x1;
		yMax = y1;
	}

	public static function union(a:Rect, b:Rect):Rect {
		return new Rect(Math.min(a.xMin, b.xMin), Math.min(a.yMin, b.yMin), Math.max(a.xMax, b.xMax), Math.max(a.yMax, b.yMax));
	}

	/** Boîte englobante de r transformé par la matrice m = [a,b,c,d,tx,ty]. */
	public static function transform(r:Rect, m:Array<Float>):Rect {
		var xs = [r.xMin, r.xMax, r.xMin, r.xMax];
		var ys = [r.yMin, r.yMin, r.yMax, r.yMax];
		var out:Rect = null;
		for (i in 0...4) {
			var x = m[0] * xs[i] + m[2] * ys[i] + m[4];
			var y = m[1] * xs[i] + m[3] * ys[i] + m[5];
			if (out == null)
				out = new Rect(x, y, x, y);
			else {
				if (x < out.xMin) out.xMin = x;
				if (x > out.xMax) out.xMax = x;
				if (y < out.yMin) out.yMin = y;
				if (y > out.yMax) out.yMax = y;
			}
		}
		return out;
	}
}

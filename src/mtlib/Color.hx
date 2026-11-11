package mtlib;

import swf.MovieClip;

/** Objet Color de Flash : modifie la transformation de couleur d'un clip. */
class Color {
	var mc:swf.DisplayObject;

	public function new(mc:swf.DisplayObject) {
		this.mc = mc;
	}

	public function setRGB(c:Int) {
		mc.__cx = [0, 0, 0, mc.__cx == null ? 1 : mc.__cx[3], (c >> 16) & 255, (c >> 8) & 255, c & 255, 0];
	}

	public function getRGB():Int {
		var c = mc.__cx;
		return c == null ? 0 : (Std.int(c[4]) << 16) | (Std.int(c[5]) << 8) | Std.int(c[6]);
	}

	public function setTransform(t:Dynamic) {
		var c = mc.__cx == null ? [1.0, 1, 1, 1, 0, 0, 0, 0] : mc.__cx.copy();
		if (t.ra != null) c[0] = t.ra / 100;
		if (t.ga != null) c[1] = t.ga / 100;
		if (t.ba != null) c[2] = t.ba / 100;
		if (t.aa != null) c[3] = t.aa / 100;
		if (t.rb != null) c[4] = t.rb;
		if (t.gb != null) c[5] = t.gb;
		if (t.bb != null) c[6] = t.bb;
		if (t.ab != null) c[7] = t.ab;
		mc.__cx = c;
	}

	/** Annule toute transformation de couleur (extension mt). */
	public function reset() {
		mc.__cx = null;
	}

	public function getTransform():Dynamic {
		var c = mc.__cx == null ? [1.0, 1, 1, 1, 0, 0, 0, 0] : mc.__cx;
		return {ra: c[0] * 100, ga: c[1] * 100, ba: c[2] * 100, aa: c[3] * 100, rb: c[4], gb: c[5], bb: c[6], ab: c[7]};
	}
}

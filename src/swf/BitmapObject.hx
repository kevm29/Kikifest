package swf;

/** Bitmap attaché par attachBitmap (le contenu est un BitmapData). */
class BitmapObject extends DisplayObject {
	public var bitmap:Dynamic;

	public function new(b:Dynamic) {
		super(-2);
		bitmap = b;
	}

	override public function __localBounds():Null<Rect> {
		return bitmap == null ? null : new Rect(0, 0, bitmap.width, bitmap.height);
	}
}

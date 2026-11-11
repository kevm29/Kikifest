package mtflash.filters;

class GlowFilter {
	public var type = 2;
	public var color:Int;
	public var alpha:Float;
	public var blurX:Float;
	public var blurY:Float;
	public var strength:Float;
	public var quality:Int;
	public var inner:Bool;
	public var knockout:Bool;

	public function new(?color:Int = 0xff0000, ?alpha:Float = 1, ?blurX:Float = 6, ?blurY:Float = 6, ?strength:Float = 2, ?quality:Int = 1, ?inner:Bool = false, ?knockout:Bool = false) {
		this.color = color; this.alpha = alpha; this.blurX = blurX; this.blurY = blurY;
		this.strength = strength; this.quality = quality; this.inner = inner; this.knockout = knockout;
	}
}

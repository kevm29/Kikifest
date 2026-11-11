package mtflash.filters;

class BlurFilter {
	public var type = 1;
	public var blurX:Float;
	public var blurY:Float;
	public var quality:Int;

	public function new(?blurX:Float = 4, ?blurY:Float = 4, ?quality:Int = 1) {
		this.blurX = blurX; this.blurY = blurY; this.quality = quality;
	}
}

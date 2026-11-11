package mtflash.display;

import js.html.CanvasElement;

/** BitmapData de Flash 8 : un canvas hors écran (utilisé pour les caches de décor). */
class BitmapData {
	public var canvas:CanvasElement;
	public var width:Int;
	public var height:Int;

	public function new(w:Int, h:Int, ?transparent:Bool = true, ?fill:Int = 0) {
		width = w;
		height = h;
		canvas = js.Browser.document.createCanvasElement();
		canvas.width = w;
		canvas.height = h;
	}

	/** Dessine un clip dans le bitmap (à l'échelle 1). */
	public function drawMC(mc:swf.MovieClip, x:Float, y:Float) {
		swf.Renderer.drawInto(canvas, mc, x, y);
	}

	public function draw(mc:swf.MovieClip, ?matrix:Dynamic) {
		swf.Renderer.drawInto(canvas, mc, 0, 0);
	}

	public function dispose() {
		canvas.width = 1;
		canvas.height = 1;
	}

	public function fillRect(r:Dynamic, c:Int) {}

	public function clone():BitmapData {
		var b = new BitmapData(width, height);
		b.canvas.getContext2d().drawImage(canvas, 0, 0);
		return b;
	}
}

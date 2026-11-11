package swf;

import js.Browser;
import js.html.CanvasElement;
import js.html.ImageElement;

/**
	Bibliothèque de symboles extraite de game.swf (voir tools/extract).
	Charge library.json (timelines, définitions) et shapes.json (SVG des formes).
**/
class Library {
	public static var inst:Library;

	public var data:Dynamic;
	public var frameRate:Float;

	var svgs:haxe.DynamicAccess<String>;
	var images:Map<Int, ImageElement> = new Map();
	var raster:Map<String, CanvasElement> = new Map();
	var base:String;

	public var pending(default, null):Int = 0;

	function new(base:String, data:Dynamic, svgs:Dynamic) {
		this.base = base;
		this.data = data;
		this.svgs = svgs;
		this.frameRate = data.frameRate;
	}

	public static function load(base:String, onReady:Library->Void, ?onError:String->Void) {
		var lib:Dynamic = null;
		var shapes:Dynamic = null;
		function done() {
			if (lib != null && shapes != null) {
				inst = new Library(base, lib, shapes);
				onReady(inst);
			}
		}
		function fail(e:Dynamic) {
			if (onError != null)
				onError(Std.string(e));
		}
		Browser.window.fetch(base + "/gfx/library.json").then(r -> r.json()).then(j -> {
			lib = j;
			done();
		}).catchError(fail);
		Browser.window.fetch(base + "/gfx/shapes.json").then(r -> r.json()).then(j -> {
			shapes = j;
			done();
		}).catchError(fail);
	}

	public inline function char(id:Int):Dynamic {
		return Reflect.field(data.chars, Std.string(id));
	}

	public function exportId(name:String):Null<Int> {
		return Reflect.field(data.exports, name);
	}

	public function exportNames():Array<String> {
		var a = Reflect.fields(data.exports);
		a.sort((x, y) -> x < y ? -1 : (x > y ? 1 : 0));
		return a;
	}

	/** Image source (SVG ou bitmap) d'un caractère, chargée à la demande. */
	public function image(id:Int):Null<ImageElement> {
		var img = images.get(id);
		if (img != null)
			return img.complete && img.naturalWidth > 0 ? img : null;
		var src:String = null;
		var svg = svgs.get(Std.string(id));
		if (svg != null) {
			src = "data:image/svg+xml;charset=utf-8," + StringTools.urlEncode(svg);
		} else {
			var c = char(id);
			if (c != null && c.file != null)
				src = base + "/gfx/" + c.file;
		}
		if (src == null)
			return null;
		img = Browser.document.createImageElement();
		pending++;
		img.onload = () -> pending--;
		img.onerror = () -> pending--;
		img.src = src;
		images.set(id, img);
		return null;
	}

	/**
		Version pixellisée d'une forme à une échelle donnée (puissance de 2),
		pour éviter de redessiner le SVG à chaque image.
	**/
	public function rasterized(id:Int, scale:Float):Null<CanvasElement> {
		var bucket = Math.pow(2, Math.ceil(Math.log(Math.max(scale, 0.125)) / Math.log(2)));
		if (bucket > 8)
			bucket = 8;
		var key = id + "@" + bucket;
		var c = raster.get(key);
		if (c != null)
			return c;
		var img = image(id);
		if (img == null)
			return null;
		var ch = char(id);
		var b:Array<Float> = ch.b;
		c = Browser.document.createCanvasElement();
		var w = Math.ceil(img.naturalWidth * bucket);
		var h = Math.ceil(img.naturalHeight * bucket);
		if (w < 1 || h < 1)
			return null;
		c.width = w;
		c.height = h;
		c.getContext2d().drawImage(img, 0, 0, w, h);
		untyped c.__scale = bucket;
		raster.set(key, c);
		return c;
	}
}

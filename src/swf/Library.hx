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

	/** Planches pré-pixellisées (tools/extract/rasterize.cjs) : id -> [page, x, y, w, h, échelle]. */
	var atlasMap:haxe.DynamicAccess<Array<Float>> = null;
	var atlasPages:Array<ImageElement> = [];

	public static function load(base:String, onReady:Library->Void, ?onError:String->Void, ?onProgress:Float->Void) {
		function fail(e:Dynamic) {
			if (onError != null)
				onError(Std.string(e));
		}
		Browser.window.fetch(base + "/gfx/library.json").then(r -> r.json()).then(lib -> {
			Browser.window.fetch(base + "/gfx/atlas.json").then(r -> r.ok ? r.json() : null).then(atlas -> {
				if (atlas == null) {
					// pas d'atlas : SVG décodés à la demande
					Browser.window.fetch(base + "/gfx/shapes.json").then(r -> r.json()).then(shapes -> {
						inst = new Library(base, lib, shapes);
						onReady(inst);
					}).catchError(fail);
					return;
				}
				var l = new Library(base, lib, {});
				l.atlasMap = atlas.map;
				var n:Int = atlas.pages;
				var loaded = 0;
				for (i in 0...n) {
					var img = Browser.document.createImageElement();
					img.onload = () -> {
						loaded++;
						if (onProgress != null)
							onProgress(loaded / n);
						if (loaded == n) {
							inst = l;
							onReady(l);
						}
					};
					img.onerror = () -> fail("planche " + i);
					img.src = base + "/gfx/atlas/atlas-" + i + ".webp";
					l.atlasPages.push(img);
				}
			}).catchError(fail);
		}).catchError(fail);
	}

	/** Région de l'atlas pour un caractère : [image, x, y, w, h] ou null. */
	public inline function atlasRegion(id:Int):Null<Array<Float>> {
		return atlasMap == null ? null : atlasMap.get(Std.string(id));
	}

	public inline function atlasPage(i:Int):ImageElement return atlasPages[i];

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

	/** Précharge toutes les formes (nécessaire pour les caches bitmap du décor). */
	public function preloadAll(onProgress:Float->Void, onDone:Void->Void) {
		if (atlasMap != null) {
			onDone();
			return;
		}
		var ids = [for (k in svgs.keys()) Std.parseInt(k)];
		var total = ids.length;
		var next = 0;
		function check() {
			// création par lots pour ne pas bloquer la page
			var end = Std.int(Math.min(next + 150, total));
			while (next < end)
				image(ids[next++]);
			onProgress((next - pending) / total);
			if (next >= total && pending <= 0)
				onDone();
			else
				js.Browser.window.setTimeout(check, 16);
		}
		check();
	}

	/** Image source (SVG ou bitmap) d'un caractère, chargée à la demande. */
	public function image(id:Int):Null<ImageElement> {
		var img = images.get(id);
		if (img != null)
			return img.complete && img.naturalWidth > 0 ? img : null;
		var src:String = null;
		var svg = svgs.get(Std.string(id));
		if (svg != null) {
			src = js.html.URL.createObjectURL(new js.html.Blob([svg], {type: "image/svg+xml"}));
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

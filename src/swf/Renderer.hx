package swf;

import js.Browser;
import js.html.CanvasElement;
import js.html.CanvasRenderingContext2D;

/**
	Rendu Canvas 2D d'une arborescence de MovieClip.
	Les formes sont pré-pixellisées par Library ; les transformations de
	couleur sont appliquées pixel par pixel sur une copie de l'image, gardée en cache
	(les filtres SVG via ctx.filter étaient très lents, surtout sous Firefox).
**/
class Renderer {
	public var canvas:CanvasElement;
	public var ctx:CanvasRenderingContext2D;
	public var scale:Float = 1;
	public var background:String = "#000";

	var layers:Array<CanvasElement> = [];
	var layerIndex = 0;
	var tintCache:Map<String, CanvasElement> = new Map();
	var tintCount = 0;

	static var IDENT:Array<Float> = [1, 1, 1, 1, 0, 0, 0, 0];

	public function new(canvas:CanvasElement) {
		this.canvas = canvas;
		this.ctx = canvas.getContext2d();
	}

	static var offscreen:Renderer;

	/** Dessine un clip dans un canvas (BitmapData.drawMC), à l'échelle 1. */
	public static function drawInto(target:CanvasElement, mc:MovieClip, x:Float, y:Float) {
		if (offscreen == null)
			offscreen = new Renderer(target);
		offscreen.canvas = target;
		offscreen.ctx = target.getContext2d();
		offscreen.layerIndex = 0;
		var g = offscreen.ctx;
		g.save();
		offscreen.drawObject(g, mc, [1, 0, 0, 1, x - mc._x, y - mc._y], IDENT, null);
		g.restore();
	}

	public function render(root:MovieClip) {
		ctx.setTransform(1, 0, 0, 1, 0, 0);
		ctx.globalCompositeOperation = "source-over";
		ctx.globalAlpha = 1;
		ctx.fillStyle = background;
		ctx.fillRect(0, 0, canvas.width, canvas.height);
		layerIndex = 0;
		drawObject(ctx, root, [scale, 0, 0, scale, 0, 0], IDENT, null);
	}

	static inline function mul(p:Array<Float>, o:DisplayObject):Array<Float> {
		var a = o.__ma(), b = o.__mb(), c = o.__mc(), d = o.__md(), __tx = o.__mtx(), __ty = o.__mty();
		return [
			p[0] * a + p[2] * b,
			p[1] * a + p[3] * b,
			p[0] * c + p[2] * d,
			p[1] * c + p[3] * d,
			p[0] * __tx + p[2] * __ty + p[4],
			p[1] * __tx + p[3] * __ty + p[5]
		];
	}

	static function concatCx(p:Array<Float>, c:Null<Array<Float>>):Array<Float> {
		if (c == null)
			return p;
		return [
			p[0] * c[0], p[1] * c[1], p[2] * c[2], p[3] * c[3],
			p[0] * c[4] + p[4], p[1] * c[5] + p[5], p[2] * c[6] + p[6], p[3] * c[7] + p[7]
		];
	}

	static function compositeOp(__blend:String):Null<String> {
		return switch (__blend) {
			case "add": "lighter";
			case "multiply": "multiply";
			case "screen": "screen";
			case "lighten": "lighten";
			case "darken": "darken";
			case "difference": "difference";
			case "overlay": "overlay";
			case "hardlight": "hard-light";
			case "erase": "destination-out";
			default: null;
		}
	}

	function drawObject(g:CanvasRenderingContext2D, o:DisplayObject, pm:Array<Float>, pcx:Array<Float>, op:Null<String>) {
		if (!o._visible)
			return;
		var m = o._parent == null && Std.isOfType(o, MovieClip) && (cast o : MovieClip).__isRoot ? mulRoot(pm, o) : mul(pm, o);
		var __cx = concatCx(pcx, o.__cx);
		if (__cx[3] <= 0 && __cx[7] <= 0)
			return;
		if (o.__blend != null) {
			var c = compositeOp(o.__blend);
			if (c != null)
				op = c;
		}
		if (Std.isOfType(o, MovieClip)) {
			if (o.__blend == "layer") {
				// mode « calque » : les enfants sont composés à part (les modes effacer/alpha
				// n'agissent qu'à l'intérieur), puis le tout est posé avec l'opacité du clip
				var layer = acquireLayer();
				var lg = layer.getContext2d();
				lg.setTransform(1, 0, 0, 1, 0, 0);
				lg.globalCompositeOperation = "source-over";
				lg.globalAlpha = 1;
				lg.clearRect(0, 0, layer.width, layer.height);
				var inner = __cx.copy();
				var alpha = inner[3];
				inner[3] = 1;
				drawChildren(lg, (cast o : MovieClip), m, inner, null);
				g.setTransform(1, 0, 0, 1, 0, 0);
				g.globalAlpha = Math.max(0, Math.min(1, alpha));
				g.globalCompositeOperation = op != null ? op : "source-over";
				g.drawImage(layer, 0, 0);
				g.globalAlpha = 1;
				g.globalCompositeOperation = "source-over";
				layerIndex--;
				return;
			}
			drawChildren(g, (cast o : MovieClip), m, __cx, op);
			return;
		}
		if (Std.isOfType(o, BitmapObject)) {
			var bo:BitmapObject = cast o;
			if (bo.bitmap != null && bo.bitmap.canvas != null) {
				g.setTransform(m[0], m[1], m[2], m[3], m[4], m[5]);
				g.globalCompositeOperation = op != null ? op : "source-over";
				var bc = bo.bitmap.canvas;
				if (applyColor(g, __cx))
					g.drawImage(tint(bc, 0, 0, bc.width, bc.height, __cx, null), 0, 0);
				else
					g.drawImage(bc, 0, 0);
				g.globalAlpha = 1;
			}
			return;
		}
		if (Std.isOfType(o, TextField)) {
			drawText(g, cast o, m, __cx, op);
			return;
		}
		drawGraphic(g, o.__charId, m, __cx, op);
	}

	inline function mulRoot(pm:Array<Float>, o:DisplayObject) return mul(pm, o);

	function drawChildren(g:CanvasRenderingContext2D, __mc:MovieClip, m:Array<Float>, __cx:Array<Float>, op:Null<String>) {
		var ch = __mc.__children;
		var i = 0;
		while (i < ch.length) {
			var c = ch[i];
			if (c.__clipDepth != 0) {
				// masque : les objets suivants jusqu'à __clipDepth sont dessinés dans un calque
				var masked = [];
				var j = i + 1;
				while (j < ch.length && ch[j].__depth <= c.__clipDepth) {
					masked.push(ch[j]);
					j++;
				}
				var layer = acquireLayer();
				var lg = layer.getContext2d();
				lg.setTransform(1, 0, 0, 1, 0, 0);
				lg.globalCompositeOperation = "source-over";
				lg.globalAlpha = 1;
				lg.clearRect(0, 0, layer.width, layer.height);
				for (mo in masked)
					drawObject(lg, mo, m, __cx, null);
				// le masque est d'abord dessiné normalement dans son propre calque, puis appliqué d'un coup
				// sur toute la surface : certains navigateurs (Firefox) ne composent "destination-in"
				// que dans l'emprise de l'image dessinée, ce qui laissait passer tout le reste
				var maskLayer = acquireLayer();
				var mg = maskLayer.getContext2d();
				mg.setTransform(1, 0, 0, 1, 0, 0);
				mg.globalCompositeOperation = "source-over";
				mg.globalAlpha = 1;
				mg.clearRect(0, 0, maskLayer.width, maskLayer.height);
				drawObject(mg, c, m, [1, 1, 1, 1, 0, 0, 0, 0], null);
				layerIndex--;
				lg.setTransform(1, 0, 0, 1, 0, 0);
				lg.globalAlpha = 1;
				lg.globalCompositeOperation = "destination-in";
				lg.drawImage(maskLayer, 0, 0);
				lg.globalCompositeOperation = "source-over";
				g.setTransform(1, 0, 0, 1, 0, 0);
				g.globalAlpha = 1;
				g.globalCompositeOperation = op != null ? op : "source-over";
				g.drawImage(layer, 0, 0);
				layerIndex--;
				i = j;
				continue;
			}
			drawObject(g, c, m, __cx, op);
			i++;
		}
	}

	function acquireLayer():CanvasElement {
		var l = layers[layerIndex];
		if (l == null) {
			l = Browser.document.createCanvasElement();
			layers[layerIndex] = l;
		}
		if (l.width != canvas.width || l.height != canvas.height) {
			l.width = canvas.width;
			l.height = canvas.height;
		}
		layerIndex++;
		return l;
	}

	function drawGraphic(g:CanvasRenderingContext2D, id:Int, m:Array<Float>, __cx:Array<Float>, op:Null<String>) {
		var ch:Dynamic = Library.inst.char(id);
		if (ch == null || ch.b == null)
			return;
		var b:Array<Float> = ch.b;
		var reg = Library.inst.atlasRegion(id);
		if (reg != null) {
			g.setTransform(m[0], m[1], m[2], m[3], m[4], m[5]);
			g.globalCompositeOperation = op != null ? op : "source-over";
			var page = Library.inst.atlasPage(Std.int(reg[0]));
			if (applyColor(g, __cx))
				g.drawImage(tint(page, Std.int(reg[1]), Std.int(reg[2]), Std.int(reg[3]), Std.int(reg[4]), __cx, "a" + id), b[0], b[1], b[2] - b[0], b[3] - b[1]);
			else
				g.drawImage(page, reg[1], reg[2], reg[3], reg[4], b[0], b[1], b[2] - b[0], b[3] - b[1]);
			g.globalAlpha = 1;
			return;
		}
		var s = Math.sqrt(Math.abs(m[0] * m[3] - m[1] * m[2]));
		var img = Library.inst.rasterized(id, s);
		if (img == null)
			return;
		g.setTransform(m[0], m[1], m[2], m[3], m[4], m[5]);
		g.globalCompositeOperation = op != null ? op : "source-over";
		if (applyColor(g, __cx))
			g.drawImage(tint(img, 0, 0, img.width, img.height, __cx, "r" + id + "@" + img.width), b[0], b[1], b[2] - b[0], b[3] - b[1]);
		else
			g.drawImage(img, b[0], b[1], b[2] - b[0], b[3] - b[1]);
		g.globalAlpha = 1;
	}

	function drawText(g:CanvasRenderingContext2D, t:TextField, m:Array<Float>, __cx:Array<Float>, op:Null<String>) {
		var d:Dynamic = t.__def != null ? t.__def : {};
		var lb = t.__localBounds();
		var b:Array<Float> = [lb.xMin, lb.yMin, lb.xMax, lb.yMax];
		g.setTransform(m[0], m[1], m[2], m[3], m[4], m[5]);
		g.globalCompositeOperation = op != null ? op : "source-over";
		g.globalAlpha = Math.max(0, Math.min(1, __cx[3] + __cx[7] / 255));
		g.font = t.fontCss();
		g.textBaseline = "top";
		g.textAlign = "left";
		var align:Int = d.align != null ? d.align : (t.format.align == "right" ? 1 : (t.format.align == "center" ? 2 : 0));
		var y = b[1] + 2;
		var lh = t.lineHeight();
		for (l in t.__layout().lines) {
			var x = align == 1 ? b[2] - 2 - l.w : (align == 2 ? (b[0] + b[2] - l.w) / 2 : b[0] + 2);
			for (r in l.runs) {
				var col:Int = r.c != null ? r.c : t.textColor;
				var rr = clamp(((col >> 16) & 255) * __cx[0] + __cx[4]);
				var gg = clamp(((col >> 8) & 255) * __cx[1] + __cx[5]);
				var bb = clamp((col & 255) * __cx[2] + __cx[6]);
				g.fillStyle = 'rgb($rr,$gg,$bb)';
				g.fillText(r.t, x, y);
				x += g.measureText(r.t).width;
			}
			y += lh;
		}
		g.globalAlpha = 1;
	}

	static inline function clamp(v:Float):Int return Std.int(Math.max(0, Math.min(255, v)));

	/** Règle l'opacité ; renvoie vrai si l'image doit être teintée (voir tint). */
	function applyColor(g:CanvasRenderingContext2D, __cx:Array<Float>):Bool {
		var tinted = __cx[0] != 1 || __cx[1] != 1 || __cx[2] != 1 || __cx[4] != 0 || __cx[5] != 0 || __cx[6] != 0 || __cx[7] != 0;
		// l'opacité multiplicative passe par globalAlpha ; seul un décalage d'alpha reste dans les pixels
		g.globalAlpha = Math.max(0, Math.min(1, __cx[3]));
		if (tinted && __cx[7] != 0)
			g.globalAlpha = 1;
		return tinted;
	}

	/** Copie teintée d'une zone d'image ; mise en cache quand key est donnée (images fixes). */
	function tint(src:Dynamic, sx:Int, sy:Int, sw:Int, sh:Int, __cx:Array<Float>, key:Null<String>):CanvasElement {
		var withAlpha = __cx[7] != 0;
		var q = function(v:Float) return Math.round(v * 64) / 64;
		var k:String = null;
		if (key != null) {
			k = key + "|" + q(__cx[0]) + "," + q(__cx[1]) + "," + q(__cx[2]) + "," + Math.round(__cx[4]) + "," + Math.round(__cx[5]) + ","
				+ Math.round(__cx[6]) + (withAlpha ? "," + q(__cx[3]) + "," + Math.round(__cx[7]) : "");
			var c = tintCache.get(k);
			if (c != null)
				return c;
		}
		var c = Browser.document.createCanvasElement();
		c.width = sw > 0 ? sw : 1;
		c.height = sh > 0 ? sh : 1;
		var g = c.getContext2d();
		if (sw > 0 && sh > 0) {
			g.drawImage(src, sx, sy, sw, sh, 0, 0, sw, sh);
			var d = g.getImageData(0, 0, sw, sh);
			var p = d.data;
			var ra = __cx[0], ga = __cx[1], ba = __cx[2], rb = __cx[4], gb = __cx[5], bb = __cx[6];
			var aa = withAlpha ? __cx[3] : 1.0, ab = withAlpha ? __cx[7] : 0.0;
			var i = 0, n = p.length;
			while (i < n) {
				if (p[i + 3] != 0) {
					p[i] = clamp(p[i] * ra + rb);
					p[i + 1] = clamp(p[i + 1] * ga + gb);
					p[i + 2] = clamp(p[i + 2] * ba + bb);
					if (withAlpha)
						p[i + 3] = clamp(p[i + 3] * aa + ab);
				}
				i += 4;
			}
			g.putImageData(d, 0, 0);
		}
		if (k != null) {
			if (tintCount >= 1500) {
				tintCache.clear();
				tintCount = 0;
			}
			tintCache.set(k, c);
			tintCount++;
		}
		return c;
	}
}

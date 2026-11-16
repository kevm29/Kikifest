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

	/** Compteurs pour le rapport de débogage du jeu : images recolorées créées, calques utilisés. **/
	public static var statTints = 0;

	public static var statLayers = 0;

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
				var layer = acquireLayer(canvas.width, canvas.height);
				var lg = layer.getContext2d();
				lg.setTransform(1, 0, 0, 1, 0, 0);
				lg.globalCompositeOperation = "source-over";
				lg.globalAlpha = 1;
				lg.clearRect(0, 0, canvas.width, canvas.height);
				var inner = __cx.copy();
				var alpha = inner[3];
				inner[3] = 1;
				drawChildren(lg, (cast o : MovieClip), m, inner, null);
				g.setTransform(1, 0, 0, 1, 0, 0);
				g.globalAlpha = Math.max(0, Math.min(1, alpha));
				g.globalCompositeOperation = op != null ? op : "source-over";
				g.drawImage(layer, 0, 0, canvas.width, canvas.height, 0, 0, canvas.width, canvas.height);
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
				// masque rectangulaire (cadre de l'aire de jeu, fenêtres du décor…) : simple découpe, sans calque
				var rm = rectMask(c, m);
				if (rm != null) {
					g.save();
					g.setTransform(rm[0], rm[1], rm[2], rm[3], rm[4], rm[5]);
					g.beginPath();
					g.rect(rm[6], rm[7], rm[8] - rm[6], rm[9] - rm[7]);
					g.clip();
					for (mo in masked)
						drawObject(g, mo, m, __cx, op);
					g.restore();
					i = j;
					continue;
				}
				// calques limités à l'emprise du masque (avant : deux calques de la taille de l'écran à
				// chaque masque, ce qui faisait ramer Firefox, par exemple aux animations du joueur)
				var gc:CanvasElement = cast g.canvas;
				var x0 = 0, y0 = 0, x1 = gc.width, y1 = gc.height;
				var lb = c._visible ? c.__localBounds() : null;
				if (lb != null) {
					var r = Rect.transform(lb, mul(m, c));
					x0 = Std.int(Math.max(0, Math.floor(r.xMin) - 2));
					y0 = Std.int(Math.max(0, Math.floor(r.yMin) - 2));
					x1 = Std.int(Math.min(gc.width, Math.ceil(r.xMax) + 2));
					y1 = Std.int(Math.min(gc.height, Math.ceil(r.yMax) + 2));
				}
				// et à l'emprise de ce qui est masqué (au village, le grand masque du puits ne cache
				// que le seau et la corde : inutile de recomposer tout l'écran)
				var mr:Rect = null;
				var unknown = false;
				for (mo in masked) {
					if (!mo._visible)
						continue;
					var ob = mo.__localBounds();
					if (ob == null) {
						if (Std.isOfType(mo, MovieClip))
							continue; // clip vide
						unknown = true;
						break;
					}
					var tr = Rect.transform(ob, mul(m, mo));
					mr = mr == null ? tr : Rect.union(mr, tr);
				}
				if (!unknown) {
					if (mr == null) {
						i = j;
						continue;
					}
					x0 = Std.int(Math.max(x0, Math.floor(mr.xMin) - 2));
					y0 = Std.int(Math.max(y0, Math.floor(mr.yMin) - 2));
					x1 = Std.int(Math.min(x1, Math.ceil(mr.xMax) + 2));
					y1 = Std.int(Math.min(y1, Math.ceil(mr.yMax) + 2));
				}
				var w = x1 - x0, h = y1 - y0;
				if (!c._visible || w <= 0 || h <= 0) {
					// masque vide ou hors de l'écran : rien de ce qu'il masque n'est visible
					i = j;
					continue;
				}
				var lm = m.copy();
				lm[4] -= x0;
				lm[5] -= y0;
				// masque et contenu immobiles (grand masque du puits au village) : on réutilise l'image
				// composée à l'image précédente au lieu de tout recomposer 40 fois par seconde
				var sig = maskSignature(c, masked, lm, __cx, w, h);
				var cached:Dynamic = sig != null ? maskCache.get(c) : null;
				if (cached != null && cached.sig == sig) {
					g.setTransform(1, 0, 0, 1, 0, 0);
					g.globalAlpha = 1;
					g.globalCompositeOperation = op != null ? op : "source-over";
					g.drawImage(cached.canvas, 0, 0, w, h, x0, y0, w, h);
					i = j;
					continue;
				}
				var layer = acquireLayer(w, h);
				var lg = layer.getContext2d();
				lg.setTransform(1, 0, 0, 1, 0, 0);
				lg.globalCompositeOperation = "source-over";
				lg.globalAlpha = 1;
				lg.clearRect(0, 0, w, h);
				for (mo in masked)
					drawObject(lg, mo, lm, __cx, null);
				// le masque est d'abord dessiné normalement dans son propre calque, puis appliqué d'un coup
				// sur toute la surface : certains navigateurs (Firefox) ne composent "destination-in"
				// que dans l'emprise de l'image dessinée, ce qui laissait passer tout le reste
				var maskLayer = acquireLayer(w, h);
				var mg = maskLayer.getContext2d();
				mg.setTransform(1, 0, 0, 1, 0, 0);
				mg.globalCompositeOperation = "source-over";
				mg.globalAlpha = 1;
				mg.clearRect(0, 0, w, h);
				drawObject(mg, c, lm, [1, 1, 1, 1, 0, 0, 0, 0], null);
				layerIndex--;
				lg.setTransform(1, 0, 0, 1, 0, 0);
				lg.globalAlpha = 1;
				lg.globalCompositeOperation = "destination-in";
				lg.drawImage(maskLayer, 0, 0, w, h, 0, 0, w, h);
				lg.globalCompositeOperation = "source-over";
				g.setTransform(1, 0, 0, 1, 0, 0);
				g.globalAlpha = 1;
				g.globalCompositeOperation = op != null ? op : "source-over";
				g.drawImage(layer, 0, 0, w, h, x0, y0, w, h);
				if (sig != null) {
					var keep:CanvasElement = cached != null ? cached.canvas : Browser.document.createCanvasElement();
					if (keep.width != w || keep.height != h) {
						keep.width = w;
						keep.height = h;
					}
					var kg = keep.getContext2d();
					kg.setTransform(1, 0, 0, 1, 0, 0);
					kg.globalCompositeOperation = "copy";
					kg.drawImage(layer, 0, 0, w, h, 0, 0, w, h);
					kg.globalCompositeOperation = "source-over";
					maskCache.set(c, {sig: sig, canvas: keep});
				}
				layerIndex--;
				i = j;
				continue;
			}
			drawObject(g, c, m, __cx, op);
			i++;
		}
	}

	/** Images composées des masques immobiles, par clip masque. **/
	var maskCache:js.lib.WeakMap<Dynamic> = new js.lib.WeakMap();

	/**
		Empreinte de tout ce qui compose un masque et son contenu (graphiques, matrices, couleurs,
		visibilité) : si elle n'a pas changé, l'image composée est la même. null si ce n'est pas
		mémorisable (texte, bitmap, trop d'objets).
	**/
	function maskSignature(c:DisplayObject, masked:Array<DisplayObject>, lm:Array<Float>, cx:Array<Float>, w:Int, h:Int):Null<String> {
		var parts:Array<String> = [w + "x" + h, lm.join(","), cx.join(",")];
		var budget = 200;
		function walk(o:DisplayObject):Bool {
			if (--budget < 0 || Std.isOfType(o, TextField) || Std.isOfType(o, BitmapObject))
				return false;
			parts.push(o.__charId + ":" + (o._visible ? 1 : 0) + ":" + o.__matrix().join(",") + ":" + (o.__cx != null ? o.__cx.join(",") : "") + ":"
				+ o.__blend + ":" + o.__clipDepth + ":" + o.__depth);
			if (Std.isOfType(o, MovieClip)) {
				parts.push("[");
				for (k in (cast o : MovieClip).__children)
					if (!walk(k))
						return false;
				parts.push("]");
			}
			return true;
		}
		if (!walk(c))
			return null;
		parts.push("|");
		for (mo in masked)
			if (!walk(mo))
				return null;
		return parts.join(";");
	}

	/** Graphiques dont l'image est un rectangle plein (vrai/faux), calculé une fois par graphique. **/
	static var rectChars:Map<Int, Bool> = new Map();

	/**
		Si le masque `c` est un rectangle plein (un graphique, ou un clip qui n'en contient qu'un),
		renvoie [matrice a,b,c,d,tx,ty, xMin,yMin,xMax,yMax] pour le découper avec clip() ; sinon null.
	**/
	function rectMask(c:DisplayObject, m:Array<Float>):Null<Array<Float>> {
		if (!c._visible)
			return null;
		var gm = mul(m, c);
		var gr:DisplayObject = c;
		if (Std.isOfType(c, MovieClip)) {
			var only:DisplayObject = null;
			for (k in (cast c : MovieClip).__children)
				if (k._visible) {
					if (only != null)
						return null;
					only = k;
				}
			if (only == null || Std.isOfType(only, MovieClip) || Std.isOfType(only, TextField) || Std.isOfType(only, BitmapObject))
				return null;
			gm = mul(gm, only);
			gr = only;
		} else if (Std.isOfType(c, TextField) || Std.isOfType(c, BitmapObject))
			return null;
		var id = gr.__charId;
		var ch:Dynamic = Library.inst.char(id);
		if (ch == null || ch.b == null || !isRectChar(id))
			return null;
		var b:Array<Float> = ch.b;
		return [gm[0], gm[1], gm[2], gm[3], gm[4], gm[5], b[0], b[1], b[2], b[3]];
	}

	/** Le graphique est-il un rectangle opaque (bords de 1 px tolérés pour l'anticrénelage) ? **/
	static function isRectChar(id:Int):Bool {
		var known = rectChars.get(id);
		if (known != null)
			return known;
		var ok = false;
		try {
			var reg = Library.inst.atlasRegion(id);
			if (reg != null) {
				var w = Std.int(reg[3]), h = Std.int(reg[4]);
				if (w > 0 && h > 0) {
					var t:CanvasElement = Browser.document.createCanvasElement();
					t.width = w;
					t.height = h;
					var tg:CanvasRenderingContext2D = untyped t.getContext("2d", {willReadFrequently: true});
					tg.drawImage(Library.inst.atlasPage(Std.int(reg[0])), reg[1], reg[2], w, h, 0, 0, w, h);
					var d = tg.getImageData(0, 0, w, h).data;
					ok = true;
					var y = 1;
					while (ok && y < h - 1) {
						var x = 1;
						while (x < w - 1) {
							if (d[(y * w + x) * 4 + 3] < 250) {
								ok = false;
								break;
							}
							x++;
						}
						y++;
					}
				}
			}
		} catch (e:Dynamic) {
			return false; // image pas encore prête : on réessaiera
		}
		rectChars.set(id, ok);
		return ok;
	}

	/** Calque de travail d'au moins w × h (les calques ne font que grandir : pas de réallocation à chaque image). **/
	function acquireLayer(w:Int, h:Int):CanvasElement {
		statLayers++;
		var l = layers[layerIndex];
		if (l == null) {
			l = Browser.document.createCanvasElement();
			layers[layerIndex] = l;
		}
		if (l.width < w || l.height < h) {
			l.width = Std.int(Math.max(l.width, w));
			l.height = Std.int(Math.max(l.height, h));
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
		// lu aussitôt (getImageData) : un canevas gardé en mémoire vive évite à Firefox et Chrome
		// de rapatrier l'image depuis la carte graphique, ce qui bloque le dessin plusieurs ms
		var g:CanvasRenderingContext2D = untyped c.getContext("2d", {willReadFrequently: true});
		statTints++;
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

package swf;

import js.Browser;
import js.html.CanvasElement;
import js.html.CanvasRenderingContext2D;

/**
	Rendu Canvas 2D d'une arborescence de MovieClip.
	Les formes sont pré-pixellisées par Library ; les transformations de
	couleur passent par des filtres SVG feColorMatrix (ctx.filter = url(#...)).
**/
class Renderer {
	public var canvas:CanvasElement;
	public var ctx:CanvasRenderingContext2D;
	public var scale:Float = 1;
	public var background:String = "#000";

	var layers:Array<CanvasElement> = [];
	var layerIndex = 0;
	var svgDefs:js.html.Element;
	var filterIds:Map<String, String> = new Map();
	var filterCount = 0;

	static var IDENT:Array<Float> = [1, 1, 1, 1, 0, 0, 0, 0];

	public function new(canvas:CanvasElement) {
		this.canvas = canvas;
		this.ctx = canvas.getContext2d();
		var svg = Browser.document.createElementNS("http://www.w3.org/2000/svg", "svg");
		svg.setAttribute("width", "0");
		svg.setAttribute("height", "0");
		svg.setAttribute("style", "position:absolute;width:0;height:0");
		svgDefs = Browser.document.createElementNS("http://www.w3.org/2000/svg", "defs");
		svg.appendChild(svgDefs);
		Browser.document.body.appendChild(svg);
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
		var a = o.ma(), b = o.mb(), c = o.mc(), d = o.md(), tx = o.mtx(), ty = o.mty();
		return [
			p[0] * a + p[2] * b,
			p[1] * a + p[3] * b,
			p[0] * c + p[2] * d,
			p[1] * c + p[3] * d,
			p[0] * tx + p[2] * ty + p[4],
			p[1] * tx + p[3] * ty + p[5]
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

	static function compositeOp(blend:String):Null<String> {
		return switch (blend) {
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
		var m = o._parent == null && Std.isOfType(o, MovieClip) && (cast o : MovieClip).isRoot ? mulRoot(pm, o) : mul(pm, o);
		var cx = concatCx(pcx, o.cx);
		if (cx[3] <= 0 && cx[7] <= 0)
			return;
		if (o.blend != null) {
			var c = compositeOp(o.blend);
			if (c != null)
				op = c;
		}
		if (Std.isOfType(o, MovieClip)) {
			drawChildren(g, (cast o : MovieClip), m, cx, op);
			return;
		}
		if (Std.isOfType(o, TextField)) {
			drawText(g, cast o, m, cx, op);
			return;
		}
		drawGraphic(g, o.charId, m, cx, op);
	}

	inline function mulRoot(pm:Array<Float>, o:DisplayObject) return mul(pm, o);

	function drawChildren(g:CanvasRenderingContext2D, mc:MovieClip, m:Array<Float>, cx:Array<Float>, op:Null<String>) {
		var ch = mc.children;
		var i = 0;
		while (i < ch.length) {
			var c = ch[i];
			if (c.clipDepth != 0) {
				// masque : les objets suivants jusqu'à clipDepth sont dessinés dans un calque
				var masked = [];
				var j = i + 1;
				while (j < ch.length && ch[j].depth <= c.clipDepth) {
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
					drawObject(lg, mo, m, cx, null);
				lg.globalCompositeOperation = "destination-in";
				drawObject(lg, c, m, [1, 1, 1, 1, 0, 0, 0, 0], "destination-in");
				g.setTransform(1, 0, 0, 1, 0, 0);
				g.globalAlpha = 1;
				g.globalCompositeOperation = op != null ? op : "source-over";
				g.drawImage(layer, 0, 0);
				layerIndex--;
				i = j;
				continue;
			}
			drawObject(g, c, m, cx, op);
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

	function drawGraphic(g:CanvasRenderingContext2D, id:Int, m:Array<Float>, cx:Array<Float>, op:Null<String>) {
		var ch:Dynamic = Library.inst.char(id);
		if (ch == null || ch.b == null)
			return;
		var s = Math.sqrt(Math.abs(m[0] * m[3] - m[1] * m[2]));
		var img = Library.inst.rasterized(id, s);
		if (img == null)
			return;
		var b:Array<Float> = ch.b;
		g.setTransform(m[0], m[1], m[2], m[3], m[4], m[5]);
		g.globalCompositeOperation = op != null ? op : "source-over";
		applyColor(g, cx);
		g.drawImage(img, b[0], b[1], b[2] - b[0], b[3] - b[1]);
		g.filter = "none";
		g.globalAlpha = 1;
	}

	function drawText(g:CanvasRenderingContext2D, t:TextField, m:Array<Float>, cx:Array<Float>, op:Null<String>) {
		var d:Dynamic = t.def;
		if (d == null)
			return;
		var b:Array<Float> = d.b;
		var size:Float = d.size != null ? d.size : 12;
		var font:Dynamic = d.font != null ? Library.inst.char(d.font) : null;
		var name = font != null && font.name != null ? font.name : "Verdana";
		g.setTransform(m[0], m[1], m[2], m[3], m[4], m[5]);
		g.globalCompositeOperation = op != null ? op : "source-over";
		var col = t.textColor;
		var r = clamp(((col >> 16) & 255) * cx[0] + cx[4]);
		var gg = clamp(((col >> 8) & 255) * cx[1] + cx[5]);
		var bb = clamp((col & 255) * cx[2] + cx[6]);
		g.globalAlpha = Math.max(0, Math.min(1, cx[3] + cx[7] / 255));
		g.fillStyle = 'rgb($r,$gg,$bb)';
		g.font = (font != null && font.bold ? "bold " : "") + size + "px " + name + ", Verdana, sans-serif";
		g.textBaseline = "top";
		var align:Int = d.align != null ? d.align : 0;
		var x = b[0] + 2;
		if (align == 1) {
			g.textAlign = "right";
			x = b[2] - 2;
		} else if (align == 2) {
			g.textAlign = "center";
			x = (b[0] + b[2]) / 2;
		} else
			g.textAlign = "left";
		var lines = t.plainText().split("\n");
		var y = b[1] + 2;
		var leading:Float = d.leading != null ? d.leading : 0;
		for (l in lines) {
			g.fillText(l, x, y);
			y += size + leading + 2;
		}
		g.globalAlpha = 1;
	}

	static inline function clamp(v:Float):Int return Std.int(Math.max(0, Math.min(255, v)));

	function applyColor(g:CanvasRenderingContext2D, cx:Array<Float>) {
		var tinted = cx[0] != 1 || cx[1] != 1 || cx[2] != 1 || cx[4] != 0 || cx[5] != 0 || cx[6] != 0 || cx[7] != 0;
		if (!tinted) {
			g.globalAlpha = Math.max(0, Math.min(1, cx[3]));
			return;
		}
		g.globalAlpha = 1;
		g.filter = "url(#" + colorFilter(cx) + ")";
	}

	function colorFilter(cx:Array<Float>):String {
		var key = [for (v in cx) Math.round(v * 1000) / 1000].join(",");
		var id = filterIds.get(key);
		if (id != null)
			return id;
		id = "kcx" + (filterCount++);
		var ns = "http://www.w3.org/2000/svg";
		var f = Browser.document.createElementNS(ns, "filter");
		f.setAttribute("id", id);
		f.setAttribute("color-interpolation-filters", "sRGB");
		var cm = Browser.document.createElementNS(ns, "feColorMatrix");
		cm.setAttribute("type", "matrix");
		cm.setAttribute("values", [
			cx[0], 0, 0, 0, cx[4] / 255,
			0, cx[1], 0, 0, cx[5] / 255,
			0, 0, cx[2], 0, cx[6] / 255,
			0, 0, 0, cx[3], cx[7] / 255
		].join(" "));
		f.appendChild(cm);
		svgDefs.appendChild(f);
		filterIds.set(key, id);
		return id;
	}
}

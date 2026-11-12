package swf;

/** Champ texte dynamique (DefineEditText), rendu avec fillText. */
class TextField extends DisplayObject {
	public var text:String = "";
	public var html:Bool = false;
	public var htmlText(get, set):String;
	public var textColor:Int = 0;
	public var __def:Dynamic;
	public var __w:Float = 100;
	public var __h:Float = 20;
	public var autoSize:Dynamic = "none";
	public var embedFonts:Bool = false;
	public var selectable:Bool = false;
	public var wordWrap:Bool = false;
	public var multiline:Bool = false;
	public var border:Bool = false;
	public var background:Bool = false;
	public var type:String = "dynamic";
	public var maxChars:Int = 0;
	public var variable:String = null;
	public var format:Dynamic = {};
	public var textWidth(get, never):Float;
	public var textHeight(get, never):Float;
	public var length(get, never):Int;

	static function __init__() {
		DisplayObject.__exposeProps(TextField, ["htmlText", "textWidth", "textHeight", "length"]);
	}

	public function new(__charId:Int) {
		super(__charId);
		__def = Library.inst.char(__charId);
		if (__def != null) {
			text = __def.text != null ? __def.text : "";
			if (__def.variable != null)
				variable = __def.variable;
			html = __def.html == true;
			wordWrap = __def.wordWrap == true;
			multiline = __def.multiline == true;
			if (__def.color != null) {
				var c:Array<Int> = __def.color;
				textColor = (c[0] << 16) | (c[1] << 8) | c[2];
			}
		}
	}

	function get_textWidth():Float {
		var w = 0.0;
		for (l in __layout().lines)
			if (l.w > w)
				w = l.w;
		return w;
	}

	function get_textHeight():Float {
		var n = __layout().lines.length;
		return n == 0 ? 0 : n * lineHeight() - leading();
	}

	public function leading():Float return __def != null && __def.leading != null ? __def.leading : 0;

	public function lineHeight():Float return fontSize() + leading() + 2;

	/** Police CSS du champ (police du SWF si connue, sinon Verdana). */
	public function fontCss():String {
		var font:Dynamic = __def != null && __def.font != null ? Library.inst.char(__def.font) : (format.font != null ? {name: format.font, bold: format.bold} : null);
		var name = font != null && font.name != null ? font.name : "Verdana";
		return (font != null && font.bold ? "bold " : "") + fontSize() + "px " + name + ", Verdana, sans-serif";
	}

	static var measureCtx:js.html.CanvasRenderingContext2D;
	var __layoutKey:String;
	var __layoutCache:Dynamic;

	/**
		Mise en page : découpe en lignes (retours à la ligne, et coupure des mots à la largeur du
		champ si wordWrap), chaque ligne étant une suite de morceaux colorés (<font color> en HTML).
	**/
	public function __layout():{lines:Array<{w:Float, runs:Array<{t:String, c:Null<Int>}>}>} {
		var lb = __localBounds();
		var width = lb.xMax - lb.xMin - 4;
		var font = fontCss();
		var key = text + "|" + font + "|" + width + "|" + wordWrap + "|" + html;
		if (key == __layoutKey)
			return __layoutCache;
		if (measureCtx == null)
			measureCtx = js.Browser.document.createCanvasElement().getContext2d();
		var g = measureCtx;
		g.font = font;
		// morceaux : {t, c} avec "\n" pour les retours à la ligne
		var pieces:Array<{t:String, c:Null<Int>}> = [];
		var t = text == null ? "" : text;
		if (html || t.indexOf("<") >= 0) {
			var colors:Array<Null<Int>> = [null];
			var re = ~/<[^>]*>|[^<]+/g;
			var pos = 0;
			while (re.matchSub(t, pos)) {
				var m = re.matched(0);
				var mp = re.matchedPos();
				pos = mp.pos + mp.len;
				if (m.charAt(0) == "<") {
					var tag = m.toLowerCase();
					if (~/^<br/.match(tag) || tag == "</p>")
						pieces.push({t: "\n", c: null});
					else if (StringTools.startsWith(tag, "<font")) {
						var cm = ~/color\s*=\s*["']?#([0-9a-f]{6})/i;
						colors.push(cm.match(m) ? Std.parseInt("0x" + cm.matched(1)) : colors[colors.length - 1]);
					} else if (tag == "</font>" && colors.length > 1)
						colors.pop();
				} else
					pieces.push({t: StringTools.htmlUnescape(m), c: colors[colors.length - 1]});
			}
			if (pieces.length > 0 && pieces[pieces.length - 1].t == "\n")
				pieces.pop();
		} else
			pieces.push({t: t, c: null});
		var lines:Array<{w:Float, runs:Array<{t:String, c:Null<Int>}>}> = [];
		var cur = {w: 0.0, runs: []};
		lines.push(cur);
		function add(word:String, c:Null<Int>) {
			var w = g.measureText(word).width;
			if (wordWrap && width > 0 && cur.w > 0 && cur.w + w > width && StringTools.trim(word) != "") {
				// supprime l'espace final de la ligne coupée
				var last = cur.runs[cur.runs.length - 1];
				if (last != null && StringTools.endsWith(last.t, " ")) {
					last.t = last.t.substr(0, last.t.length - 1);
					cur.w -= g.measureText(" ").width;
				}
				cur = {w: 0.0, runs: []};
				lines.push(cur);
				if (StringTools.trim(word) == "")
					return;
			}
			var last = cur.runs[cur.runs.length - 1];
			if (last != null && last.c == c)
				last.t += word;
			else
				cur.runs.push({t: word, c: c});
			cur.w += w;
		}
		for (p in pieces) {
			if (p.t == "\n") {
				cur = {w: 0.0, runs: []};
				lines.push(cur);
				continue;
			}
			var parts = p.t.split("\n");
			for (i in 0...parts.length) {
				if (i > 0) {
					cur = {w: 0.0, runs: []};
					lines.push(cur);
				}
				// mots avec leur espace final
				var wr = ~/[^ ]+ *| +/g;
				var q = 0;
				var str = parts[i];
				while (q < str.length && wr.matchSub(str, q)) {
					var mp = wr.matchedPos();
					add(wr.matched(0), p.c);
					q = mp.pos + mp.len;
				}
			}
		}
		__layoutKey = key;
		__layoutCache = {lines: lines};
		return __layoutCache;
	}

	function get_length():Int return text == null ? 0 : text.length;

	public function fontSize():Float {
		if (format.size != null)
			return format.size;
		return __def != null && __def.size != null ? __def.size : 12;
	}

	public function setNewTextFormat(f:Dynamic) mergeFormat(f);

	public function setTextFormat(?a:Dynamic, ?b:Dynamic, ?c:Dynamic) {
		var f = c != null ? c : (b != null ? b : a);
		if (f != null && !Std.isOfType(f, Int))
			mergeFormat(f);
	}

	function mergeFormat(f:Dynamic) {
		for (k in Reflect.fields(f))
			if (Reflect.field(f, k) != null)
				Reflect.setField(format, k, Reflect.field(f, k));
		if (f.color != null)
			textColor = f.color;
	}

	public function getTextFormat():Dynamic return format;

	public function getNewTextFormat():Dynamic return format;

	override public function __localBounds():Null<Rect> {
		if (__def != null && __def.b != null) {
			var b:Array<Float> = __def.b;
			return new Rect(b[0], b[1], b[2], b[3]);
		}
		return new Rect(0, 0, __w, __h);
	}

	function get_htmlText() return text;

	function set_htmlText(v:String) {
		return text = v;
	}

	/** Texte affichable : on retire les balises HTML. */
	public function __plainText():String {
		var t = text == null ? "" : text;
		if (html || t.indexOf("<") >= 0) {
			t = ~/<br\s*\/?>/gi.replace(t, "\n");
			t = ~/<\/p>/gi.replace(t, "\n");
			t = ~/<[^>]*>/g.replace(t, "");
			t = StringTools.htmlUnescape(t);
		}
		return t;
	}

	/** Champ lié à une variable (ex. "_parent.label") : affiche sa valeur, comme Flash. */
	override public function __advance(queue:Array<Void->Void>) {
		if (variable == null || _parent == null)
			return;
		var parts = variable.split(".");
		var o:Dynamic = _parent;
		for (i in 0...parts.length - 1) {
			var p = parts[i];
			o = p == "_root" ? swf.FrameScripts.MtStdRoot.root : Reflect.field(o, p);
			if (o == null)
				return;
		}
		var v:Dynamic = Reflect.field(o, parts[parts.length - 1]);
		if (v != null)
			text = Std.string(v);
	}
}

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
			html = __def.html == true;
			if (__def.color != null) {
				var c:Array<Int> = __def.color;
				textColor = (c[0] << 16) | (c[1] << 8) | c[2];
			}
		}
	}

	function get_textWidth():Float return (text == null ? 0 : text.length) * fontSize() * 0.6;

	function get_textHeight():Float return fontSize() * 1.2;

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
}

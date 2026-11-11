package swf;

/** Champ texte dynamique (DefineEditText), rendu avec fillText. */
class TextField extends DisplayObject {
	public var text:String = "";
	public var html:Bool = false;
	public var htmlText(get, set):String;
	public var textColor:Int = 0;
	public var def:Dynamic;

	public function new(charId:Int) {
		super(charId);
		def = Library.inst.char(charId);
		if (def != null) {
			text = def.text != null ? def.text : "";
			html = def.html == true;
			if (def.color != null) {
				var c:Array<Int> = def.color;
				textColor = (c[0] << 16) | (c[1] << 8) | c[2];
			}
		}
	}

	function get_htmlText() return text;

	function set_htmlText(v:String) {
		return text = v;
	}

	/** Texte affichable : on retire les balises HTML. */
	public function plainText():String {
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

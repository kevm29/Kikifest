package mtlib;

class MtXmlNode {
	public var firstChild:MtXmlNode;
	public var lastChild:MtXmlNode;
	public var nextSibling:MtXmlNode;
	public var previousSibling:MtXmlNode;
	public var parentNode:MtXmlNode;
	public var nodeValue:String;
	public var nodeName:String;
	public var nodeType:Int;
	public var attributes:Dynamic = {};

	public function new(type:Int, nameOrValue:String) {
		nodeType = type;
		if (type == 1) nodeName = nameOrValue else nodeValue = nameOrValue;
	}

	public static function fromDom(n:js.html.Node, ignoreWhite:Bool):MtXmlNode {
		if (n.nodeType == js.html.Node.TEXT_NODE || n.nodeType == js.html.Node.CDATA_SECTION_NODE) {
			if (ignoreWhite && StringTools.trim(n.nodeValue) == "")
				return null;
			return new MtXmlNode(3, n.nodeValue);
		}
		if (n.nodeType != js.html.Node.ELEMENT_NODE)
			return null;
		var e:js.html.Element = cast n;
		var x = new MtXmlNode(1, unescapeName(e.nodeName));
		for (i in 0...e.attributes.length) {
			var a = e.attributes.item(i);
			Reflect.setField(x.attributes, unescapeName(a.name), a.value);
		}
		var c = e.firstChild;
		while (c != null) {
			var cx = fromDom(c, ignoreWhite);
			if (cx != null)
				x.appendChild(cx);
			c = c.nextSibling;
		}
		return x;
	}

	static inline function unescapeName(n:String):String {
		return StringTools.startsWith(n, "_xD_") ? "$" + n.substr(4) : n;
	}

	public function get(att:String):String return Reflect.field(attributes, att);

	public function set(att:String, v:String):Void Reflect.setField(attributes, att, v);

	public function exists(att:String):Bool return Reflect.hasField(attributes, att);

	public function attributesIter(f:String->String->Void) {
		for (k in Reflect.fields(attributes)) f(k, Reflect.field(attributes, k));
	}

	public function childrenIter(f:MtXmlNode->Void) {
		var c = firstChild;
		while (c != null) {
			var n = c.nextSibling;
			f(c);
			c = n;
		}
	}

	public function appendChild(c:MtXmlNode) {
		if (c == null) return;
		c.removeNode();
		c.parentNode = this;
		c.previousSibling = lastChild;
		if (lastChild == null) firstChild = c else lastChild.nextSibling = c;
		lastChild = c;
	}

	/** Détache le nœud de son parent (Flash : XMLNode.removeNode). */
	public function removeNode() {
		var p = parentNode;
		if (p == null) return;
		if (previousSibling != null) previousSibling.nextSibling = nextSibling else p.firstChild = nextSibling;
		if (nextSibling != null) nextSibling.previousSibling = previousSibling else p.lastChild = previousSibling;
		parentNode = null;
		previousSibling = null;
		nextSibling = null;
	}

	public function hasChildNodes():Bool return firstChild != null;

	function childrenString():String {
		var b = new StringBuf();
		var c = firstChild;
		while (c != null) {
			b.add(c.toString());
			c = c.nextSibling;
		}
		return b.toString();
	}

	static function esc(v:String):String
		return StringTools.replace(StringTools.replace(StringTools.replace(StringTools.replace(v, "&", "&amp;"), "<", "&lt;"), ">", "&gt;"), '"', "&quot;");

	public function toString():String {
		if (nodeType != 1) return nodeValue == null ? "" : esc(nodeValue);
		if (nodeName == null) return childrenString();
		var b = new StringBuf();
		b.add("<" + nodeName);
		for (k in Reflect.fields(attributes)) b.add(" " + k + '="' + esc(Std.string(Reflect.field(attributes, k))) + '"');
		if (firstChild == null) {
			b.add(" />");
		} else {
			b.add(">");
			b.add(childrenString());
			b.add("</" + nodeName + ">");
		}
		return b.toString();
	}
}

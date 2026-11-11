package mtlib;

/** XML façon Flash 7 (firstChild/nextSibling/get), construit avec DOMParser. */
class MtXml extends MtXmlNode {
	public var ignoreWhite:Bool = false;

	public function new(?src:String) {
		super(1, null);
		if (src != null)
			parseXML(src);
	}

	public function parseXML(s:String) {
		// retire BOM et déclarations <?xml ?> (le contenu est enveloppé dans une racine)
		s = ~/^\uFEFF/.replace(s, "");
		s = ~/<\?xml[^?]*\?>/g.replace(s, "");
		// le parseur Flash ignorait les commentaires, même mal formés (<!-- a -- b -->)
		s = ~/<!--[\s\S]*?-->/g.replace(s, "");
		// Flash acceptait des noms commençant par $ (<$e x="1" $a="2">) : interdits en XML
		s = ~/(<\/?)\$/g.replace(s, "$1_xD_");
		s = ~/(\s)\$([A-Za-z_][\w]*\s*=)/g.replace(s, "$1_xD_$2");
		var doc = new js.html.DOMParser().parseFromString("<__root>" + s + "</__root>", APPLICATION_XML);
		if (doc.getElementsByTagName("parsererror").length > 0)
			js.Browser.console.warn("XML invalide : " + doc.getElementsByTagName("parsererror")[0].textContent);
		var r = doc.documentElement;
		firstChild = lastChild = null;
		var n = r.firstChild;
		while (n != null) {
			var c = MtXmlNode.fromDom(n, ignoreWhite);
			if (c != null)
				appendChild(c);
			n = n.nextSibling;
		}
	}
}


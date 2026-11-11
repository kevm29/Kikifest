// Converti automatiquement depuis hammer/Lang.mt (Motion Twin)
package;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
class Lang {

	public static var strList		= [];
	public static var itemNames	= [];
	public static var familyNames	= [];
	public static var questNames	= [];
	public static var questDesc	= [];
	public static var levelNames	= [];
	public static var keyNames		= [];
	public static var lang:String			= "ERR ";
	public static var fl_debug:Bool		= false;
	public static var doc			: MtXmlNode;

	/*------------------------------------------------------------------------
	INITIALISATION
	------------------------------------------------------------------------*/
	public static function init(raw:String)  untyped {
		var docXml:Dynamic = new MtXml(raw);
//		doc = new Xml( raw ).firstChild;
		{ if (docXml != null) docXml.ignoreWhite = true; }
		docXml?.parseXML( raw );
		doc = docXml?.firstChild;

		lang		= doc?.get("$id".substring(1));
		fl_debug	= doc?.get("$debug".substring(1))=="1";
		strList		= new Array();


		strList		= _getStringData("$statics","$v");
		itemNames	= _getStringData("$items","$name");
		familyNames	= _getStringData("$families","$name");
		questNames	= _getStringData("$quests","$title");
		keyNames	= _getStringData("$keys","$name");
//		levelNames	= _getStringData("$levels","$name");

		// Quest descriptions
		var node:Dynamic = _find( doc, "$quests".substring(1) );
		while ( node!=null ) {
			var id:Dynamic	= MtStd.parseInt( node?.get("$id".substring(1)), 10 );
			questDesc[id] = Data.cleanString( node?.firstChild?.nodeValue );
			node = node?.nextSibling;
		}

		// Level names
		node = _find( doc, "$dimensions".substring(1) );
		while ( node!=null ) {
			var did:Dynamic	= MtStd.parseInt( node?.get("$id".substring(1)), 10 );
			levelNames[did] = new Array();
			var child:Dynamic = node?.firstChild;
			while (child!=null) {
				var lid:Dynamic = MtStd.parseInt( child?.get("$id".substring(1)), 10 );
				levelNames[did][lid] = child?.get("$name".substring(1));
				child = child?.nextSibling;
			}
			node = node?.nextSibling;
		}

	}


	/*------------------------------------------------------------------------
	RENVOIE LA LISTE DE STRINGS DEMAND�E DEPUIS LE XML LANG
	------------------------------------------------------------------------*/
	public static function _getStringData( parentNode:String, attrName:String )  untyped {
		var tab:Dynamic = new Array();
		var node:Dynamic = _find( doc, parentNode?.substring(1) );
		while ( node!=null ) {
			var id:Dynamic	= MtStd.parseInt( node?.get("$id".substring(1)), 10 );
			var txt:Dynamic	= node?.get(attrName?.substring(1));
			if ( fl_debug ) {
				txt= "["+lang?.toLowerCase()+"]"+txt;
			}
			tab[id] = txt;
			node = node?.nextSibling;
		}
		return tab;
	}


	/*------------------------------------------------------------------------
	RENVOIE LE CONTENU D'UNE NODE INDIQU�E
	------------------------------------------------------------------------*/
	public static function _find(doc:MtXmlNode, name:String) : MtXmlNode  untyped {
		var node:Dynamic = doc?.firstChild;
		while ( node?.nodeName!=name ) {
			node = node?.nextSibling;
			if ( node==null ) {
				GameManager.fatal("node '"+name+"' not found !");
				return null;
			}
		}
		return node?.firstChild;
	}



	/*------------------------------------------------------------------------
	RENVOIE UNE STRING LOCALIS�E
	------------------------------------------------------------------------*/
	public static function get(id:Dynamic)  untyped {
		if ( fl_debug ) {
			return "["+lang?.toLowerCase()+"]"+strList[id];
		}
		else {
			return strList[id];
		}

	}

	/*------------------------------------------------------------------------
	RENVOIE UN NOM D'ITEM
	------------------------------------------------------------------------*/
	public static function getItemName(id:Dynamic)  untyped {
		if ( itemNames[id]==null ) {
//			GameManager.warning("name not found for item #"+id);
		}
		if ( fl_debug ) {
			return "["+lang?.toLowerCase()+"]"+itemNames[id];
		}
		else {
			return itemNames[id];
		}
	}


	/*------------------------------------------------------------------------
	GETTERS
	------------------------------------------------------------------------*/
	public static function getFamilyName(id:Dynamic)  untyped {
		return familyNames[id];
	}

	public static function getQuestName(id:Dynamic)  untyped {
		return questNames[id];
	}

	public static function getQuestDesc(id:Dynamic)  untyped {
		return questDesc[id];
	}

	public static function getLevelName(did:Dynamic,lid:Dynamic)  untyped {
		return MtStd.ix(levelNames[did], lid);
	}


	public static function getSectorName(did:Dynamic,lid:Dynamic)  untyped {
		var n:Dynamic = getLevelName(did,lid);
		while (lid>0 && n==null) {
			lid--;
			n = getLevelName(did,lid);
		}
		if ( n==null ) {
			n = "";
		}
		return n;
	}

	public static function getKeyName(kid:Dynamic)  untyped {
		return keyNames[kid];
	}
}

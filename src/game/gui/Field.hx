// Converti automatiquement depuis hammer/gui/Field.mt (Motion Twin)
package gui;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
import Data as RootData;
class Field extends gui.Item
{
	// (déjà déclaré dans la classe parente) public var field : TextField;
	public var bg : MovieClip;

	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new()  untyped {
		super();
		{ if (field != null) field.text=""; }
	}

	public function initField(c:Dynamic)  untyped {
		setWidth(50);
		scale(1);
		init( c, getField() );
	}

	public function setWidth(w:Dynamic)  untyped {
		{ if (field != null) field._width = w; }
		{ if (bg != null) bg._width = w+5; }
		width = w+10;
	}


	/*------------------------------------------------------------------------
	ATTACHEMENT
	------------------------------------------------------------------------*/
	public static function attach(c:gui.Container)  untyped {
		var mc : gui.Field = (( c?.depthMan?.attach("hammer_editor_field", RootData.DP_INTERF) ):Dynamic) ;
		mc?.initField(c);
		return mc;
	}


	/*------------------------------------------------------------------------
	AFFECTATION / LECTURE
	------------------------------------------------------------------------*/
	public function setField(s:String)  untyped {
		{ if (field != null) field.text = s; }
	}

	public function getField()  untyped {
		return field?.text;
	}

	override public function setLabel(s:Dynamic)  untyped {
		setField(s);
	}
}
// Converti automatiquement depuis hammer/gui/Label.mt (Motion Twin)
package gui;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
import Data as RootData;
class Label extends gui.Item
{

	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new()  untyped {
		super();
	}

	/*------------------------------------------------------------------------
	ATTACHEMENT
	------------------------------------------------------------------------*/
	public static function attach(c:gui.Container, l:String)  untyped {
		var b : gui.Label = (( c?.depthMan?.attach("hammer_editor_label", RootData.DP_INTERF) ):Dynamic);
		b?.init(c,l);
		return b;
	}
}
// Converti automatiquement depuis hammer/gui/Item.mt (Motion Twin)
package gui;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
import Data as RootData;
class Item extends MovieClip
{
	public var field : TextField ;
	public var container : gui.Container ;

	public var width : Float ;


	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new()  untyped { super();
	}

	/*------------------------------------------------------------------------
	DÉFINI LE LABEL
	------------------------------------------------------------------------*/
	public function setLabel(l:Dynamic)  untyped {
		{ if (field != null) field.text = l ; }
		width = field?.textWidth+5 ;
	}

	/*------------------------------------------------------------------------
	RESIZE
	------------------------------------------------------------------------*/
	public function scale(ratio:Dynamic)  untyped {
		_xscale = ratio*100;
		_yscale = _xscale;
	}


	/*------------------------------------------------------------------------
	INITIALISATION
	------------------------------------------------------------------------*/
	public function init(c:gui.Container, l:String)  untyped {
//		tabEnabled = false;
//		tabChildren = false;
		container = c ;
		setLabel(l) ;
		var p:Dynamic = container?.insert(((this):Dynamic)) ;
		_x = p?.x ;
		_y = p?.y ;
	}


	public function update()  untyped {
	}

}
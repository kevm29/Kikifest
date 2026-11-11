// Converti automatiquement depuis hammer/gui/ExtendBox.mt (Motion Twin)
package gui;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
import Data as RootData;
class ExtendBox
{
	public var game: mode.GameMode;
	public var list : Array< Dynamic >;
	public var x : Float;
	public var y : Float;

	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new(g:Dynamic)  untyped {
		game = g;
		list = new Array();
		x = RootData.DOC_WIDTH-20;
		y = 250;
	}


	/*------------------------------------------------------------------------
	AJOUTE UNE LETTRE
	------------------------------------------------------------------------*/
	public function collect(id:Dynamic)  untyped {
		var mc : Dynamic;
		mc = ((game?.depthMan?.attach("hammer_interf_extend", RootData.DP_INTERF)):Dynamic);
		mc?.letter?.gotoAndStop( Std.string(id+1) );
		{ if (mc != null) mc._x = x; }
		{ if (mc != null) mc._y = y+id*16; }
		{ if (mc != null) mc._xscale = 75; }
		{ if (mc != null) mc._yscale = mc?._xscale; }
		list?.push(mc);
	}


	/*------------------------------------------------------------------------
	DESTRUCTION
	------------------------------------------------------------------------*/
	public function clear()  untyped {
		{ var i:Dynamic=0; while (i<list?.length) {
			list[i]?.removeMovieClip();
		
i++; } }
		list = new Array();
	}

}

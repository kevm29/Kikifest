// Converti automatiquement depuis hammer/gui/Container.mt (Motion Twin)
package gui;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
import Data as RootData;
class Container
{
	public static var MARGIN:Int		= 5;
	public static var MIN_HEIGHT:Int	= 20;


	public var mode			: Mode;
	public var depthMan		: DepthManager;
	public var mc				: MovieClip;

	public var fl_lock			: Bool;

	public var scale			: Float;

	public var width			: Int;
	public var currentX		: Float;
	public var currentY		: Float;
	public var lineHeight		: Float;
	public var list			: Array< gui.Item >;



	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new(m:Mode, x:Dynamic,y:Dynamic, wid:Dynamic)  untyped {
		mode = m;
		mc = mode.depthMan.empty(RootData.DP_INTERF);
		depthMan = new DepthManager(mc);

		{ if (mc != null) mc._x = x; }
		{ if (mc != null) mc._y = y; }
		width = wid;
		currentX = 0;
		currentY = 0;
		scale = 1;
		lineHeight = MIN_HEIGHT;

		list = new Array();
		unlock();
	}


	/*------------------------------------------------------------------------
	GESTION VERROU
	------------------------------------------------------------------------*/
	public function lock()  untyped {
		fl_lock = true;
	}
	public function unlock()  untyped {
		fl_lock = false;
	}


	/*------------------------------------------------------------------------
	INSERTION D'UN BOUTON
	------------------------------------------------------------------------*/
	public function insert(b:gui.Item)  untyped {
		b?.scale(scale);
		var endX:Dynamic = currentX + b?.width*scale + MARGIN;
		if ( endX > width ) {
			endLine();
			endX = b?.width*scale + MARGIN;
		}
		var pt:Dynamic = { x:currentX, y:currentY }

		currentX = endX;

		lineHeight = Math.max( lineHeight, b?._height );
		list?.push(b);
		return pt;
	}


	/*------------------------------------------------------------------------
	REMPLI LA PROCHAINE LIGNE INCOMPLÈTE
	------------------------------------------------------------------------*/
	public function endLine()  untyped {
		currentX = 0;
		currentY += lineHeight + MARGIN;
		lineHeight = MIN_HEIGHT*scale;
	}


	/*------------------------------------------------------------------------
	RESIZE
	------------------------------------------------------------------------*/
	public function setScale(ratio:Dynamic)  untyped {
		scale = ratio;
//		mc._xscale = ratio*100;
//		mc._yscale = mc._xscale;
	}


	/*------------------------------------------------------------------------
	MAIN
	------------------------------------------------------------------------*/
	public function update()  untyped {
		{ var i:Dynamic=0; while (i<list?.length) {
			list[i]?.update();
		
i++; } }
	}

}
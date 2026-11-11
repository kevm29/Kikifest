// Converti automatiquement depuis hammer/entity/Supa.mt (Motion Twin)
package entity;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
import Data as RootData;
class Supa extends entity.Mover
{

	public var radius : Float;
	public var speed : Float;

	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new()  untyped {
		super();
		fl_hitGround	= false;
		fl_hitWall		= false;
		fl_gravity		= false;
		fl_friction		= false;
		fl_hitBorder	= false;
		fl_alphaBlink	= false;
		blinkColorAlpha	= 80;

		minAlpha = 0;

		speed = 0;
		radius = 0;
	}


	/*------------------------------------------------------------------------
	INITIALISATION
	------------------------------------------------------------------------*/
	override public function init(g:mode.GameMode)  untyped {
		super.init(g);
		register(RootData.SUPA);

		disableAnimator();
	}

	/*------------------------------------------------------------------------
	INITIALISATION SUPA POWA
	------------------------------------------------------------------------*/
	public function initSupa(g:mode.GameMode,x:Dynamic,y:Dynamic)  untyped {
		init(g);
		moveTo(x,y);
		endUpdate();
	}

	/*------------------------------------------------------------------------
	INFIXE
	------------------------------------------------------------------------*/
	override public function infix()  untyped {
		// no super
	}


	/*------------------------------------------------------------------------
	DÉSACTIVATION DE LA GESTION PAR TRIGGER
	------------------------------------------------------------------------*/
	override public function tAdd(cx:Dynamic,cy:Dynamic)  untyped {
		// do nothing
	}
	override public function tRem(cx:Dynamic,cy:Dynamic)  untyped {
		// do nothing
	}

}



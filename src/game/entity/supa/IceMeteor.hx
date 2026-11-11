// Converti automatiquement depuis hammer/entity/supa/IceMeteor.mt (Motion Twin)
package entity.supa;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
import Data as RootData;
class IceMeteor extends entity.Supa
{

	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new()  untyped {
		super();
	}


	/*------------------------------------------------------------------------
	ATTACH
	------------------------------------------------------------------------*/
	public static function attach(g:mode.GameMode)  untyped {
		var linkage:Dynamic = "hammer_supa_icemeteor";
		var mc : entity.supa.IceMeteor = (( g?.depthMan?.attach(linkage,RootData.DP_SUPA) ):Dynamic);
		mc?.initSupa(g, RootData.GAME_WIDTH,0 );
		return mc;
	}


	/*------------------------------------------------------------------------
	INITIALISATION
	------------------------------------------------------------------------*/
	override public function initSupa(g:Dynamic,x:Dynamic,y:Dynamic)  untyped {
		super.initSupa(g,x,y);
		speed = 10;
		radius = 50;
		moveToAng(130,speed);
		setLifeTimer(RootData.SUPA_DURATION);
	}


	/*------------------------------------------------------------------------
	INFIXE
	------------------------------------------------------------------------*/
	override public function prefix()  untyped {
		super.prefix();
		var l:Dynamic = game?.getClose( RootData.BAD, x,y, radius, false );
		{ var i:Dynamic=0; while (i<l?.length) {
			var e : entity.Bad = ((l[i]):Dynamic);
			if ( !e?.fl_freeze ) {
				e?.freeze(RootData.FREEZE_DURATION);
				{ if (e != null) e.dx = dx*2; }
				{ if (e != null) e.dy = -5; }
			}
		
i++; } }
	}


	/*------------------------------------------------------------------------
	POSTFIXE
	------------------------------------------------------------------------*/
	override public function postfix()  untyped {
		super.postfix();
		rotation-=7*Timer.tmod;
		if ( !world?.shapeInBound(this) ) {
			moveTo(RootData.GAME_WIDTH,0);
		}
	}

}

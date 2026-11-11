// Converti automatiquement depuis hammer/entity/supa/Arrow.mt (Motion Twin)
package entity.supa;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
import Data as RootData;
class Arrow extends entity.Supa
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
		var linkage:Dynamic = "hammer_supa_arrow";
		var mc : entity.supa.Arrow = (( g?.depthMan?.attach(linkage,RootData.DP_SUPA) ):Dynamic);
		mc?.initSupa(g, RootData.GAME_WIDTH,-50 );
		return mc;
	}


	/*------------------------------------------------------------------------
	INITIALISATION
	------------------------------------------------------------------------*/
	override public function initSupa(g:Dynamic,x:Dynamic,y:Dynamic)  untyped {
		super.initSupa(g,x,y);
		speed = 10;
		radius = 50;
		moveLeft(speed);
	}


	/*------------------------------------------------------------------------
	INFIXE
	------------------------------------------------------------------------*/
	override public function prefix()  untyped {
		super.prefix();
		var l:Dynamic = game?.getClose( RootData.BAD, x,y, radius, false );
		{ var i:Dynamic=0; while (i<l?.length) {
			var e : entity.Bad = ((l[i]):Dynamic);
			if ( e?.y>=y-RootData.CASE_HEIGHT && e?.y<=y+RootData.CASE_HEIGHT*2 ) {
				if ( !e?.fl_kill ) {
					e?.killHit(-speed*1.5);
				}
			}
		
i++; } }
	}


	/*------------------------------------------------------------------------
	POSTFIXE
	------------------------------------------------------------------------*/
	override public function postfix()  untyped {
		super.postfix();
		if ( !world?.shapeInBound(this) ) {
			moveTo( RootData.GAME_WIDTH, MtStd.random(Std.int(RootData.GAME_HEIGHT*0.7))+40 );
		}
	}

}

// Converti automatiquement depuis hammer/entity/supa/Ball.mt (Motion Twin)
package entity.supa;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
import Data as RootData;
class Ball extends entity.Supa
{

	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new()  untyped {
		super() ;
		fl_gravity = true ;
	}


	/*------------------------------------------------------------------------
	ATTACH
	------------------------------------------------------------------------*/
	public static function attach(g:mode.GameMode)  untyped {
		var linkage:Dynamic = "hammer_supa_ball" ;
		var mc : entity.supa.Ball = (( g?.depthMan?.attach(linkage,RootData.DP_SUPA) ):Dynamic) ;
		mc?.initSupa(g, RootData.GAME_WIDTH,0 ) ;
		return mc ;
	}


	/*------------------------------------------------------------------------
	INITIALISATION
	------------------------------------------------------------------------*/
	override public function initSupa(g:Dynamic,x:Dynamic,y:Dynamic)  untyped {
		super.initSupa(g,x,y) ;
		speed = 2 ;
		radius = 40 ;
		fallFactor = 0.8 ;
		gravityFactor = 0.8 ;
		dx = speed ;
		moveTo(0,-50) ;
		scale(220) ;
	}


	/*------------------------------------------------------------------------
	INFIXE
	------------------------------------------------------------------------*/
	override public function prefix()  untyped {
		super.prefix() ;
		var l:Dynamic = game?.getClose( RootData.BAD, x,y, radius, false ) ;
		{ var i:Dynamic=0; while (i<l?.length) {
			var e : entity.Bad = ((l[i]):Dynamic) ;
			if ( !e?.fl_knock ) {
				e?.knock(RootData.KNOCK_DURATION*3) ;
				{ if (e != null) e.dx = dx*2 ; }
				{ if (e != null) e.dy = -5 ; }
			}
		
i++; } }
	}


	/*------------------------------------------------------------------------
	POSTFIXE
	------------------------------------------------------------------------*/
	override public function postfix()  untyped {
		super.postfix() ;
		if ( dy>0 && y>=RootData.GAME_HEIGHT ) {
			dy = -Math.abs(dy) ;
			game?.shake(RootData.SECOND*0.5,3);
		}
		if ( x>=RootData.GAME_WIDTH+50 ) {
			destroy() ;
		}
	}

}

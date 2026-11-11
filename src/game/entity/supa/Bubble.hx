// Converti automatiquement depuis hammer/entity/supa/Bubble.mt (Motion Twin)
package entity.supa;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
import Data as RootData;
class Bubble extends entity.Supa
{

	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new()  untyped {
		super();
		fl_alphaBlink	= true;
		blinkAlpha		= 25;
	}


	/*------------------------------------------------------------------------
	ATTACH
	------------------------------------------------------------------------*/
	public static function attach(g:mode.GameMode)  untyped {
		var linkage:Dynamic = "hammer_supa_bubble";
		var mc : entity.supa.Bubble = (( g.depthMan.attach(linkage,RootData.DP_SUPA) ):Dynamic);
		mc?.initSupa(g, RootData.GAME_WIDTH,0 );
		return mc;
	}


	/*------------------------------------------------------------------------
	INITIALISATION
	------------------------------------------------------------------------*/
	override public function initSupa(g:Dynamic,x:Dynamic,y:Dynamic)  untyped {
		super.initSupa(g,x,y);
		speed = 8;
		radius = 80;
		moveTo(RootData.GAME_WIDTH/2,RootData.GAME_HEIGHT/2);
		moveToAng(
			45 + (MtStd.random(30))*(MtStd.random(2)*2-1) + (MtStd.random(4)+1)*90,
			speed+MtStd.random(5)
		);
		setLifeTimer(RootData.SECOND*10);
	}


	/*------------------------------------------------------------------------
	INFIXE
	------------------------------------------------------------------------*/
	override public function prefix()  untyped {
		super.prefix();
		var l:Dynamic = game?.getClose( RootData.BAD, x,y, radius, false );
		{ var i:Dynamic=0; while (i<l?.length) {
			var e : entity.Bad = ((l[i]):Dynamic);
			if ( !e?.fl_knock ) {
				e?.knock(RootData.KNOCK_DURATION*2);
				{ if (e != null) e.dx = dx*2; }
				{ if (e != null) e.dy = -5; }
				game?.fxMan?.inGameParticles( RootData.PARTICLE_ICE, e?.x,e?.y-RootData.CASE_HEIGHT, MtStd.random(5) );
//				e.dy = -Math.abs(dy*2);
			}
		
i++; } }
	}


	/*------------------------------------------------------------------------
	POSTFIXE
	------------------------------------------------------------------------*/
	override public function postfix()  untyped {
		super.postfix();

		// Rebonds
		if ( y<=0 ) {
			dy = Math.abs(dy);
		}
		if ( y>=RootData.GAME_HEIGHT ) {
			dy = -Math.abs(dy);
		}
		if ( x<=0 ) {
			dx = Math.abs(dx);
		}
		if ( x>=RootData.GAME_WIDTH ) {
			dx = -Math.abs(dx);
		}
	}


}

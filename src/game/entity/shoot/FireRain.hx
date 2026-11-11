// Converti automatiquement depuis hammer/entity/shoot/FireRain.mt (Motion Twin)
package entity.shoot;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
import Data as RootData;
class FireRain extends entity.Shoot
{


	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new()  untyped {
		super() ;
		shootSpeed		= 10+MtStd.random(5);
		fl_checkBounds	= false;
//		fl_hitWall		= true;
//		fl_hitGround	= true;
	}


	/*------------------------------------------------------------------------
	INITIALISATION
	------------------------------------------------------------------------*/
	override public function init(g:Dynamic)  untyped {
		super.init(g) ;
		playAnim(RootData.ANIM_SHOOT_LOOP) ;
	}


	/*------------------------------------------------------------------------
	ATTACH
	------------------------------------------------------------------------*/
	public static function attach( g:mode.GameMode, x:Dynamic,y:Dynamic )  untyped {
		var linkage:Dynamic = "hammer_shoot_firerain" ;
		var s : entity.shoot.FireBall = (( g.depthMan.attach(linkage,RootData.DP_SHOTS) ):Dynamic) ;
		s?.initShoot(g, x, y-10) ;
		return s ;
	}


	/*------------------------------------------------------------------------
	EVENTS: LIGNE DU BAS
	------------------------------------------------------------------------*/
	override public function onDeathLine()  untyped {
		destroy();
	}



	/*------------------------------------------------------------------------
	DESTRUCTION
	------------------------------------------------------------------------*/
	override public function destroy()  untyped {
		super.destroy() ;
	}


	/*------------------------------------------------------------------------
	EVENT: HIT
	------------------------------------------------------------------------*/
	override public function hit(e:Entity)  untyped {
		if ( (e?.types & RootData.BAD_CLEAR) > 0 ) {
			var et : entity.Bad = ((e):Dynamic) ;
			game?.fxMan?.inGameParticles(RootData.PARTICLE_SPARK,x,y,MtStd.random(5)+1);
			et?.burn();
			destroy();
		}
	}


	/*------------------------------------------------------------------------
	EVENTS: CONTACT AVEC LE LEVEL
	------------------------------------------------------------------------*/
	override public function onHitWall()  untyped {
		hitLevel();
	}
	override public function onHitGround(h:Dynamic)  untyped {
		hitLevel();
	}


	/*------------------------------------------------------------------------
	TOUCHE UN DECOR
	------------------------------------------------------------------------*/
	public function hitLevel()  untyped {
		game?.fxMan?.attachExplodeZone(x,y,30);
		game?.fxMan?.inGameParticles(RootData.PARTICLE_STONE,x,y,MtStd.random(4));
		destroy();
	}


	/*------------------------------------------------------------------------
	ENTRÉE DANS UNE NOUVELLE CASE
	------------------------------------------------------------------------*/
//	function infix() {
//		super.infix();
//		if ( world.getCase( {x:cx,y:cy} )>0 && Std.random(10)==0 ) {
//			hitLevel();
//			fl_stopStepping = true;
//		}
//	}


	/*------------------------------------------------------------------------
	MAIN
	------------------------------------------------------------------------*/
	override public function update()  untyped {
		super.update();
		if ( x<0 ) {
			hitLevel();
		}
	}

}


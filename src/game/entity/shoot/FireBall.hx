// Converti automatiquement depuis hammer/entity/shoot/FireBall.mt (Motion Twin)
package entity.shoot;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
import Data as RootData;
class FireBall extends entity.Shoot
{


	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new()  untyped {
		super() ;
		fl_largeTrigger		= true;
		shootSpeed			= 7 ;
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
		var linkage:Dynamic = "hammer_shoot_fireball" ;
		var s : entity.shoot.FireBall = (( g?.depthMan?.attach(linkage,RootData.DP_SHOTS) ):Dynamic) ;
		s?.initShoot(g, x, y-10) ;
		return s ;
	}


	/*------------------------------------------------------------------------
	DESTRUCTION
	------------------------------------------------------------------------*/
	override public function destroy()  untyped {
		game?.fxMan?.attachFx(x,y-RootData.CASE_HEIGHT/2, "hammer_fx_pop") ;
		super.destroy() ;
	}


	/*------------------------------------------------------------------------
	EVENT: HIT
	------------------------------------------------------------------------*/
	override public function hit(e:Entity)  untyped {
		if ( (e?.types & RootData.PLAYER) > 0 ) {
			var p : entity.Player = ((e):Dynamic) ;
			var dist:Dynamic = distance(p?.x,p?.y);
			if ( dist<=RootData.CASE_WIDTH*1.2 ) {
				game?.fxMan?.attachExplosion(x,y,25);
				p?.killHit(dx) ;
			}
		}
	}

}

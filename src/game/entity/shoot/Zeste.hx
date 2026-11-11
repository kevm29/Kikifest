// Converti automatiquement depuis hammer/entity/shoot/Zeste.mt (Motion Twin)
package entity.shoot;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
import Data as RootData;
class Zeste extends entity.Shoot {

	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new()  untyped {
		super() ;
		shootSpeed	= 6 ;
	}


	/*------------------------------------------------------------------------
	ATTACH
	------------------------------------------------------------------------*/
	public static function attach( g:mode.GameMode, x:Dynamic,y:Dynamic )  untyped {
		var linkage:Dynamic = "hammer_shoot_zest" ;
		var s : entity.shoot.Pepin = (( g.depthMan.attach(linkage,RootData.DP_SHOTS) ):Dynamic) ;
		s?.initShoot(g, x, y) ;
		return s ;
	}


	/*------------------------------------------------------------------------
	DÉPLACEMENT VERS LE BAS
	------------------------------------------------------------------------*/
	override public function moveDown(s:Dynamic)  untyped {
		super.moveDown(s) ;
		_yscale = -_yscale ;
		_yOffset = -RootData.CASE_HEIGHT ;
	}


	/*------------------------------------------------------------------------
	EVENT: HIT
	------------------------------------------------------------------------*/
	override public function hit(e:Entity)  untyped {
		if ( (e?.types & RootData.PLAYER) > 0 ) {
			if (  Math.abs(e?.x-x) <= RootData.CASE_WIDTH*0.65 ) { // affinement
				var et : entity.Player = ((e):Dynamic) ;
				et?.killHit( (e?.x-x)*1.5 ) ;
				game?.fxMan?.attachExplodeZone(x,y,15) ;
			}
		}
	}
}

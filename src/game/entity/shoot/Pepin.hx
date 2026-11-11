// Converti automatiquement depuis hammer/entity/shoot/Pepin.mt (Motion Twin)
package entity.shoot;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
import Data as RootData;
class Pepin extends entity.Shoot
{

	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new()  untyped {
		super() ;
		shootSpeed = 5 ;
		_yOffset = -2 ;
	}


	/*------------------------------------------------------------------------
	ATTACH
	------------------------------------------------------------------------*/
	public static function attach( g:mode.GameMode, x:Dynamic,y:Dynamic )  untyped {
		var linkage:Dynamic = "hammer_shoot_pepin" ;
		var s : entity.shoot.Pepin = (( g?.depthMan?.attach(linkage,RootData.DP_SHOTS) ):Dynamic) ;
		s?.initShoot(g, x, y) ;
		return s ;
	}


	/*------------------------------------------------------------------------
	EVENT: HIT
	------------------------------------------------------------------------*/
	override public function hit(e:Entity)  untyped {
		if ( (e?.types & RootData.PLAYER) > 0 ) {
			var et : entity.Player = ((e):Dynamic) ;
			et?.killHit(dx) ;
		}
	}
}

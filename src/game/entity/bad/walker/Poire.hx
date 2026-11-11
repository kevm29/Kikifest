// Converti automatiquement depuis hammer/entity/bad/walker/Poire.mt (Motion Twin)
package entity.bad.walker;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
import Data as RootData;
class Poire extends entity.bad.Shooter
{

	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new()  untyped {
		super() ;
//		setJumpUp(3) ;
		setJumpH(100) ;
		setClimb(100,1);
//		setFall(20) ;
		setShoot(4) ;
		initShooter(50, 8) ;
	}


	/*------------------------------------------------------------------------
	ATTACHEMENT
	------------------------------------------------------------------------*/
	public static function attach(g:mode.GameMode,x:Dynamic,y:Dynamic)  untyped {
		var linkage:Dynamic = RootData.LINKAGES[RootData.BAD_POIRE];
		var mc : entity.bad.walker.Poire = (( g?.depthMan?.attach(linkage,RootData.DP_BADS) ):Dynamic) ;
		mc?.initBad(g,x,y) ;
		return mc ;
	}


	/*------------------------------------------------------------------------
	EVENT: TIR
	------------------------------------------------------------------------*/
	override public function onShoot()  untyped {
		var s:Dynamic = entity.bomb.bad.PoireBomb.attach(game, x,y) ;
		var spd:Dynamic = 10 ;
		if ( dir<0 ) {
			s?.moveToAng(-135,spd) ;
		}
		else {
			s?.moveToAng(-45,spd) ;
		}
		setNext(null,null,shootDuration,RootData.ACTION_FALLBACK) ;
	}

}


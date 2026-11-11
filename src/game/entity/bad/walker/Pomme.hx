// Converti automatiquement depuis hammer/entity/bad/walker/Pomme.mt (Motion Twin)
package entity.bad.walker;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
import Data as RootData;
class Pomme extends entity.bad.Shooter {

	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new()  untyped {
		super() ;

		setJumpUp(3) ;
		setJumpH(100) ;
		setClimb(100,1);
		setFall(20) ;
		setShoot(2) ;

		initShooter(20, 12) ;
	}


	/*------------------------------------------------------------------------
	INITIALISATION
	------------------------------------------------------------------------*/
	override public function init(g:Dynamic)  untyped {
		super.init(g) ;
	}


	/*------------------------------------------------------------------------
	ATTACHEMENT
	------------------------------------------------------------------------*/
	public static function attach(g:mode.GameMode,x:Dynamic,y:Dynamic)  untyped {
		var linkage:Dynamic = RootData.LINKAGES[RootData.BAD_POMME];
		var mc : entity.bad.walker.Pomme = (( g?.depthMan?.attach(linkage,RootData.DP_BADS) ):Dynamic) ;
		mc?.initBad(g,x,y) ;
		return mc ;
	}


	/*------------------------------------------------------------------------
	EVENT: TIR
	------------------------------------------------------------------------*/
	override public function onShoot()  untyped {
		var s:Dynamic = entity.shoot.Pepin.attach(game, x,y) ;
		if ( dir<0 ) {
			s?.moveLeft(s?.shootSpeed) ;
		}
		else {
			s?.moveRight(s?.shootSpeed) ;
		}
	}

}


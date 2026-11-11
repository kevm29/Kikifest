// Converti automatiquement depuis hammer/entity/bad/flyer/Tzongre.mt (Motion Twin)
package entity.bad.flyer;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
import Data as RootData;
class Tzongre extends entity.bad.Flyer
{

	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new()  untyped {
		super() ;
	}


	/*------------------------------------------------------------------------
	INITIALISATION
	------------------------------------------------------------------------*/
	override public function init(g:Dynamic)  untyped {
		super.init(g);
		unregister( RootData.BAD_CLEAR );
	}


	/*------------------------------------------------------------------------
	ANNULATION DE CERTAINES FONCTIONNALITÉS
	------------------------------------------------------------------------*/
	override public function freeze(d:Dynamic)  untyped {}
	override public function knock(d:Dynamic)  untyped {}
	override public function killHit(dx:Dynamic)  untyped {}


	/*------------------------------------------------------------------------
	RENCONTRE UNE AUTRE ENTITÉ
	------------------------------------------------------------------------*/
	override public function hit(e:Entity)  untyped {
		// Joueur
		if ( (e?.types & RootData.PLAYER) > 0 ) {
			var et : entity.Player = ((e):Dynamic) ;
			game?.fxMan?.attachFx(x,y-RootData.CASE_HEIGHT,"hammer_fx_shine") ;
			et?.getScore(this, 50000) ;
			this.destroy() ;
		}

		// Bads
		if ( (e?.types & RootData.BAD) >0 ) {
			var et : entity.Bad = ((e):Dynamic) ;
			et?.knock(RootData.KNOCK_DURATION) ;
		}
	}


	/*------------------------------------------------------------------------
	ATTACHEMENT
	------------------------------------------------------------------------*/
	public static function attach(g:mode.GameMode,x:Dynamic,y:Dynamic)  untyped {
		var linkage:Dynamic = RootData.LINKAGES[RootData.BAD_TZONGRE];
		var mc : entity.bad.flyer.Tzongre = (( g?.depthMan?.attach(linkage,RootData.DP_BADS) ):Dynamic) ;
		mc?.initBad(g,x,y) ;
		mc?.setLifeTimer(RootData.SECOND*60) ;
		return mc ;
	}
}


// Converti automatiquement depuis hammer/entity/bomb/player/Black.mt (Motion Twin)
package entity.bomb.player;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
import Data as RootData;
class Black extends entity.bomb.PlayerBomb {

	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new()  untyped {
		super() ;
		duration = 100 ;
		power = 20 ;
		explodeSound="sound_bomb_black";
	}


	/*------------------------------------------------------------------------
	ATTACH
	------------------------------------------------------------------------*/
	public static function attach(g:mode.GameMode,x:Dynamic,y:Dynamic)  untyped {
		var linkage:Dynamic = "hammer_bomb_black" ;
		var mc : entity.bomb.player.Black = (( g?.depthMan?.attach(linkage,RootData.DP_BOMBS) ):Dynamic) ;
		mc?.initBomb(g, x,y ) ;
		return mc ;
	}


	/*------------------------------------------------------------------------
	DUPLICATION
	------------------------------------------------------------------------*/
	override public function duplicate()  untyped {
		return attach(game, x,y) ;
	}


	/*------------------------------------------------------------------------
	EVENT: EXPLOSION
	------------------------------------------------------------------------*/
	override public function onExplode()  untyped {
		super.onExplode() ;

		var l:Dynamic = bombGetClose(RootData.BAD) ;
		game?.shake(10,4) ;
		game?.fxMan?.attachExplodeZone(x,y,radius);

		{ var i:Dynamic=0; while (i<l?.length) {
			var e : entity.Bad = ((l[i]):Dynamic) ;
			e?.setCombo(uniqId) ;
			e?.killHit(0);
			shockWave( e, radius, power) ;
			{ if (e != null) e.dy = -10-MtStd.random(20) ; }
		
i++; } }
	}

}


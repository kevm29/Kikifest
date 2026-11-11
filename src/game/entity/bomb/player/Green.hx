// Converti automatiquement depuis hammer/entity/bomb/player/Green.mt (Motion Twin)
package entity.bomb.player;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
import Data as RootData;
class Green extends entity.bomb.PlayerBomb
{

	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new()  untyped {
		super() ;
		duration		= 200 ;
		power			= 25 ;
		fl_blink		= true;
		fl_alphaBlink	= false;
		fl_unstable		= true;
		explodeSound	= "sound_bomb_green";
	}


	/*------------------------------------------------------------------------
	ATTACH
	------------------------------------------------------------------------*/
	public static function attach(g:mode.GameMode,x:Dynamic,y:Dynamic)  untyped {
		var linkage:Dynamic = "hammer_bomb_green" ;
		var mc : entity.bomb.player.Green = (( g?.depthMan?.attach(linkage,RootData.DP_BOMBS) ):Dynamic) ;
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
	MISE À JOUR GRAPHIQUE
	------------------------------------------------------------------------*/
	override public function endUpdate()  untyped {
		super.endUpdate() ;
		rotation = 0 ;
		_rotation = rotation ;
	}


	/*------------------------------------------------------------------------
	EVENT: EXPLOSION
	------------------------------------------------------------------------*/
	override public function onExplode()  untyped {
		if ( fl_explode ) return;

		game?.soundMan?.playSound("sound_bomb", RootData.CHAN_BOMB);

		super.onExplode() ;


		var l:Dynamic = bombGetClose(RootData.BAD) ;

		{ var i:Dynamic=0; while (i<l?.length) {
			var e : entity.Bad = ((l[i]):Dynamic) ;
			e?.setCombo(uniqId) ;
			e?.freeze(RootData.FREEZE_DURATION) ;
			shockWave( e, radius, power) ;
		
i++; } }
		game?.fxMan?.inGameParticles(RootData.PARTICLE_ICE, x,y, MtStd.random(2)+2) ;

		l = bombGetClose(RootData.BAD_BOMB);
		{ var i:Dynamic=0; while (i<l?.length) {
			var b : entity.bomb.BadBomb = ((l[i]):Dynamic);
			if ( !b?.fl_explode ) {
				var bf:Dynamic = b?.getFrozen(uniqId);
				if ( bf!=null ) {
					shockWave( bf, radius, power );
					b?.destroy();
				}
			}
		
i++; } }
	}

}


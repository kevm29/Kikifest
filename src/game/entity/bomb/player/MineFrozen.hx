// Converti automatiquement depuis hammer/entity/bomb/player/MineFrozen.mt (Motion Twin)
package entity.bomb.player;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
import Data as RootData;
class MineFrozen extends entity.bomb.PlayerBomb
{

	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new()  untyped {
		super();
		duration = MtStd.random(20)+15;
		power = 30;
	}


	/*------------------------------------------------------------------------
	ATTACH
	------------------------------------------------------------------------*/
	public static function attach(g:mode.GameMode,x:Dynamic,y:Dynamic)  untyped {
		var linkage:Dynamic = "hammer_bomb_mine_frozen";
		var mc : entity.bomb.player.MineFrozen = (( g.depthMan.attach(linkage,RootData.DP_BOMBS) ):Dynamic);
		mc?.initBomb(g, x,y );
		return mc;
	}


	/*------------------------------------------------------------------------
	DUPLICATION
	------------------------------------------------------------------------*/
	override public function duplicate()  untyped {
		return attach(game, x,y);
	}

	/*------------------------------------------------------------------------
	REBONDS AUX MURS
	------------------------------------------------------------------------*/
	override public function onHitWall()  untyped {
		dx = -dx;
	}


	/*------------------------------------------------------------------------
	EVENT: EXPLOSION
	------------------------------------------------------------------------*/
	override public function onExplode()  untyped {
		super.onExplode();

		game?.fxMan?.attachExplodeZone(x,y,radius);

		var l:Dynamic = bombGetClose(RootData.BAD);
		{ var i:Dynamic=0; while (i<l?.length) {
			var e : entity.Bad = ((l[i]):Dynamic);
			e?.setCombo(uniqId);
			e?.freeze(RootData.FREEZE_DURATION);
			shockWave( e, radius, power);
		
i++; } }


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


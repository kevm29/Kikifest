// Converti automatiquement depuis hammer/entity/bomb/player/Red.mt (Motion Twin)
package entity.bomb.player;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
import Data as RootData;
class Red extends entity.bomb.PlayerBomb
{

	public var JUMP_POWER : Int;

	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new()  untyped {
		super();
		duration = 38;
		power = 30;
		JUMP_POWER = 32;
	}


	/*------------------------------------------------------------------------
	ATTACH
	------------------------------------------------------------------------*/
	public static function attach(g:mode.GameMode,x:Dynamic,y:Dynamic)  untyped {
		var linkage:Dynamic = "hammer_bomb_red";
		var mc : entity.bomb.player.Red = (( g?.depthMan?.attach(linkage,RootData.DP_BOMBS) ):Dynamic);
		mc?.initBomb(g, x,y);
		return mc;
	}


	/*------------------------------------------------------------------------
	DUPLICATION
	------------------------------------------------------------------------*/
	override public function duplicate()  untyped {
		return attach(game, x,y);
	}


	/*------------------------------------------------------------------------
	EVENT: EXPLOSION
	------------------------------------------------------------------------*/
	override public function onExplode()  untyped {
		super.onExplode();

		// freeze bads
		var l:Dynamic = bombGetClose(RootData.BAD);
		{ var i:Dynamic=0; while (i<l?.length) {
			var e : entity.Bad = ((l[i]):Dynamic);
			e?.setCombo(uniqId);
			e?.freeze(RootData.FREEZE_DURATION);
			shockWave( e, radius, power);
			if ( e?.dy<0 ) {
				{ if (e != null) e.dy*=3; }
				if ( distance(e?.x,e?.y)<=radius*0.5 ) {
					{ if (e != null) e.dx *= 0.5; }
					{ if (e != null) e.dy *= 2; }
				}
			}
		
i++; } }

//		// freeze bad bombs
//		l = bombGetClose(Data.BAD_BOMB);
//		for (var i=0;i<l.length;i++) {
//			var b : entity.bomb.BadBomb = downcast(l[i]);
//			if ( !b.fl_explode ) {
//				var bf = b.getFrozen(uniqId);
//				if ( bf!=null ) {
//					shockWave( bf, radius, power );
//					b.destroy();
//				}
//			}
//		}

		// fx
		game?.fxMan?.inGameParticles(RootData.PARTICLE_ICE, x,y, MtStd.random(2)+2);
		game?.fxMan?.attachExplodeZone(x,y,radius);


		// player bomb jump
		l = game?.getList(RootData.PLAYER) ;
		{ var i:Dynamic=0; while (i<l?.length) {
			var e : entity.Player = ((l[i]):Dynamic);
			var distX:Dynamic = (e?.x-x);
			var distY:Dynamic = (e?.y-y);

			// Facilite le bomb jump
			if ( fl_stable ) {
				distX *= 1.5;
				distY *= 0.5;
			}
			else {
				distX *= 0.9;
				distY *= 0.35;
			}

			var dist:Dynamic = Math.sqrt( distX*distX + distY*distY );
			if ( dist <= 40 ) {
				if ( e?.dy > 0 ) {
					{ if (e != null) e.dy = 0; }
				}
				{ if (e != null) e.dy -= JUMP_POWER; }
				if ( e?.dy<=-35 ) {
					game?.shake(10,3);
					game?.fxMan?.attachExplodeZone(e?.x,e?.y-40, 50);
					game?.fxMan?.attachExplodeZone(e?.x,e?.y-80, 40);
					game?.fxMan?.attachExplodeZone(e?.x,e?.y-120, 30);
				}
			}
			else {
				if ( e?.distance(x,y)<=radius ) {
					shockWave( e, radius, power );
				}
			}
		
i++; } }

	}
}


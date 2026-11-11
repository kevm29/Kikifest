// Converti automatiquement depuis hammer/entity/bomb/player/Blue.mt (Motion Twin)
package entity.bomb.player;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
import Data as RootData;
class Blue extends entity.bomb.PlayerBomb
{

	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new()  untyped {
		super();
		duration = 45;
		power = 20;
		explodeSound="sound_bomb_blue";
	}


	/*------------------------------------------------------------------------
	ATTACH
	------------------------------------------------------------------------*/
	public static function attach(g:mode.GameMode,x:Dynamic,y:Dynamic)  untyped {
		var linkage:Dynamic = "hammer_bomb_blue";
		var mc : entity.bomb.player.Blue = (( g.depthMan.attach(linkage,RootData.DP_BOMBS) ):Dynamic);
		mc?.initBomb( g, x,y );
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

		var l:Dynamic = bombGetClose(RootData.BAD);

		{ var i:Dynamic=0; while (i<l?.length) {
			var e : entity.Bad = ((l[i]):Dynamic);
			e?.setCombo(uniqId);
			e?.knock(RootData.KNOCK_DURATION*0.75);
			shockWave(e,radius,power);
			{ if (e != null) e.dx *= 0.3; }
			{ if (e != null) e.dy = -6; }
			{ if (e != null) e.yTrigger = e?.y+RootData.CASE_HEIGHT*1.5; }
			{ if (e != null) e.fl_hitGround = false; }
		
i++; } }
	}

}


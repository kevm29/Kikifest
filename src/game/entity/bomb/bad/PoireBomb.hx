// Converti automatiquement depuis hammer/entity/bomb/bad/PoireBomb.mt (Motion Twin)
package entity.bomb.bad;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
import Data as RootData;
class PoireBomb extends entity.bomb.BadBomb
{

	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new()  untyped {
		super();
		duration = 45;
		power = 30;
		radius = RootData.CASE_WIDTH*4;
	}


	/*------------------------------------------------------------------------
	ATTACH
	------------------------------------------------------------------------*/
	public static function attach(g:mode.GameMode,x:Dynamic,y:Dynamic)  untyped {
		var linkage:Dynamic = "hammer_bomb_poire";
		var mc : entity.bomb.bad.PoireBomb = (( g.depthMan.attach(linkage,RootData.DP_BOMBS) ):Dynamic);
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
	GÈLE LA BOMBE
	------------------------------------------------------------------------*/
//	function getFrozen(uid) {
//		var b = entity.bomb.player.PoireBombFrozen.attach(game, x, y);
//		b.uniqId = uid;
//		return b;
//	}


	/*------------------------------------------------------------------------
	EVENT: EXPLOSION
	------------------------------------------------------------------------*/
	override public function onExplode()  untyped {
		super.onExplode();

		game?.fxMan?.attachExplodeZone(x,y,radius);

		var l:Dynamic = game?.getClose(RootData.PLAYER,x,y,radius,false);

		{ var i:Dynamic=0; while (i<l?.length) {
			var e : entity.Player = ((l[i]):Dynamic);
			e?.killHit(0);
			shockWave( e, radius, power );
			if ( !e?.fl_shield ) {
				{ if (e != null) e.dy = -10-MtStd.random(20); }
			}
		
i++; } }
	}


	/*------------------------------------------------------------------------
	EVENT: KICK (CES BOMBES SONT FACILEMENT REPOUSSABLES)
	------------------------------------------------------------------------*/
	override public function onKick(p:Dynamic)  untyped {
		super.onKick(p);
		setLifeTimer( lifeTimer + RootData.SECOND*0.5 );
	}
}


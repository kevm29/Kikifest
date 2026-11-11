// Converti automatiquement depuis hammer/entity/bomb/bad/BossBomb.mt (Motion Twin)
package entity.bomb.bad;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
import Data as RootData;
class BossBomb extends entity.bomb.BadBomb
{

	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new()  untyped {
		super();
		duration		= RootData.SECOND*2 + ( MtStd.random(50)/10 * (MtStd.random(2)*2-1) );
		fl_blink		= true;
		fl_alphaBlink	= false;
		blinkColorAlpha	= 50;
		explodeSound	= null;
	}


	/*------------------------------------------------------------------------
	ATTACH
	------------------------------------------------------------------------*/
	public static function attach(g:mode.GameMode,x:Dynamic,y:Dynamic)  untyped {
		var linkage:Dynamic = "hammer_bomb_boss";
		var mc : entity.bomb.bad.BossBomb = (( g.depthMan.attach(linkage,RootData.DP_BOMBS) ):Dynamic);
		mc?.initBomb(g, x,y );
		return mc;
	}


	/*------------------------------------------------------------------------
	INITIALISATION: BOMBE
	------------------------------------------------------------------------*/
	override public function initBomb(g:Dynamic,x:Dynamic,y:Dynamic)  untyped {
		super.initBomb(g,x,y);
		setLifeTimer(duration*1.5);
		updateLifeTimer(duration);
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
		var b:Dynamic = entity.bad.walker.Orange.attach(game,x-RootData.CASE_WIDTH*0.5,y-RootData.CASE_HEIGHT*0.5);
		var boss : entity.boss.Tuberculoz = (( game.getOne(RootData.BOSS) ):Dynamic);
		if ( boss?.lives<=70 ) {
			b?.angerMore();
		}
		if ( boss?.lives<=50 ) {
			b?.angerMore();
		}
		b?.moveUp(10);
		b?.knock(RootData.SECOND);
		{ if (b != null) b.dropReward = null; }
		playAnim(RootData.ANIM_BOMB_EXPLODE);
	}


	/*------------------------------------------------------------------------
	EVENT: KICK (CES BOMBES SONT FACILEMENT REPOUSSABLES)
	------------------------------------------------------------------------*/
	override public function onKick(p:Dynamic)  untyped {
		super.onKick(p);
		setLifeTimer( lifeTimer + RootData.SECOND*0.5 );
	}

}


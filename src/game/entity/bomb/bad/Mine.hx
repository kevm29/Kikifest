// Converti automatiquement depuis hammer/entity/bomb/bad/Mine.mt (Motion Twin)
package entity.bomb.bad;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
import Data as RootData;
class Mine extends entity.bomb.BadBomb
{
	public static var SUDDEN_DEATH	= RootData.SECOND * 1.1;
	public static var HIDE_SPEED:Int	= 3;
	public static var DETECT_RADIUS= RootData.CASE_WIDTH*2.5;

	public var fl_trigger	: Bool;
	public var fl_defuse	: Bool;
	public var fl_plant	: Bool;

	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new()  untyped {
		super() ;
		fl_blink		= true;
		fl_alphaBlink	= false;
		duration		= RootData.SECOND*15;
		power			= 50 ;
		radius			= RootData.CASE_WIDTH*3;

		fl_trigger		= false;
		fl_defuse		= false;
		fl_plant		= false;
	}

	/*------------------------------------------------------------------------
	INITIALISATION BOMBE
	------------------------------------------------------------------------*/
	override public function initBomb(g:Dynamic,x:Dynamic,y:Dynamic)  untyped {
		super.initBomb(g,x,y);
		if ( game?.fl_bombExpert ) {
			radius*=1.3; // higher factor than other badbombs !
		}
	}


	/*------------------------------------------------------------------------
	ATTACH
	------------------------------------------------------------------------*/
	public static function attach(g:mode.GameMode,x:Dynamic,y:Dynamic)  untyped {
		var linkage:Dynamic = "hammer_bomb_mine" ;
		var mc : entity.bomb.bad.Mine = (( g?.depthMan?.attach(linkage,RootData.DP_BOMBS) ):Dynamic) ;
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
	EVENT: TOUCHE LE SOL
	------------------------------------------------------------------------*/
	override public function onHitGround(h:Dynamic)  untyped {
		super.onHitGround(h);
		if ( !fl_trigger ) {
			playAnim(RootData.ANIM_BOMB_LOOP);
		}
		if ( !fl_defuse ) {
			rotation = 0;
		}
	}

	/*------------------------------------------------------------------------
	EVENT: EXPLOSION
	------------------------------------------------------------------------*/
	override public function onExplode()  untyped {
		if ( !fl_trigger || fl_defuse ) {
			game?.fxMan?.attachFx(x,y-RootData.CASE_HEIGHT,"hammer_fx_pop") ;
			destroy();
		}
		else {
			super.onExplode() ;
			game?.fxMan?.attachExplodeZone(x,y,radius) ;

			var l:Dynamic = game?.getClose(RootData.PLAYER,x,y,radius,false) ;

			{ var i:Dynamic=0; while (i<l?.length) {
				var e : entity.Player = ((l[i]):Dynamic) ;
				e?.killHit(0) ;
				shockWave( e, radius, power ) ;
				if ( !e?.fl_shield ) {
					{ if (e != null) e.dy = -10-MtStd.random(20) ; }
				}
			
i++; } }
		}
	}


	/*------------------------------------------------------------------------
	EVENT: KICK (CES BOMBES SONT FACILEMENT REPOUSSABLES)
	------------------------------------------------------------------------*/
	override public function onKick(p:Dynamic)  untyped {
		super.onKick(p);
		triggerMine();

		updateLifeTimer(RootData.SECOND*0.7);
		dx *= 0.8 + MtStd.random(10)/10;
//		fl_defuse = true;
	}


	/*------------------------------------------------------------------------
	ACTIVE LA MINE
	------------------------------------------------------------------------*/
	public function triggerMine()  untyped {
		if ( fl_trigger ) {
			return;
		}
		fl_trigger = true;
		playAnim(RootData.ANIM_BOMB_DROP);
		dy = -7;
		show();
		alpha = 100;

		setLifeTimer(SUDDEN_DEATH*3); // pour forcer le blink
		updateLifeTimer(SUDDEN_DEATH);
		blinkLife();
	}


	/*------------------------------------------------------------------------
	LANCE UNE ANIM
	------------------------------------------------------------------------*/
	override public function playAnim(a:Dynamic)  untyped {
		super.playAnim(a);
		if ( a?.id==RootData.ANIM_BOMB_DROP.id ) {
			fl_loop = true;
		}
		if ( a?.id==RootData.ANIM_BOMB_LOOP.id ) {
			fl_loop = false;
		}
	}


	/*------------------------------------------------------------------------
	GÈLE LA BOMBE
	------------------------------------------------------------------------*/
//	function getFrozen(uid) {
//		var b = entity.bomb.player.MineFrozen.attach(game, x, y);
//		b.uniqId = uid;
//		return b;
//	}


	/*------------------------------------------------------------------------
	BOUCLE PRINCIPALE
	------------------------------------------------------------------------*/
	override public function update()  untyped {
		super.update();

		// Activation à l'atterrissage
		if ( fl_stable && !fl_plant ) {
			fl_plant = true;
		}

		// Disparition après la pose
		if ( fl_plant && !fl_trigger && alpha>0 ) {
			alpha-=Timer.tmod*HIDE_SPEED;
			if ( alpha<=0 ) {
				hide();
			}
		}

		// Déclenchement
		if ( fl_plant && !fl_trigger ) {
			var l:Dynamic = game?.getClose(RootData.PLAYER,x,y,DETECT_RADIUS,false);
			{ var i:Dynamic=0; while (i<l?.length) {
				if ( !l[i]?.fl_kill ) {
					triggerMine();
				}
			
i++; } }
		}
	}

}


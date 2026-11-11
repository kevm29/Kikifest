// Converti automatiquement depuis hammer/entity/shoot/BossFireBall.mt (Motion Twin)
package entity.shoot;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
import Data as RootData;
class BossFireBall extends entity.Shoot
{
	public var maxDist		: Float;

	public var bat			: entity.boss.Bat;
	public var ang			: Float;	// angle radians
	public var dist		: Float;

	public var distSpeed	: Float;
	public var turnSpeed	: Float;

	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new()  untyped {
		super();
		fl_checkBounds	= false;
		fl_largeTrigger	= true;
		turnSpeed		= 0.025;
		distSpeed		= 2;
		dist			= RootData.CASE_WIDTH*0.2;
		maxDist			= RootData.CASE_WIDTH*5;
		disablePhysics();
	}


	/*------------------------------------------------------------------------
	INITIALISATION
	------------------------------------------------------------------------*/
	override public function init(g:Dynamic)  untyped {
		super.init(g) ;
		playAnim(RootData.ANIM_SHOOT_LOOP) ;
	}


	/*------------------------------------------------------------------------
	INITIALISE LE TIR SPÉCIFIQUEMENT AU BOSS
	------------------------------------------------------------------------*/
	public function initBossShoot( b:Dynamic, a:Dynamic )  untyped { // angle en degré
		bat		= b;
		ang		= a*Math.PI/180;

		center();
	}


	/*------------------------------------------------------------------------
	PLACE LA FIREBALL AUTOUR DU BOSS
	------------------------------------------------------------------------*/
	public function center()  untyped {
		moveTo(
			bat?.x + Math.cos(ang)*dist,
			bat?.y + Math.sin(ang)*dist
		);
	}


	/*------------------------------------------------------------------------
	ATTACH
	------------------------------------------------------------------------*/
	public static function attach( g:mode.GameMode, x:Dynamic,y:Dynamic )  untyped {
		var linkage:Dynamic = "hammer_shoot_boss_fireball" ;
		var s : entity.shoot.BossFireBall = (( g.depthMan.attach(linkage,RootData.DP_SHOTS) ):Dynamic) ;
		s?.initShoot(g, x, y-10) ;
		return s ;
	}


	/*------------------------------------------------------------------------
	DESTRUCTION
	------------------------------------------------------------------------*/
	override public function destroy()  untyped {
		game?.fxMan?.attachExplodeZone(x,y,RootData.CASE_WIDTH*2);
		super.destroy() ;
	}


	/*------------------------------------------------------------------------
	EVENT: HIT
	------------------------------------------------------------------------*/
	override public function hit(e:Entity)  untyped {
		if ( (e?.types & RootData.BOMB) > 0 ) {
			var et : entity.Bomb = ((e):Dynamic) ;
			if ( !et?.fl_explode ) {
				game?.fxMan?.attachFx(et?.x,et?.y-RootData.CASE_HEIGHT,"hammer_fx_pop");
				et?.destroy();
				game?.fxMan?.inGameParticles(RootData.PARTICLE_CLASSIC_BOMB, x,y,6);

				destroy();
				return;
			}
		}
		if ( (e?.types & RootData.PLAYER) > 0 ) {
			var et : entity.Player = ((e):Dynamic) ;
			et?.killHit(dx) ;
		}
	}


	/*------------------------------------------------------------------------
	PRÉFIXE DE STEPPING
	------------------------------------------------------------------------*/
	override public function update()  untyped {
		super.update();

		var ocx:Dynamic = cx;
		var ocy:Dynamic = cy;
		ang		+= Timer.tmod * turnSpeed;
		dist	+= Timer.tmod * distSpeed;
		dist	= Math.min( dist, maxDist );
		center();
		if ( ocx!=cx || ocy!=cy ) {
			checkHits();
		}
	}

}

// Converti automatiquement depuis hammer/entity/shoot/Ball.mt (Motion Twin)
package entity.shoot;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
import Data as RootData;
class Ball extends entity.Shoot
{

	public var targetCatcher : Entity;


	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new()  untyped {
		super();
		shootSpeed = 8.5;
		_yOffset = 0;
		setLifeTimer(RootData.BALL_TIMEOUT);
		fl_alphaBlink = false;
		fl_borderBounce = true;
	}


	/*------------------------------------------------------------------------
	INITIALISATION
	------------------------------------------------------------------------*/
	override public function init(g:Dynamic)  untyped {
		super.init(g);
		register(RootData.BALL);
	}



	/*------------------------------------------------------------------------
	ATTACH
	------------------------------------------------------------------------*/
	public static function attach( g:mode.GameMode, x:Dynamic,y:Dynamic )  untyped {
		var linkage:Dynamic = "hammer_shoot_ball";
		var s : entity.shoot.Ball = (( g?.depthMan?.attach(linkage,RootData.DP_SHOTS) ):Dynamic);
		s?.initShoot(g, x, y);
		return s;
	}


	/*------------------------------------------------------------------------
	EVENT: TIMER DE VIE ATTEINT (et pas catché, à priori)
	------------------------------------------------------------------------*/
	override public function onLifeTimer()  untyped {
		// Ré-attribution d'une balle perdue
		game?.fxMan?.attachFx(x,y-RootData.CASE_HEIGHT/2, "hammer_fx_pop");

		var bad : entity.bad.walker.Fraise = ((game?.getOne(RootData.CATCHER)):Dynamic);
		bad?.assignBall();

		super.onLifeTimer();
	}


	/*------------------------------------------------------------------------
	EVENT: HIT
	------------------------------------------------------------------------*/
	override public function hit(e:Entity)  untyped {
		if ( (e?.types & RootData.PLAYER) > 0 ) {
			var et : entity.Player = ((e):Dynamic);
			et?.killHit(dx);
		}
		if ( (e?.types & RootData.CATCHER) > 0 && targetCatcher==((e):Dynamic) ) {
			((e):Dynamic)?.catchBall(this);
		}
	}
}

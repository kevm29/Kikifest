// Converti automatiquement depuis hammer/entity/bomb/player/SoccerBall.mt (Motion Twin)
package entity.bomb.player;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
import Data as RootData;
class SoccerBall extends entity.bomb.PlayerBomb
{

	public static var TOP_SPEED:Int	= 4;

	public var speed				: Float;
	public var burnTimer			: Float;
	public var lastPlayer			: entity.Player;


	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new()  untyped {
		super();
		lastPlayer		= null;
		duration		= 999999;
		burnTimer		= 0;
		bounceFactor	= 0.8;
		fl_bounce		= true;
		slideFriction	= RootData.FRICTION_SLIDE * 0.9;
	}


	/*------------------------------------------------------------------------
	ATTACH
	------------------------------------------------------------------------*/
	public static function attach(g:mode.GameMode,x:Dynamic,y:Dynamic)  untyped {
		var linkage:Dynamic = "hammer_bomb_soccer";
		var mc : entity.bomb.player.SoccerBall = (( g.depthMan.attach(linkage,RootData.DP_BOMBS) ):Dynamic);
		mc?.initBomb(g, x,y );
		return mc;
	}


	/*------------------------------------------------------------------------
	INITIALISATION
	------------------------------------------------------------------------*/
	override public function init(g:Dynamic)  untyped {
		super.init(g);
		register(RootData.SOCCERBALL);
		FxManager.addGlow(this, 0x808080, 2);
		game?.fxMan?.attachShine( x, y-RootData.CASE_HEIGHT*0.5 );
	}


	/*------------------------------------------------------------------------
	DUPLICATION
	------------------------------------------------------------------------*/
	override public function duplicate()  untyped {
		return null;
	}

	/*------------------------------------------------------------------------
	AUGMENTE LA PUISSANCE DE LA BOMBE
	------------------------------------------------------------------------*/
	override public function upgradeBomb(p:Dynamic)  untyped {
		// do nothing
	}


	/*------------------------------------------------------------------------
	EVENT: KICK
	------------------------------------------------------------------------*/
	override public function onKick(p:Dynamic)  untyped {
		super.onKick(p);
		lastPlayer = p;
		if ( Math.abs(dx)<10 ) {
			dx *= 3;
			dy *= 1.1;
		}
	}


	/*------------------------------------------------------------------------
	MET LE FEU AU BALLON
	------------------------------------------------------------------------*/
	public function burn()  untyped {
		burnTimer = RootData.SECOND;
	}


	/*------------------------------------------------------------------------
	EVENT: EXPLOSION
	------------------------------------------------------------------------*/
	override public function onExplode()  untyped {
		// never explodes
	}


	/*------------------------------------------------------------------------
	INFIXE DE STEPPING
	------------------------------------------------------------------------*/
	override public function infix()  untyped {
		super.infix();
		var id:Dynamic = world?.getCase( {x:cx,y:cy} ) ;
		if ( id==RootData.FIELD_GOAL_1 ) {
			((game):Dynamic)?.goal(1);
			destroy();
		}
		if ( id==RootData.FIELD_GOAL_2 ) {
			((game):Dynamic)?.goal(0);
			destroy();
		}
	}


	/*------------------------------------------------------------------------
	UPDATE GRAPHIQUE
	------------------------------------------------------------------------*/
	override public function endUpdate()  untyped {
		super.endUpdate();
		{ if (sub != null) sub._rotation += dx*5; }
		if ( dx>0 ) {
			{ if (sub != null) sub._xscale = -Math.abs(sub?._xscale); }
		}
		if ( dx<0 ) {
			{ if (sub != null) sub._xscale = Math.abs(sub?._xscale); }
		}

	}


	/*------------------------------------------------------------------------
	EVENT: TOUCHE UN MUR
	------------------------------------------------------------------------*/
	override public function onHitWall()  untyped {
		var ocx:Dynamic = Entity.x_rtc(oldX);
		var ocy:Dynamic = Entity.y_rtc(oldY);
		if ( world?.getCase( {x:ocx,y:ocy} ) != RootData.GROUND ) {
			dx = -dx;
			if ( Math.abs(dx)>7 ) {
				game?.fxMan?.inGameParticlesDir( RootData.PARTICLE_DUST, x,y, MtStd.random(5)+1, dx);
			}
		}

	}


	/*------------------------------------------------------------------------
	MAIN
	------------------------------------------------------------------------*/
	override public function update()  untyped {
		speed = Math.sqrt( Math.pow(dx,2) + Math.pow(dy,2) );
		animFactor = 0.5 * speed/TOP_SPEED ;
		fl_airKick = true;

		if ( burnTimer>0 ) {
			game?.fxMan?.inGameParticles(RootData.PARTICLE_SPARK, x,y,MtStd.random(3));
			var fx:Dynamic = game?.fxMan?.attachFx(
				x + MtStd.random(5)*(MtStd.random(2)*2-1),
				y - MtStd.random(20),
				"hammer_fx_ballBurn"
			);
			var ratio:Dynamic = Math.min(1,speed/TOP_SPEED);
			{ if (fx?.mc != null) fx.mc._xscale = 100 * ratio; }
			{ if (fx?.mc != null) fx.mc._yscale = fx?.mc?._xscale; }
			burnTimer-=Timer.tmod;
		}
		super.update();
	}
}


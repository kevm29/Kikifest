// Converti automatiquement depuis hammer/entity/bad/ww/Saw.mt (Motion Twin)
package entity.bad.ww;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
import Data as RootData;
class Saw extends entity.bad.WallWalker
{
	public static var ROTATION_RECAL:Float	= 0.3;
	public static var STUN_DURATION	= RootData.SECOND*3;
	public static var BASE_SPEED:Int		= 3;
	public static var ROTATION_SPEED:Int	= 10;

	public var fl_stun				: Bool;
	public var fl_stop				: Bool;
	public var fl_updateSpeed		: Bool;
	public var stunTimer			: Float;
	public var rotSpeed			: Float;


	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new()  untyped {
		super() ;
		speed				= BASE_SPEED;
		angerFactor			= 0;
		subOffset			= 2;
		rotSpeed			= 0;
		fl_stun				= false;
		fl_stop				= false;
		fl_updateSpeed		= false;
	}


	/*------------------------------------------------------------------------
	INITIALISATION
	------------------------------------------------------------------------*/
	override public function init(g:Dynamic)  untyped {
		super.init(g);
		unregister(RootData.BAD_CLEAR);
	}



	/*------------------------------------------------------------------------
	INITIALISATION BAD
	------------------------------------------------------------------------*/
	override public function initBad(g:Dynamic,x:Dynamic,y:Dynamic)  untyped {
		super.initBad(g,x,y);
		scale(80);
	}


	/*------------------------------------------------------------------------
	ATTACHEMENT
	------------------------------------------------------------------------*/
	public static function attach(g:mode.GameMode,x:Dynamic,y:Dynamic)  untyped {
		var linkage:Dynamic = RootData.LINKAGES[RootData.BAD_SAW];
		var mc : entity.bad.ww.Saw = (( g.depthMan.attach(linkage,RootData.DP_BADS) ):Dynamic) ;
		mc?.initBad(g,x,y) ;
		return mc ;
	}


	/*------------------------------------------------------------------------
	INTERRUPTION
	------------------------------------------------------------------------*/
	public function stun()  untyped {
		if ( fl_stop ) {
			return;
		}
		game?.fxMan?.attachExplosion( x,y-RootData.CASE_HEIGHT*0.5, 30);
		if ( !fl_stun ) {
			game?.fxMan?.inGameParticlesDir( RootData.PARTICLE_METAL, x,y, 5, dx);
			game?.fxMan?.inGameParticlesDir( RootData.PARTICLE_STONE, x,y, MtStd.random(4), dx);
		}
		fl_stun		= true;
		fl_wallWalk	= false;
		stunTimer	= STUN_DURATION;
		dx			= 0;
		dy			= 0;
	}


	/*------------------------------------------------------------------------
	ARRÊT / MARCHE
	------------------------------------------------------------------------*/
	public function halt()  untyped {
		if ( fl_stop ) {
			return;
		}
		fl_stop		= true;
		fl_wallWalk	= false;
		dx			= 0;
		dy			= 0;
	}

	public function run()  untyped {
		if ( !fl_stop ) {
			return;
		}
		fl_stop		= false;
		fl_wallWalk	= true;
		updateSpeed();
	}


	/*------------------------------------------------------------------------
	RENVOIE TRUE SI "EN BONNE SANTÉ"
	------------------------------------------------------------------------*/
	override public function isHealthy()  untyped {
		return !fl_kill && !fl_stun && !fl_stop;
	}


	/*------------------------------------------------------------------------
	TOUCHE UNE ENTITÉ
	------------------------------------------------------------------------*/
	override public function hit(e:Dynamic)  untyped {
		if ( isHealthy() ) {
			if ( e?.isType(RootData.PLAYER) ) {
				game?.fxMan?.inGameParticles( RootData.PARTICLE_CLASSIC_BOMB, x,y, MtStd.random(5)+3 );
			}
		}

		super.hit(e);

		if ( isHealthy() ) {

			if ( e?.isType(RootData.BOMB) && !e?.isType(RootData.BAD_BOMB) ) {
				var b : entity.Bomb = ((e):Dynamic);
				b?.setLifeTimer(RootData.SECOND*0.6);
				{ if (b != null) b.dx = (dx!=0 )		? -dx		: -cp?.x*4; }
				{ if (b != null) b.dy = (cp?.y!=0)	? -cp?.y*13	: -8; }
				game?.fxMan?.inGameParticlesDir( RootData.PARTICLE_SPARK, b?.x,b?.y, 2, b?.dx );
			}

//			if ( e.isType(Data.BAD_CLEAR) ) {
//				downcast(e).killHit(-dx);
//			}
		}
	}

	/*------------------------------------------------------------------------
	MODE GRAVITÉ "NORMALE" DES WALLWALKERS DÉSACTIVÉ
	------------------------------------------------------------------------*/
	override public function land()  untyped {
		// do nothing
	}


	/*------------------------------------------------------------------------
	IMMORTALITÉ
	------------------------------------------------------------------------*/
	override public function killHit(dx:Dynamic)  untyped {
		stun();
	}
	override public function knock(d:Dynamic)  untyped {
		stun();
	}
	override public function freeze(d:Dynamic)  untyped {
		stun();
	}


	/*------------------------------------------------------------------------
	EVENT: RÉVEIL
	------------------------------------------------------------------------*/
	override public function onWakeUp()  untyped {
		// specific to stun effect
		fl_wallWalk	= true;
		moveToSafePos();
		updateSpeed();
		game?.fxMan?.inGameParticles( RootData.PARTICLE_STONE, x,y, 3);
	}


	/*------------------------------------------------------------------------
	UPDATE GRAPHIQUE
	------------------------------------------------------------------------*/
	override public function endUpdate()  untyped {
		super.endUpdate();
		if ( fl_stun ) {
			var f:Dynamic = 1-stunTimer/STUN_DURATION;
			_x = x + f*(MtStd.random(20)/10) * (MtStd.random(2)*2-1);
			_y = y + f*(MtStd.random(20)/10) * (MtStd.random(2)*2-1);
		}
		if ( fl_wallWalk || fl_stop ) {
			var ang:Dynamic = Math.atan2( cp?.y,cp?.x );
			var angDeg:Dynamic = 180 * ang/Math.PI - 90;
			var delta:Dynamic = angDeg-sub?._rotation;
			if ( delta<-180 ) {
				delta+=360;
			}
			if ( delta>180 ) {
				delta-=360;
			}
			{ if (sub != null) sub._rotation += (delta)*ROTATION_RECAL; }
		}
		else {
			if ( fl_kill ) {
				{ if (sub != null) sub._rotation += Timer.tmod*14.5; }
			}
			else {
				if ( isHealthy() ) {
					{ if (sub != null) sub._rotation += (0-sub?._rotation)*(ROTATION_RECAL*0.25); }
				}
			}
		}

		if ( fl_stop || fl_stun ) {
			rotSpeed *= 0.9;
		}
		else {
			rotSpeed = Math.min(ROTATION_SPEED, rotSpeed+Timer.tmod);
		}
		((sub):Dynamic).sub._rotation += rotSpeed;
	}



	/*------------------------------------------------------------------------
	MAIN
	------------------------------------------------------------------------*/
	override public function update()  untyped {

		// Controle par variables dynamiques
		var dyn_sp:Dynamic = game?.getDynamicInt("$SAW_SPEED");
		var old:Dynamic = speed;
		if ( MtStd.isNaN(dyn_sp) || dyn_sp<0 ) {
			speed = BASE_SPEED;
			run();
		}
		else {
			if ( dyn_sp==0 ) {
				halt();
			}
			else {
				speed = dyn_sp;
				run();
			}
		}
		if ( old!=speed ) {
			fl_updateSpeed = true;
		}

		if ( fl_updateSpeed && isHealthy() ) {
			fl_updateSpeed = false;
			updateSpeed();
		}



		if ( fl_stop || fl_stun ) {
			dx = 0;
			dy = 0;
		}

		if ( fl_stun ) {
			if ( MtStd.random(10)==0 ) {
				game?.fxMan?.inGameParticles(RootData.PARTICLE_SPARK, x,y, 1);
			}
			stunTimer-=Timer.tmod;
			if ( stunTimer<=0 ) {
				fl_stun = false;
				onWakeUp();
			}
		}
		super.update();
	}

}



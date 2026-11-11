// Converti automatiquement depuis hammer/entity/fx/Particle.mt (Motion Twin)
package entity.fx;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
import Data as RootData;
class Particle extends entity.Mover
{

	public var bounce		: Float ;
	// (déjà déclaré dans la classe parente) public var sub			: MovieClip;
	public var subFrame	: Int;
	public var skipWallsY	: Float;
	public var pid			: Int;



	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new()  untyped {
		super() ;
		setLifeTimer(RootData.SECOND*2 + (RootData.SECOND*2)*MtStd.random(100)/100);
		disableAnimator();
	}


	/*------------------------------------------------------------------------
	INITIALISATION
	------------------------------------------------------------------------*/
	override public function init(g:Dynamic)  untyped {
		super.init(g) ;
		register(RootData.FX);
	}


	/*------------------------------------------------------------------------
	INITIALISATION
	------------------------------------------------------------------------*/
	public function initParticle(g:Dynamic,frame:Dynamic,x:Dynamic,y:Dynamic)  untyped {
		init(g) ;
		pid = frame;

		if ( pid!=RootData.PARTICLE_RAIN ) {
			bounce = MtStd.random(65)/10 + 1.5 ;
			setNext(
				(1+MtStd.random(50)/10) * (MtStd.random(2)*2-1),
				-bounce,
				0, RootData.ACTION_MOVE
			);
		}

		this.gotoAndStop(""+pid);
		subFrame = MtStd.random(sub?._totalframes)+1;
		sub?.gotoAndStop(""+subFrame);

		scale(MtStd.random(50)+50);
		rotation = MtStd.random(360);

		moveTo(x,y) ;
		skipWallsY = y;
		bounceFactor = 0.6;

		{ var __sw:Dynamic = pid;
if (__sw == (RootData.PARTICLE_SPARK)) {
				scale( scaleFactor*100 * 2 );
				updateLifeTimer( RootData.SECOND );
			
			}
else if (__sw == (RootData.PARTICLE_STONE)) {
				scale(scaleFactor*150);
			
			}
else if (__sw == (RootData.PARTICLE_RAIN)) {
				_yscale		= 10;
				rotation	= 5;
				alpha		= MtStd.random(70)+30;
			
			}
else if (__sw == (RootData.PARTICLE_METAL)) {
				scale( MtStd.random(40)+80 );
				bounceFactor = 0.3;
			
			}
else if (__sw == (RootData.PARTICLE_LITCHI)) {
				bounceFactor = 0.4;
			
			}
else if (__sw == (RootData.PARTICLE_BUBBLE)) {
				fl_gravity	= false;
				fl_hitCeil	= true;
				fl_blink	= false;
				_alpha		= MtStd.random(80)+20;
				moveUp( 0.3 + MtStd.random(10)/10 );
				scale( MtStd.random(40)+30 );
				next = null;
				updateLifeTimer( RootData.SECOND + MtStd.random(RootData.SECOND*20)/10 );
			
			}
else if (__sw == (RootData.PARTICLE_ICE_BAD)) {
				bounceFactor = 0.5;
				{ if (next != null) next.dx *= 0.3; }
				{ if (next != null) next.dy = -Math.abs(next?.dy); }
			
			}
else if (__sw == (RootData.PARTICLE_BLOB)) {
				gravityFactor	= 0.6;
				fallFactor		= gravityFactor;
				updateLifeTimer(RootData.SECOND*3);
				fl_blink		= false;
			
		}
}

		endUpdate() ;
	}


	/*------------------------------------------------------------------------
	CONTACT
	------------------------------------------------------------------------*/
	override public function hit(e:Dynamic)  untyped {
		if ( pid!=RootData.PARTICLE_RAIN ) {
			return;
		}
		if ( (e?.types&RootData.PLAYER)>0 ) {
			if ( !((e):Dynamic)?.fl_shield ) {
				e?.scale( 100*e?.scaleFactor-1 );
				destroy();
			}
		}
	}


	/*------------------------------------------------------------------------
	PRÉFIXE
	------------------------------------------------------------------------*/
	override public function prefix()  untyped {
		if ( y>skipWallsY ) {
			fl_hitWall = true;
		}
		else {
			fl_hitWall = false;
		}
		super.prefix();
	}


	/*------------------------------------------------------------------------
	POSTFIXE
	------------------------------------------------------------------------*/
	override public function postfix()  untyped {
		fl_friction = false ;
	}


	/*------------------------------------------------------------------------
	EVENT: TOUCHE LE SOL
	------------------------------------------------------------------------*/
	override public function onHitGround(h:Dynamic)  untyped {
		if ( pid==RootData.PARTICLE_BLOB ) {
			recal();
			dx = 0;
			dy = 0;
			fl_gravity = false;
//			game.fxMan.attachExplosion(x,y,Std.random(10)+10);
//			destroy();
//			return;
		}
		if ( pid==RootData.PARTICLE_RAIN ) {
			recal();
			var fx:Dynamic = game?.fxMan?.attachFx(x,y,"hammer_fx_water_drop");
			{ if (fx?.mc != null) fx.mc._alpha = MtStd.random(50)+10; }
			{ if (fx?.mc != null) fx.mc._xscale = 100*(MtStd.random(2)*2-1); }
			destroy();
			return;
		}

		skipWallsY = 0;
		fl_hitWall = true;

		setNext(dx,-dy*bounceFactor, 0, RootData.ACTION_MOVE) ;
		if ( Math.abs(next?.dy)<=1.5 ) {
			{ if (next != null) next.dx*=game?.gFriction ; }
		}
		fl_skipNextGravity = true ;
		super.onHitGround(h) ;

	}


	override public function onHitCeil()  untyped {
		destroy();
	}


	/*------------------------------------------------------------------------
	EVENT: TOUCHE UN MUR
	------------------------------------------------------------------------*/
	override public function onHitWall()  untyped {
		if ( fl_hitWall ) {
			if ( pid==RootData.PARTICLE_BLOB ) {
				dx = 0;
			}
			else {
				dx = -dx*0.5;
			}
		}
	}


	/*------------------------------------------------------------------------
	EVENT: LIGNE DU BAS
	------------------------------------------------------------------------*/
	override public function onDeathLine()  untyped {
		destroy() ;
	}


	/*------------------------------------------------------------------------
	ATTACHEMENT
	------------------------------------------------------------------------*/
	public static function attach(g:mode.GameMode,frame:Dynamic,x:Dynamic,y:Dynamic)  untyped {
		var linkage:Dynamic = "hammer_fx_particle" ;
		var mc : entity.fx.Particle = (( g.depthMan.attach(linkage,RootData.DP_BADS) ):Dynamic) ;
		mc?.initParticle(g,frame,x,y) ;
		return mc ;
	}



	/*------------------------------------------------------------------------
	UPDATE GRAPHIQUE
	------------------------------------------------------------------------*/
	override public function endUpdate()  untyped {
		if ( pid==RootData.PARTICLE_RAIN ) {
			_yscale = Math.min( 100, _yscale+Timer.tmod*4 );
			rotation *= 0.93;
		}
		else {
			rotation+=dx*2 ;
		}

		super.endUpdate() ;

		if ( pid==RootData.PARTICLE_BUBBLE && totalLife>0 ) {
			_alpha = Math.min(100, 150 * lifeTimer / totalLife);
		}

		if ( pid==RootData.PARTICLE_BLOB && totalLife>0 ) {
			_xscale = 100 * scaleFactor * Math.min(1, 1.5 * lifeTimer / totalLife);
			_yscale = _xscale;
		}
	}



	/*------------------------------------------------------------------------
	MAIN
	------------------------------------------------------------------------*/
	override public function update()  untyped {
		if ( Math.abs(dx)<=0.5 && pid!=RootData.PARTICLE_BLOB ) {
			lifeTimer-=Timer.tmod;
			if ( lifeTimer<=0 ) {
				onLifeTimer();
			}
		}
		super.update();
	}

}


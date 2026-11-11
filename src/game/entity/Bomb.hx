// Converti automatiquement depuis hammer/entity/Bomb.mt (Motion Twin)
package entity;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
import Data as RootData;
class Bomb extends entity.Mover
{

	public var radius		: Float;
	public var power		: Float;
	public var duration	: Float;

	public var fl_explode	: Bool;
	public var fl_airKick	: Bool;
	public var fl_bumped	: Bool;

	public var explodeSound: String;


	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new()  untyped {
		super();

		explodeSound	 = "sound_bomb";

		radius		= RootData.CASE_WIDTH*3;
		power		= 0;
		duration	= 0;

		fl_slide	= false;
		fl_bounce	= false;
		fl_teleport = true;
		fl_wind		= true;
		fl_blink	= false;
		fl_explode	= false;
		fl_airKick	= false;
		fl_portal	= true;
		fl_bump		= true;
		fl_bumped	= false; // true si a passé un bumper au - une fois
		fl_strictGravity	= false;
		slideFriction		= 0.98;
	}


	/*------------------------------------------------------------------------
	INITIALISATION
	------------------------------------------------------------------------*/
	public function initBomb(g:Dynamic, x:Dynamic,y:Dynamic )  untyped {
		init(g);
		register(RootData.BOMB);
		moveTo(x,y);
		setLifeTimer(duration);
		updateCoords();
		playAnim( RootData.ANIM_BOMB_DROP );
	}


	/*------------------------------------------------------------------------
	AUTORISE L'APPLICATION DU PATCH COLLISION AU SOL (ESCALIERS)
	------------------------------------------------------------------------*/
	override public function needsPatch()  untyped {
		return true;
	}



	/*------------------------------------------------------------------------
	RENVOIE LES ENTITÉS AFFECTÉES PAR LA BOMBE
	------------------------------------------------------------------------*/
	public function bombGetClose(type:Dynamic):Array<Entity>  untyped {
		return game?.getClose(type, x,y, radius, fl_stable);
	}


	/*------------------------------------------------------------------------
	EVENT: EXPLOSION
	------------------------------------------------------------------------*/
	public function onExplode()  untyped {
		playAnim( RootData.ANIM_BOMB_EXPLODE );
		if ( explodeSound!=null ) {
			game?.soundMan?.playSound(explodeSound,RootData.CHAN_BOMB);
		}
		rotation = 0;
		fl_physics = false;
		fl_explode = true;
	}


	/*------------------------------------------------------------------------
	EVENT: FIN D'ANIM
	------------------------------------------------------------------------*/
	override public function onEndAnim(id:Dynamic)  untyped {
		super.onEndAnim(id);
		if ( id==RootData.ANIM_BOMB_DROP.id ) {
			playAnim(RootData.ANIM_BOMB_LOOP);
		}
		if ( id==RootData.ANIM_BOMB_EXPLODE.id ) {
			destroy();
		}
	}


	/*------------------------------------------------------------------------
	MISE À JOUR GRAPHIQUE
	------------------------------------------------------------------------*/
	override public function endUpdate()  untyped {
		if ( !fl_stable ) {
			var ang:Dynamic = 30;
			if ( dx>0 ) {
				rotation += 0.02*(ang-rotation);
			}
			else {
				rotation -= 0.02*(ang-rotation);
			}
			rotation = Math.max(-ang,Math.min(ang,rotation));
		}
		super.endUpdate();
	}


	/*------------------------------------------------------------------------
	EVENT: TIMER DE VIE
	------------------------------------------------------------------------*/
	override public function onLifeTimer()  untyped {
		stopBlink();
		onExplode();
	}


	/*------------------------------------------------------------------------
	EVENT: LIGNE DU BAS
	------------------------------------------------------------------------*/
	override public function onDeathLine()  untyped {
		super.onDeathLine();
		destroy();
	}

	public function onKick(p:entity.Player)  untyped {
		// do nothing
	}


	/*------------------------------------------------------------------------
	EVENT: TOUCHE UN MUR
	------------------------------------------------------------------------*/
	override public function onHitWall()  untyped {
		if ( fl_bumped ) {
			dx = -dx*0.7;
		}
		else {
			super.onHitWall();
		}
	}


	/*------------------------------------------------------------------------
	EVENT: PORTAL
	------------------------------------------------------------------------*/
	override public function onPortal(pid:Dynamic)  untyped {
		super.onPortal(pid);
		game?.fxMan?.attachFx(x,y-RootData.CASE_HEIGHT*0.5,"hammer_fx_shine");
		destroy();
	}

	/*------------------------------------------------------------------------
	EVENT: PORTAL FERMÉ
	------------------------------------------------------------------------*/
	override public function onPortalRefusal()  untyped {
		super.onPortalRefusal();
		dx = -dx*3;
		dy = -5;
		game?.fxMan?.inGameParticles( RootData.PARTICLE_PORTAL, x,y,5 );
	}


	/*------------------------------------------------------------------------
	EVENT: BUMPER
	------------------------------------------------------------------------*/
	override public function onBump()  untyped {
		fl_bumped = true;
	}


	/*------------------------------------------------------------------------
	DUPLIQUE LA BOMBE EN COURS
	------------------------------------------------------------------------*/
	public function duplicate():entity.Bomb  untyped {
		return null ; // do nothing
	}

}


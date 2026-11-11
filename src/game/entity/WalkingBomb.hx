// Converti automatiquement depuis hammer/entity/WalkingBomb.mt (Motion Twin)
package entity;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
import Data as RootData;
class WalkingBomb extends entity.Physics
{
	public var left			: Int;
	public var right			: Int;

	public var fl_knock		: Bool;
	public var knockTimer		: Float;
	public var realBomb		: entity.bomb.PlayerBomb;
	public var fl_unstable		: Bool; // comportement bombe verte

	public var dir				: Int;

	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new()  untyped {
		super();

		left	= Key.PGUP;
		right	= Key.PGDN;
		dir		= 1;

		fl_slide		= false;
		fl_teleport		= true;
		fl_wind			= true;
		fl_blink		= false;
		fl_portal		= true;
		fl_unstable		= false;

		fl_knock		= false;
	}

	/*------------------------------------------------------------------------
	ATTACHEMENT
	------------------------------------------------------------------------*/
	public static function attach(g:mode.GameMode, b:entity.bomb.PlayerBomb)  untyped {
		var linkage:Dynamic = "hammer_player_wbomb" ;
		var mc : entity.WalkingBomb = (( g.depthMan.attach(linkage,RootData.DP_BOMBS) ):Dynamic) ;
		mc?.initBomb(g, b) ;
		return mc ;
	}


	/*------------------------------------------------------------------------
	INITIALISATION
	------------------------------------------------------------------------*/
	public function initBomb(g:Dynamic, b:Dynamic)  untyped {
		init(g);
		register(RootData.BOMB);

		realBomb = b;
		moveTo(realBomb?.x, realBomb?.y);
		setLifeTimer(b?.lifeTimer);
		dx = realBomb?.dx;
		dy = realBomb?.dy;
		fl_unstable = realBomb?.fl_unstable;

		updateCoords();
		playAnim( RootData.ANIM_WBOMB_STOP );
	}


	/*------------------------------------------------------------------------
	AUTORISE L'APPLICATION DU PATCH COLLISION AU SOL (ESCALIERS)
	------------------------------------------------------------------------*/
	override public function needsPatch()  untyped {
		return true;
	}


	/*------------------------------------------------------------------------
	DÉTRUIT LA WALKING ET LA BOMBE RÉELLE
	------------------------------------------------------------------------*/
	public function destroyBoth()  untyped {
		realBomb?.destroy();
		destroy();
	}


	/*------------------------------------------------------------------------
	CONTACT
	------------------------------------------------------------------------*/
	override public function hit(e:Dynamic)  untyped {
		super.hit(e);
		if ( fl_unstable && (e?.types&RootData.BAD)>0 ) {
			onExplode() ;
		}
	}


	/*------------------------------------------------------------------------
	EVENT: LIGNE DU BAS
	------------------------------------------------------------------------*/
	override public function onDeathLine()  untyped {
		super.onDeathLine();
		destroyBoth();
	}


	/*------------------------------------------------------------------------
	EVENT: KICKÉE
	------------------------------------------------------------------------*/
	public function onKick(p:entity.Player)  untyped {
		fl_stable = false;
	}


	/*------------------------------------------------------------------------
	EVENT: PORTAL
	------------------------------------------------------------------------*/
	override public function onPortal(pid:Dynamic)  untyped {
		super.onPortal(pid);
		game?.fxMan?.attachFx(x,y-RootData.CASE_HEIGHT*0.5,"hammer_fx_shine");
		destroyBoth();
	}

	/*------------------------------------------------------------------------
	EVENT: PORTAL FERMÉ
	------------------------------------------------------------------------*/
	override public function onPortalRefusal()  untyped {
		super.onPortalRefusal();
		knock(RootData.SECOND);
		dx = -dx*3;
		dy = -5;
		game?.fxMan?.inGameParticles( RootData.PARTICLE_PORTAL, x,y,5 );
	}


	/*------------------------------------------------------------------------
	EVENT: FIN DE TIMER DE VIE
	------------------------------------------------------------------------*/
	override public function onLifeTimer()  untyped {
		onExplode();
		super.onLifeTimer();
	}


	/*------------------------------------------------------------------------
	EVENT: EXPLOSION
	------------------------------------------------------------------------*/
	public function onExplode()  untyped {
		realBomb?.moveTo(x,y);
		realBomb?.updateCoords();
		realBomb?.onExplode();
		destroy();
	}


	/*------------------------------------------------------------------------
	EVENT: TOUCHE LE SOL
	------------------------------------------------------------------------*/
	override public function onHitGround(h:Dynamic)  untyped {
		super.onHitGround(h);
		if ( fl_unstable && h>=10) {
			onExplode();
		}
	}


	/*------------------------------------------------------------------------
	EVENT: TOUCHE UN MUR
	------------------------------------------------------------------------*/
	override public function onHitWall()  untyped {
		if ( fl_stable ) {
			// gauche
			if ( Key.isDown(left) && world?.checkFlag( {x:cx,y:cy}, RootData.IA_CLIMB_LEFT) ) {
				var h:Dynamic = world?.getWallHeight( cx-1,cy, RootData.IA_CLIMB );
				if ( h<=1 ) {
					jump( RootData.BAD_VJUMP_X_CLIFF, RootData.BAD_VJUMP_Y_LIST[0] );
					centerInCase();
				}
			}
			// droite
			if ( Key.isDown(right) && world?.checkFlag( {x:cx,y:cy}, RootData.IA_CLIMB_RIGHT) ) {
				var h:Dynamic = world?.getWallHeight( cx+1,cy, RootData.IA_CLIMB );
				if ( h<=1 ) {
					jump( RootData.BAD_VJUMP_X_CLIFF, RootData.BAD_VJUMP_Y_LIST[0] );
					centerInCase();
				}
			}
		}
	}


	/*------------------------------------------------------------------------
	CONTRÔLES
	------------------------------------------------------------------------*/
	public function getControls()  untyped {
		// *** Gauche
		if ( Key.isDown(left) ) {
			dx=-RootData.WBOMB_SPEED;
			dir = -1;
			if ( fl_stable ) {
				playAnim(RootData.ANIM_WBOMB_WALK);
			}
		}

		// *** Droite
		if ( Key.isDown(right) ) {
			dx=RootData.WBOMB_SPEED;
			dir = 1;
			if ( fl_stable ) {
				playAnim(RootData.ANIM_WBOMB_WALK);
			}
		}

		// Anim d'arrêt
		if ( !Key.isDown(left) && !Key.isDown(right) ) {
			dx*=game?.gFriction*0.9;
			if ( animId==RootData.ANIM_WBOMB_WALK.id ) {
				playAnim(RootData.ANIM_WBOMB_STOP);
			}
		}
	}


	/*------------------------------------------------------------------------
	ASSOME LA BOMBE
	------------------------------------------------------------------------*/
	public function knock(d:Dynamic)  untyped {
		fl_knock = true;
		knockTimer = d;
		playAnim(RootData.ANIM_WBOMB_STOP);
	}


	/*------------------------------------------------------------------------
	UPDATE GRAPHIQUE
	------------------------------------------------------------------------*/
	override public function endUpdate()  untyped {
		super.endUpdate();
		this._xscale = dir*Math.abs(this._xscale) ;
	}


	/*------------------------------------------------------------------------
	INFIXE DE STEPPING
	------------------------------------------------------------------------*/
	override public function infix()  untyped {
		super.infix();

		// Auto jump horizontal
		if ( fl_stable ) {
			// gauche
			if ( world?.checkFlag( {x:cx,y:cy}, RootData.IA_JUMP_LEFT) && dx<0 ) {
				jump(RootData.BAD_HJUMP_X, RootData.BAD_HJUMP_Y);
//				adjustToRight();
			}
			// droite
			if ( world?.checkFlag( {x:cx,y:cy}, RootData.IA_JUMP_RIGHT) && dx>0 ) {
				jump(RootData.BAD_HJUMP_X, RootData.BAD_HJUMP_Y);
//				adjustToLeft();
			}
		}

	}


	/*------------------------------------------------------------------------
	VÉRIFIE SI UN ESCALIER EST PRÉSENT ET S'IL PEUT ÊTRE MONTÉ
	------------------------------------------------------------------------*/
	public function checkClimb()  untyped {
	}


	/*------------------------------------------------------------------------
	SAUT !
	------------------------------------------------------------------------*/
	public function jump(jx:Dynamic,jy:Dynamic)  untyped {
		dx = dir*jx;
		dy = -jy;
		fl_stable = false;
	}


	/*------------------------------------------------------------------------
	MAIN
	------------------------------------------------------------------------*/
	override public function update()  untyped {
		// Inhibe la bombe réelle
		{ if (realBomb != null) realBomb.y = -1500; }
		{ if (realBomb != null) realBomb.lifeTimer = RootData.SECOND*10; }

		if ( fl_knock && knockTimer>0 ) {
			knockTimer-=Timer.tmod;
			if ( knockTimer<=0 ) {
				fl_knock = false;
			}
		}

		if ( fl_stable && !fl_knock ) {
			getControls();
		}
		else {
			if ( animId==RootData.ANIM_WBOMB_WALK.id ) {
				playAnim(RootData.ANIM_WBOMB_STOP);
			}
		}

		super.update();

		if ( realBomb?._name==null ) {
			destroy();
		}
	}

}




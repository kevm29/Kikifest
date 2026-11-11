// Converti automatiquement depuis hammer/entity/bad/FireBall.mt (Motion Twin)
package entity.bad;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
import Data as RootData;
class FireBall extends entity.Bad
{
	public var eyes : MovieClip ;
	public var body : MovieClip ;

	public var ang : Float ;
	public var tang : Float ;
	public var speed : Float ;
	public var angSpeed : Float ;

	public var angerTimer : Float ;
	public var summonTimer : Float ;
	public var fl_summon : Bool ;

	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new()  untyped {
		super() ;
		disableAnimator() ;
		fl_hitGround = false ;
		fl_hitWall = false ;
		fl_gravity = false ;
		fl_hitBorder = false ;

		fl_alphaBlink = true;

		speed		= 2.5 ;
		angSpeed	= 1.5 ;
		ang			= 270 ;

		summonTimer = 85 ;
		fl_summon = true ;
		blink(RootData.BLINK_DURATION) ;

		angerTimer = 0 ;
		angerFactor = 0.05 ;
		maxAnger = 9999;
	}


	/*------------------------------------------------------------------------
	INITIALISATION
	------------------------------------------------------------------------*/
	override public function init(g:Dynamic)  untyped {
		super.init(g) ;
		register( RootData.HU_BAD ) ;
		unregister( RootData.BAD_CLEAR );
	}


	/*------------------------------------------------------------------------
	ATTACHEMENT
	------------------------------------------------------------------------*/
	public static function attach(g:mode.GameMode, p:entity.Player)  untyped {
		var linkage:Dynamic = RootData.LINKAGES[RootData.BAD_FIREBALL]; 
		var mc : entity.bad.FireBall = (( g.depthMan.attach(linkage,RootData.DP_BADS) ):Dynamic) ;
		var n:Dynamic = g?.countList(RootData.PLAYER);
		var offs:Dynamic = (n==1) ? 0 : -30+p?.pid*60;

		mc?.initBad( g, RootData.GAME_WIDTH/2+offs, RootData.GAME_HEIGHT+10 );
		mc?.hate(p);
		return mc ;
	}


	/*------------------------------------------------------------------------
	ANNULATION D'EVENT
	------------------------------------------------------------------------*/
	override public function playAnim(o:Dynamic)  untyped {
		// do nothing
	}
	override public function freeze(d:Dynamic)  untyped {
		// do nothing
	}
	override public function knock(d:Dynamic)  untyped {
		// do nothing
	}
	override public function killHit(dx:Dynamic)  untyped {
		// do nothing
	}


	/*------------------------------------------------------------------------
	AJOUT SUPPLÉMENTAIRE DANS LES LISTES D'INVENTAIRE
	------------------------------------------------------------------------*/

	override public function tAdd(cx:Dynamic,cy:Dynamic)  untyped {
		super.tAdd(cx,cy) ;
		tAddSingle(cx,cy+1) ;
	}
	override public function tRem(cx:Dynamic,cy:Dynamic)  untyped {
		super.tRem(cx,cy) ;
		tRemSingle(cx,cy+1) ;
	}



	/*------------------------------------------------------------------------
	MISE À JOUR GRAPHIQUE
	------------------------------------------------------------------------*/
	override public function endUpdate()  untyped {
		super.endUpdate() ;
		{ if (body != null) body._rotation = ang ; }
		eyes?.gotoAndStop( ""+ (Math.round(ang/360*eyes?._totalframes)+1) ) ;
	}


	/*------------------------------------------------------------------------
	INTÉRACTION
	------------------------------------------------------------------------*/
	override public function hit(e:Entity)  untyped {
		if ( fl_summon ) {
			return ;
		}

		if ( (e?.types&RootData.PLAYER)>0 ) {
			var et : entity.Player = ((e):Dynamic) ;
			if ( et?.animId!=RootData.ANIM_PLAYER_DIE.id ) {
				{ if (et != null) et.fl_shield = false ; }
				et?.killHit(dx) ;
			}
		}

		if ( (e?.types&RootData.BOMB)>0 ) {
			var b : entity.Bomb = ((e):Dynamic) ;

			if (!b?.fl_kill && !b?.fl_explode) {
				b?.onExplode() ;
			}
		}
	}

	/*------------------------------------------------------------------------
	EFFETS DE L'ENERVEMENT
	------------------------------------------------------------------------*/
	override public function angerMore()  untyped {
		super.angerMore();
		angSpeed*=1.15;
	}


	/*------------------------------------------------------------------------
	EVENT: HURRY UP!
	------------------------------------------------------------------------*/
	override public function onHurryUp()  untyped {
		// do nothing
	}
	override public function onDeathLine()  untyped {
		// do nothing
	}


	/*------------------------------------------------------------------------
	MAIN
	------------------------------------------------------------------------*/
	override public function update()  untyped {
		// Mal d'invocation
		if ( fl_summon ) {
			summonTimer-=Timer.tmod ;
			if ( summonTimer<=0 ) {
				fl_summon = false ;
				stopBlink() ;
			}
		}

		// Mort de la cible
		if ( player?.fl_kill || player?._name==null) {
			game?.fxMan?.attachShine(x,y) ;
			game?.fxMan?.attachExplodeZone(x,y,4*RootData.CASE_WIDTH) ;
			game?.shake(RootData.SECOND*1,5);
			destroy() ;
			return ;
		}

		// Auto-énervement
		angerTimer+=Timer.tmod*game?.diffFactor;
		if ( angerTimer>=RootData.AUTO_ANGER ) {
			angerTimer = 0 ;
			angerMore() ;
		}

		// Angle vers la cible
		tang = Math.atan2( player?.y-y, player?.x-x ) ;
		tang = adjustAngle( tang*180/Math.PI ) ;

		// Recalage des angles trop grands
		if ( ang-tang>180 ) {
			ang-=360 ;
		}
		if ( tang-ang>180 ) {
			ang+=360 ;
		}

		// Vise le player
		if ( ang<tang ) {
			ang+=angSpeed*speedFactor*Timer.tmod ;
			if ( ang>tang )
			ang = tang ;
		}
		if ( ang>tang ) {
			ang-=angSpeed*speedFactor*Timer.tmod ;
			if ( ang<tang )
			ang = tang ;
		}

		// Déplacement
		ang = adjustAngle(ang) ;
		moveToAng(ang,speed*speedFactor) ;

		super.update() ;
	}

}



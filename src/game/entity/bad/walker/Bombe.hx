// Converti automatiquement depuis hammer/entity/bad/walker/Bombe.mt (Motion Twin)
package entity.bad.walker;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
import Data as RootData;
class Bombe extends entity.bad.Jumper
{
	public static var RADIUS			= RootData.CASE_WIDTH*5;
	public static var EXPERT_RADIUS	= RootData.CASE_WIDTH*8;
	public static var POWER:Int			= 30;

	public var fl_overheat	: Bool;

	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new()  untyped {
		super() ;
		setJumpUp(10) ;
		setJumpDown(6) ;
		setJumpH(100) ;
		setClimb(100,3);
//		setFall(50);
		fl_alphaBlink	= false;
		fl_overheat		= false;
		blinkColor		= 0xff9e5e;
		blinkColorAlpha	= 50;
	}


	/*------------------------------------------------------------------------
	INITIALISATION
	------------------------------------------------------------------------*/
	override public function init(g:Dynamic)  untyped {
		super.init(g) ;
		if ( game?.fl_bombExpert ) {
			RADIUS = EXPERT_RADIUS;
		}
	}


	/*------------------------------------------------------------------------
	ATTACHEMENT
	------------------------------------------------------------------------*/
	public static function attach(g:mode.GameMode,x:Dynamic,y:Dynamic)  untyped {
		var linkage:Dynamic = RootData.LINKAGES[RootData.BAD_BOMBE];
		var mc : entity.bad.walker.Bombe = (( g.depthMan.attach(linkage,RootData.DP_BADS) ):Dynamic) ;
		mc?.initBad(g,x,y) ;
		return mc ;
	}


	/*------------------------------------------------------------------------
	LOOP SUR L'ANIM DE RÉFLEXION
	------------------------------------------------------------------------*/
	override public function playAnim(obj:Dynamic)  untyped {
		if (fl_overheat ) {
			return;
		}
		super.playAnim(obj) ;
		if ( obj?.id == RootData.ANIM_BAD_THINK.id ) {
			fl_loop = true ;
		}
		if ( obj?.id == RootData.ANIM_BAD_JUMP.id ) {
			fl_loop = false ;
		}
	}


	/*------------------------------------------------------------------------
	DÉCLENCHEMENT EXPLOSION
	------------------------------------------------------------------------*/
	public function trigger()  untyped {
		if ( fl_overheat ) {
			return;
		}
		halt();

		playAnim(RootData.ANIM_BAD_DIE);
		fl_loop = false;
		fl_freeze = false;
//		fl_anim=false;

		var duration:Dynamic = RootData.SECOND * ( 0.25 + (MtStd.random(10)/100) * (MtStd.random(2)*2-1) );
		setLifeTimer(RootData.SECOND*3);
		updateLifeTimer(RootData.SECOND);
		setNext(null,null,RootData.SECOND*3,RootData.ACTION_WALK);
		fl_overheat = true;
	}


	/*------------------------------------------------------------------------
	KAMIKAZE!!
	------------------------------------------------------------------------*/
	public function selfDestruct()  untyped {
		// Onde de choc
		game?.fxMan?.attachExplodeZone(x,y,RADIUS) ;

		var l:Dynamic = game?.getClose(RootData.PLAYER,x,y,RADIUS,false) ;

		{ var i:Dynamic=0; while (i<l?.length) {
			var e : entity.Player = ((l[i]):Dynamic) ;
			e?.killHit(0) ;
			shockWave( e, RADIUS, POWER ) ;
			if ( !e?.fl_shield ) {
				{ if (e != null) e.dy = -10-MtStd.random(20) ; }
			}
		
i++; } }
		game?.soundMan?.playSound("sound_bomb_black", RootData.CHAN_BOMB);

		// Item
		dropReward();

		game?.fxMan?.inGameParticles( RootData.PARTICLE_METAL, x,y, MtStd.random(4)+5 );
		game?.fxMan?.inGameParticles( RootData.PARTICLE_SPARK, x,y, MtStd.random(4) );
		onKill();
		destroy();
	}


	/*------------------------------------------------------------------------
	MORT DU BAD
	------------------------------------------------------------------------*/
	override public function killHit(dx:Dynamic)  untyped {
		trigger();
	}


	/*------------------------------------------------------------------------
	EVENT: FREEZE
	------------------------------------------------------------------------*/
	override public function onFreeze()  untyped {
		trigger() ;
	}


	/*------------------------------------------------------------------------
	RENVOIE TRUE SI LE MONSTRE EST EN ÉTAT DE "JOUER"
	------------------------------------------------------------------------*/
	override public function isHealthy()  untyped {
		return !fl_overheat && super.isHealthy();
	}


	/*------------------------------------------------------------------------
	FIN DE TIMER DE VIE
	------------------------------------------------------------------------*/
	override public function onLifeTimer()  untyped {
		selfDestruct();
	}


	/*------------------------------------------------------------------------
	MAIN
	------------------------------------------------------------------------*/
	override public function prefix()  untyped {
		if ( !fl_stable && fl_overheat ) {
			dx = 0;
		}
		super.prefix();
	}

}


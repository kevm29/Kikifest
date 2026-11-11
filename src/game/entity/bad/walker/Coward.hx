// Converti automatiquement depuis hammer/entity/bad/walker/Coward.mt (Motion Twin)
package entity.bad.walker;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
import Data as RootData;
class Coward extends entity.bad.Jumper
{
	public static var VCLOSE_DISTANCE	= RootData.CASE_HEIGHT*2;
	public static var CLOSE_DISTANCE	= RootData.CASE_WIDTH*7;
	public static var SPEED_BOOST:Int		= 3;
	public static var FLEE_DURATION	= RootData.SECOND*4;

	public static var FLEE_JUMP_FACTOR:Int	= 25;


	public var fleeTimer		: Float;


	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new()  untyped {
		super() ;
		setJumpUp(5) ;
		setJumpDown(5) ;
		setJumpH(100) ;
		setClimb(100,RootData.IA_CLIMB);
		setFall(5) ;
		closeDistance	= 0;
	}


	/*------------------------------------------------------------------------
	INITIALISATION
	------------------------------------------------------------------------*/
	override public function init(g:Dynamic)  untyped {
		super.init(g) ;
	}


	/*------------------------------------------------------------------------
	ATTACHEMENT
	------------------------------------------------------------------------*/
	public static function attach(g:mode.GameMode,x:Dynamic,y:Dynamic)  untyped {
		var linkage:Dynamic = RootData.LINKAGES[RootData.BAD_BANANE];
		var mc : entity.bad.walker.Coward = (( g?.depthMan?.attach(linkage,RootData.DP_BADS) ):Dynamic) ;
		mc?.initBad(g,x,y) ;
		return mc ;
	}


	/*------------------------------------------------------------------------
	SAUT: CHANGEMENT DE DÉLAI
	------------------------------------------------------------------------*/
	override public function jump(dx:Dynamic,dy:Dynamic,delay:Dynamic)  untyped {
		if ( delay!=null && delay>0 ) {
			delay = RootData.SECOND*0.2;
		}
		super.jump(dx,dy, delay);
	}


	/*------------------------------------------------------------------------
	CALCUL DES CHANCES DE CHANGER D'ÉTAGE
	------------------------------------------------------------------------*/
	override public function decideJumpUp()  untyped {
		var fl_danger:Dynamic = player?.y<y && fleeTimer>0;
		if ( vclose() && close() && fleeTimer>0 ) {
			return MtStd.random(1000)<chanceJumpUp*FLEE_JUMP_FACTOR && isReady();
		}
		else {
			if ( player?.y<y ) {
				return !fl_danger && MtStd.random(1000)*0.5<chanceJumpUp && isReady();
			}
			else {
				return !fl_danger && MtStd.random(1000)<chanceJumpUp && isReady();
			}
		}
	}

	override public function decideJumpDown()  untyped {
		var fl_danger:Dynamic = player?.y>y && fleeTimer>0;
		if ( vclose() && close() && fleeTimer>0 ) {
			return MtStd.random(1000)<chanceJumpDown*FLEE_JUMP_FACTOR && isReady();
		}
		else {
			if ( player?.y>y ) {
				return !fl_danger && MtStd.random(1000)<chanceJumpDown*0.5 && isReady();
			}
			else {
				return !fl_danger && MtStd.random(1000)<chanceJumpDown && isReady();
			}
		}
	}


	/*------------------------------------------------------------------------
	CHANCE DE SE LAISSER TOMBER
	------------------------------------------------------------------------*/
	override public function decideFall()  untyped {
		var fall:Dynamic = MtStd.ix(world?.fallMap[cx], cy);
		if ( fall>0 ) {
			if ( vclose() ) {
				return true;
			}
		}
		return false;
	}


	/*------------------------------------------------------------------------
	CHANCE DE GRIMPER UN MUR
	------------------------------------------------------------------------*/
	override public function decideClimb()  untyped {
		var fl_stairway:Dynamic =
			( world?.checkFlag( {x:cx,y:cy}, RootData.IA_CLIMB_LEFT) && world?.getCase( {x:cx-1,y:cy-1} )<=0 ) ||
			( world?.checkFlag( {x:cx,y:cy}, RootData.IA_CLIMB_RIGHT) && world?.getCase( {x:cx+1,y:cy-1} )<=0 );

		var fl_danger:Dynamic =
			fleeTimer>0 && player?.cy<cy &&
			(	( world?.checkFlag( {x:cx,y:cy}, RootData.IA_CLIMB_LEFT) && player?.x<x ) ||
				( world?.checkFlag( {x:cx,y:cy}, RootData.IA_CLIMB_RIGHT) && player?.x>x ) );

		return !fl_danger && isReady() && ( fl_stairway || MtStd.random(1000)<chanceClimb );
	}


	/*------------------------------------------------------------------------
	CHANCE DE S'ENFUIR FACE AU JOUEUR
	------------------------------------------------------------------------*/
	public function decideFlee()  untyped {
		if ( fl_stable && dx!=0 && next==null ) {
			if ( vclose() && close() ) {
				return fleeTimer<=0;
			}
			if ( distance(player?.x,player?.y)<=RootData.CASE_WIDTH*4 ) {
				return fleeTimer<=0;
			}
		}
		return false;
	}


	/*------------------------------------------------------------------------
	RENVOIE TRUE SI LE PLAYER EST PROCHE
	------------------------------------------------------------------------*/
	public function vclose()  untyped {
		return Math.abs( player?.y - y ) <= VCLOSE_DISTANCE;
	}


	public function close()  untyped {
		return distance(player?.x,player?.y) <= CLOSE_DISTANCE;
	}


	/*------------------------------------------------------------------------
	CALCUL DE LA VITESSE DE MARCHE
	------------------------------------------------------------------------*/
	override public function calcSpeed()  untyped {
		super.calcSpeed();
		if ( fleeTimer>0 ) {
			speedFactor *= SPEED_BOOST;
		}
	}


	/*------------------------------------------------------------------------
	ÉNERVEMENT DÉSACTIVÉ
	------------------------------------------------------------------------*/
	override public function angerMore()  untyped {
		anger = 0;
	}


	/*------------------------------------------------------------------------
	INFIXE DE STEPPING
	------------------------------------------------------------------------*/
	override public function infix()  untyped {
		super.infix();

		if ( fl_stable && next==null && decideFlee() ) {
			flee();
		}
	}


	/*------------------------------------------------------------------------
	GESTION FUITE
	------------------------------------------------------------------------*/
	public function flee()  untyped {
		if ( (player?.x<=x && dir<0) || (player?.x>=x && dir>0) ) {
			dir = -dir;
		}
		fleeTimer = FLEE_DURATION;
		updateSpeed();
	}

	public function endFlee()  untyped {
		updateSpeed();
	}


	/*------------------------------------------------------------------------
	MAIN
	------------------------------------------------------------------------*/
	override public function update()  untyped {
		super.update();
		if ( isHealthy() && fleeTimer>0 ) {
			if ( !fl_stick ) {
				var mc:Dynamic = game?.depthMan?.attach("curse", RootData.DP_FX) ;
				mc?.gotoAndStop(""+RootData.CURSE_TAUNT) ;
				stick(mc,0,-RootData.CASE_HEIGHT*2.5);
			}
		}
		else {
			unstick();
		}

		// Timer de fuite
		if ( fleeTimer>0 ) {
			fleeTimer-=Timer.tmod;
			if ( fleeTimer<=0 ) {
				endFlee();
			}
		}
	}


}


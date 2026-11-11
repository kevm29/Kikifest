// Converti automatiquement depuis hammer/entity/bad/walker/Hunter.mt (Motion Twin)
package entity.bad.walker;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
import Data as RootData;
class Hunter extends entity.bad.Jumper
{
	public static var VCLOSE_DISTANCE	= RootData.CASE_HEIGHT*2;
	public static var CLOSE_DISTANCE	= RootData.CASE_WIDTH*8;
	public static var SPEED_BOOST:Float		= 2.2;

	public var prey			: entity.Physics;
	public var fl_hunt			: Bool;


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
		chaseFactor = 12;
		fl_hunt		= false;
	}


	/*------------------------------------------------------------------------
	INITIALISATION
	------------------------------------------------------------------------*/
	override public function init(g:Dynamic)  untyped {
		super.init(g);
		prey = ((game.getOne(RootData.PLAYER)):Dynamic);
	}


	/*------------------------------------------------------------------------
	ATTACHEMENT
	------------------------------------------------------------------------*/
	public static function attach(g:mode.GameMode,x:Dynamic,y:Dynamic)  untyped {
		var linkage:Dynamic = RootData.LINKAGES[RootData.BAD_BANANE];
		var mc : entity.bad.walker.Hunter = (( g.depthMan.attach(linkage,RootData.DP_BADS) ):Dynamic) ;
		mc?.initBad(g,x,y) ;
		return mc ;
	}


	/*------------------------------------------------------------------------
	RENVOIE TRUE SI LE PLAYER EST PROCHE
	------------------------------------------------------------------------*/
	public function vclose()  untyped {
		return Math.abs( prey?.y - y ) <= VCLOSE_DISTANCE;
	}

	public function close()  untyped {
		return distance(prey?.x,prey?.y) <= CLOSE_DISTANCE;
	}


	/*------------------------------------------------------------------------
	CALCUL DE LA VITESSE DE MARCHE
	------------------------------------------------------------------------*/
	override public function calcSpeed()  untyped {
		super.calcSpeed();
		if ( isHealthy() && close() ) {
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

		if ( fl_stable && next==null && decideHunt() ) {
			hunt();
		}
	}


	/*------------------------------------------------------------------------
	RENVOIE TRUE SI UNE TRAQUE EST À LANCER
	------------------------------------------------------------------------*/
	public function decideHunt()  untyped {
		return close();
	}


	/*------------------------------------------------------------------------
	LANCE UNE TRAQUE
	------------------------------------------------------------------------*/
	public function hunt()  untyped {
		if ( vclose() ) {
			if ( (dir>0 && prey?.x<x) || (dir<0 && prey?.x>x) ) {
				dir = -dir;
			}
		}
		fl_hunt = true;
		updateSpeed();
	}


	/*------------------------------------------------------------------------
	MAIN
	------------------------------------------------------------------------*/
	override public function update()  untyped {
		if ( fl_hunt ) {
			if ( isReady() && !close() ) {
				updateSpeed();
				fl_hunt = false;
			}
		}
		super.update();
	}


}


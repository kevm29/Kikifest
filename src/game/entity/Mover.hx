// Converti automatiquement depuis hammer/entity/Mover.mt (Motion Twin)
package entity;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
import Data as RootData;
class Mover extends entity.Physics {

	public var next			: {dx:Float,dy:Float,delay:Float, action:Int} ;
	public var fl_bounce		: Bool ;
	public var bounceFactor	: Float;

	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new()  untyped {
		super() ;
		fl_bounce		= false ;
		bounceFactor	= 0.5;
	}


	/*------------------------------------------------------------------------
	INITIALISATION
	------------------------------------------------------------------------*/
	override public function init(g:mode.GameMode)  untyped {
		super.init(g) ;
	}


	/*------------------------------------------------------------------------
	DÉFINI LA DÉCISION SUIVANTE
	------------------------------------------------------------------------*/
	public function setNext(dx:Dynamic,dy:Dynamic,delay:Dynamic,action:Dynamic)  untyped {
		next={
			dx:dx,
			dy:dy,
			delay:delay,
			action:action
		} ;
	}



	/*------------------------------------------------------------------------
	SUIT LA DÉCISION SUIVANTE
	------------------------------------------------------------------------*/
	public function onNext()  untyped {
		if ( next?.action == RootData.ACTION_MOVE ) {
			dx = next?.dx ;
			dy = next?.dy ;
			if (dy!=0) {
				fl_stable = false ;
			}
			next=null ;
			//      fl_skipNextGravity = true ;
		}
	}


	/*------------------------------------------------------------------------
	EVENT: MORT
	------------------------------------------------------------------------*/
	override public function onKill()  untyped {
		super.onKill() ;
		next = null ;
	}


	/*------------------------------------------------------------------------
	EVENT: TOUCHE LE SOL
	------------------------------------------------------------------------*/
	override public function onHitGround(h:Dynamic)  untyped {
		if ( fl_bounce ) {
			var b:Dynamic = bounceFactor*Math.abs(dy) ;
			if (b>=2) {
				setNext(dx,-b,0,RootData.ACTION_MOVE) ;
				fl_skipNextGravity = true ;
			}
		}
		super.onHitGround(h) ;
	}


	/*------------------------------------------------------------------------
	RENVOIE TRUE SI L'ENTITÉ EST EN ÉTAT D'AGIR
	------------------------------------------------------------------------*/
	public function isReady()  untyped {
		return fl_stable && next==null ;
	}


	/*------------------------------------------------------------------------
	MAIN
	------------------------------------------------------------------------*/
	override public function update()  untyped {

		// On agit comme on a prévu
		if ( next!=null ) {
			{ if (next != null) next.delay -= Timer.tmod ; }
			if ( next?.delay<=0 ) {
				onNext() ;
			}
		}

		super.update() ;
	}


}


// Converti automatiquement depuis hammer/entity/bad/Flyer.mt (Motion Twin)
package entity.bad;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
import Data as RootData;
class Flyer extends entity.Bad
{

	public var xSpeed			: Float ;
	public var ySpeed			: Float ;
	public var fl_fly			: Bool ;
	public var fl_intercept	: Bool; // true si gelé en plein vol
	public var speed			: Float ;
	public var dir				: Float ;


	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new()  untyped {
		super() ;
		speed = 4 ;
		angerFactor = 0.5;
		// attention changement: contenu déplacé dans init()
	}


	/*------------------------------------------------------------------------
	INITIALISATION
	------------------------------------------------------------------------*/
	override public function init(g:Dynamic)  untyped {
		super.init(g) ;
		xSpeed = Math.cos(Math.PI*0.25)*speed ;
		ySpeed = Math.sin(Math.PI*0.25)*speed ;
		if ( game?.fl_static ) {
			dir = -1;
		}
		else {
			dir = (MtStd.random(2)*2-1);
		}
		fly() ;
	}


	/*------------------------------------------------------------------------
	ENVOL
	------------------------------------------------------------------------*/
	public function fly()  untyped {
		if ( !isHealthy() ) {
			return ;
		}

		if ( anger>0 ) {
			playAnim(RootData.ANIM_BAD_ANGER);
		}
		else {
			playAnim(RootData.ANIM_BAD_WALK);
		}

		dx = dir*xSpeed*speedFactor ;
		dy = -ySpeed*speedFactor ;
		fl_fly			= true ;
		fl_intercept	= false;
		fl_gravity		= false ;
		fl_friction		= false ;
		fl_hitCeil		= true ;
	}


	/*------------------------------------------------------------------------
	STOPPE LE VOL
	------------------------------------------------------------------------*/
	public function land()  untyped {
		fl_fly = false ;
		fl_gravity = true ;
		fl_friction = true ;
		fl_hitCeil = false ;
	}

	/*------------------------------------------------------------------------
	MORT
	------------------------------------------------------------------------*/
	override public function killHit(dx:Dynamic)  untyped {
		super.killHit(dx) ;
		land() ;
	}


	/*------------------------------------------------------------------------
	INFIXE
	------------------------------------------------------------------------*/
	override public function infix()  untyped {
		super.infix() ;
		if ( fl_fly && y>=RootData.GAME_HEIGHT ) {
			y = RootData.GAME_HEIGHT ;
			dy = -ySpeed*speedFactor ;
		}
	}


	/*------------------------------------------------------------------------
	POSTFIXE
	------------------------------------------------------------------------*/
	override public function postfix()  untyped {
		super.postfix() ;
		if ( fl_fly ) {
			fl_friction = false ;
		}
	}
	//
	//
	///*------------------------------------------------------------------------
	//    DÉFINI L'ACTION SUIVANTE
	// ------------------------------------------------------------------------*/
	//  function setNext(dx,dy,delay,act) {
	//    if ( !fl_fly )
	//      super.setNext(dx,dy,delay,act) ;
	//  }


	override public function playAnim(a:Dynamic)  untyped {
		if ( a?.id!=RootData.ANIM_BAD_JUMP.id ) {
			super.playAnim(a);
		}
	}


	/*------------------------------------------------------------------------
	CHANGEMENT DE VITESSE
	------------------------------------------------------------------------*/
	override public function updateSpeed()  untyped {
		super.updateSpeed() ;
		if ( fl_fly ) {
			dx = dir*xSpeed*speedFactor ;
			if ( dy<0 ) {
				dy = -ySpeed*speedFactor ;
			}
			else {
				dy = ySpeed*speedFactor ;
			}
		}
	}


	/*------------------------------------------------------------------------
	EVENT: ACTION SUIVANTE
	------------------------------------------------------------------------*/
	override public function onNext()  untyped {
		if ( !fl_fly ) {
			super.onNext() ;
		}
	}



	/*------------------------------------------------------------------------
	EVENT: ATTERRISSAGE
	------------------------------------------------------------------------*/
	override public function onHitGround(h:Dynamic)  untyped {
		if ( !fl_fly ) {
			fl_intercept = false;
			super.onHitGround(h) ;
			return ;
		}
		fl_stopStepping = true ;
		dy = -ySpeed*speedFactor ;
	}


	/*------------------------------------------------------------------------
	EVENT: ATTERRISSAGE
	------------------------------------------------------------------------*/
	override public function onHitCeil()  untyped {
		if ( !fl_fly ) {
			super.onHitCeil() ;
			return ;
		}
		fl_stopStepping = true ;
		dy = ySpeed*speedFactor ;
	}



	/*------------------------------------------------------------------------
	EVENT: TOUCHE UN MUR
	------------------------------------------------------------------------*/
	override public function onHitWall()  untyped {
		if ( !fl_fly ) {
			if (world?.getCase( {x:cx,y:cy} )!=RootData.WALL) {
				dx = -dx ;
			}
			return ;
		}
		fl_stopStepping = true ;
		dir = -dir ;
		dx = dir*xSpeed*speedFactor ;
	}


	/*------------------------------------------------------------------------
	EVENT: GEL
	------------------------------------------------------------------------*/
	override public function onFreeze()  untyped {
		super.onFreeze() ;
		if ( fl_fly ) {
			fl_intercept = true;
		}
		land() ;
	}

	/*------------------------------------------------------------------------
	EVENT: SONNÉ
	------------------------------------------------------------------------*/
	override public function onKnock()  untyped {
		super.onKnock() ;
		land() ;
	}

	/*------------------------------------------------------------------------
	EVENT: DÉGEL
	------------------------------------------------------------------------*/
	override public function onMelt()  untyped {
		super.onMelt() ;
		fly() ;
	}

	/*------------------------------------------------------------------------
	EVENT: RÉVEIL
	------------------------------------------------------------------------*/
	override public function onWakeUp()  untyped {
		super.onWakeUp() ;
		fly() ;
	}


	/*------------------------------------------------------------------------
	MAIN
	------------------------------------------------------------------------*/
	override public function update()  untyped {
		super.update();

		// Collisions haut du niveau
		if ( fl_fly && dy<0 && y<=RootData.CASE_HEIGHT ) {
			dy = Math.abs(dy);
		}
	}


	/*------------------------------------------------------------------------
	UPDATE GRAPHIQUE
	------------------------------------------------------------------------*/
	override public function endUpdate()  untyped {
		super.endUpdate() ;
		_xscale = dir*Math.abs(_xscale) ;
	}
}


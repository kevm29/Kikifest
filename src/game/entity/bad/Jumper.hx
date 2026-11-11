// Converti automatiquement depuis hammer/entity/bad/Jumper.mt (Motion Twin)
package entity.bad;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
import Data as RootData;
class Jumper extends entity.bad.Walker
{
	public var jumpTimer : Float;

	public var fl_jUp : Bool;
	public var fl_jDown : Bool;
	public var fl_jH : Bool;
	public var fl_jumper : Bool; // flag résumant les 3 précédents
	public var fl_climb : Bool;


	public var chanceJumpH : Float;
	public var chanceJumpUp : Float;
	public var chanceJumpDown : Float;
	public var chanceClimb : Float;

	public var maxClimb : Int;

	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new()  untyped {
		super();
		jumpTimer = 0;
		setJumpUp(null);
		setJumpDown(null);
		setJumpH(null);
		setClimb(null, null);
	}


	/*------------------------------------------------------------------------
	INITIALISATION
	------------------------------------------------------------------------*/
	override public function init(g:Dynamic)  untyped {
		super.init(g);
	}


	/*------------------------------------------------------------------------
	DÉFINI LES SAUTS AUTORISÉS
	------------------------------------------------------------------------*/
	// Haut
	public function setJumpUp(chance:Dynamic)  untyped {
		if ( chance==null ) {
			fl_jUp = false;
		}
		else {
			fl_jUp = true;
			chanceJumpUp = chance*10;
		}
		setJumper();
	}

	// Bas
	public function setJumpDown(chance:Dynamic)  untyped {
		if ( chance==null ) {
			fl_jDown = false;
		}
		else {
			fl_jDown = true;
			chanceJumpDown = chance*10;
		}
		setJumper();
	}

	// Horizontal
	public function setJumpH(chance:Dynamic)  untyped {
		if ( chance==null ) {
			fl_jH = false;
		}
		else {
			fl_jH = true;
			chanceJumpH = chance*10;
		}
		setJumper();
	}

	// Escalade
	public function setClimb(chance:Dynamic, max:Dynamic)  untyped {
		if ( chance==null ) {
			fl_climb = false;
			maxClimb = 0;
		}
		else {
			fl_climb = true;
			maxClimb = max;
			chanceClimb = chance*10;
		}
		setJumper();
	}

	// Général
	public function setJumper()  untyped {
		fl_jumper = fl_jUp || fl_jDown || fl_jH;
	}



	// *** IA: DÉCISIONS

	public function decideJumpUp()  untyped {
		if ( fl_playerClose ) {
			return player?.cy<cy && MtStd.random(1000)<chanceJumpUp*chaseFactor && isReady();
		}
		else {
			return MtStd.random(1000)<chanceJumpUp && isReady();
		}
	}

	public function decideJumpDown()  untyped {
		if ( fl_playerClose ) {
			return player?.cy>cy && MtStd.random(1000)<chanceJumpDown*chaseFactor && isReady();
		}
		else {
			return MtStd.random(1000)<chanceJumpDown && isReady();
		}
	}

	public function decideClimb()  untyped {
		var d:Dynamic = Math.abs(player?.cy-cy);
		var fl_good:Dynamic  =  d>=3 || ( d<3 && ((player?.cx<cx && dx<0) || (player?.cx>cx && dx>0)) );
		var fl_stairway:Dynamic =
			( world?.checkFlag( {x:cx,y:cy}, RootData.IA_CLIMB_LEFT) || world?.checkFlag( {x:cx,y:cy}, RootData.IA_CLIMB_RIGHT) ) &&
			world?.checkFlag( {x:cx,y:cy}, RootData.IA_SMALL_SPOT) ;
		if ( fl_playerClose ) {
			return isReady() && ( fl_stairway || ( fl_good && MtStd.random(1000)<chanceClimb*chaseFactor ) );
		}
		else {
			return isReady() && ( fl_stairway || MtStd.random(1000)<chanceClimb );
		}
	}



	/*------------------------------------------------------------------------
	LANCE UN SAUT
	------------------------------------------------------------------------*/
	public function jump(dx:Dynamic,dy:Dynamic,delay:Dynamic)  untyped {
		halt();
		//    x = oldX;
		//    y = oldY;
		setNext(dx,dy,delay,RootData.ACTION_MOVE);
		if (delay>0) {
			playAnim( RootData.ANIM_BAD_THINK );
		}
	}


	/*------------------------------------------------------------------------
	TESTE SI LE BAD PEUT GRIMPER
	------------------------------------------------------------------------*/
	public function checkClimb()  untyped {
		if ( decideClimb() ) {

			// Gauche
			if ( dx<0 && world?.checkFlag( {x:cx,y:cy}, RootData.IA_CLIMB_LEFT) ) {
				var h:Dynamic;
				if (  world?.checkFlag( {x:cx,y:cy}, RootData.IA_TILE_TOP)  ) {
					h = world?.getWallHeight( cx-1,cy, RootData.IA_CLIMB );
				}
				else {
					h = world?.getStepHeight( cx,cy, RootData.IA_CLIMB );
				}
				if ( h<= maxClimb ) {
					var wait:Dynamic = (h>1)?RootData.SECOND:0;
					if ( world?.checkFlag( {x:cx,y:cy}, RootData.IA_TILE_TOP) ) {
						jump( -RootData.BAD_VJUMP_X_CLIFF, -RootData.BAD_VJUMP_Y_LIST[h-1], wait );
					}
					else {
						jump( -RootData.BAD_VJUMP_X, -RootData.BAD_VJUMP_Y_LIST[h-1], wait );
						x = oldX;
					}
					fl_stopStepping = true;
				}
			}

			// Droite
			if ( dx>0 && world?.checkFlag( {x:cx,y:cy}, RootData.IA_CLIMB_RIGHT) ) {
				var h:Dynamic;
				if (  world?.checkFlag( {x:cx,y:cy}, RootData.IA_TILE_TOP)  ) {
					h = world?.getWallHeight( cx+1,cy, RootData.IA_CLIMB );
				}
				else {
					h = world?.getStepHeight( cx,cy, RootData.IA_CLIMB );
				}
				if ( h<= maxClimb ) {
					var wait:Dynamic = (h>1)?RootData.SECOND:0;
					if ( world?.checkFlag( {x:cx,y:cy}, RootData.IA_TILE_TOP) ) {
						jump( RootData.BAD_VJUMP_X_CLIFF, -RootData.BAD_VJUMP_Y_LIST[h-1], wait );
					}
					else {
						jump( RootData.BAD_VJUMP_X, -RootData.BAD_VJUMP_Y_LIST[h-1], wait );
						x = oldX;
					}
					fl_stopStepping = true;
				}
			}
		}
	}

	/*------------------------------------------------------------------------
	EVENT: ORDRE SUIVANT
	------------------------------------------------------------------------*/
	override public function onNext()  untyped {
		if ( next?.action == RootData.ACTION_MOVE && next?.dy!=0 ) {
			playAnim( RootData.ANIM_BAD_JUMP );
		}

		super.onNext();
	}


	/*------------------------------------------------------------------------
	EVENT: SUR LE POINT DE TOMBER
	------------------------------------------------------------------------*/
	override public function onFall()  untyped {
		if ( fl_jumper ) {
			if ( isReady() && fl_jH ) {

				// Au bord du vide et décide de se laisser tomber
				// (le fait de ne pas sauter ici fait que le Walker se laissera
				// tomber). Note: ceci est un patch bien porc.
				if ( fl_fall && decideFall() ) {
					if ( world?.checkFlag( {x:cx,y:cy},RootData.IA_ALLOW_FALL) ) {
						fl_willFallDown = true;
					}
				}

				// Descente d'une petite marche (hauteur 1)
				if ( fl_fall && fl_climb ) {
					if (	world?.checkFlag( {x:cx,y:cy+1}, RootData.IA_CLIMB_LEFT ) ||
							world?.checkFlag( {x:cx,y:cy+1}, RootData.IA_CLIMB_RIGHT ) ) {
						fl_willFallDown = true;
					}
				}

				if ( !fl_willFallDown ) {

					// Saut gauche
					if ( dx<0 && world?.checkFlag( {x:cx,y:cy}, RootData.IA_JUMP_LEFT ) ) {
						jump( -RootData.BAD_HJUMP_X, -RootData.BAD_HJUMP_Y, 0);
						adjustToRight();
					}
					// Saut droite
					if ( dx>0 && world?.checkFlag( {x:cx,y:cy}, RootData.IA_JUMP_RIGHT ) ) {
						jump( RootData.BAD_HJUMP_X, -RootData.BAD_HJUMP_Y, 0);
						adjustToLeft();
					}

					// Escalade
					if ( fl_climb ) {
						checkClimb();
					}
				}
			}
		}
		super.onFall();
	}


	/*------------------------------------------------------------------------
	EVENT: RENCONTRE UN MUR
	------------------------------------------------------------------------*/
	override public function onHitWall()  untyped {
		// Escalade
		if ( fl_climb ) {
			checkClimb();
		}

		super.onHitWall();

	}


	/*------------------------------------------------------------------------
	EVENT: FREEZE
	------------------------------------------------------------------------*/
	override public function onFreeze()  untyped {
		super.onFreeze();
		fl_skipNextGround = false;
	}


	/*------------------------------------------------------------------------
	EVENT: FREEZE
	------------------------------------------------------------------------*/
	override public function onKnock()  untyped {
		super.onKnock();
		fl_skipNextGround = false;
	}


	/*------------------------------------------------------------------------
	INFIXE
	------------------------------------------------------------------------*/
	override public function infix()  untyped {
		super.infix();
		// Saut vertical
		if ( fl_jumper ) {
			updateCoords();

			// Haut
			if ( fl_jUp ) {
				if ( decideJumpUp() ) {
					if ( world?.checkFlag( {x:cx,y:cy}, RootData.IA_JUMP_UP) ) {
						jump( 0, -RootData.BAD_VJUMP_Y, RootData.SECOND);
						fl_stopStepping = true;
					}
				}
			}

			// Bas
			if ( fl_jDown ) {
				if ( decideJumpDown() ) {
					if ( world?.checkFlag( {x:cx,y:cy}, RootData.IA_JUMP_DOWN) ) {
						jump( 0, -RootData.BAD_VDJUMP_Y, RootData.SECOND);
						fl_skipNextGround = true;
						fl_stopStepping = true;
					}
				}
			}

		}
	}


}

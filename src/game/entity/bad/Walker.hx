// Converti automatiquement depuis hammer/entity/bad/Walker.mt (Motion Twin)
package entity.bad;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
import Data as RootData;
class Walker extends entity.Bad
{

	public var speed			: Float;
	public var dir				: Float;

	public var fl_fall			: Bool;
	public var fl_willFallDown	: Bool;
	public var chanceFall		: Float;

	public var recentParticles	: Float; // reduces frequency of ice particles when hitting walls


	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new()  untyped {
		super();
		setFall(null);
		speed			= 2;
		fl_willFallDown	= false;
		recentParticles	= 0;
	}


	/*------------------------------------------------------------------------
	INITIALISATION
	------------------------------------------------------------------------*/
	override public function init(g:mode.GameMode)  untyped {
		super.init(g);
		if ( game?.fl_static ) {
			if ( x<=RootData.GAME_WIDTH*0.5 ) {
				dir = 1;
			}
			else {
				dir = -1;
			}
		}
		else {
			dir = MtStd.random(2)*2-1;
		}
	}


	/*------------------------------------------------------------------------
	STOPPE LE MOUVEMENT DU BAD
	------------------------------------------------------------------------*/
	public function halt()  untyped {
		if ( !fl_freeze && !fl_knock ) {
			dx=0;
		}
		dy=0;
	}


	/*------------------------------------------------------------------------
	CALCULE LA VITESSE DE MARCHE DU MONSTRE
	------------------------------------------------------------------------*/
	public function walk()  untyped {
		var base:Dynamic = speedFactor * speed * game?.speedFactor;

		if ( !isReady() ) {
			return;
		}

		if (dir==-1) { // gauche
			base = -base;
		}

		if ( fl_stable ) {
			playAnim( RootData.ANIM_BAD_WALK );
		}
		setNext(base,0,0,RootData.ACTION_MOVE);
	}


	/*------------------------------------------------------------------------
	DEMI-TOUR
	------------------------------------------------------------------------*/
	public function fallBack()  untyped {
		dx = -dx;
		if ( !fl_freeze && !fl_knock ) {
			dir = -dir;
		}
	}


	/*------------------------------------------------------------------------
	INFIXE
	------------------------------------------------------------------------*/
	override public function infix()  untyped {
		if ( fl_stable && world?.checkFlag( {x:cx,y:cy}, RootData.IA_FALL_SPOT) ) {
			onFall();
			fl_stopStepping = true;
			return;
		}
		super.infix();
	}

	/*------------------------------------------------------------------------
	POSTFIXE
	------------------------------------------------------------------------*/
	override public function postfix()  untyped {
		super.postfix();

		// Désactivation de la friction pendant la marche
		if ( isReady() ) {
			fl_friction = false;
		}
		else {
			fl_friction = true;
		}
	}


	/*------------------------------------------------------------------------
	RENVOIE TRUE SI LE BAD EST DISPOSÉ À AGIR
	------------------------------------------------------------------------*/
	override public function isReady()  untyped {
		return super.isReady() && isHealthy();
	}


	/*------------------------------------------------------------------------
	DÉFINI LES CHANCES DE SE LAISSER TOMBER
	------------------------------------------------------------------------*/
	public function setFall(chance:Dynamic)  untyped {
		if ( chance==null ) {
			fl_fall = false;
		}
		else {
			fl_fall = true;
			chanceFall = chance*10;
		}
	}


	/*------------------------------------------------------------------------
	LE BAD RETROUVE SON CALME
	------------------------------------------------------------------------*/
	override public function calmDown()  untyped {
		super.calmDown();
		if ( animId==RootData.ANIM_BAD_ANGER.id ) {
			playAnim( RootData.ANIM_BAD_WALK );
		}

		if ( isReady() ) {
			halt();
			walk();
		}
	}

	/*------------------------------------------------------------------------
	ÉNERVEMENT
	------------------------------------------------------------------------*/
	override public function angerMore()  untyped {
		super.angerMore();
		if (isReady()) {
			halt();
			walk();
		}
	}


	/*------------------------------------------------------------------------
	CHANGEMENT DE VITESSE
	------------------------------------------------------------------------*/
	override public function updateSpeed()  untyped {
		super.updateSpeed();
		walk();
	}


	// *** IA: DÉCISIONS

	public function decideFall()  untyped {
		var d:Dynamic = player?.cy - cy;
		var fall:Dynamic = MtStd.ix(world?.fallMap[cx], cy);
		var fl_good:Dynamic = fall>0 && d>0 && fall<=d+3;
		if ( fl_playerClose ) {
			return fl_good;
		}
		else {
			return MtStd.random(1000)<chanceFall;
		}
	}


//	function decideFallBack() { // *** NOT USED ! ***
//		if ( fl_playerClose ) {
//			// proche en Y
//			if ( Math.abs(player.cy - cy) < 3 ) {
//				// aucun obstacle entre le mob et le joueur
//				var inc = (player.cx<cx)?-1:1;
//				var fl_obst = false;
//				for (var i=cx ; i!=player.cx && !fl_obst ; i+=inc) {
//					if ( world.getCase( {x:i,y:cy} )>0 ) {
//						fl_obst = true;
//					}
//				}
//				return !fl_obst;
//			}
//			else {
//				return false;
//			}
//		}
//		else {
//			return false;
//		}
//	}



	// *** EVENTS

	/*------------------------------------------------------------------------
	SUIT LA DÉCISION SUIVANTE
	------------------------------------------------------------------------*/
	override public function onNext()  untyped {
		if ( next?.action == RootData.ACTION_WALK ) {
			next=null;
			walk();
		}
		if ( next?.action == RootData.ACTION_FALLBACK ) {
			next=null;
			walk();
			{ if (next != null) next.dx = -next?.dx; }
		}
		if ( next?.action == RootData.ACTION_MOVE && next?.dy==0 ) {
			playAnim( RootData.ANIM_BAD_WALK );
		}
		super.onNext();
	}


	/*------------------------------------------------------------------------
	EVENT: MUR
	------------------------------------------------------------------------*/
	override public function onHitWall()  untyped {
		if ( !fl_stopStepping ) {
			if (world?.getCase( {x:cx,y:cy} )!=RootData.WALL) {
				if ( !isHealthy() || fl_stable ) {
					fallBack();
				}
			}
		}
		if ( GameManager.CONFIG.fl_detail && fl_freeze && Math.abs(dx)>=4 ) {
			if ( recentParticles<=0 ) {
				if ( GameManager.CONFIG.fl_shaky ) {
					game?.shake(RootData.SECOND*0.2,2);
				}
				game?.fxMan?.inGameParticles( RootData.PARTICLE_ICE_BAD, x, y, MtStd.random(4)+1 );
				recentParticles=10;
			}
			if ( fl_stable ) {
				game?.fxMan?.dust(cx,cy+1);
			}
		}
	}


	/*------------------------------------------------------------------------
	EVENT: ATTERRISSAGE
	------------------------------------------------------------------------*/
	override public function onHitGround(h:Dynamic)  untyped {
		super.onHitGround(h);
		halt();
		walk();
	}


	/*------------------------------------------------------------------------
	EVENT: SUR LE POINT DE TOMBER
	------------------------------------------------------------------------*/
	public function onFall()  untyped {
		if ( !isReady() ) {
			return;
		}

		// Ne reste pas sur une dalle merdique s'il peut s'en laisser tomber
		if ( world?.checkFlag( Entity.rtc(oldX,oldY), RootData.IA_SMALL_SPOT ) && world?.checkFlag( {x:cx,y:cy}, RootData.IA_ALLOW_FALL ) ) {
			halt();
			return;
		}

		// Se laisse tomber (NB: le Jumper peut avoir mis le flag à true)
		if ( fl_fall ) {
			if ( decideFall() ) {
				if ( world?.checkFlag( {x:cx,y:cy},RootData.IA_ALLOW_FALL) ) {
					fl_willFallDown = true;
				}
			}

			if ( fl_willFallDown ) {
				fl_willFallDown = false;
				halt();
				return;
			}
		}

		x = oldX;
		y = oldY;
		fallBack();
	}


	/*------------------------------------------------------------------------
	BAD FREEZÉ
	------------------------------------------------------------------------*/
	override public function onFreeze()  untyped {
		super.onFreeze();
		next=null;
	}


	/*------------------------------------------------------------------------
	EVENT: FIN DE FREEZE
	------------------------------------------------------------------------*/
	override public function onMelt()  untyped {
		super.onMelt();
		walk();
		if ( !fl_stable ) {
			playAnim( RootData.ANIM_BAD_JUMP );
		}
	}



	/*------------------------------------------------------------------------
	BAD SONNÉ
	------------------------------------------------------------------------*/
	override public function onKnock()  untyped {
		super.onKnock();
		next=null;
	}


	/*------------------------------------------------------------------------
	EVENT: FIN DE KNOCK
	------------------------------------------------------------------------*/
	override public function onWakeUp()  untyped {
		super.onWakeUp();
		walk();
		if ( !fl_stable ) {
			playAnim( RootData.ANIM_BAD_JUMP );
		}
	}



	/*------------------------------------------------------------------------
	MISE À JOUR GRAPHIQUE
	------------------------------------------------------------------------*/
	override public function endUpdate()  untyped {
		super.endUpdate();

		// Flip gauche/droite du movie
		if ( !fl_freeze && !fl_knock ) {
			if ( dx<0 ) {
				dir = -1;
			}
			if ( dx>0 ) {
				dir = 1;
			}
			_xscale = dir*Math.abs(_xscale);
		}
	}


	/*------------------------------------------------------------------------
	MAIN
	------------------------------------------------------------------------*/
	override public function update()  untyped {
		fl_willFallDown = false;
		if ( recentParticles>0 ) {
			recentParticles-=Timer.tmod;
		}
		super.update();
	}


}


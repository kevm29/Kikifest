// Converti automatiquement depuis hammer/entity/bad/WallWalker.mt (Motion Twin)
package entity.bad;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
import Data as RootData;
class WallWalker extends entity.Bad
{
	public static var SUB_RECAL:Float	= 0.2;


	public var fl_wallWalk		: Bool;
	public var fl_intercept	: Bool;
	public var fl_lost			: Bool;

	public var cp				: {x:Int,y:Int}; // check-point (relative coords)
	public var speed			: Float;

	public var xSpeed			: Float;
	public var ySpeed			: Float;

	public var xSub			: Float;
	public var ySub			: Float;
	public var xSubBase		: Float;
	public var ySubBase		: Float;
	public var subOffset		: Float;

	public var lastSafe			: {
			x		: Float,
			y		: Float,
			xSpeed	: Float,
			ySpeed	: Float,
			cp		: {x:Int,y:Int},
	};



	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new()  untyped {
		super() ;
		speed			= 3;
		angerFactor		= 0.4;
		subOffset		= 8;
		fl_intercept	= false;
		fl_lost			= false;
		fl_largeTrigger	= true;
	}


	/*------------------------------------------------------------------------
	INITIALISATION
	------------------------------------------------------------------------*/
	override public function initBad(g:Dynamic,x:Dynamic,y:Dynamic)  untyped {
		super.initBad(g,x,y);
		xSub = sub?._x;
		ySub = sub?._y;
		xSubBase = xSub;
		ySubBase = ySub;
		wallWalk();
	}


	/*------------------------------------------------------------------------
	ACTIVE / DÉSACTIVE LE WALL-WALK
	------------------------------------------------------------------------*/
	public function wallWalk()  untyped {
		if ( !isHealthy() || !isReady() ) {
			return ;
		}
		fl_wallWalk		= true;

		fl_gravity		= false;
		fl_friction		= false;
		fl_hitWall		= false;
		fl_hitGround	= false;
		fl_hitBorder	= false;
		var choices:Dynamic = [
			{x:1,y:0,	cpx:0,cpy:1}, // horizontal + bas
			{x:-1,y:0,	cpx:0,cpy:1},
			{x:1,y:0,	cpx:0,cpy:-1}, // horizontal + haut
			{x:-1,y:0,	cpx:0,cpy:-1},
			{x:0,y:1,	cpx:1,cpy:0}, // vertical + droite
			{x:0,y:-1,	cpx:1,cpy:0},
			{x:0,y:1,	cpx:-1,cpy:0}, // vertical + gauche
			{x:0,y:-1,	cpx:-1,cpy:0},
		];
		{ var i:Dynamic=0; while (i<choices?.length) {
			var ch:Dynamic = choices[i];
			if ( world?.getCase( {x:cx+ch?.x,y:cy+ch?.y} )>0 || world?.getCase( {x:cx+ch?.cpx,y:cy+ch?.cpy} )<=0 ) {
				choices?.splice(i,1);
				i--;
			}
		
i++; } }
		var choice:Dynamic = choices[ MtStd.random(choices?.length) ];
		if ( choice!=null ) {
			setDir(choice?.x,choice?.y);
			setCP(choice?.cpx,choice?.cpy);
			playAnim(RootData.ANIM_BAD_WALK);
		}
		else {
			suicide();
		}

		fl_softRecal	= false;
	}


	public function land()  untyped {
		fl_wallWalk		= false;

		fl_gravity		= true;
		fl_friction		= true;
		fl_hitWall		= true;
		fl_hitGround	= true;
		fl_hitBorder	= true;
	}



	/*------------------------------------------------------------------------
	MODIFIE LA DIRECTION DE DÉPLACEMENT
	------------------------------------------------------------------------*/
	public function setDir(xoff:Dynamic, yoff:Dynamic)  untyped {
		xSpeed = speed*xoff;
		ySpeed = speed*yoff;
		updateSpeed();
		x = Entity.x_ctr(cx);
		y = Entity.y_ctr(cy);
		activateSoftRecal();
		setNext(dx,dy,0,RootData.ACTION_MOVE);
	}

	public function setCP(xoff:Dynamic,yoff:Dynamic)  untyped {
		cp = {x:xoff, y:yoff};
	}


	/*------------------------------------------------------------------------
	CHANGEMENT DE VITESSE
	------------------------------------------------------------------------*/
	override public function updateSpeed()  untyped {
		super.updateSpeed() ;
		if ( fl_wallWalk && isReady() ) {
			dx = xSpeed*speedFactor;
			dy = ySpeed*speedFactor;
		}
	}




	/*------------------------------------------------------------------------
	INFIXE DE STEPPING
	------------------------------------------------------------------------*/
	override public function infix()  untyped {
		super.infix();

		if ( fl_wallWalk ) {
			wallWalkIA();
		}
	}


	/*------------------------------------------------------------------------
	GESTION DU DÉPLACEMENT AUX MURS
	------------------------------------------------------------------------*/
	public function wallWalkIA()  untyped {
		if ( deathTimer>0 ) {
			return;
		}

		var dirX :Int = Math.round( (dx==0) ? 0 : dx/Math.abs(dx) );
		var dirY :Int = Math.round( (dy==0) ? 0 : dy/Math.abs(dy) );

		// Haut du niveau
		if ( cy==0 ) {
			if ( dy<0 ) {
				setDir(-cp?.x, 0);
				setCP(0,-1);
			}
			else {
				if ( world?.getCase( {x: cx+dirX, y: cy} )>0 ) {
					setDir(0,1);
					setCP(dirX,0);
				}
			}
		}
		else {
			// Coins convexes
			if ( world?.getCase( {x: cx+cp?.x, y: cy+cp?.y} )<=0 ) {
				setDir(cp?.x,cp?.y);
				setCP(-dirX,-dirY);
			}
			else {
				// Coins non-convexes
				if ( world?.getCase( {x:cx+dirX, y:cy+dirY} ) > 0 ) {
					setDir(-cp?.x, -cp?.y);
					setCP(dirX, dirY);
				}
			}
		}

		// Impasses
		var fl_deadEnd:Dynamic = true;
		var tries:Dynamic = 0;
		while ( fl_deadEnd && tries<4 ) {
			dirX = Math.round( (dx==0) ? 0 : dx/Math.abs(dx) );
			dirY = Math.round( (dy==0) ? 0 : dy/Math.abs(dy) );
			if ( world?.getCase( {x:cx+dirX, y:cy+dirY} )>0 && world?.getCase( {x: cx+cp?.x, y: cy+cp?.y} )>0 ) {
				setDir(-cp?.x, -cp?.y);
				setCP(dirX, dirY);
			}
			else {
				fl_deadEnd = false;
			}
			tries++;
		}

		// Bloqué ? Suicide !
		if ( fl_deadEnd && !(deathTimer>0) ) {
			suicide();
		}


	}


	/*------------------------------------------------------------------------
	MORT
	------------------------------------------------------------------------*/
	override public function killHit(dx:Dynamic)  untyped {
		super.killHit(dx);
		land();
		fl_hitGround	= false;
		fl_hitWall		= false;
	}


	/*------------------------------------------------------------------------
	SUICIDE!
	------------------------------------------------------------------------*/
	public function suicide()  untyped {
		if ( deathTimer>0 ) {
			return;
		}
		dx = 0;
		dy = 0;
		land();
		fl_lost			= true;
		deathTimer		= RootData.SECOND*3;
	}


	/*------------------------------------------------------------------------
	RECALAGE EN POSITION SÛRE
	------------------------------------------------------------------------*/
	public function moveToSafePos()  untyped {
		if ( x!=lastSafe?.x || y!=lastSafe?.x ) {
			x			= lastSafe?.x;
			y			= lastSafe?.y;
			cp			= lastSafe?.cp;
			xSpeed		= lastSafe?.xSpeed;
			ySpeed		= lastSafe?.ySpeed;
			updateCoords();
		}
	}


	/*------------------------------------------------------------------------
	RENVOIE TRUE SI DISPONIBLE POUR UNE ACTION
	------------------------------------------------------------------------*/
	override public function isReady()  untyped {
		return isHealthy() && !fl_lost;
	}



	/*------------------------------------------------------------------------
	EVENT: GEL
	------------------------------------------------------------------------*/
	override public function onFreeze()  untyped {
		super.onFreeze() ;
		if ( fl_wallWalk ) {
			fl_intercept = true;
		}
		land();
	}

	/*------------------------------------------------------------------------
	EVENT: SONNÉ
	------------------------------------------------------------------------*/
	override public function onKnock()  untyped {
		super.onKnock() ;
		land();
	}

	/*------------------------------------------------------------------------
	EVENT: DÉGEL
	------------------------------------------------------------------------*/
	override public function onMelt()  untyped {
		super.onMelt() ;
		wallWalk() ;
	}

	/*------------------------------------------------------------------------
	EVENT: RÉVEIL
	------------------------------------------------------------------------*/
	override public function onWakeUp()  untyped {
		super.onWakeUp() ;
		wallWalk() ;
	}


	/*------------------------------------------------------------------------
	EVENT: TOUCHE UN MUR
	------------------------------------------------------------------------*/
	override public function onHitWall()  untyped {
		if ( !fl_wallWalk ) {
			if (world?.getCase( {x:cx,y:cy} )!=RootData.WALL) {
				dx = -dx ;
			}
			return ;
		}
	}

	/*------------------------------------------------------------------------
	EVENT: TOUCHE LE SOL
	------------------------------------------------------------------------*/
	override public function onHitGround(h:Dynamic)  untyped {
		super.onHitGround(h);
		fl_intercept = false;
		if ( fl_lost ) {
			fl_lost = false;
			deathTimer = null;
			wallWalk();
		}
	}


	/*------------------------------------------------------------------------
	UPDATE GRAPHIQUE
	------------------------------------------------------------------------*/
	override public function endUpdate()  untyped {
		super.endUpdate();

		if ( isHealthy() ) {
			// Excentrage
			xSub = xSubBase + cp?.x*subOffset;
			ySub = ySubBase + cp?.y*subOffset;
			if ( cp?.y>0 ) {
				ySub = ySubBase + subOffset*0.5;
			}
		}
		else {
			xSub = xSubBase;
			if ( fl_freeze ) {
				ySub = ySubBase;
			}
			else {
				ySub = ySubBase + subOffset*0.5;
			}
		}
		{ if (sub != null) sub._x += SUB_RECAL * (xSub - sub?._x) * speedFactor; }
		{ if (sub != null) sub._y += SUB_RECAL * (ySub - sub?._y) * speedFactor; }
	}



	/*------------------------------------------------------------------------
	MAIN
	------------------------------------------------------------------------*/
	override public function update()  untyped {
		// Radius auto (pour décapiter ^^)
		if ( game?.getOne(RootData.PLAYER)?.y>y ) {
			realRadius = RootData.CASE_WIDTH*1.4;
		}
		else {
			realRadius = RootData.CASE_WIDTH;
		}

		super.update();

		// Perte du point de fixation
		if ( lastSafe!=null && world?.getCase( {x: Entity.x_rtc(lastSafe?.x)+lastSafe?.cp?.x, y: Entity.y_rtc(lastSafe?.y)+lastSafe?.cp?.y} )<=0 ) {
			lastSafe = null;
			fl_gravity		= true;
			fl_wallWalk		= false;
			fl_hitGround	= true;
			fl_friction		= true;
			fl_lost			= true;
		}

		// Position sûre
		if ( world?.getCase( {x: cx+cp?.x, y: cy+cp?.y} )>0 ) {
			lastSafe = {
				x		: x,
				y		: y,
				xSpeed	: xSpeed,
				ySpeed	: ySpeed,
				cp		: {x:cp.x, y:cp.y},
			}
		}
	}



}


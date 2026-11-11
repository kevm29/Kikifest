// Converti automatiquement depuis hammer/entity/bad/ww/Crawler.mt (Motion Twin)
package entity.bad.ww;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
import Data as RootData;
class Crawler extends entity.bad.WallWalker
{
	public static var SCALE_RECAL:Float			= 0.2;
	public static var CRAWL_STRETCH:Float		= 1.8;
	public static var COLOR:Int				= 0xFF9146;
	public static var COLOR_ALPHA:Int			= 40;

	public static var SHOOT_SPEED:Int			= 6;
	public static var CHANCE_ATTACK:Int		= 10;
	public static var COOLDOWN				= RootData.SECOND * 2;
	public static var ATTACK_TIMER			= RootData.SECOND * 0.5;

	public var fl_attack		: Bool;
	public var attackCD		: Float;
	public var attackTimer		: Float;
	public var colorAlpha		: Float;

	public var xscale			: Float;
	public var yscale			: Float;

	public var blobCpt			: Float;



	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new()  untyped {
		super() ;
		speed			= 2;
		angerFactor		= 0.5;
		fl_attack		= false;
		attackCD		= RootData.PEACE_COOLDOWN;
		blobCpt			= 0;
	}


	/*------------------------------------------------------------------------
	INITIALISATION BAD
	------------------------------------------------------------------------*/
	override public function initBad(g:Dynamic,x:Dynamic,y:Dynamic)  untyped {
		super.initBad(g,x,y);
		scale(90);
	}


	/*------------------------------------------------------------------------
	ATTACHEMENT
	------------------------------------------------------------------------*/
	public static function attach(g:mode.GameMode,x:Dynamic,y:Dynamic)  untyped {
		var linkage:Dynamic = RootData.LINKAGES[RootData.BAD_CRAWLER];
		var mc : entity.bad.ww.Crawler = (( g.depthMan.attach(linkage,RootData.DP_BADS) ):Dynamic) ;
		mc?.initBad(g,x,y) ;
		return mc ;
	}




	/*------------------------------------------------------------------------
	MORT
	------------------------------------------------------------------------*/
	override public function killHit(dx:Dynamic)  untyped {
		super.killHit(dx);
		fl_attack		= false;
	}


	/*------------------------------------------------------------------------
	RENVOIE TRUE SI DISPONIBLE POUR UNE ACTION
	------------------------------------------------------------------------*/
	override public function isReady()  untyped {
		return super.isReady() && !fl_attack;
	}


	/*------------------------------------------------------------------------
	DÉMARRAGE ATTAQUE
	------------------------------------------------------------------------*/
	public function prepareAttack()  untyped {
		dx			= 0;
		dy			= 0;
		fl_attack	= true;
		fl_wallWalk	= false;
		attackTimer	= ATTACK_TIMER;
		playAnim(RootData.ANIM_BAD_SHOOT_START);
	}


	/*------------------------------------------------------------------------
	ATTAQUE
	------------------------------------------------------------------------*/
	public function attack()  untyped {
		// Fireball
		var s:Dynamic = entity.shoot.FireBall.attach( game, x,y);
		s?.moveTo(x,y);
		{ if (s != null) s.dx = -cp?.x*SHOOT_SPEED; }
		{ if (s != null) s.dy = -cp?.y*SHOOT_SPEED; }
		s?.scale(70);
		var n:Dynamic = MtStd.random(3)+2;
		if ( cp?.x!=0 ) {
			game?.fxMan?.inGameParticlesDir(RootData.PARTICLE_BLOB, x,y, n, -cp?.x);
		}
		else {
			game?.fxMan?.inGameParticles(RootData.PARTICLE_BLOB, x,y, n );
		}
		game?.fxMan?.attachExplosion(x,y,20);

		{ if (sub != null) sub._xscale = 150 + Math.abs(cp?.x)*150; }
		{ if (sub != null) sub._yscale = 150 + Math.abs(cp?.y)*150; }
		colorAlpha = COLOR_ALPHA;
		setColorHex( Math.round(colorAlpha), COLOR );

		// Bomb
//		var b = entity.bomb.bad.PoireBomb.attach(game,x,y);
//		var bdx = (xSpeed!=0) ? -xSpeed/Math.abs(xSpeed)*5 : -cp.x*15;
//		var bdy = (cp.y==-1) ? 0 : -cp.y*10;
//		b.setNext(bdx,bdy, 0, Data.ACTION_MOVE);

		attackCD = COOLDOWN;
		playAnim(RootData.ANIM_BAD_SHOOT_END);
	}


	/*------------------------------------------------------------------------
	RENVOIE TRUE SI DÉCIDE D'ATTAQUER
	------------------------------------------------------------------------*/
	public function decideAttack()  untyped {
		if ( fl_attack ) {
			return false;
		}

		var fl_inSight:Dynamic = false;
		var factor:Dynamic = 1.0;

		// Player au dessus/dessous
		if ( cp?.y!=0 && Math.abs(player?.x-x)<=RootData.CASE_WIDTH*2 ) {
			if ( cp?.y>0 && player?.y<y ) {
				fl_inSight = true;
			}
			if ( cp?.y<0 && player?.y>y ) {
				fl_inSight = true;
			}
		}

		// Player à gauche/droite
		if ( cp?.x!=0 && Math.abs(player?.y-y)<=RootData.CASE_HEIGHT*2 ) {
			if ( cp?.x>0 && player?.x<x ) {
				fl_inSight = true;
			}
			if ( cp?.x<0 && player?.x>x ) {
				fl_inSight = true;
			}
		}

		if ( fl_inSight ) {
			attackCD -= Timer.tmod*4;
			factor = 8;
		}

		return isReady() && isHealthy() && attackCD<=0 && MtStd.random(1000) < CHANCE_ATTACK*factor;
	}


	/*------------------------------------------------------------------------
	EVENT: FIN D'ANIM
	------------------------------------------------------------------------*/
	override public function onEndAnim(id:Dynamic)  untyped {
		super.onEndAnim(id);

		if ( id==RootData.ANIM_BAD_SHOOT_END.id ) {
			fl_attack = false;
			fl_wallWalk	= true;
			moveToSafePos();
			updateSpeed();
			if ( dx==0 && dy==0 ) {
				wallWalk();
			}
		}
	}


	/*------------------------------------------------------------------------
	EVENT: GEL
	------------------------------------------------------------------------*/
	override public function onFreeze()  untyped {
		super.onFreeze() ;
		fl_attack = false;
	}

	/*------------------------------------------------------------------------
	EVENT: SONNÉ
	------------------------------------------------------------------------*/
	override public function onKnock()  untyped {
		super.onKnock() ;
		fl_attack = false;
	}


	/*------------------------------------------------------------------------
	EVENT: TOUCHE LE SOL
	------------------------------------------------------------------------*/
	override public function onHitGround(h:Dynamic)  untyped {
		super.onHitGround(h);
		if ( Math.abs(h)>=RootData.CASE_HEIGHT*3 ) {
			{ if (sub != null) sub._xscale = 2*100*scaleFactor; }
			{ if (sub != null) sub._yscale = 0.2*100*scaleFactor; }
			{ if (sub != null) sub._y = ySubBase+10; }
			if ( !fl_freeze ) {
				game?.fxMan?.inGameParticles( RootData.PARTICLE_BLOB, x,y, MtStd.random(3)+2 );
			}
		}
	}


	/*------------------------------------------------------------------------
	UPDATE GRAPHIQUE
	------------------------------------------------------------------------*/
	override public function endUpdate()  untyped {
		super.endUpdate();
		if ( fl_attack ) {
			// Vibration attaque
			_x += MtStd.random(15)/10 * (MtStd.random(2)*2-1);
			_y += MtStd.random(15)/10 * (MtStd.random(2)*2-1);
			xscale = scaleFactor * 100 + MtStd.random(20)*(MtStd.random(2)*2-1);
			yscale = scaleFactor * 100 + MtStd.random(20)*(MtStd.random(2)*2-1);
		}
		else {
			xscale = scaleFactor * 100;
			yscale = scaleFactor * 100;
		}

		if ( fl_wallWalk ) {
			// Etirement en déplacement
			if ( dx!=0 ) {
				xscale = 100 * scaleFactor * CRAWL_STRETCH;
			}
			if ( dy!=0 ) {
				yscale = 100 * scaleFactor * CRAWL_STRETCH;
			}
		}

		if ( isHealthy() ) {
			// Déformation blob cosinus
			xscale+= 10*Math.sin(blobCpt);
			yscale+= 10*Math.cos(blobCpt);
			blobCpt+=Timer.tmod*0.1;
		}


		{ if (sub != null) sub._xscale += SCALE_RECAL * (xscale - sub?._xscale); }
		{ if (sub != null) sub._yscale += SCALE_RECAL * (yscale - sub?._yscale); }

		if ( colorAlpha>0 ) {
			colorAlpha-=Timer.tmod*3;
			if ( colorAlpha<=0 ) {
				resetColor();
			}
			else {
				setColorHex( Math.round(colorAlpha), COLOR );
			}
		}


	}



	/*------------------------------------------------------------------------
	MAIN
	------------------------------------------------------------------------*/
	override public function update()  untyped {
		if ( fl_attack ) {
			dx = 0;
			dy = 0;
		}

		super.update();

		// Cooldown d'attaque
		if ( attackCD>0 ) {
			attackCD-=Timer.tmod;
		}

		// Attaque
		if ( decideAttack() ) {
			if ( world?.getCase( {x:cx+cp?.x,y:cy+cp?.y} ) > 0 ) {
				prepareAttack();
			}
		}

		if ( fl_attack && attackTimer>0 ) {
			attackTimer-=Timer.tmod;
			if ( attackTimer<=0 ) {
				attack();
			}
		}
	}

}


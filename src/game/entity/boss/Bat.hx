// Converti automatiquement depuis hammer/entity/boss/Bat.mt (Motion Twin)
package entity.boss;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
import Data as RootData;
class Bat extends entity.Mover {

	public static var GLOW_BASE:Int	= 8;
	public static var GLOW_RANGE:Int	= 4;
	public static var RADIUS		= RootData.CASE_WIDTH*1.5;
	public static var SPEED:Float		= 6.5;
	public static var SHOOT_SPEED:Int	= 8;
	public static var LIVES:Int		= 3;
	public static var WAIT_TIME	= RootData.SECOND*3.5;
	public static var FLOAT_X:Int		= 5;
	public static var FLOAT_Y:Int		= 10;
	public static var MAX_FALL_ROTATION:Int	= 80;

	public var dir			: Int;
	public var lives		: Int;

	public var fl_trap		: Bool; // entity.Bad compatibility (spikes)

	public var fl_shield	: Bool;
	public var fl_immune	: Bool;
	public var immuneTimer	: Float;
	public var fl_move		: Bool;
	public var fl_wait		: Bool;
	public var fl_death	: Bool;
	public var fl_deathUp	: Bool;

	public var fl_anger	: Bool;

	public var floatOffset	: Float;
	public var tx			: Float;
	public var ty			: Float;

	public var fbList		: Array<entity.shoot.BossFireBall>;

//	var shieldMC	: MovieClip;
	public var glow		: mtflash.filters.GlowFilter;
	public var glowCpt		: Float;



	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new()  untyped {
		super() ;

		fl_hitGround	= false;
		fl_hitCeil 		= false;
		fl_hitWall		= false;
		fl_hitBorder	= true;
		fl_gravity		= false;
		fl_friction		= false;
		fl_moveable		= false;
		fl_alphaBlink	= false;
		fl_trap			= false;

		fl_move			= false;
		fl_wait			= false;
		fl_shield		= false;
		fl_immune		= false;
		immuneTimer		= 0;
		fl_anger		= false;
		floatOffset		= 0;

		fl_death		= false;
		fl_deathUp		= false;

		dir			= 1;
		lives		= LIVES;
		fbList		= new Array();

		glow		= new mtflash.filters.GlowFilter();
	}


	/*------------------------------------------------------------------------
	ATTACHEMENT
	------------------------------------------------------------------------*/
	public static function attach(g:mode.GameMode)  untyped {
		var linkage:Dynamic = "hammer_boss_bat";
		var mc : entity.boss.Bat = (( g.depthMan.attach(linkage,RootData.DP_BADS) ):Dynamic) ;
		mc?.initBoss(g) ;
		return mc ;
	}



	/*------------------------------------------------------------------------
	INITIALISATION GÉNÉRIQUE
	------------------------------------------------------------------------*/
	override public function init(g:Dynamic)  untyped {
		super.init(g);
		register(RootData.BAD);
		register(RootData.BOSS);
	}


	/*------------------------------------------------------------------------
	INITIALISATION DU BOSS
	------------------------------------------------------------------------*/
	public function initBoss(g:Dynamic)  untyped {
		init(g);
		moveTo(RootData.GAME_WIDTH*0.5,30) ;

		playAnim(RootData.ANIM_BAT_INTRO);
		_xscale = -scaleFactor*100;
		endUpdate();
	}


	override public function destroy()  untyped {
//		shieldMC.removeMovieClip();
		super.destroy();
		{ if (game != null) game.fl_clear = true; }
		game?.fxMan?.attachExit();
	}


	/*------------------------------------------------------------------------
	GÉNÈRE UN NOUVEAU POINT DE DESTINATION
	------------------------------------------------------------------------*/
	public function moveRandom()  untyped {
		if ( fl_death ) {
			return;
		}
		var limit:Dynamic = 0.8;
		do {
			tx = RootData.GAME_WIDTH*(1-limit)*0.5 + MtStd.random( Math.round(RootData.GAME_WIDTH*limit) );
			ty = RootData.GAME_HEIGHT*(1-limit)*0.5 + MtStd.random( Math.round(RootData.GAME_HEIGHT*limit) );
		} while (  distance(tx,ty)<RootData.BOSS_BAT_MIN_DIST  ||  Math.abs(x-tx)<RootData.BOSS_BAT_MIN_X_DIST  );

		var sign:Dynamic = Math.round(  (tx-x)/Math.abs(tx-x)  );
		if ( sign!=dir ) {
			flip();
		}
		else {
			playAnim(RootData.ANIM_BAT_MOVE);
			fl_move = true;
		}
	}


	/*------------------------------------------------------------------------
	CHANGE DE SENS GAUCHE-DROITE
	------------------------------------------------------------------------*/
	public function flip()  untyped {
		halt();
		playAnim(RootData.ANIM_BAT_SWITCH);
		dir = -dir;
		_xscale = dir*scaleFactor*100;
	}


	/*------------------------------------------------------------------------
	STOP / CONTINUE LE MOUVEMENT VERTICAL
	------------------------------------------------------------------------*/
	public function halt()  untyped {
		fl_stopStepping = true;
		fl_move = false;
		dx = 0;
		dy = 0;
	}


	/*------------------------------------------------------------------------
	GESTION IMMUNITÉ
	------------------------------------------------------------------------*/
	public function immune()  untyped {
		fl_immune	= true;
		immuneTimer	= RootData.SECOND*3;
	}

	public function removeImmunity()  untyped {
		fl_immune	= false;
		stopBlink();
		shield();
	}


	public function wait()  untyped {
		fl_wait = true;
	}

	public function stopWait()  untyped {
		fl_wait = false;
		x = _x;
		y = _y;
	}


	/*------------------------------------------------------------------------
	GESTION BOUCLIER
	------------------------------------------------------------------------*/
	public function shield()  untyped {
		if ( fl_shield || fl_death ) {
			return;
		}
//		shieldMC = game.depthMan.attach("hammer_player_shield", Data.DP_BADS) ;
//		shieldMC._xscale *= 1.5;
//		shieldMC._yscale = shieldMC._xscale;
		fl_shield	= true;
		filters		= null;

		glowCpt			= 0;
	}

	public function removeShield()  untyped {
//		shieldMC.removeMovieClip();
		fl_shield	= false;

		{ if (glow != null) glow.quality	= 1; }
		{ if (glow != null) glow.color		= 0xffd78c; }
		{ if (glow != null) glow.strength	= 180; }
		{ if (glow != null) glow.blurX		= GLOW_BASE; }
		{ if (glow != null) glow.blurY		= GLOW_BASE; }
		{ if (glow != null) glow.alpha		= 1.0; }
		filters			= [(cast (glow))];
	}


	/*------------------------------------------------------------------------
	TOUCHÉ PAR UNE BOMBE
	------------------------------------------------------------------------*/
	public function freeze(d:Dynamic)  untyped {
		if ( fl_immune || fl_death ) {
			return;
		}

		if ( fl_shield ) {
			removeShield();
			bossAnger();
		}
		else {
			stopWait();
			immune();
			shield();
			bossCalmDown();
			loseLife();
		}
	}


	/*------------------------------------------------------------------------
	BEHAVIOURS DÉSACTIVÉS
	------------------------------------------------------------------------*/
	public function knock(d:Dynamic)  untyped {	}
	override public function killHit(dx:Dynamic)  untyped { }


	/*------------------------------------------------------------------------
	APPELÉ SUR LA MORT DU JOUEUR
	------------------------------------------------------------------------*/
	public function onPlayerDeath()  untyped {
		bossCalmDown();
		shield();
	}


	/*------------------------------------------------------------------------
	EVENT: FIN D'ANIMATION
	------------------------------------------------------------------------*/
	override public function onEndAnim(id:Dynamic)  untyped {
		super.onEndAnim(id);


		// arrivée
		if ( id==RootData.ANIM_BAT_INTRO.id ) {
			_xscale = scaleFactor*100;
			shield();
			moveRandom();
		}

		// switch
		if ( id==RootData.ANIM_BAT_SWITCH.id ) {
			playAnim(RootData.ANIM_BAT_MOVE);
			fl_move = true;
		}
	}


	/*------------------------------------------------------------------------
	PRÉFIXE DU STEPPING
	------------------------------------------------------------------------*/
	override public function prefix()  untyped {
		super.prefix();
		if ( !fl_immune && !fl_death ) {
			var l:Dynamic = game?.getClose(RootData.PLAYER,x,y+RootData.CASE_HEIGHT*0.5, RADIUS, false);
			{ var i:Dynamic=0; while (i<l?.length) {
				var e : entity.Player = ((l[i]):Dynamic) ;
				e?.killHit(dx) ;
			
i++; } }
		}
	}


	/*------------------------------------------------------------------------
	INFIX DE STEPPING
	------------------------------------------------------------------------*/
	override public function infix()  untyped {
		super.infix();

	}


	/*------------------------------------------------------------------------
	EVENT: ACTION SUIVANTE
	------------------------------------------------------------------------*/
	override public function onNext()  untyped {
		if ( next?.action==RootData.ACTION_MOVE ) {
			if ( fl_anger ) {
				bossCalmDown();
				shield();
				return;
			}
			moveRandom();
			stopWait();
		}
		next = null;
	}


	/*------------------------------------------------------------------------
	PERD UNE VIE
	------------------------------------------------------------------------*/
	public function loseLife()  untyped {
		if ( fl_death ) {
			return;
		}
		blinkColor		= 0xff0000;
		blinkColorAlpha	= 100;
		blink(RootData.BLINK_DURATION);
		playAnim(RootData.ANIM_BAT_KNOCK);
		game?.fxMan?.attachExplosion(x,y,100);

		lives--;
		if ( lives<=0 ) {
			kill();
		}
		else {
			game?.shake(RootData.SECOND, 2);
		}
	}


	/*------------------------------------------------------------------------
	MORT
	------------------------------------------------------------------------*/
	public function kill()  untyped {
		removeShield();
		game?.shake(RootData.SECOND*5, 3);
		playAnim(RootData.ANIM_BAT_MOVE);
		blinkColorAlpha	= 50;
		halt();

		filters		= null;
		fl_wait		= false;
		fl_death 	= true;
		fl_deathUp	= true;
		rotation	= -30*dir;
		dy			= -1.5;
		if ( y>=RootData.GAME_HEIGHT*0.5 ) {
			dy*=2;
		}
		floatOffset	= 0;
		setNext(null,null,RootData.SECOND*9999,RootData.ACTION_MOVE);

	}


	/*------------------------------------------------------------------------
	ATTACHE UNE FIREBALL FLOTTANTE
	------------------------------------------------------------------------*/
	public function attachFireBall(ang:Dynamic, distFactor:Dynamic)  untyped {
		var s:Dynamic = entity.shoot.BossFireBall.attach(game,x,y);
		s?.initBossShoot( this, ang);
		fbList?.push(s);
		{ if (s != null) s.maxDist	*= distFactor; }
		{ if (s != null) s.distSpeed	*= distFactor; }
		return s;
	}


	/*------------------------------------------------------------------------
	ÉNERVEMENT: LANCE SON ATTAQUE
	------------------------------------------------------------------------*/
	public function bossAnger()  untyped {
		stopWait();
		halt();
		playAnim( RootData.ANIM_BAT_ANGER ) ;
		game?.fxMan?.attachExplosion(x,y,60);
		fl_anger	= true;

		var s:Dynamic;
		attachFireBall(0,	1.0);
		attachFireBall(180,	1.0);
		attachFireBall(0,	0.5);
		attachFireBall(180,	0.5);

		attachFireBall(90,	1.0);
		attachFireBall(270,	1.0);

		setNext(null,null, RootData.SECOND*15, RootData.ACTION_MOVE);

//		fl_alphaBlink	= false;
//		blinkColor		= 0xff6e2e;
//		blinkColorAlpha	= 65;
//		blink(Data.BLINK_DURATION);
	}


	/*------------------------------------------------------------------------
	FIN D'ÉNERVEMENT
	------------------------------------------------------------------------*/
	public function bossCalmDown()  untyped {
		{ var i:Dynamic=0; while (i<fbList?.length) {
			fbList[i]?.destroy();
		
i++; } }
		if ( fl_anger ) {
			game?.fxMan?.attachExplosion(x,y,50);
			playAnim(RootData.ANIM_BAT_WAIT);
		}
		fbList = new Array();
		setNext(null,null, RootData.SECOND, RootData.ACTION_MOVE);
		fl_anger = false;
	}


	/*------------------------------------------------------------------------
	MISE À JOUR GRAPHIQUE
	------------------------------------------------------------------------*/
	override public function endUpdate()  untyped {
		super.endUpdate();

		// flottement sur place
		if ( fl_wait ) {
			floatOffset -= 0.1*dir;
			_x = x+Math.sin(floatOffset)*FLOAT_X;
			_y = y+Math.cos(floatOffset)*FLOAT_Y;
		}

		// Mort
		if ( fl_death ) {
			if ( !fl_deathUp ) {
				_rotation = MAX_FALL_ROTATION + Math.sin(floatOffset)*7;
				floatOffset -= 0.5*dir;
				_x = x+Math.sin(floatOffset)*FLOAT_X*1.7;
			}
			else {
				floatOffset -= 0.2*dir;
				_x = x+Math.sin(floatOffset)*FLOAT_X*3;
			}
		}

		// Bouclier
//		if ( shieldMC._name != null ) {
//			shieldMC._x = _x;//-dir*20;
//			shieldMC._y = _y-5;
//		}

	}


	/*------------------------------------------------------------------------
	MAIN
	------------------------------------------------------------------------*/
	override public function update()  untyped {
		// Hurry up désactivé
		if ( !fl_death ) {
			{ if (game != null) game.huTimer = 0; }
		}
		else {
			{ if (game != null) game.huTimer += Timer.tmod*3; }
		}

		super.update();

		// Timer immunité
		if ( fl_immune ) {
			immuneTimer-=Timer.tmod;
			if ( immuneTimer<=0 ) {
				removeImmunity();
			}
		}

		if ( game?.manager?.isDev() && Key.isDown(75) && !fl_death ) {
			kill();
		}

		// Déplacement
		if ( fl_move ) {
			moveToPoint(tx,ty,SPEED);
			{ if (glow != null) glow.alpha	= 0.5; }
			if ( distance(tx,ty) <=10 ) {
				{ if (glow != null) glow.alpha = 1.0; }
				halt();
				wait();
				floatOffset	= 0;
				playAnim(RootData.ANIM_BAT_WAIT);
				setNext(null,null, WAIT_TIME, RootData.ACTION_MOVE);
			}
		}


		if ( !fl_shield && !fl_death ) {
			glowCpt += 0.3*Timer.tmod;
			{ if (glow != null) glow.blurX	= GLOW_BASE + GLOW_RANGE*Math.sin(glowCpt); }
			{ if (glow != null) glow.blurY	= glow?.blurX; }
			filters		= [(cast (glow))];
		}

		// Mort
		if ( fl_death ) {
			// Ascension
			if ( fl_deathUp && MtStd.random(6)==0 ) {
				game?.fxMan?.inGameParticles( RootData.PARTICLE_STONE, MtStd.random(RootData.GAME_WIDTH),0, MtStd.random(3)+1 );
				game?.shake(RootData.SECOND,1);
				game?.fxMan?.attachExplodeZone(
					x+MtStd.random(20)*(MtStd.random(2)*2-1),
					y+MtStd.random(20)*(MtStd.random(2)*2-1),
					MtStd.random(40)+10
				);
			}

			// Chute
			if ( !fl_deathUp && MtStd.random(2)==0 ) {
				var fx:Dynamic = game?.fxMan?.attachFx(
					x+MtStd.random(20)*(MtStd.random(2)*2-1),
					y-MtStd.random(40),
					"hammer_fx_pop"
				);
				{ if (fx?.mc != null) fx.mc._rotation = MtStd.random(360); }
				{ if (fx?.mc != null) fx.mc._xscale = MtStd.random(50)+50; }
				{ if (fx?.mc != null) fx.mc._yscale = fx?.mc?._xscale; }
//				game.fxMan.attachExplodeZone(
//					x+Std.random(20)*(Std.random(2)*2-1),
//					y+Std.random(20)*(Std.random(2)*2-1),
//					Std.random(20)+5
//				);
			}


			if ( y<=-50 && fl_deathUp ) {
				_xscale = scaleFactor*100;
				playAnim(RootData.ANIM_BAT_FINAL_DIVE);
				dy = 5;
				fl_deathUp = false;
			}

			if ( !fl_deathUp ) {
				rotation = Math.min(MAX_FALL_ROTATION, rotation+2.5*Timer.tmod);
				dy += 0.1*Timer.tmod;
				if ( MtStd.random(2)==0 ) {
					game?.fxMan?.inGameParticles( RootData.PARTICLE_SPARK, x,y, MtStd.random(2)+1 );
				}
				if ( y>=RootData.DEATH_LINE+RootData.GAME_HEIGHT*1.5 ) {
//					game.fxMan.inGameParticles( Data.PARTICLE_SPARK, x,Data.GAME_HEIGHT, Data.MAX_FX);
//					game.fxMan.attachFx(x,Data.GAME_HEIGHT*0.5, "hammer_fx_death");
//					game.fxMan.attachExplodeZone(x,y,100);
					game?.shake(RootData.SECOND*1.5, 5);
					this.destroy();
				}
			}
		}
	}
}


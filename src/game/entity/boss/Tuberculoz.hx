// Converti automatiquement depuis hammer/entity/boss/Tuberculoz.mt (Motion Twin)
package entity.boss;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
import Data as RootData;
class Tuberculoz extends entity.Mover {

	// Codes d'action
	public static var auto_inc:Int		= 1;
	public static var WALK			= auto_inc++;
	public static var JUMP			= auto_inc++;
	public static var DASH			= auto_inc++;
	public static var BOMB			= auto_inc++;
	public static var HIT			= auto_inc++;
	public static var BURN			= auto_inc++;
	public static var TORNADO		= auto_inc++;
	public static var TORNADO_END	= auto_inc++;
	public static var DIE			= auto_inc++;

	// Séquences d'attaque
	public static var seq_inc:Int		= 0;
	public static var SEQ_BURN		= seq_inc++;
	public static var SEQ_TORNADO	= seq_inc++;
	public static var SEQ_DASH		= seq_inc++;
	public static var LAST_SEQ		= seq_inc-1;
	public static var SEQ_DURATION	= RootData.SECOND*9;

	public static var LIVES:Int			= 100;
	public static var GROUND_Y:Int			= 446;
	public static var CENTER_OFFSET:Int	= -28;
	public static var HEAD_OFFSET_X:Int	= 10;
	public static var HEAD_OFFSET_Y:Int	= -54;
	public static var RADIUS			= RootData.CASE_WIDTH*1.7;
	public static var HEAD_RADIUS		= RootData.CASE_WIDTH*0.9;
	public static var MAX_BADS:Int			= 3; // compter +1 car les bads spawnent par 2

	public static var INVERT_KICK_X:Int	= 150; /* distance au bord à laquelle la bombe est
										renvoyée en arrière plutot qu'en avant */

	public static var WALK_SPEED:Int		= 3;
	public static var DASH_SPEED:Int		= 16;
	public static var FIREBALL_SPEED:Int	= 3;

	public static var TORNADO_INTRO	= RootData.SECOND*2;
	public static var TORNADO_DURATION	= RootData.SECOND*7;

	public static var JUMP_Y:Int			= 15;
	public static var JUMP_EST_X:Int		= 80;
	public static var JUMP_EST_Y:Int		= -145;

	public static var A_STEP:Int			= 5; // nb de bads tués avant spawn d'item A & B
	public static var B_STEP:Int			= 10;
	public static var EXTRA_LIFE_STEP:Int	= 30;

	// Chances sur 1000
	public static var CHANCE_PLAYER_JUMP:Int		= 22;
	public static var CHANCE_BOMB_JUMP:Int			= 15;
	public static var CHANCE_DASH:Int				= 1;
	public static var CHANCE_SPAWN:Int				= 25;
	public static var CHANCE_BURN:Int				= 5;
	public static var CHANCE_FINAL_ANGER:Int		= 35;


	public var _firstUniq		: Int;
	public var lives			: Int;
	public var dir				: Int;

	public var fl_trap			: Bool; // entity.Bad compatibility (spikes)

	public var fl_shield		: Bool;
	public var fl_immune		: Bool;
	public var immuneTimer		: Float;
	public var fl_death		: Bool;
	public var fl_defeated		: Bool;

	public var recents			: Array<Bool>;
	public var badKills		: Int;
	public var totalKills		: Int;

	public var action			: Int;
	public var dashCount		: Int;
	public var seq				: Int;
	public var seqTimer		: Float;
	public var fl_twister		: Bool;

	public var fl_bodyRadius	: Bool; // ! DEBUG ONLY !

	public var lifeBar			: Dynamic;
	public var itemA			: entity.item.SpecialItem;
	public var itemB			: entity.item.SpecialItem;

	public var fbCoolDown		: Float;

	public var defeatTimeOut	: Float;


	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new()  untyped {
		super() ;
		fl_hitGround	= false;
		fl_hitCeil 		= false;
		fl_hitWall		= false;
		fl_hitBorder	= true;
		fl_physics		= true;
		fl_gravity		= false;
		fl_friction		= false;
		fl_moveable		= false;
		fl_blink		= true;
		fl_alphaBlink	= false;
		fl_trap			= false;
		blinkColorAlpha	= 60;
		blinkColor		= 0xff6600;

		fl_shield		= false;
		fl_immune		= false;
		immuneTimer		= 0;
		recents			= new Array();
		fl_death		= false;
		fl_defeated		= false;

		fbCoolDown		= 0;
		defeatTimeOut	= 0;

		x			= RootData.GAME_WIDTH * 0.5;
		y			= GROUND_Y;
		dir			= MtStd.random(2)*2-1;

		lives		= LIVES;
		badKills	= 0;
		totalKills	= 0;
		seq			= 0;
		seqTimer	= SEQ_DURATION;
	}


	/*------------------------------------------------------------------------
	ATTACHEMENT
	------------------------------------------------------------------------*/
	public static function attach(g:mode.GameMode)  untyped {
		var linkage:Dynamic = "hammer_boss_human";
		var mc : entity.boss.Tuberculoz = (( g.depthMan.attach(linkage,RootData.DP_BADS) ):Dynamic) ;
		mc?.initBoss(g) ;
		return mc ;
	}


	/*------------------------------------------------------------------------
	INITIALISATION
	------------------------------------------------------------------------*/
	override public function init(g:Dynamic)  untyped {
		super.init(g);
//		register(Data.BAD);
		register(RootData.BOSS);
		_firstUniq = game?.getUniqId();
	}


	/*------------------------------------------------------------------------
	INITIALISATION BOSS
	------------------------------------------------------------------------*/
	public function initBoss(g:Dynamic)  untyped {
		init(g);
		playAnim(RootData.ANIM_BOSS_BAT_FORM);
		endUpdate();

		lifeBar		= (( game.depthMan.attach("hammer_interf_boss_bar",RootData.DP_INTERF) ):Dynamic);
		{ if (lifeBar != null) lifeBar._rotation = -90; }
		{ if (lifeBar != null) lifeBar._x = 0; }
		{ if (lifeBar != null) lifeBar._y	= RootData.GAME_HEIGHT*0.5; }
	}


	/*------------------------------------------------------------------------
	DESTRUCTION
	------------------------------------------------------------------------*/
	override public function destroy()  untyped {
		lifeBar?.removeMovieClip();
		super.destroy();
	}


	/*------------------------------------------------------------------------
	RENVOIE UNE LISTE D'ENTITÉS AU CONTACT
	------------------------------------------------------------------------*/
	public function getHitList(t:Dynamic)  untyped {
		var l:Dynamic;
		l = game?.getClose( t, x, y+CENTER_OFFSET, RADIUS, false );
		if ( action==WALK ) {
			var lh:Dynamic = game?.getClose( t, x+HEAD_OFFSET_X*dir, y+HEAD_OFFSET_Y, HEAD_RADIUS, false );
			{ var i:Dynamic=0; while (i<lh?.length) {
				l?.push(lh[i]);
			
i++; } }
		}
		return l;
	}


	/*------------------------------------------------------------------------
	CONTACTS AVEC D'AUTRES ENTITÉS
	------------------------------------------------------------------------*/
	override public function checkHits()  untyped {
		if ( fl_death ) {
			return;
		}

		var l:Dynamic;

		// Bombes
		l = getHitList(RootData.PLAYER_BOMB);
		{ var i:Dynamic=0; while (i<l?.length) {
			var b : entity.bomb.PlayerBomb = ((l[i]):Dynamic);
			if ( !b?.fl_explode && action==DASH && dx!=0 ) {
				b?.onExplode();
			}
			if ( !b?.fl_explode && !checkFlag(b?.uniqId) ) {
				kickBomb(b);
				flag( b?.uniqId );
			}
		
i++; } }


		// Joueur
		if ( !fl_immune ) {
			l = getHitList(RootData.PLAYER);
			{ var i:Dynamic=0; while (i<l?.length) {
				var p : entity.Player = ((l[i]):Dynamic);
				if ( !p?.fl_kill ) {
					p?.killHit(dx);
					if ( action==DASH && dx!=0 ) {
						game?.fxMan?.attachExplodeZone(p?.x, p?.y-RootData.CASE_HEIGHT*0.5, RootData.CASE_WIDTH*2);
					}
					game?.shake(RootData.SECOND,3);
				}
			
i++; } }
		}


		// Bads
		l = getHitList(RootData.BAD);
		{ var i:Dynamic=0; while (i<l?.length) {
			var b : entity.Bad = ((l[i]):Dynamic);
			if ( b?.uniqId!=uniqId && !b?.fl_kill && b?.fl_trap ) {
				if ( !fl_immune && b?.fl_freeze && b?.evaluateSpeed()>=RootData.ICE_HIT_MIN_SPEED ) {
					game?.fxMan?.inGameParticles(RootData.PARTICLE_CLASSIC_BOMB, x,y,4);
					game?.fxMan?.attachExplodeZone( b?.x, b?.y-RootData.CASE_HEIGHT*0.5, RootData.CASE_WIDTH*2 );
					loseLife(10);
					onKillBad();
					b?.destroy();
				}
				else {
					b?.killHit(dx);
					if ( action==DASH && dx!=0 ) {
						game?.fxMan?.attachExplodeZone(b?.x, b?.y-RootData.CASE_HEIGHT*0.5, RootData.CASE_WIDTH*2);
					}
				}
			}
		
i++; } }
	}


	/*------------------------------------------------------------------------
	FLAG PAR UNIQID
	------------------------------------------------------------------------*/
	public function flag(uid:Dynamic)  untyped {
		recents[uid-_firstUniq]=true;
	}

	public function checkFlag(uid:Dynamic)  untyped {
		return ( recents[uid-_firstUniq]==true );
	}


	/*------------------------------------------------------------------------
	MISE À JOUR BARRE DE VIE
	------------------------------------------------------------------------*/
	public function updateBar()  untyped {
		{ if (lifeBar?.barFade != null) lifeBar.barFade._xscale = lifeBar?.bar?._xscale; }
		lifeBar?.barFade?.gotoAndPlay("1");
		{ if (lifeBar?.bar != null) lifeBar.bar._xscale = lives/LIVES*100; }
	}


	/*------------------------------------------------------------------------
	PERTE D'UNE VIE
	------------------------------------------------------------------------*/
	public function loseLife(n:Dynamic)  untyped {
		if ( fl_immune ) {
			return;
		}

		lives-=n;
		updateBar();
		if ( lives<=0 ) {
			die();
		}
		else {
			game?.killPointer();
			immune();

			// Gros dégâts
			if ( n>1 ) {
				fl_gravity		= true;
				fl_hitBorder	= true;
				dy		= -9;
				next	= null;
				action	= HIT;
				playAnim(RootData.ANIM_BOSS_HIT);
				game?.shake(RootData.SECOND,4);
				// Petit moment de répit
				game?.destroyList(RootData.SHOOT);
				var lp:Dynamic = game?.getPlayerList();
				{ var i:Dynamic=0; while (i<lp?.length) {
					lp[i]?.knock(RootData.SECOND);
				
i++; } }
				var l:Dynamic = game?.getBadList();
				{ var i:Dynamic=0; while (i<l?.length) {
					var b:Dynamic = l[i];
					if ( fl_stable ) {
						{ if (b != null) b.dx = 0; }
					}
					b?.knock(RootData.KNOCK_DURATION);
				
i++; } }
			}
		}
	}

	/*------------------------------------------------------------------------
	IMMUNITÉ
	------------------------------------------------------------------------*/
	public function immune()  untyped {
		fl_immune	= true;
		immuneTimer	= RootData.SECOND*3;
		blink(RootData.BLINK_DURATION_FAST);
	}


	/*------------------------------------------------------------------------
	FAIT APPARAITRE N BOMBES EN JEU
	------------------------------------------------------------------------*/
	public function spawnBombs(n:Dynamic)  untyped {
		var bList:Dynamic = new Array();
		var fl_tooClose:Dynamic = false;

		{ var i:Dynamic=0; while (i<n) {
			var b:Dynamic = entity.bomb.bad.BossBomb.attach(game,0,0);
			do {
				b?.moveTo(
					MtStd.random(Math.round(RootData.GAME_WIDTH*0.8)) + RootData.GAME_WIDTH*0.1,
					MtStd.random(150)+100
				);
				fl_tooClose = false;
				{ var j:Dynamic=0; while (j<bList?.length) {
					if (  bList[j]?.distance(b?.x,b?.y)<=RootData.CASE_WIDTH*6  ) {
						fl_tooClose = true;
					}
				
j++; } }
			} while (fl_tooClose);
			game?.fxMan?.attachFx( b?.x, b?.y-RootData.CASE_HEIGHT*0.5, "hammer_fx_pop" );
			bList?.push(b);
		
i++; } }
	}


	/*------------------------------------------------------------------------
	POUSSE UNE BOMBE
	------------------------------------------------------------------------*/
	public function kickBomb(b:Dynamic)  untyped {
		if ( dx==0 ) {
			{ if (b != null) b.dx = dir*15; }
		}
		else {
			{ if (b != null) b.dx = dx*5; }
		}
		{ if (b != null) b.dy = -7; }
		b?.setLifeTimer(RootData.SECOND*0.7);
		if (  (b?.x<x && dir>0)  ||  (b?.x>x && dir<0)  ) {
			{ if (b != null) b.dx*=-1; }
		}
	}


	/*------------------------------------------------------------------------
	RENVOIE TRUE SI L'ENTITÉ EST AFFECTÉE PAR LE VENT
	------------------------------------------------------------------------*/
	public function isWindCompatible(e:Dynamic)  untyped {
		if ( !fl_twister && (e?.types&RootData.FX)==0 ) {
			return false;
		}
		if ( e?.fl_kill ) {
			return false;
		}
		if ( e?.uniqId==uniqId ) {
			return false;
		}
		if ( (e?.types&RootData.SHOOT)>0 || (e?.types&RootData.ITEM)>0 ) {
			return false;
		}
		if ( (e?.types&RootData.BAD)>0 && ((e):Dynamic)?.fl_freeze ) {
			return false;
		}
		if ( e?.y<30 ) {
			return false;
		}

		return true;
	}


	/*------------------------------------------------------------------------
	MAIN: DASH
	------------------------------------------------------------------------*/
	public function updateDash()  untyped {
		// Particules d'entrée
		if ( (oldX<0 && x>=0) || (oldX>0 && x<=0) ) {
			game?.fxMan?.inGameParticles( RootData.PARTICLE_STONE, 10, y-30, 6 );
		}
		if ( (oldX>RootData.GAME_WIDTH && x<=RootData.GAME_WIDTH) || (oldX<RootData.GAME_WIDTH && x>=RootData.GAME_WIDTH) ) {
			game?.fxMan?.inGameParticles( RootData.PARTICLE_STONE, RootData.GAME_WIDTH-10, y-30, 6 );
		}
		// Changement de direction
		if (  (dx<0 && x<=-RootData.GAME_WIDTH) || (dx>0 && x>=RootData.GAME_WIDTH*2)  ) {
			var p : entity.Player = (( game.getOne(RootData.PLAYER) ):Dynamic);
			dx = -dx;
			y = p?.y;
			dir = -dir;
			_xscale = -_xscale;
			if ( x<0 ) {
				game?.attachPointer( 0, p?.cy-2, p?.cx,p?.cy-2 );
			}
			else {
				game?.attachPointer( RootData.LEVEL_WIDTH, p?.cy-2, p?.cx,p?.cy-2 );
			}
			dashCount++;
			// Fin
			if ( dashCount>2 ) {
				if ( dir<0 ) {
					x = RootData.GAME_WIDTH+80;
				}
				else {
					x = -80;
				}
				y = GROUND_Y;
				game?.killPointer();
				fl_hitBorder = true;
				jump(JUMP_Y*0.6);
			}

		}
	}


	/*------------------------------------------------------------------------
	MAIN: TORNADE
	------------------------------------------------------------------------*/
	public function updateTornado()  untyped {

		if ( MtStd.random(3)>0 ) {
			// Particules
			if ( fl_twister || MtStd.random(5)==0 ) {
				game?.fxMan?.inGameParticles( RootData.PARTICLE_DUST, MtStd.random(RootData.GAME_WIDTH), MtStd.random(RootData.GAME_HEIGHT), MtStd.random(3));
			}

			// Vent
			var l:Dynamic = game?.getList(RootData.PHYSICS);
			{ var i:Dynamic=0; while (i<l?.length) {
				var e : entity.Physics = ((l[i]):Dynamic);
				if ( isWindCompatible(e) ) {
					var wind:Dynamic = MtStd.random(22)/10 + 0.5;
					if ( e?.fl_stable ) {
						if ( wind>RootData.GRAVITY ) {
							{ if (e != null) e.dy -= wind+3; }
							{ if (e != null) e.dx += MtStd.random(2) * (MtStd.random(2)*2-1); }
						}
					}
					else {
						{ if (e != null) e.dy-=wind; }
						{ if (e != null) e.dx += MtStd.random(2) * (MtStd.random(2)*2-1); }
					}
				}
			
i++; } }
		}
	}


	/*------------------------------------------------------------------------
	MAIN: MORT
	------------------------------------------------------------------------*/
	public function updateDeath()  untyped {
		// Roches
		if (  (dx!=0 || dy!=0 || next?.action==DIE)  &&  MtStd.random(3)==0  ) {
			if ( MtStd.random(2)==0 ) {
				game?.fxMan?.inGameParticles(RootData.PARTICLE_STONE, MtStd.random(RootData.GAME_WIDTH),0, MtStd.random(2));
			}
			else {
				game?.fxMan?.inGameParticles(RootData.PARTICLE_STONE, MtStd.random(RootData.GAME_WIDTH),MtStd.random(Math.round(RootData.GAME_HEIGHT*0.6)), MtStd.random(2));
			}
			game?.shake(RootData.SECOND,1);
		}

		// Atterissage
		if ( dy>0 && y>=GROUND_Y-8 ) {
			game?.shake(RootData.SECOND,5);
			land();
			y = GROUND_Y-8;
		}


		// Strikes
		if ( next?.action==DIE ) {
			dx *= game?.xFriction;
			if ( MtStd.random(3)==0 ) {
				var s:Dynamic = game?.depthMan?.attach("hammer_fx_strike", RootData.FX);
				playAnim(RootData.ANIM_BOSS_HIT);
				replayAnim();
				{ if (s != null) s._y = y - MtStd.random(60); }
				{ if (s != null) s._x = RootData.GAME_WIDTH*0.5; }
				var d:Dynamic = MtStd.random(2)*2-1;
				{ if (s != null) s._xscale = 100 * d; }
				if ( dx< 0 ) {
					dx = (MtStd.random(4)+2);
				}
				else {
					dx = -(MtStd.random(4)+2);
				}
			}
		}

		// Envol
		if ( animId!=RootData.ANIM_BOSS_DEATH.id ) {
			if ( MtStd.random(3)==0 ) {
				game?.fxMan?.attachExplodeZone(
					MtStd.random(20)*(MtStd.random(2)*2-1) + x,
					y - MtStd.random(70),
					MtStd.random(20)+8
				);
			}
		}
	}


	/*** ACTIONS ***/

	/*------------------------------------------------------------------------
	GESTION DE L'IA
	------------------------------------------------------------------------*/
	public function ia()  untyped {
		if ( action==WALK ) {
			seqTimer-=Timer.tmod;

			// Retournement au bord
			if (  (x>=RootData.GAME_WIDTH-RADIUS && dir>0) || (x<=RADIUS && dir<0) ) {
				dir = -dir;
				walk();
				return;
			}

			// Saute vers le joueur
			if ( MtStd.random(1000)<CHANCE_PLAYER_JUMP ) {
				if (  game?.getClose( RootData.PLAYER, x+JUMP_EST_X*dir, y+JUMP_EST_Y, RADIUS, false )?.length > 0  ) {
					jump(JUMP_Y);
					return;
				}
			}

			// Saute vers une bombe de joueur
			if ( MtStd.random(1000)<CHANCE_BOMB_JUMP ) {
				if (  game?.getClose( RootData.PLAYER_BOMB, x+JUMP_EST_X*dir, y+JUMP_EST_Y, RADIUS, false )?.length > 0  ) {
					jump(JUMP_Y);
					return;
				}
			}


			// Attaques spéciales
			if ( seqTimer<=0 && !fl_death ) {
				seqTimer = SEQ_DURATION;

				{ var __sw:Dynamic = seq;
if (__sw == (SEQ_BURN)) { burn(); 
					}
else if (__sw == (SEQ_DASH)) { dash(); 
					}
else if (__sw == (SEQ_TORNADO)) { tornado(); 
				}
}
				seq++;
				if ( seq>LAST_SEQ ) {
					seq=0;
				}
			}

			// Spawn d'ennemis
			if ( MtStd.random(1000)<CHANCE_SPAWN ) {
				if ( game?.getBadList()?.length + game?.getList(RootData.BAD_BOMB)?.length < MAX_BADS ) {
					dropBombs();
					return;
				}
			}


		}
	}


	/*------------------------------------------------------------------------
	ARRÊT
	------------------------------------------------------------------------*/
	public function halt()  untyped {
		dx = 0;
	}


	/*------------------------------------------------------------------------
	MARCHE
	------------------------------------------------------------------------*/
	public function walk()  untyped {
		if ( fl_death ) {
			setNext(null,null,RootData.SECOND*3,DIE);
			return;
		}

		if ( _xscale*dir<0 ) {
			playAnim(RootData.ANIM_BOSS_SWITCH);
			halt();
		}
		else {
			playAnim(RootData.ANIM_BOSS_WAIT);
			_xscale = dir*Math.abs(_xscale);
			dx = WALK_SPEED * dir;

			action = WALK;
		}
	}


	/*------------------------------------------------------------------------
	SAUT
	------------------------------------------------------------------------*/
	public function jump(jumpY:Dynamic)  untyped {
		action		= JUMP;
		fl_gravity	= true;
		dx			= dir*WALK_SPEED*1.6;
		dy			= -jumpY;

		playAnim(RootData.ANIM_BOSS_JUMP_UP);
	}


	/*------------------------------------------------------------------------
	ATTERRISSAGE
	------------------------------------------------------------------------*/
	public function land()  untyped {
		action		= null;
		fl_gravity	= false;
		y			= GROUND_Y;
		dy			= 0;

		playAnim(RootData.ANIM_BOSS_JUMP_LAND);
	}


	/*------------------------------------------------------------------------
	ATTAQUE DASH EN FIREBALL
	------------------------------------------------------------------------*/
	public function dash()  untyped {
		action = DASH;
		halt();
		dashCount = 0;
		playAnim(RootData.ANIM_BOSS_DASH_START);
	}


	/*------------------------------------------------------------------------
	LANCÉ DE BOMBES
	------------------------------------------------------------------------*/
	public function dropBombs()  untyped {
		action = BOMB;
		halt();
		playAnim(RootData.ANIM_BOSS_BOMB);
	}


	/*------------------------------------------------------------------------
	EMBRASEMENT
	------------------------------------------------------------------------*/
	public function burn()  untyped {
		halt();
		playAnim(RootData.ANIM_BOSS_BURN_START);
		setNext(null,null,RootData.SECOND*3.5,BURN);
		action = BURN;
	}


	/*------------------------------------------------------------------------
	TORNADE (??)
	------------------------------------------------------------------------*/
	public function tornado()  untyped {
		halt();
		playAnim(RootData.ANIM_BOSS_TORNADO_START);
		setNext( null,null, TORNADO_INTRO, TORNADO );
		fl_twister = false;
		action = TORNADO;
	}


	/*------------------------------------------------------------------------
	MORT
	------------------------------------------------------------------------*/
	public function die()  untyped {
		halt();
		action			= null;
		defeatTimeOut	= RootData.SECOND*15;
		fl_death		= true;
		fl_gravity		= true;
		var dist:Dynamic		= RootData.GAME_WIDTH*0.5-x;
		dx				= dist*0.025;
		dy				= -13;
		dir				= (dx>0)?-1:1;
		_xscale			= scaleFactor*100 * dir;
		lifeBar?.removeMovieClip();

		game?.bulletTime(RootData.SECOND*2);
		game?.shake(RootData.SECOND,5);
		playAnim(RootData.ANIM_BOSS_HIT);

		// bads
		var bl:Dynamic = game?.getBadList();
		{ var i:Dynamic=0; while (i<bl?.length) {
			var b:Dynamic = bl[i];
			{ if (b != null) b.dropReward = null; }
			b?.killHit( MtStd.random(50)*(MtStd.random(2)*2-1) );
			{ if (b != null) b.dy-=MtStd.random(10); }
			game?.fxMan?.inGameParticles( RootData.PARTICLE_SPARK, b?.x, b?.y, MtStd.random(3)+1 );
		
i++; } }

		// bombes
		var l:Dynamic = game?.getList(RootData.BOMB);
		{ var i:Dynamic=0; while (i<l?.length) {
			l[i]?.destroy();
			game?.fxMan?.inGameParticles( RootData.PARTICLE_CLASSIC_BOMB, l[i]?.x, l[i]?.y, MtStd.random(3)+1 );
		
i++; } }

		// entités diverses
		game?.destroyList(RootData.SHOOT);
		game?.destroyList(RootData.BOMB);

	}


	/*------------------------------------------------------------------------
	GRAND NETTOYAGE FINAL + OUVERTURE DE SORTIE
	------------------------------------------------------------------------*/
	public function final_()  untyped {
		if ( fl_defeated ) {
			return;
		}
		halt();
		openExit();
		game?.fxMan?.attachExplodeZone(x,y+CENTER_OFFSET,150);
		game?.fxMan?.inGameParticles( RootData.PARTICLE_TUBERCULOZ, x,y+CENTER_OFFSET, RootData.MAX_FX );
		game?.shake(RootData.SECOND,5);
		playAnim(RootData.ANIM_BOSS_DEATH);
		game?.destroyList(RootData.BAD);
		{ if (game != null) game.fl_clear = true; }
		fl_defeated = true;
	}


	/*------------------------------------------------------------------------
	ACTIONS APRÈS LA MORT DU BOSS
	------------------------------------------------------------------------*/
	public function openExit()  untyped {
		if ( fl_defeated ) {
			return;
		}
		game?.depthMan?.swap( (cast (this)), RootData.DP_SPRITE_BACK_LAYER );
		var cloak:Dynamic = entity.item.SpecialItem.attach(game, RootData.GAME_WIDTH*0.5, RootData.GAME_HEIGHT-40, 113, null);
		{ if (cloak != null) cloak.dy = -20; }

		var tubkey:Dynamic = entity.item.ScoreItem.attach(game, RootData.GAME_WIDTH*0.5-40, RootData.GAME_HEIGHT-40, 199, null);
		{ if (tubkey != null) tubkey.dy = -25; }

		var door:Dynamic = game?.world?.view?.attachSprite(  "$door", game?.flipCoordReal(Entity.x_ctr(5)), Entity.y_ctr(6), true );
		game?.fxMan?.inGameParticles( RootData.PARTICLE_STONE, door?._x+RootData.CASE_WIDTH, door?._y, 3+MtStd.random(10) );
		game?.fxMan?.attachExplodeZone( door?._x+RootData.CASE_WIDTH, door?._y-RootData.CASE_HEIGHT, 40 );
		game?.playMusic(0);

		// bonus vies
		var pl:Dynamic = game?.getPlayerList();
		{ var i:Dynamic=0; while (i<pl?.length) {
			var p:Dynamic = pl[i];
			var bonus:Dynamic = p?.lives*20000;
			p?.getScore( p, bonus );
			game?.fxMan?.attachAlert( Lang.get(35) + p?.lives + " x " + RootData.formatNumber(20000) );
		
i++; } }
	}



	/*** EVENTS ***/

	/*------------------------------------------------------------------------
	EVENT: FIN D'ANIM
	------------------------------------------------------------------------*/
	override public function onEndAnim(id:Dynamic)  untyped {
		super.onEndAnim(id);

		// Retournement
		if ( id==RootData.ANIM_BOSS_SWITCH.id ) {
			walk();
		}

		// Démarrage
		if ( id==RootData.ANIM_BOSS_BAT_FORM.id ) {
			walk();
		}

		// Atterrissage
		if ( id==RootData.ANIM_BOSS_JUMP_LAND.id ) {
			walk();
		}

		// dash
		if ( id==RootData.ANIM_BOSS_DASH_START.id ) {
			playAnim(RootData.ANIM_BOSS_DASH_BUILD);
			setNext( null,null, RootData.SECOND*2, DASH );
		}

		// dash
		if ( id==RootData.ANIM_BOSS_DASH.id ) {
			playAnim(RootData.ANIM_BOSS_DASH_LOOP);
		}

		// bombes
		if ( id==RootData.ANIM_BOSS_BOMB.id ) {
			spawnBombs(2);
			walk();
		}

		// hit
		if ( id==RootData.ANIM_BOSS_HIT.id ) {
			playAnim(RootData.ANIM_BOSS_WAIT);
		}

		// Enflammé
		if ( id==RootData.ANIM_BOSS_BURN_START.id ) {
			playAnim(RootData.ANIM_BOSS_BURN_LOOP);
		}

		// Tornado
		if ( id==RootData.ANIM_BOSS_TORNADO_START.id ) {
			playAnim(RootData.ANIM_BOSS_TORNADO_LOOP);
		}

		// Fin de tornade
		if ( id==RootData.ANIM_BOSS_TORNADO_END.id ) {
			walk();
		}
	}


	/*------------------------------------------------------------------------
	EVENT: ACTION SUIVANTE
	------------------------------------------------------------------------*/
	override public function onNext()  untyped {
		// Dash
		if ( next?.action==DASH ) {
			playAnim(RootData.ANIM_BOSS_DASH);
			dx = dir * DASH_SPEED;
			fl_hitBorder = false;
		}


		// Burn
		if ( next?.action==BURN ) {
			playAnim(RootData.ANIM_BOSS_TORNADO_END);
			var n:Dynamic=10;
			{ var i:Dynamic=0; while (i<n) {
				var bx:Dynamic = i*RootData.GAME_WIDTH/n + RootData.CASE_WIDTH;
				if ( Math.abs(bx-x)>60 ) {
					var s:Dynamic = entity.shoot.FireBall.attach(
						game,
						bx,
						RootData.GAME_HEIGHT
					);
					s?.moveUp(FIREBALL_SPEED);
				}
			
i++; } }
		}

		// Tornade
		if ( next?.action==TORNADO ) {
			if ( !fl_twister ) {
				fl_twister = true;
				setNext(null,null,TORNADO_DURATION,TORNADO);
				return;
			}
			else {
				playAnim(RootData.ANIM_BOSS_TORNADO_END);
			}
		}

		// Mort
		if ( next?.action==DIE ) {
			final_();
		}

		next = null;
	}


	/*------------------------------------------------------------------------
	MORT DU JOUEUR
	------------------------------------------------------------------------*/
	public function onPlayerDeath()  untyped {
		// do nothing
	}


	/*------------------------------------------------------------------------
	MORT D'UN BAD
	------------------------------------------------------------------------*/
	public function onKillBad()  untyped {
		badKills++;
		totalKills++;

		// Items multi-bombe
		if ( badKills>=B_STEP ) {
			itemB?.destroy();
			itemB = entity.item.SpecialItem.attach(game, RootData.GAME_WIDTH-31,0, 5,null);
			itemB?.setLifeTimer(0);
			badKills=0;
		}
		else {
			if ( badKills==A_STEP ) {
				itemA?.destroy();
				itemA = entity.item.SpecialItem.attach(game, 31,0, 4,null);
				itemA?.setLifeTimer(0);
			}
		}

		// Vie supplémentaire
		if ( totalKills==EXTRA_LIFE_STEP ) {
			var it:Dynamic = entity.item.SpecialItem.attach(game, 214,340, 36,null);
			it?.setLifeTimer(0);
		}
	}


	/*------------------------------------------------------------------------
	EVENT: EXPLOSION D'UNE BOMBE DANS LE LEVEL
	------------------------------------------------------------------------*/
	public function onExplode(x:Dynamic,y:Dynamic,radius:Dynamic)  untyped {
		if ( fl_death ) {
			return;
		}
		var d:Dynamic = Math.sqrt(  Math.pow(this.x-x,2)  +  Math.pow(this.y+CENTER_OFFSET-y,2)  );
		if ( d<=radius && action!=DASH ) {
			loseLife(1);
		}
	}


	/*------------------------------------------------------------------------
	MISE À JOUR GRAPHIQUE
	------------------------------------------------------------------------*/
	override public function endUpdate()  untyped {
		super.endUpdate();

		if ( dir<0 ) {
			_xscale = -Math.abs(_xscale);
		}
		else {
			_xscale = Math.abs(_xscale);
		}


		// Tornade
		if ( action==TORNADO ) {
			updateTornado();
		}

		// Link la barre de vie aux tremblements du jeu
		{ if (lifeBar != null) lifeBar._x = game?.mc?._x-game?.xOffset; }
		{ if (lifeBar != null) lifeBar._y	= game?.mc?._y+RootData.GAME_HEIGHT*0.5; }
	}


	/*------------------------------------------------------------------------
	MAIN
	------------------------------------------------------------------------*/
	override public function update()  untyped {
		var prev:Dynamic;

		// Hurry up désactivé
		if ( !fl_death ) {
			{ if (game != null) game.huTimer = 0; }
		}
		else {
			{ if (game != null) game.huTimer += Timer.tmod*3; }
		}

		ia();

		// Immunité
		if ( fl_immune ) {
			immuneTimer-=Timer.tmod;
			if (immuneTimer<=0) {
				fl_immune = false;
				stopBlink();
			}
		}

		// Phases de saut
		if ( action==JUMP ) {
			if ( dy>=0 && animId==RootData.ANIM_BOSS_JUMP_UP.id ) {
				playAnim(RootData.ANIM_BOSS_JUMP_DOWN);
			}
			if ( dy>0 && y>=GROUND_Y ) {
				land();
			}
		}

		// Tir de fireball de dernier recours
		if ( !fl_death && lives<=50 ) {
			fbCoolDown-=Timer.tmod;
			if ( action==WALK && fbCoolDown<=0 && game?.countList(RootData.SHOOT)<2 && MtStd.random(1000)<=CHANCE_FINAL_ANGER ) {
				fbCoolDown = RootData.SECOND*0.5;
				var s:Dynamic = entity.shoot.FireBall.attach(
					game,
					x,
					y
				);
				s?.moveToTarget(game?.getOne(RootData.PLAYER), FIREBALL_SPEED*2);
			}
		}

		// Phases hit
		if ( action==HIT ) {
			if ( dy>0 && y>=GROUND_Y ) {
				land();
			}
		}


		// Fix: tuberculoz ne mourrant pas ?
		if ( defeatTimeOut>0 && !fl_defeated ) {
			defeatTimeOut-=Timer.tmod;
			if ( defeatTimeOut<=0 ) {
				final_();
			}
		}

		// Mort
		if ( fl_death ) {
			updateDeath();
		}

		super.update();

		// Dash
		if ( action==DASH ) {
			updateDash();
		}

		// DEBUG
		if ( game?.manager?.isDev() && Key.isDown(Key.ENTER) ) {
			die();
		}

		if ( game?.manager?.isDev() && Key.isDown(Key.SHIFT) ) {
			lives-=1;
			updateBar();
		}

		checkHits();

	}
}


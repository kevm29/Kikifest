// Converti automatiquement depuis hammer/entity/Bad.mt (Motion Twin)
package entity;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
import Data as RootData;
import entity.item.ScoreItem;

class Bad extends entity.Mover
{
	public var player			: entity.Player ;
	public var fl_playerClose	: Bool;
	public var closeDistance	: Int;

	public var freezeTimer		: Float;
	public var freezeTotal		: Float;
	public var fl_freeze		: Bool;

	public var fl_ninFriend	: Bool;
	public var fl_ninFoe		: Bool;

	public var knockTimer		: Float;
	public var fl_knock		: Bool;
	public var fl_showIA		: Bool; // shows an icon overhead when player is close

	public var deathTimer		: Float;

	public var fl_trap			: Bool; // false if immunity against traps (spears)
	public var comboId			: Int;
	public var yTrigger		: Float;
	public var anger			: Int;
	public var angerFactor		: Float;
	public var speedFactor		: Float;

	public var chaseFactor		: Float;
	public var maxAnger		: Int;

	public var realRadius		: Float; // if not null, will be used as additionnal check for "hitTest"

	public var iceMc			: MovieClip;


	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new()  untyped {
		super();

		comboId = null;

		freezeTimer	= 0;
		fl_freeze	= false;

		knockTimer	= 0;
		fl_knock	= false;
		yTrigger	= null;

		fl_ninFoe	= false;
		fl_ninFriend= false;
		fl_showIA 	= false;
		fl_trap		= true; //
		fl_strictGravity	= false;
		fl_largeTrigger		= true;
		closeDistance		= RootData.IA_CLOSE_DISTANCE;


		realRadius	= RootData.CASE_WIDTH;

		maxAnger	= RootData.MAX_ANGER;
		speedFactor	= 1.0;
		anger		= 0;
		angerFactor	= 0.7 ; // Ajout au speedFactor pour chaque point de anger
		chaseFactor	= 5.0; // multiplicateur aux chances de décision (pour suivre le joueur)
		calcSpeed();
	}


	/*------------------------------------------------------------------------
	INITIALISATION
	------------------------------------------------------------------------*/
	override public function init(g:mode.GameMode)  untyped {
		super.init(g);
		register(RootData.BAD);
		register(RootData.BAD_CLEAR);
	}


	/*------------------------------------------------------------------------
	INITIALISATION SPÉCIALE DES BADS
	------------------------------------------------------------------------*/
	public function initBad(g:mode.GameMode,x:Dynamic,y:Dynamic):Void  untyped {
		init(g);
		moveTo(x+RootData.CASE_WIDTH*0.5, y+RootData.CASE_HEIGHT) ; // colle les bads au sol
		endUpdate();
	}


	/*------------------------------------------------------------------------
	ANIM DE MORT
	------------------------------------------------------------------------*/
	override public function killHit(dx:Dynamic)  untyped {
		if ( fl_freeze ) {
			game?.fxMan?.inGameParticles( RootData.PARTICLE_ICE, x,y, MtStd.random(3)+2 );
			game?.fxMan?.attachExplosion( x,y-RootData.CASE_HEIGHT*0.5, RootData.CASE_WIDTH*2 );
			melt();
		}
		if ( fl_knock) {
			wakeUp();
		}
		if (dx==null) {
			dx = MtStd.random(200)/10 * (MtStd.random(2)*2-1);
		}
		playAnim(RootData.ANIM_BAD_DIE);
		super.killHit(dx);
	}


	/*------------------------------------------------------------------------
	MORT SANS CONDITION, NON-CONTRABLE
	------------------------------------------------------------------------*/
	public function forceKill(dx:Dynamic)  untyped {
		killHit(dx);
	}


	/*------------------------------------------------------------------------
	MORT SUR PLACE
	------------------------------------------------------------------------*/
	public function burn()  untyped {
		var fx:Dynamic = game?.fxMan?.attachFx( x,y, "hammer_fx_burning" );
		dropReward() ;
		onKill();
		destroy();
	}


	/*------------------------------------------------------------------------
	RENVOIE TRUE SI LE MONSTRE EST EN ÉTAT DE FONCTIONNER
	------------------------------------------------------------------------*/
	public function isHealthy()  untyped {
		return !fl_kill && !fl_freeze && !fl_knock;
	}


	/*------------------------------------------------------------------------
	RENCONTRE UNE AUTRE ENTITÉ
	------------------------------------------------------------------------*/
	override public function hit(e:Entity)  untyped {
		// Joueur
		if ( (e?.types & RootData.PLAYER) > 0 ) {
			var et:entity.Player = ((e):Dynamic);

			// additionnal (optionnal) check with distance
			var fl_hit:Dynamic = true;
			if ( realRadius!=null ) {
				if (  distance(et?.x,et?.y) > realRadius  ) {
					fl_hit = false;
				}
			}
			if ( fl_hit ){
				if ( et?.specialMan?.actives[86] ) {
					// bonbon fantome
					game?.fxMan?.attachFx(x,y-RootData.CASE_HEIGHT,"hammer_fx_shine");
					et?.getScore(this, 666);
					this.destroy();
				}
				else {
					if ( isHealthy() ) {
						if ( et?.specialMan?.actives[114] && et?.oldY<=y-RootData.CASE_HEIGHT*0.5 && et?.dy>0 ) {
							{ if (et != null) et.dy = -RootData.PLAYER_AIR_JUMP*2.5; }
							freeze(RootData.FREEZE_DURATION);
							setCombo(null);
							game?.fxMan?.attachExplodeZone(x,y-5,30);
							game?.fxMan?.inGameParticles(RootData.PARTICLE_CLASSIC_BOMB, x,y-5, 3+MtStd.random(3));
						}
						else {
							if ( !et?.fl_shield ) {
								if (et?.x<x) {
									et?.killHit(-1);
								}
								else {
									et?.killHit(1);
								}
							}
						}
					}
				}
			}
		}

		// Bads
		if ( (e?.types & RootData.BAD) > 0 ) {
			// Gelé qui shoot un autre monstre
			var et:entity.Bad = ((e):Dynamic);
			if ( fl_freeze && et?.fl_freeze==false ) {
				var spd:Dynamic = evaluateSpeed();
				if ( spd>=RootData.ICE_HIT_MIN_SPEED ) {
					et?.setCombo(comboId);
					et?.killHit(dx);
				}
				else {
					if ( spd>=RootData.ICE_KNOCK_MIN_SPEED ) {
						et?.setCombo(comboId);
						et?.knock(RootData.KNOCK_DURATION);
					}
				}

			}
		}
	}


	/*------------------------------------------------------------------------
	DÉFINI L'ID DE COMBO
	------------------------------------------------------------------------*/
	public function setCombo(id:Dynamic)  untyped {
		if (!fl_kill) {
			comboId = id;
		}
	}


	/*------------------------------------------------------------------------
	JOUE UNE ANIM
	------------------------------------------------------------------------*/
	override public function playAnim(o:Dynamic)  untyped {
		if ( o?.id==RootData.ANIM_BAD_WALK.id && anger>0 ) {
			super.playAnim(RootData.ANIM_BAD_ANGER);
		}
		else {
			super.playAnim(o);
		}
	}


	/*------------------------------------------------------------------------
	CALCULE LE FACTEUR VITESSE
	------------------------------------------------------------------------*/
	public function calcSpeed()  untyped {
		speedFactor = 1.0 + angerFactor*anger;
		if ( game?.globalActives[69] ) speedFactor *= 0.6 ; // tortue
		if ( game?.globalActives[80] ) speedFactor *= 0.3 ; // escargot
	}


	/*------------------------------------------------------------------------
	MODIFIE LE FACTEUR SPEED
	------------------------------------------------------------------------*/
	public function updateSpeed()  untyped {
		calcSpeed();
		// extended classes will add call for dx/dy update
	}


	/*------------------------------------------------------------------------
	GÉNÈRE UNE RÉCOMPENSE SUR LE MONSTRE
	------------------------------------------------------------------------*/
	public function dropReward()  untyped {
		var itY:Dynamic;
		// Y de spawn de l'item
		if ( world?.inBound(cx,cy) ) {
			itY = y;
		}
		else {
			itY = -30;
		}

		if ( comboId!=null ) {
			// Crystal normal
			var n:Dynamic = game?.countCombo(comboId) - 1;
			if ( n+1 > game?.statsMan?.read( RootData.STAT_MAX_COMBO ) ) {
				game?.statsMan?.write( RootData.STAT_MAX_COMBO, n+1 );
			}
			ScoreItem.attach(game, x,itY, 0,n);
		}
		else {
			// Diamant
			ScoreItem.attach(game, x,itY, RootData.DIAMANT,null);
		}
	}


	/*------------------------------------------------------------------------
	CALCULE LA VITESSE APPROXIMATIVE
	------------------------------------------------------------------------*/
	public function evaluateSpeed()  untyped {
		return Math.sqrt( Math.pow(dx,2)+Math.pow(dy,2) );
	}


	/*------------------------------------------------------------------------
	DESTRUCTION
	------------------------------------------------------------------------*/
	override public function destroy()  untyped {
		super.destroy();
//		if ( (types&Data.BAD_CLEAR)>0 ) {
//			game.checkLevelClear();
//		}
		iceMc?.removeMovieClip();
	}


	/*------------------------------------------------------------------------
	AUTORISE L'APPLICATION DU PATCH COLLISION AU SOL (ESCALIERS)
	------------------------------------------------------------------------*/
	override public function needsPatch()  untyped {
		return fl_freeze || fl_knock;
	}


	// *** EVENTS


	/*------------------------------------------------------------------------
	EVENT: LIGNE DU BAS
	------------------------------------------------------------------------*/
	override public function onDeathLine()  untyped {
		var mc:Dynamic = game?.depthMan?.attach("hammer_fx_death", RootData.FX);
		{ if (mc != null) mc._x = x; }
		{ if (mc != null) mc._y = RootData.GAME_HEIGHT*0.5; }
		game?.shake(10,3);
		game?.soundMan?.playSound("sound_bad_death", RootData.CHAN_BAD);
		deathTimer = 0;

		super.onDeathLine();

		if ( !fl_kill ) {
			onKill();
		}
		dropReward();
		destroy();
	}


	/*------------------------------------------------------------------------
	EVENT: FIN DE FREEZE
	------------------------------------------------------------------------*/
	public function onMelt()  untyped {
		iceMc?.removeMovieClip();
	}


	/*------------------------------------------------------------------------
	EVENT: FIN DE KNOCK
	------------------------------------------------------------------------*/
	public function onWakeUp()  untyped {
		// do nothing
	}


	/*------------------------------------------------------------------------
	EVENT: FREEZE
	------------------------------------------------------------------------*/
	public function onFreeze()  untyped {
		playAnim(RootData.ANIM_BAD_FREEZE);
		if ( iceMc?._name==null ) {
			iceMc = game?.depthMan?.attach("hammer_bad_ice", RootData.DP_BADS);
		}
	}


	/*------------------------------------------------------------------------
	EVENT: ASSOMÉ
	------------------------------------------------------------------------*/
	public function onKnock()  untyped {
		playAnim(RootData.ANIM_BAD_KNOCK);
	}


	/*------------------------------------------------------------------------
	EVENT: HURRY UP!
	------------------------------------------------------------------------*/
	public function onHurryUp()  untyped {
		angerMore();
	}


	/*------------------------------------------------------------------------
	EVENT: MORT
	------------------------------------------------------------------------*/
	override public function onKill()  untyped {
		super.onKill();

		// friend is killed !
		if ( fl_ninFriend ) {
			var plist:Dynamic = game?.getPlayerList();
			{ var i:Dynamic=0; while (i<plist?.length) {
				var p:Dynamic = plist[i];
				if ( !p?.fl_kill ) {
					p?.unshield();
					p?.killHit( MtStd.random(20) );
					game?.fxMan?.detachLastAlert();
					game?.fxMan?.attachAlert(Lang.get(44));
				}
			
i++; } }
		}

		// foe killed
		if ( fl_ninFoe ) {
			var blist:Dynamic = game?.getBadClearList();
			var n:Dynamic=1;
			{ var i:Dynamic=0; while (i<blist?.length) {
				var b:Dynamic = blist[i];
				{ if (b != null) b.fl_ninFriend = false; }
				if ( b?.uniqId!=uniqId ) {
					ScoreItem.attach(game, b?.x,b?.y, 0, n);
					b?.destroy();
					n++;
				}
				b?.unstick();
			
i++; } }

			ScoreItem.attach(game, RootData.GAME_WIDTH*0.5,-20, 236, null);
			game?.fxMan?.detachLastAlert();
			game?.fxMan?.attachAlert(Lang.get(45));
		}

		deathTimer = RootData.SECOND*5;
		game?.onKillBad(this);
	}

	/*------------------------------------------------------------------------
	EVENT: TOUCHE LE SOL
	------------------------------------------------------------------------*/
	override public function onHitGround(h:Dynamic)  untyped {
		super.onHitGround(h);
		if ( fl_freeze ) {
			game?.fxMan?.inGameParticles( RootData.PARTICLE_ICE_BAD, x,y, MtStd.random(3)+2 );
			if ( h >= RootData.DUST_FALL_HEIGHT ) {
				game?.fxMan?.dust(cx,cy+1);
			}
		}
	}


	// *** CHANGEMENTS ÉTATS

	/*------------------------------------------------------------------------
	GÈLE CE MONSTRE
	------------------------------------------------------------------------*/
	public function freeze(timer:Dynamic)  untyped {
		if ( fl_kill ) {
			return;
		}
		if ( fl_knock ) {
			wakeUp();
		}

//		game.soundMan.playSound("sound_freeze", Data.CHAN_BAD);

		fallFactor = RootData.FALL_FACTOR_FROZEN;
		fl_slide = true;
		freezeTimer = timer;
		freezeTotal = timer;
		fl_freeze = true;
		onFreeze();
	}


	/*------------------------------------------------------------------------
	ASSOME LE MONSTRE
	------------------------------------------------------------------------*/
	public function knock(timer:Dynamic)  untyped {
		if ( fl_freeze ) {
			melt();
		}

		fallFactor = RootData.FALL_FACTOR_KNOCK;
		knockTimer = timer;
		fl_knock = true;
		game?.statsMan?.inc(RootData.STAT_KNOCK,1);
		onKnock();
	}


	/*------------------------------------------------------------------------
	MET FIN AU FREEZE
	------------------------------------------------------------------------*/
	public function melt()  untyped {
		next = null;
		angerMore();
		freezeTimer=0;
		fl_freeze = false;
		fl_slide = false;
		fallFactor = 1.0;
		onMelt();
	}


	/*------------------------------------------------------------------------
	MET FIN AU KNOCK
	------------------------------------------------------------------------*/
	public function wakeUp()  untyped {
		next = null;
		knockTimer = 0;
		fl_knock = false;
		fallFactor = 1.0;
		onWakeUp();
	}


	/*------------------------------------------------------------------------
	LE BAD RETROUVE SON CALME
	------------------------------------------------------------------------*/
	public function calmDown()  untyped {
		if ( fl_kill ) {
			return;
		}
		anger = 0;
		updateSpeed();
	}

	/*------------------------------------------------------------------------
	ÉNERVEMENT
	------------------------------------------------------------------------*/
	public function angerMore()  untyped {
		anger = Math.round( Math.min( anger+1, maxAnger ) );
		updateSpeed();
	}

	/*------------------------------------------------------------------------
	DÉFINI LE JOUEUR CIBLE DU MONSTRE
	------------------------------------------------------------------------*/
	public function hate(p:entity.Player)  untyped {
		player = p;
	}



	/*------------------------------------------------------------------------
	UPDATE GRAPHIQUE
	------------------------------------------------------------------------*/
	override public function endUpdate()  untyped {
		if ( fl_ninFriend || fl_ninFoe ) {
			if( isHealthy() && sticker?._name==null ) {
				var mc:Dynamic = game?.depthMan?.attach("hammer_interf_ninjaIcon", RootData.DP_BADS);
				if ( fl_ninFoe ) {
					mc?.gotoAndStop("1");
				}
				else {
					mc?.gotoAndStop("2");
				}
				stick(mc,0,-RootData.CASE_HEIGHT*1.8);
			}
		}
		var oldX:Dynamic = _x;
		var oldY:Dynamic = _y;

		if ( fl_softRecal ) {
			softRecalFactor += 0.1 * Timer.tmod * speedFactor;
		}

		super.endUpdate();

		var minSpeed:Dynamic = 2;
		if ( GameManager.CONFIG.fl_detail ) {
			if ( fl_freeze && fl_stable && Math.abs(dx)>minSpeed) {
				var nb:Dynamic = MtStd.random(5)+2;
				{ var i:Dynamic=0; while (i<nb) {
					var part:Dynamic = game?.fxMan?.attachFx(
						oldX+MtStd.random(12)*(MtStd.random(2)*2-1),
						oldY-MtStd.random(5)+2,
						"hammer_fx_partIce"
					);
					{ if (part?.mc != null) part.mc._rotation = MtStd.random(360); }
					{ if (part?.mc != null) part.mc._xscale = MtStd.random(80)+20; }
					{ if (part?.mc != null) part.mc._yscale = part?.mc?._xscale; }
					{ if (part?.mc != null) part.mc._alpha = Math.min(100, (Math.abs(dx)-minSpeed)/5*100); }

					// particules physiques derrière le bloc
//					if ( Math.abs(dx)>minSpeed*2 && Std.random(40)==0 ) {
//						game.fxMan.inGameParticles( part.mc._x, y, 1 );
//					}
				
i++; } }
			}
		}

		if ( iceMc?._name!=null ) {
			{ if (iceMc != null) iceMc._x = this._x; }
			{ if (iceMc != null) iceMc._y = this._y; }
			{ if (iceMc != null) iceMc._xscale = 0.85*scaleFactor*100; }
			{ if (iceMc != null) iceMc._yscale = 0.85*scaleFactor*freezeTimer/freezeTotal*100; }
		}
		if ( !fl_stable && isHealthy() && ( animId==null || animId==RootData.ANIM_BAD_WALK.id || animId==RootData.ANIM_BAD_ANGER.id ) ) {
			playAnim( RootData.ANIM_BAD_JUMP );
		}
	}


	/*------------------------------------------------------------------------
	MAIN
	------------------------------------------------------------------------*/
	override public function update()  untyped {
		if ( player?._name==null ) {
			hate( (( game.getOne(RootData.PLAYER) ):Dynamic) );
		}

		fl_playerClose = isHealthy() && ( distance(player?.x,player?.y) <= closeDistance*(anger+1) );

		if ( fl_showIA ) {
			if ( fl_playerClose ) {
				if ( !fl_stick ) {
					var mc:Dynamic = game?.depthMan?.attach("curse", RootData.DP_FX) ;
					mc?.gotoAndStop(""+RootData.CURSE_TAUNT) ;
					stick(mc,0,-RootData.CASE_HEIGHT*2.5);
				}
			}
			else {
				unstick();
			}
		}

		// Freezé
		if ( freezeTimer>0 ) {
			freezeTimer-=Timer.tmod;
			if ( freezeTimer<=0 ) {
				melt();
			}
		}


		// Fix: mort forcée (utile ?)
		if ( deathTimer>0 ) {
			deathTimer-=Timer.tmod;
			if ( deathTimer<=0 ) {
				game?.fxMan?.attachExplosion(x,y,80);
				y = 1000;
			}
		}


		// Sonné
		if ( knockTimer>0 ) {
			knockTimer-=Timer.tmod;
			if ( knockTimer<=0 ) {
				wakeUp();
			}
		}

		super.update();

		// Ré-active le contact au sol qui avait été désactivé
		if ( yTrigger!=null && !fl_kill ) {
			if ( y>=yTrigger ) {
				fl_hitGround = true;
				yTrigger=null;
			}
		}

		// Perte de l'id de combo si est de nouveau healthy
		if ( comboId!=null ) {
			if ( isHealthy() ) {
				setCombo(null);
			}
		}
	}

}


// Converti automatiquement depuis hammer/mode/Soccer.mt (Motion Twin)
package mode;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
import Data as RootData;
class Soccer extends mode.MultiCoop {
	public static var BOOST_DISTANCE:Int		= 180;
	public static var MAX_BOOST:Float			= 1.5;
	public static var MATCH_DURATION		= 5 * (1000*60); // millisec
	public static var WARNING_TIME			= 1 * (1000*60);
	public static var BLINK_COLOR:Int			= 0xffbbaa;
	public static var BLINK_GLOWCOLOR:Int		= 0x990000;

	public static var GOAL_OFFTIME			= 5 * RootData.SECOND;
	public static var START_OFFTIME		= 3 * RootData.SECOND;
	public static var END_TIMER			= 13 * RootData.SECOND;

	public var fl_party		: Bool;
	public var fl_match		: Bool;
	public var fl_end			: Bool;
	public var fl_help			: Bool;
	public var scores			: Array<Int>;
	public var teams			: Array< Array<entity.Player> >;

	public var ball			: entity.bomb.player.SoccerBall;
	public var blinkTimer		: Float;

	public var chrono			: Chrono;
	public var offPlayTimer	: Float;
	public var finalTimer		: Float;
	public var winners			: Int; // id team gagnante (null si ex-aequo)


	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new(m:Dynamic,id:Dynamic)  untyped {
		id = null;
		if ( GameManager.CONFIG.hasOption(RootData.OPT_SET_SOC_0) ) {	id = 0;	}
		if ( GameManager.CONFIG.hasOption(RootData.OPT_SET_SOC_1) ) {	id = 1;	}
		if ( GameManager.CONFIG.hasOption(RootData.OPT_SET_SOC_2) ) {	id = 2;	}
		if ( GameManager.CONFIG.hasOption(RootData.OPT_SET_SOC_3) ) {	id = 3;	}
		if ( id==null ) {
			GameManager.fatal("unknown soccermap ID");
			return;
		}

		super(m,id);


		_name		= "$soccer";
		fl_disguise	= false;
		fl_map		= false;

		fl_help		= true;
		fl_party	= false;
		fl_match	= false;
		fl_end		= false;
		fl_nightmare= false;

		blinkTimer	= 0;

		chrono		= new Chrono();
		scores		= new Array();
		teams		= new Array();

		{ if (manager != null) manager.fl_debug = false; }
	}


	/*------------------------------------------------------------------------
	INITIALISATION DU JEU
	------------------------------------------------------------------------*/
	override public function initGame()  untyped {
		super.initGame();

		if ( fl_party ) {
			var p1:Dynamic = insertPlayer(6,10);
			p1?.ctrl?.setKeys(79, 76, 75, 77, 73) ; // OKLM
			var p2:Dynamic = insertPlayer(14,10);
			p2?.ctrl?.setKeys(101/*Z*/, 98/*S*/, 97/*A*/, 99/*D*/, 100/*A*/) ;
		}


		// Construction teams
		var pl:Dynamic = getPlayerList();
		teams = [ [], [] ];
		{ var i:Dynamic=0; while (i<pl?.length) {
			if ( i<pl?.length/2 ) {
				teams[0]?.push(pl[i]);
			}
			else {
				teams[1]?.push(pl[i]);
			}
		
i++; } }


		scores	= [0,0];

		var mc:Dynamic = depthMan?.empty(RootData.DP_INTERF);
		var t:Dynamic = MtStd.createTextField(mc,1);
		{ if (t != null) t._width	= 300; }
		{ if (t != null) t._height	= 50; }
		{ if (t != null) t._x		= RootData.GAME_WIDTH*0.5 - t?._width*0.5; }
		{ if (t != null) t._y		= RootData.GAME_HEIGHT-20; }
		{ if (t != null) t.textColor	= 0xffffff; }
		{ if (t != null) t.html		= true; }
		{ if (t != null) t.htmlText	= "<P ALIGN=\"CENTER\"><FONT COLOR=\"#FFFFFF\">"+Lang.get(33)+"</FONT></P>"; }
		{ if (t != null) t.wordWrap	= false; }
		{ if (t != null) t.selectable= false; }

	}


	/*------------------------------------------------------------------------
	INITIALISATION INTERFACE
	------------------------------------------------------------------------*/
	override public function initInterface()  untyped {
		gi?.destroy();
		gi = (cast ( new gui.SoccerInterface(this) ));
	}


	/*------------------------------------------------------------------------
	GESTION CHRONO
	------------------------------------------------------------------------*/
	override public function unlock()  untyped {
		super.unlock();
		chrono?.start();
	}

	override public function lock()  untyped {
		super.lock();
		chrono?.stop();
	}


	/*------------------------------------------------------------------------
	CHANGEMENT DE LEVEL
	------------------------------------------------------------------------*/
	override public function forcedGoto(id:Dynamic)  untyped {
		super.forcedGoto(id);
		cleanKills();
		var pl:Dynamic = getPlayerList();
		{ var i:Dynamic=0; while (i<pl?.length) {
			initPlayer(pl[i]);
		
i++; } }

	}



	/*------------------------------------------------------------------------
	INITIALISATION JOUEUR
	------------------------------------------------------------------------*/
	override public function initPlayer(p:Dynamic)  untyped {
		super.initPlayer(p);

		{ if (p != null) p.baseColor = RootData.BASE_COLORS[ getTeam(p)+1 ]; }
		{ if (p != null) p.skin		= p?.pid+3; }
		if ( p?.skin==4 ) {
			{ if (p != null) p.defaultHead = RootData.HEAD_SANDY; }
			{ if (p != null) p.head = p?.defaultHead; }
		}
//		p.setColorHex( 30+22*getTeamPos(p), p.baseColor );
		{ if (p != null) p.baseWalkAnim			= RootData.ANIM_PLAYER_SOCCER; }
		{ if (p?.ctrl != null) p.ctrl.fl_upKick		= true; }
		{ if (p?.ctrl != null) p.ctrl.fl_powerControl	= GameManager.CONFIG.hasOption(RootData.OPT_KICK_CONTROL); }
		{ if (p != null) p.lives					= 0; }
		{ if (p != null) p.dx					= 0; }
		{ if (p != null) p.dy					= 0; }
		p?.unshield();
		if ( p?.fl_knock ) {
			p?.onWakeUp();
		}

		if ( getTeam(p)==0 ) {
			p?.moveTo( Entity.x_ctr(world?.current?.__S_playerX+getTeamPos(p)), Entity.y_ctr(world?.current?.__S_playerY) );
		}
		else {
			p?.moveTo( Entity.x_ctr(RootData.LEVEL_WIDTH - world?.current?.__S_playerX -1 - getTeamPos(p)), Entity.y_ctr(world?.current?.__S_playerY) );
		}

		if ( GameManager.CONFIG.hasOption(RootData.OPT_SOCCER_BOMBS) ) {
			p?.changeWeapon( RootData.WEAPON_B_REPEL );
		}
		else {
			p?.changeWeapon( RootData.WEAPON_NONE );
		}

	}


	/*------------------------------------------------------------------------
	INITIALISATION INTERFACE
	------------------------------------------------------------------------*/
//	function initInterface() {
//		gi.destroy();
//	}


	/*------------------------------------------------------------------------
	RENVOIE LE NUMÉRO DE TEAM D'UN JOUEUR
	------------------------------------------------------------------------*/
	public function getTeam(p:Dynamic)  untyped {
		var tid:Dynamic = 0;
		{ var i:Dynamic=0; while (i<teams[1]?.length) {
			if ( MtStd.ix(teams[1], i)?.pid == p?.pid ) {
				tid = 1;
			}
		
i++; } }
		return tid;
	}


	/*------------------------------------------------------------------------
	RENVOIE LE NUMÉRO DE TEAM D'UN JOUEUR
	------------------------------------------------------------------------*/
	public function getTeamPos(p:Dynamic)  untyped {
		var tid:Dynamic = getTeam(p);
		var pos:Dynamic = 0;
		{ var i:Dynamic=0; while (i<teams[tid]?.length) {
			if ( p?.pid == MtStd.ix(teams[tid], i)?.pid ) {
				pos = i;
			}
		
i++; } }
		return pos;
	}


	/*------------------------------------------------------------------------
	RENVOIE LE SCORE D'UNE TEAM
	------------------------------------------------------------------------*/
	public function getTeamScore(tid:Dynamic)  untyped {
		return scores[tid];
	}


	/*------------------------------------------------------------------------
	INIT DU MONDE
	------------------------------------------------------------------------*/
	override public function initWorld()  untyped {
		addWorld("xml_soccer");
	}



	/*------------------------------------------------------------------------
	FONCTIONS DÉSACTIVÉES
	------------------------------------------------------------------------*/
	override public function onHurryUp()  untyped {return null; }
	public function darknessManager()  untyped {}
	override public function getDebugControls()  untyped {}
	override public function addLevelItems()  untyped {}


	/*------------------------------------------------------------------------
	MARQUAGE DE BUT
	------------------------------------------------------------------------*/
	public function goal(tid:Dynamic)  untyped {
		var shooter:Dynamic = ball?.lastPlayer;
		var pl:Dynamic = getPlayerList();
		scores[tid]++;
		pl[tid]?.getScoreHidden(1);

		{ var i:Dynamic=0; while (i<pl?.length) {
			var p:Dynamic = pl[i];
			{ if (p != null) p.head = p?.defaultHead; }
			{ if (p != null) p.speedFactor = 1; }
			if ( getTeam(p)==tid ) {
				p?.setBaseAnims( RootData.ANIM_PLAYER_WALK_V, RootData.ANIM_PLAYER_STOP_V );
			}
			else {
				p?.setBaseAnims( RootData.ANIM_PLAYER_SOCCER, RootData.ANIM_PLAYER_STOP );
			}
		
i++; } }

		if ( tid==getTeam(shooter) ) {
			// but normal
			soundMan?.playSound("sound_item_score", RootData.CHAN_FIELD);
			fxMan?.attachAlert(Lang.get(22)+" ("+getTeamScore(0)+" - "+getTeamScore(1)+")");
			if ( shooter?.skin==4 ) {
				{ if (shooter != null) shooter.head = RootData.HEAD_SANDY_CROWN; }
			}
			else {
				{ if (shooter != null) shooter.head = RootData.HEAD_CROWN; }
			}
		}
		else {
			// but contre son camp
			soundMan?.playSound("sound_player_death", RootData.CHAN_FIELD);
			fxMan?.attachAlert(Lang.get(23));
			if ( shooter?.skin==4 ) {
				{ if (shooter != null) shooter.head = RootData.HEAD_SANDY_LOSE; }
			}
			else {
				{ if (shooter != null) shooter.head = RootData.HEAD_LOSE; }
			}

		}
		shooter?.replayAnim();
		fxMan?.inGameParticlesDir( RootData.PARTICLE_CLASSIC_BOMB, ball?.x,ball?.y, 10, -ball?.dx);
		fxMan?.attachFx( ball?.x, ball?.y-RootData.CASE_HEIGHT, "hammer_fx_shine" ) ;

		offPlayTimer = GOAL_OFFTIME;
	}


	/*------------------------------------------------------------------------
	FIN DU MATCH
	------------------------------------------------------------------------*/
	public function endMatch()  untyped {
		fxMan?.clear();
		fxMan?.inGameParticles( RootData.PARTICLE_CLASSIC_BOMB, ball?.x,ball?.y, 10 );
		ball?.destroy();
		fxMan?.attachAlert( Lang.get(25) );

		offPlayTimer = 99999;
		fl_end = true;

		// Détermine l'équipe gagnante
		if ( getTeamScore(0) > getTeamScore(1) ) {
			winners = 0;
		}
		if ( getTeamScore(0) < getTeamScore(1) ) {
			winners = 1;
		}
		var pl:Dynamic = getPlayerList();
		{ var i:Dynamic=0; while (i<pl?.length) {
			var p:Dynamic = pl[i];
			{ if (p != null) p.speedFactor = 1; }
			p?.setBaseAnims( RootData.ANIM_PLAYER_SOCCER, RootData.ANIM_PLAYER_STOP );
		
i++; } }

	}


	/*------------------------------------------------------------------------
	AFFICHE LE RÉSULTAT DU MATCH
	------------------------------------------------------------------------*/
	public function showResults()  untyped {
		// Message de résultat
		if ( winners==0 ) {
			fxMan?.attachAlert( Lang.get(26) );
		}
		if ( winners==1 ) {
			fxMan?.attachAlert( Lang.get(27) );
		}
		if ( winners==null ) {
			fxMan?.attachAlert( Lang.get(28) );
		}


		shake(RootData.SECOND, 5);

		// Anims de fin
		var pl:Dynamic = getPlayerList();
		{ var i:Dynamic=0; while (i<pl?.length) {
			var p:Dynamic = pl[i];
			if ( winners!=null && getTeam(p)==winners ) {
				{ if (p != null) p.speedFactor = 1; }
				p?.setBaseAnims( RootData.ANIM_PLAYER_WALK_V, RootData.ANIM_PLAYER_STOP_V );
			}
			else {
				{ if (p != null) p.speedFactor = 0.3; }
				p?.setBaseAnims( RootData.ANIM_PLAYER_WALK_L, RootData.ANIM_PLAYER_STOP_L );
			}
		
i++; } }
	}


	/*------------------------------------------------------------------------
	EVENT: LEVEL PRÊT
	------------------------------------------------------------------------*/
	override public function onLevelReady()  untyped {
		super.onLevelReady();
		fl_match = false;
		offPlayTimer = START_OFFTIME;

		onPause();
		{ if (pauseMC != null) pauseMC.onRelease	= (this).onUnpause; }
		{ if (pauseMC?.click != null) pauseMC.click.text	= Lang.get(6); }
		fxMan?.levelName?.removeMovieClip();
	}


	/*------------------------------------------------------------------------
	EVENT: MISE EN PAUSE
	------------------------------------------------------------------------*/
	override public function onPause()  untyped {
		super.onPause();

		pauseMC?.gotoAndStop("2");
		{ if (pauseMC?.move != null) pauseMC.move.text			= Lang.get(29); }
		{ if (pauseMC?.attack != null) pauseMC.attack.text			= Lang.get(30); }
		{ if (((pauseMC):Dynamic)?.up != null) ((pauseMC):Dynamic).up.text	= Lang.get(31); }
		{ if (pauseMC?.tip != null) pauseMC.tip.text			= Lang.get(32); }
		{ if (pauseMC?.click != null) pauseMC.click.text			= ""; }
	}


	override public function onUnpause()  untyped {
		super.onUnpause();
		if ( fl_help ) {
			fxMan?.attachAlert(Lang.get(21));
			fl_help = false;
		}
	}


	/*------------------------------------------------------------------------
	FIN DE MODE
	------------------------------------------------------------------------*/
	public function onEndMode()  untyped {
		endMode();
	}

	override public function endMode()  untyped {
		var url:Dynamic = MtStd.getVar( MtStd.getRoot(), "$out" );
		manager?.redirect(url,null);
	}

	override public function onGameOver()  untyped {
		endMode();
	}


	/*------------------------------------------------------------------------
	AJOUTE LE BALLON
	------------------------------------------------------------------------*/
	public function insertBall()  untyped {
		var s:Dynamic = world?.current?.__S_specialSlots[ MtStd.random(world?.current?.__S_specialSlots?.length) ];
		ball = entity.bomb.player.SoccerBall.attach(
			this,
			Entity.x_ctr(s?.__S_x),
			Entity.y_ctr(s?.__S_y)
		);

		fxMan?.inGameParticles( RootData.PARTICLE_CLASSIC_BOMB, ball?.x,ball?.y, 9);
		fxMan?.inGameParticles( RootData.PARTICLE_ICE, ball?.x,ball?.y, 5);

		var pl:Dynamic = getPlayerList();
		{ var i:Dynamic=0; while (i<pl?.length) {
			pl[i]?.setBaseAnims( RootData.ANIM_PLAYER_SOCCER, RootData.ANIM_PLAYER_STOP );
		
i++; } }

		soundMan?.playSound("sound_pop", RootData.CHAN_FIELD);

	}



	/*------------------------------------------------------------------------
	BOUCLE MAIN
	------------------------------------------------------------------------*/
	override public function main()  untyped {
		chrono?.update();
		if ( !fl_match ) {
			chrono?.reset();
		}

		if ( manager?.isDev() && Key.isDown(Key.SHIFT) ) {
			chrono?.timeShift(-1);
		}


		var t:Dynamic;
		if ( chrono?.fl_stop ) {
			t = MATCH_DURATION-(chrono?.suspendTimer-chrono?.gameTimer);
		}
		else {
			t = MATCH_DURATION-chrono?.get();
		}
		t = Std.int( Math.max(0,t) );
		((gi):Dynamic)?.setTime( chrono?.formatTimeShort(t) );



		// Blink chrono
		if ( t<WARNING_TIME ) {
			blinkTimer-=Timer.tmod;
			if ( blinkTimer<=0 ) {
				var tf : TextField = ((gi):Dynamic)?.time;
				if ( tf?.textColor==BLINK_COLOR || t==0 ) {
					{ if (tf != null) tf.textColor = 0xffffff; }
					FxManager.addGlow( ((tf):Dynamic), gui.SoccerInterface.GLOW_COLOR, 2 );
				}
				else {
					{ if (tf != null) tf.textColor = BLINK_COLOR; }
					FxManager.addGlow( ((tf):Dynamic), BLINK_GLOWCOLOR, 2 );

				}
				blinkTimer = 15 * (t/WARNING_TIME);
			}
		}



		if ( !fl_lock ) {
			// Gestion off-play
			if ( offPlayTimer>0 ) {
				offPlayTimer-=Timer.tmod;
			}

			// Remise en jeu
			if ( ball?._name == null && offPlayTimer<=0 ) {
				fl_match = true;
				fxMan?.attachAlert(Lang.get(24));
				insertBall();
				chrono?.start();
			}

			// Speed boost
			if ( ball?._name!=null ) {
				var pl:Dynamic = getPlayerList();
				{ var i:Dynamic=0; while (i<pl?.length) {
					var p:Dynamic = pl[i];
					var dist:Dynamic = p?.distance(ball?.x,ball?.y);
					if ( dist > BOOST_DISTANCE ) {
						var ratio:Dynamic = Math.min(MAX_BOOST, dist/BOOST_DISTANCE);
						{ if (p != null) p.speedFactor = ratio; }
					}
					else {
						{ if (p != null) p.speedFactor = 1; }
					}
				
i++; } }
			}
		}

		super.main();

		fxMan?.detachExit();

		// Fin de match
		if ( !fl_lock ) {
			if ( chrono?.get()>=MATCH_DURATION && !fl_end ) {
				endMatch();
				finalTimer = RootData.SECOND * 3;
			}

			// Résultat final
			if ( finalTimer>0 ) {
				finalTimer -= Timer.tmod;
				if ( finalTimer<=0 ) {
					showResults();
					endModeTimer = END_TIMER;
				}
			}

			// Particules pour les gagnants
			if ( endModeTimer>0 ) {
				var pl:Dynamic = getPlayerList();
				{ var i:Dynamic=0; while (i<pl?.length) {
					var p:Dynamic = pl[i];
					if ( getTeam(p)==winners ) {
						if ( p?.dx!=0 ) {
							fxMan?.inGameParticlesDir( RootData.PARTICLE_SPARK, p?.x,p?.y-MtStd.random(40), MtStd.random(3), -p?.dir );
						}
						else {
							fxMan?.inGameParticles( RootData.PARTICLE_SPARK, p?.x,p?.y-MtStd.random(40), MtStd.random(2) );
						}
					}
				
i++; } }
			}
		}
	}

}

// Converti automatiquement depuis hammer/mode/Adventure.mt (Motion Twin)
package mode;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
import Data as RootData;
class Adventure extends mode.GameMode
{

	public var perfectOrder	: Array<Int>;
	public var perfectCount	: Int;

	public var firstLevel		: Int;

	public var fl_warpStart	: Bool;

	public var trackPos		: Float;

	public static var BUCKET_X:Int			= 11;
	public static var BUCKET_Y:Int			= 19;


	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new(m:Dynamic,id:Dynamic)  untyped {
		super(m);
		firstLevel	= id;

		fl_warpStart	= false;
		fl_map			= true;
		_name 			= "$adventure";
	}


	/*------------------------------------------------------------------------
	INITIALISATION
	------------------------------------------------------------------------*/
	override public function init()  untyped {
		super.init();

		initGame();

		var pl:Dynamic = getPlayerList();
		{ var i:Dynamic=0; while (i<pl?.length) {
			initPlayer(pl[i]);
		
i++; } }

		initInterface();



	}


	/*------------------------------------------------------------------------
	FIN DE MODE
	------------------------------------------------------------------------*/
	override public function destroy()  untyped {
		super.destroy();
	}


	/*------------------------------------------------------------------------
	CONTRÔLES DE JEU
	------------------------------------------------------------------------*/
	override public function getDebugControls()  untyped {
		super.getDebugControls();
		if ( Key.isDown(Key.SHIFT) && Key.isDown(Key.CONTROL) && Key.isDown(77) ) { //  Ctrl+Shift+M
			manager?.startGameMode( new mode.MultiCoop(manager,0) );
		}
	}


	/*------------------------------------------------------------------------
	PLACE LES ITEMS STANDARDS DU NIVEAU
	------------------------------------------------------------------------*/
	override public function addLevelItems()  untyped {
		super.addLevelItems();
		var n:Dynamic,pt:Dynamic;

		// Extends
		if ( world?.current?.__S_specialSlots?.length>0 ) {
			statsMan?.spreadExtend();
		}

		// Special
		if ( world?.current?.__S_specialSlots?.length>0 ) {
			n = MtStd.random(world?.current?.__S_specialSlots?.length);
			pt = world?.current?.__S_specialSlots[n];
			world?.scriptEngine?.insertSpecialItem(
				randMan?.draw(RootData.RAND_ITEMS_ID),
				null,
				pt?.__S_x,
				pt?.__S_y,
				RootData.SPECIAL_ITEM_TIMER,
				null,
				false,
				true
			);
		}

		// Score
		if ( world?.current?.__S_scoreSlots?.length>0 ) {
			n = MtStd.random(world?.current?.__S_scoreSlots?.length);
			pt = world?.current?.__S_scoreSlots[n];
			world?.scriptEngine?.insertScoreItem(
				randMan?.draw(RootData.RAND_SCORES_ID),
				null,
				pt?.__S_x,
				pt?.__S_y,
				RootData.SCORE_ITEM_TIMER,
				null,
				false,
				true
			);

			if ( globalActives[94] ) {
				var cx:Dynamic = MtStd.random(RootData.LEVEL_WIDTH);
				var cy:Dynamic = MtStd.random(RootData.LEVEL_HEIGHT-5);
				var ptC:Dynamic = world?.getGround(cx,cy);
				world?.scriptEngine?.insertScoreItem(
					randMan?.draw(RootData.RAND_SCORES_ID),
					null,
					ptC?.x,
					ptC?.y,
					RootData.SCORE_ITEM_TIMER,
					null,
					false,
					true
				);
			}
		}
	}


	/*------------------------------------------------------------------------
	ATTACHEMENT BAD: GESTION DU PERFECT ORDER POUR LE SUPA ITEM
	------------------------------------------------------------------------*/
	override public function attachBad(id:Dynamic,x:Dynamic,y:Dynamic)  untyped {
		var b:Dynamic = super.attachBad(id,x,y);
		if ( (b?.types&RootData.BAD_CLEAR)>0 ) {
			perfectOrder?.push(b?.uniqId);
			perfectCount++;
		}
		return b;
	}


	/*------------------------------------------------------------------------
	INITIALISATION DU MONDE
	------------------------------------------------------------------------*/
	override public function initWorld()  untyped {
		super.initWorld();

		addWorld("xml_adventure");
		addWorld("xml_deepnight");
		addWorld("xml_hiko");
		addWorld("xml_ayame");
		addWorld("xml_hk");
		if ( manager?.isDev() ) {
			addWorld("xml_dev");
		}
	}


	/*------------------------------------------------------------------------
	INITIALISATION PARTIE
	------------------------------------------------------------------------*/
	override public function initGame()  untyped {
		super.initGame();
		playMusic(0);
		world?.goto(firstLevel);
		insertPlayer(world?.current?.__S_playerX, world?.current?.__S_playerY);
	}


	/*------------------------------------------------------------------------
	CHANGEMENT DE LEVEL
	------------------------------------------------------------------------*/
	override public function goto(id:Dynamic)  untyped {
		perfectOrder = new Array();
		perfectCount = 0;

		super.goto(id);
	}


	/*------------------------------------------------------------------------
	DÉMARRE LE NIVEAU
	------------------------------------------------------------------------*/
	override public function startLevel()  untyped {
		var pl:Dynamic = getPlayerList();
		{ var i:Dynamic=0; while (i<pl?.length) {
			pl[i]?.setBaseAnims(RootData.ANIM_PLAYER_WALK, RootData.ANIM_PLAYER_STOP);
		
i++; } }
		perfectOrder = new Array();
		perfectCount = 0;
		super.startLevel();

		// Boss 1
		if ( world?.fl_mainWorld && world?.currentId == RootData.BAT_LEVEL ) {
			entity.boss.Bat.attach(this);
			fl_clear = false;
		}

		// Boss 2
		if ( world?.fl_mainWorld && world?.currentId == RootData.TUBERCULOZ_LEVEL ) {
			entity.boss.Tuberculoz.attach(this);
			fl_clear = false;
		}

		// Pas de fleche au level 0
		if ( world?.fl_mainWorld && world?.currentId==0 ) {
			fxMan?.detachExit();
		}
	}

	/*------------------------------------------------------------------------
	LANCE LE NIVEAU SUIVANT
	------------------------------------------------------------------------*/
	override public function nextLevel()  untyped {

		super.nextLevel();

		if ( fl_warpStart ) {
			{ if (world != null) world.currentId = 0; }
			unlock();
			world?.view?.detach();
			forcedGoto(10);
		}

	}


	/*------------------------------------------------------------------------
	ENVOI DU RÉSULTAT DE LA PARTIE
	------------------------------------------------------------------------*/
	override public function saveScore()  untyped {
		if(GameManager.HH.get("$"+Md5.encode(world?.setName))!="$"+Md5.encode(""+world?.csum)) {GameManager.fatal("argh"); return;}
		if(world?.setName!="xml_adventure") { GameManager.fatal("");return; }
		MtStd.getGlobal("gameOver") (
			savedScores[0],
			null,
			{
				__S_reachedLevel	: dimensions[0].currentId,
				__S_item2			: getPicks2(),
				__S_data			: manager.history,
			}
		);
	}


	/*------------------------------------------------------------------------
	RENVOIE TRUE POUR LES LEVELS DE BOSS
	------------------------------------------------------------------------*/
	override public function isBossLevel(id:Dynamic)  untyped {
		return
			super.isBossLevel(id) ||
			world?.fl_mainWorld && (
				( id>=30 && (id % 10)==0 ) ||
				id==RootData.BAT_LEVEL ||
				id==RootData.TUBERCULOZ_LEVEL
			);
	}



	/*------------------------------------------------------------------------
	EVENT: LEVEL PRÊT À ÊTRE JOUÉ (APRES SCROLL)
	------------------------------------------------------------------------*/
	override public function onLevelReady()  untyped {
		super.onLevelReady();
		if ( fl_warpStart ) {
			if ( world?.fl_mainWorld ) {
				var p:Dynamic = getOne(RootData.PLAYER);
				world?.view?.attachSprite(
					"$door_secret",
					Entity.x_ctr( world?.current?.__S_playerX ),
					Entity.x_ctr( world?.current?.__S_playerY ) + RootData.CASE_HEIGHT*0.5,
					true
				);
			}
			fl_warpStart = false;
		}
		if ( !world?.isVisited() ) {
			fxMan?.attachLevelPop( Lang.getLevelName(currentDim,world?.currentId), world?.currentId>0 );
		}
	}


	/*------------------------------------------------------------------------
	EVENT: LEVEL TERMINÉ
	------------------------------------------------------------------------*/
	override public function onLevelClear()  untyped {
		super.onLevelClear();
		if ( !world?.isVisited() && perfectOrder?.length==0 && world?.scriptEngine?.cycle>=10 ) {
			var pl:Dynamic = getPlayerList();
			{ var i:Dynamic=0; while (i<pl?.length) {
				pl[i]?.setBaseAnims(RootData.ANIM_PLAYER_WALK_V, RootData.ANIM_PLAYER_STOP_V);
			
i++; } }
			entity.supa.SupaItem.attach(this, perfectCount-1);
			statsMan?.inc(RootData.STAT_SUPAITEM,1);
		}
	}



	/*------------------------------------------------------------------------
	EVENT: MORT D'UN BAD
	------------------------------------------------------------------------*/
	override public function onKillBad(b:Dynamic)  untyped {
		super.onKillBad(b);

		// Boss Tuberculoz
		if ( world?.fl_mainWorld && world?.currentId==RootData.TUBERCULOZ_LEVEL ) {
			(( getOne(RootData.BOSS) ):Dynamic)?.onKillBad();
		}

		// Perfect order
		if ( badCount>1 && b?.uniqId==perfectOrder[0] ) {
			perfectOrder?.splice(0,1);
		}
	}


	/*------------------------------------------------------------------------
	LOOPS ON ADVENTURE MODE
	------------------------------------------------------------------------*/
//	function endMode() {
//		world.destroy();
//		manager.startGameMode(  new mode.Adventure(manager)  );
//	}


	/*------------------------------------------------------------------------
	EVENT: EXPLOSION D'UNE BOMBE DE JOUEUR
	------------------------------------------------------------------------*/
	override public function onExplode(x:Dynamic,y:Dynamic,radius:Dynamic)  untyped {
		super.onExplode(x,y,radius);

		if ( world?.fl_mainWorld && world?.currentId==RootData.TUBERCULOZ_LEVEL ) {
			((getOne(RootData.BOSS)):Dynamic)?.onExplode(x,y,radius);
		}

	}


	/*------------------------------------------------------------------------
	EVENT: FIN DU SET DE LEVELS
	------------------------------------------------------------------------*/
	override public function onEndOfSet()  untyped {
		super.onEndOfSet();
		exitGame();
	}


	/*------------------------------------------------------------------------
	EVENT: GAME OVER
	------------------------------------------------------------------------*/
	override public function onGameOver()  untyped {
		super.onGameOver();
		manager?.logAction(
			"$t="+Math.round(duration/RootData.SECOND)
		);

		var fl_illegal:Dynamic = ( manager?.history?.join("|")?.indexOf("!",0)>=0 );

		{ if (manager != null) manager.history = [
			"F="+((MtStd.getRoot()):Dynamic)?.__S_version,
			"T="+gameChrono?.get()
		]; }
		if ( fl_illegal ) {
			manager?.history?.push("$illegal".substring(1));
		}


		stopMusic();

		saveScore();
	}

	/*------------------------------------------------------------------------
	EVENT: HURRY UP !
	------------------------------------------------------------------------*/
	override public function onHurryUp()  untyped {
		var mc:Dynamic = super.onHurryUp();
		if ( GameManager.CONFIG.hasMusic() && currentTrack==0 ) {
			trackPos = manager?.musics[currentTrack]?.position;
			playMusic(2);
		}
		return mc;
	}


	/*------------------------------------------------------------------------
	FIN DE HURRY UP
	------------------------------------------------------------------------*/
	override public function resetHurry()  untyped {
		super.resetHurry();
		if ( currentTrack==2 ) {
			playMusic(0);
//			playMusicAt(0,trackPos);
		}
	}


	/*------------------------------------------------------------------------
	FIN DE MODE
	------------------------------------------------------------------------*/
	override public function endMode()  untyped {
		stopMusic();
		// éditeur de niveaux non porté
	}



}

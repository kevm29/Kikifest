// Converti automatiquement depuis hammer/mode/GameMode.mt (Motion Twin)
package mode;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
import Data as RootData;
class GameMode extends Mode
{
	public static var WATER_COLOR:Int		= 0x0000ff;


	public var fxMan			: FxManager;
	public var statsMan		: StatsManager;
	public var randMan			: RandomManager;
	public var fl_static		: Bool; // si true, le comportement initial des monstres sera prévisible (random sinon)
	public var fl_bullet		: Bool;
	public var fl_disguise		: Bool;
	public var fl_map			: Bool;
	public var fl_mirror		: Bool;
	public var fl_nightmare	: Bool;
	public var fl_bombControl	: Bool;
	public var fl_ninja		: Bool;
	public var fl_bombExpert	: Bool;

	public var fl_ice			: Bool;
	public var fl_aqua			: Bool;

	public var fl_badsCallback	: Bool;

	public var duration		: Float;

	public var gFriction		: Float;
	public var sFriction		: Float;

	public var speedFactor		: Float;
	public var diffFactor		: Float;

	public var lists			: Array<Array<Entity>>;
	public var killList		: Array<Entity>;
	public var unregList		: Array< {type:Int,ent:Entity} >;
	public var world			: levels.GameMechanics;

	public var comboList		: Array<Int>;
	public var badCount		: Int;
	public var friendsLimit	: Int;

	public var fl_clear		: Bool;
	public var fl_gameOver		: Bool;
	public var fl_pause		: Bool;

	public var fl_rightPortal	: Bool;

	public var huTimer			: Float;
	public var huState			: Int;

	public var endModeTimer	: Float;

	public var shakeTotal		: Float;
	public var shakeTimer		: Float;
	public var shakePower		: Float;
	public var windSpeed		: Float;
	public var windTimer		: Float;
	public var fl_wind			: Bool;
	public var fl_flipX		: Bool;
	public var fl_flipY		: Bool;
	public var aquaTimer		: Float;

	public var keyLock			: Int;

	public var globalActives	: Array<Bool>;
	public var endLevelStack	: Array<Void->Void>;

	public var popMC			: Dynamic;
	public var pointerMC		: MovieClip;
	public var radiusMC		: MovieClip;
	public var darknessMC		: Dynamic;
	public var itemNameMC		: Dynamic;
	public var pauseMC			: Dynamic;
	public var mapMC			: Dynamic;
	public var mapIcons		: Array<MovieClip>;
	public var dfactor			: Float;
	public var targetDark		: Float;
	public var extraHoles		: Array< {x:Float, y:Float, d:Float, mc:MovieClip} >;

	public var lagCpt			: Float;

	public var tipId			: Int;

	public var bulletTimer		: Float;

	public var specialPicks	: Array<Int>;
	public var scorePicks		: Array<Int>;
	public var savedScores		: Array<Int>;

	public var dimensions		: Array<levels.GameMechanics>;
	public var currentDim		: Int;
	public var portalId		: Int;
	public var latePlayers		: Array<entity.Player>;		// liste de players arrivant en retard d'un portal
	public var portalMcList	: Array< {mc:MovieClip, x:Float,y:Float, cpt:Float} >;

	public var gi				: gui.GameInterface;
	public var gameChrono		: Chrono;

	public var mapEvents		: Array< {lid:Int, eid:Int, misc:String} >;
	public var mapTravels		: Array< {lid:Int, eid:Int, misc:String} >;


	public var dvars			: Hash<String>;

	public var color			: Color;
	public var colorHex		: Int;

	public var worldKeys		: Array<Bool>;

	public var forcedDarkness	: Int;

	public var nextLink		: levels.PortalLink;
	public var fakeLevelId		: Int;


	public var perfectItemCpt	: Int;


	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new(m:Dynamic)  untyped {
		super(m);
		duration		= 0;
		lagCpt			= 0;
		fl_static		= false;
		fl_bullet		= true;
		fl_disguise		= true;
		fl_map			= false;
		fl_mirror		= GameManager.CONFIG.hasOption(RootData.OPT_MIRROR);
		fl_nightmare	= GameManager.CONFIG.hasOption(RootData.OPT_NIGHTMARE);
		fl_ninja		= GameManager.CONFIG.hasOption(RootData.OPT_NINJA);
		fl_bombExpert	= GameManager.CONFIG.hasOption(RootData.OPT_BOMB_EXPERT);
		fl_bombControl	= false;
		savedScores		= new Array();

		xOffset			= 10;

		fxMan = new FxManager(this);
		statsMan = new StatsManager(this);
		randMan = new RandomManager();
		var old:Dynamic = MtStd.getTimer();
		randMan?.register(RootData.RAND_EXTENDS_ID,	RootData.RAND_EXTENDS);
		randMan?.register(
			RootData.RAND_ITEMS_ID,
			RootData.getRandFromFamilies(RootData.SPECIAL_ITEM_FAMILIES, GameManager.CONFIG.specialItemFamilies)
		);
		randMan?.register(
			RootData.RAND_SCORES_ID,
			RootData.getRandFromFamilies(RootData.SCORE_ITEM_FAMILIES, GameManager.CONFIG.scoreItemFamilies)
		);

		speedFactor = 1.0; // facteur de vitesse des bads
		diffFactor	= 1.0;

		endModeTimer = 0;

		comboList = new Array();

		killList = new Array();
		unregList = new Array();
		lists = new Array();
		{ var i:Dynamic=0; while (i<200) {
			lists[i] = new Array();
		
i++; } }

		globalActives	= new Array();
		endLevelStack	= new Array();
		portalMcList	= new Array();
		extraHoles		= new Array();
		dfactor			= 0;

		shake(null,null);
		wind(null,null);
		aquaTimer = 0;

		bulletTimer = 0;

		fl_flipX	= false;
		fl_flipY	= false;
		fl_clear	= false;
		fl_gameOver	= false;
		huTimer		= 0;
		huState		= 0;
		tipId		= 0;

		_name		= "$abstractGameMode";

		specialPicks	= new Array();
		scorePicks		= new Array();

		currentDim	= 0;
		dimensions	= new Array();
		latePlayers	= new Array();
		mapIcons	= new Array();
		mapEvents	= new Array();
		mapTravels	= new Array();

		gameChrono	= new Chrono();

		clearDynamicVars();


		worldKeys = new Array();
		{ var i:Dynamic=5000; while (i<5100) {
			if ( GameManager.CONFIG.hasFamily(i) ) {
				giveKey(i-5000);
			}
		
i++; } }

	}


	/*------------------------------------------------------------------------
	INITIALISATION DE LA VARIABLE WORLD
	------------------------------------------------------------------------*/
	public function initWorld()  untyped {
		// do nothing
	}

	/*------------------------------------------------------------------------
	INITIALISE LE JEU SUR LE PREMIER LEVEL
	------------------------------------------------------------------------*/
	public function initGame()  untyped {
		initWorld();
	}


	/*------------------------------------------------------------------------
	INITIALISE L'INTERFACE DE JEU (non appelé dans la classe gamemode)
	------------------------------------------------------------------------*/
	public function initInterface()  untyped {
		gi?.destroy();
		gi = new gui.GameInterface(this);
	}


	/*------------------------------------------------------------------------
	INITIALISE LE LEVEL
	------------------------------------------------------------------------*/
	public function initLevel()  untyped {
		if ( !world?.isVisited() ) {
			resetHurry();
		}
		badCount		= 0;
		forcedDarkness	= null;
		fl_clear		= false;
		var l:Dynamic = getPlayerList();
		{ var i:Dynamic=0; while (i<l?.length) {
			l[i]?.onStartLevel();
			if ( l[i]?.y<0 ) {
				fxMan?.attachEnter( l[i]?.x, 0);//l[i].pid );
			}
		
i++; } }

	}


	/*------------------------------------------------------------------------
	INITIALISE UN JOUEUR
	------------------------------------------------------------------------*/
	public function initPlayer(p:entity.Player)  untyped {
		// do nothing
	}


	/*------------------------------------------------------------------------
	DÉCLENCHE UN TREMBLEMENT DE TERRE
	------------------------------------------------------------------------*/
	public function shake(duration:Dynamic, power:Dynamic)  untyped {
		if ( duration==null ) {
			shakeTimer = 0;
			shakeTimer = 0;
		}
		else {
			if ( duration<shakeTimer || power<shakePower ) {
				return;
			}

			shakeTotal = duration;
			shakeTimer = duration;
			shakePower = power;

		}
	}


	/*------------------------------------------------------------------------
	DÉCLENCHE UN SOUFFLE DE VENT
	------------------------------------------------------------------------*/
	public function wind(speed:Dynamic,duration:Dynamic)  untyped {
		if ( speed==null ) {
			fl_wind = false;
		}
		else {
			fl_wind = true;
			windSpeed = speed;
			windTimer = duration;
		}
	}


	/*------------------------------------------------------------------------
	INVERSION HORIZONTALE
	------------------------------------------------------------------------*/
	public function flipX(fl:Bool)  untyped {
		fl_flipX = fl;
		if (fl) {
			{ if (mc != null) mc._xscale = -100; }
			{ if (mc != null) mc._x = RootData.GAME_WIDTH+xOffset; }
		}
		else {
			{ if (mc != null) mc._xscale = 100; }
			{ if (mc != null) mc._x = xOffset; }
		}
	}


	/*------------------------------------------------------------------------
	INVERSION VERTICALE
	------------------------------------------------------------------------*/
	public function flipY(fl:Bool)  untyped {
		fl_flipY = fl;
		if (fl) {
			{ if (mc != null) mc._yscale = -100; }
			{ if (mc != null) mc._y = RootData.GAME_HEIGHT+yOffset+20; }
		}
		else {
			{ if (mc != null) mc._yscale = 100; }
			{ if (mc != null) mc._y = yOffset; }
		}
	}


	/*------------------------------------------------------------------------
	REMET LE HURRY UP À ZÉRO
	------------------------------------------------------------------------*/
	public function resetHurry()  untyped {
		huTimer = 0;
		huState = 0;

		// Calcul variateur de difficulté
		var max:Dynamic = 0;
		var pl:Dynamic = getPlayerList();
		{ var i:Dynamic=0; while (i<pl?.length) {
			max = ( (pl[i]?.lives:Float) > (max:Float) ) ? pl[i]?.lives : max;
		
i++; } }
		if ( max<4 ) {
			diffFactor = 1.0;
		}
		else {
			diffFactor = 1.0 + 0.05*(max-3);
		}
		if ( fl_nightmare ) {
			diffFactor *= 1.4;
		}


		destroyList(RootData.HU_BAD);

		var l:Dynamic = getBadList();
		{ var i:Dynamic=0; while (i<l?.length) {
			l[i]?.calmDown();
		
i++; } }

		// Boss
		var b:Dynamic = getOne(RootData.BOSS);
		if ( b!=null ) {
			((b):Dynamic)?.onPlayerDeath();
		}
	}


	/*------------------------------------------------------------------------
	RENVOIE TRUE SI LEVEL EST TERMINÉ
	------------------------------------------------------------------------*/
	public function checkLevelClear():Bool  untyped {
		if ( fl_clear ) {
			return true;
		}

		// Bads
		if ( countList(RootData.BAD_CLEAR)>0 ) {
			return false;
		}

		// Boss
		if ( world?.fl_mainWorld ) {
			if ( world?.currentId==RootData.BAT_LEVEL || world?.currentId==RootData.TUBERCULOZ_LEVEL ) {
				return false;
			}
		}

		onLevelClear();
		return true;
	}


	/*------------------------------------------------------------------------
	CONTROLES DE BASE
	------------------------------------------------------------------------*/
	override public function getControls()  untyped {
		super.getControls();

		// Pause
		if ( keyLock!=null && !Key.isDown(keyLock) ) {
			keyLock = null;
		}
		if (Key.isDown(80) && keyLock!=80) {
			if (fl_lock) {
				onUnpause();
			}
			else {
				onPause();
			}
			keyLock = 80;
		}


		// Carte
		if (fl_map && Key.isDown(67) && keyLock!=67) {
			if (fl_lock) {
				onUnpause();
			}
			else {
				onMap();
			}
			keyLock = 67;
		}


		// Musique
		if (!fl_lock && fl_music && Key.isDown(77) && keyLock!=77) {
			fl_mute = !fl_mute;
			if (fl_mute) {
				setMusicVolume(0);
			}
			else {
				setMusicVolume(1);
			}
			keyLock = 77;
		}


		// Suicide
		if ( Key.isDown(Key.SHIFT) && Key.isDown(Key.CONTROL) && Key.isDown(75) ) {
			if ( !fl_switch && !fl_lock && countList(RootData.PLAYER)>0 ) {
				destroyList(RootData.PLAYER);
				onGameOver();
			}
		}


		// Pause / quitter
		if (!fl_switch && Key.isDown(Key.ESCAPE) && !fl_gameOver && keyLock!=Key.ESCAPE ) {
			if ( manager?.fl_local && !fl_lock ) {
				endMode();
			}
			else {
				if ( manager?.fl_debug ) {
					if ( !fl_lock ) {
						destroyList(RootData.PLAYER);
						onGameOver();
					}
				}
				else {
					if (fl_lock) {
						onUnpause();
					}
					else {
						onPause();
					}
				}
			}
			keyLock = Key.ESCAPE;
		}

		// Déguisements
		if ( fl_disguise && Key.isDown(68) && keyLock!=68 ) {
			var p:Dynamic = getPlayerList()[0];
			var old:Dynamic = p?.head;
			{ if (p != null) p.head++; }
			if ( p?.head==RootData.HEAD_AFRO && !GameManager.CONFIG.hasFamily(109) ) p.head++; // touffe
			if ( p?.head==RootData.HEAD_CERBERE && !GameManager.CONFIG.hasFamily(110) ) p.head++; // cerbère
			if ( p?.head==RootData.HEAD_PIOU && !GameManager.CONFIG.hasFamily(111) ) p.head++; // piou
			if ( p?.head==RootData.HEAD_MARIO && !GameManager.CONFIG.hasFamily(112) ) p.head++; // mario
			if ( p?.head==RootData.HEAD_TUB && !GameManager.CONFIG.hasFamily(113) ) p.head++; // cape
			if ( p?.head>6 ) {
				{ if (p != null) p.head = p?.defaultHead; }
			}
			if ( old!=p?.head ) {
				p?.replayAnim();
			}
			keyLock = 68;
		}

		// FPS
		if ( Key.isDown(70) ) {
			Log.print( Math.round(Timer.fps())+" FPS" );
			Log.print("Performances: "+Math.min(100,Math.round(100*Timer.fps()/30))+"%");
		}

		// Build time
		if ( Key.isDown(66) ) {
			Log.print("Dernière mise à jour:");
			Log.print( "kikifest" );
			Log.print("Version de Flash: "+manager?.fVersion);
		}
	}


	/*------------------------------------------------------------------------
	CONTROLES DE DEBUG
	------------------------------------------------------------------------*/
	override public function getDebugControls()  untyped {
		super.getDebugControls();

		if (Key.isDown(Key.SHIFT)) {
			Timer.tmod = 0.3;
		}

		if (Key.isDown(Key.HOME)) {
			Timer.tmod = 1.0;
		}

	}


	/*------------------------------------------------------------------------
	AFFICHE DES INFOS DE DEBUG
	------------------------------------------------------------------------*/
	public function printDebugInfos()  untyped {
//		printBetaInfos();return;
		Log.print("build:"+"kikifest");
		Log.print("lang="+Lang.lang+" debug="+Lang.fl_debug);
		Log.print("debug="+manager?.fl_debug+" local="+manager?.fl_local);
		Log.print("cookie="+manager?.fl_cookie);
		Log.print("--- DATA ---");
		Log.print(GameManager.CONFIG.toString());
		Log.print("fl8 = "+manager?.fl_flash8);
		Log.print("ent = "+countList(RootData.ENTITY));
		Log.print("bad = "+countList(RootData.BAD));

		var k:Dynamic = new Array();
		{ var i:Dynamic=0; while (i<worldKeys?.length) {
			if ( worldKeys[i] ) {
				k?.push(i);
			}
		
i++; } }
		Log.print("keys= "+k?.join(", "));
		/***
		Log.print("details = "+GameManager.CONFIG.fl_detail);
		Log.print("--- PARAMS ---");
		Log.print(GameManager.CONFIG.families.join("\n~ "));
		Log.print("snd="+GameManager.CONFIG.soundVolume+" mus="+GameManager.CONFIG.musicVolume);
		if ( manager.fl_cookie ) {
			Log.print("--- COOKIE ---");
			var d = new Date();
			d.setTime( manager.cookie.data.lastModified );
			Log.print("ver = "+Cookie.VERSION);
			Log.print("date = "+d.getDate()+"/"+(d.getMonth()+1)+"/"+d.getFullYear() );
			Log.print("time = "+d.getHours()+":"+d.getMinutes()+":"+d.getSeconds() );
		}
		/***
		Log.print("--- SCRIPT ---");
		Log.print("fl_clear="+fl_clear);
		var node = world.scriptEngine.script.firstChild;
		while ( node!=null ) {
			if ( node.nodeName!=null ) {
				Log.print(node.nodeName);
			}
			node = node.nextSibling;
		}
		Log.print("--- HIST ---");
		Log.print(world.scriptEngine.history.join("\n"));
		/***/
	}


	/*------------------------------------------------------------------------
	AFFICHE DES INFOS DE BETA TEST
	------------------------------------------------------------------------*/
	public function printBetaInfos()  untyped {
//		Log.print(manager.history.join("\n"));
//		return;
		Log.print("appuyez sur 'C' pour\ncopier ce texte dans le\npresse-papier");
		Log.print("--- VERSION ---");
		Log.print("beta 6.1+");
		Log.print("build:"+"kikifest");
		Log.print("f:"+GameManager.CONFIG.families.join("."));
		Log.print("--- DATA ---");
		Log.print("lvl= "+world?.currentId);
		Log.print("bads= "+countList(RootData.BAD));
		Log.print("bads_c= "+countList(RootData.BAD_CLEAR));
		Log.print("clear= "+fl_clear);
		Log.print("cycle= "+Math.round(world?.scriptEngine?.cycle));
		Log.print("compile= "+world?.scriptEngine?.fl_compile);
		Log.print("--- SCRIPT ---");
		var node:Dynamic = world?.scriptEngine?.script?.firstChild;
		while ( node!=null ) {
			if ( node?.nodeName!=null ) {
				Log.print(node?.nodeName);
			}
			node = node?.nextSibling;
		}
		Log.print("--- HIST ---");
		Log.print("\n"+world?.scriptEngine?.history?.join("\n*"));
		Log.print("------");
	}


	/*------------------------------------------------------------------------
	ITEMS PAR NIVEAU (DÉPENDANT DU MODE)
	------------------------------------------------------------------------*/
	public function addLevelItems()  untyped {
		// do nothing
	}


	/*------------------------------------------------------------------------
	DÉMARRE LE LEVEL
	------------------------------------------------------------------------*/
	public function startLevel()  untyped {
		var n:Dynamic=0;
		n = world?.scriptEngine?.insertBads();
		if ( n==0 ) {
			fxMan?.attachExit();
			fl_clear = true;
		}

		updateDarkness();

		if ( !world?.isVisited() ) {
			addLevelItems();
		}

		statsMan?.reset();
//		world.scriptEngine.compile();
		world?.scriptEngine?.onPlayerBirth();
		world?.unlock();

		fl_badsCallback = false;

		if ( isBossLevel(world?.currentId) ) {
			fxMan?.attachWarning();
		}
	}


	/*------------------------------------------------------------------------
	PASSE AU NIVEAU SUIVANT
	------------------------------------------------------------------------*/
	public function nextLevel()  untyped {
		fakeLevelId++;
		goto(world?.currentId+1);
	}


	/*------------------------------------------------------------------------
	PASSAGE FORCÉ À UN NIVEAU
	------------------------------------------------------------------------*/
	public function forcedGoto(id:Dynamic)  untyped {
		fakeLevelId += id-world?.currentId;
		{ if (world != null) world.fl_hideBorders	= false; }
		{ if (world != null) world.fl_hideTiles		= false; }
		goto(id);

		var lp:Dynamic = getPlayerList();
		{ var i:Dynamic=0; while (i<lp?.length) {
			lp[i]?.moveTo(
				Entity.x_ctr(world?.current?.__S_playerX),
				Entity.y_ctr(world?.current?.__S_playerY-1)
			);
			lp[i]?.shield(RootData.SHIELD_DURATION*1.3);
			lp[i]?.hide();
		
i++; } }
	}


	/*------------------------------------------------------------------------
	VIDE LE NIVEAU EN COURS
	------------------------------------------------------------------------*/
	public function clearLevel()  untyped {
		killPop();
		killPointer();
		killItemName();

		destroyList(RootData.BAD);
		destroyList(RootData.ITEM);
		destroyList(RootData.BOMB);
		destroyList(RootData.SUPA);
		destroyList(RootData.SHOOT);
		destroyList(RootData.FX);
		destroyList(RootData.BOSS);

		clearDynamicVars();
	}


	/*------------------------------------------------------------------------
	CHANGE DE NIVEAU
	------------------------------------------------------------------------*/
	public function goto(id:Dynamic)  untyped {
		if (fl_lock || fl_gameOver) {
			return;
		}



		if ( id>=world?.levels?.length ) {
			world?.onEndOfSet();
			return;
		}

		var l : Array<Entity>;
		var lp : Array<entity.Player>;

		clearExtraHoles();
		world?.lock();
		killPortals();
		clearLevel();

		lock();
		fl_clear = false;
		world?.goto(id);

		l = getList(RootData.ENTITY);
		{ var i:Dynamic=0; while (i<l?.length) {
			{ if (l[i] != null) l[i].world = world; }
		
i++; } }

		// Le 1er player arrivé en bas débarque en 1er au level suivant
		lp = getPlayerList();
		var best : entity.Player = null;
		{ var i:Dynamic=0; while (i<lp?.length) {
			if ( best==null || lp[i]?.y > best?.y ) {
				best = lp[i];
			}
		
i++; } }
		{ var i:Dynamic=0; while (i<lp?.length) {
			lp[i]?.moveTo( best?.x, -600 );
			lp[i]?.hide();
			lp[i]?.onNextLevel();
		
i++; } }
		best?.moveTo(best?.x,-200);

		fxMan?.onNextLevel();

		soundMan?.playSound("sound_level_clear", RootData.CHAN_INTERF);
	}


	override public function lock()  untyped {
		super.lock();
		gameChrono?.stop();
	}

	override public function unlock()  untyped {
		super.unlock();
		gameChrono?.start();
	}


	/*------------------------------------------------------------------------
	COMPTEUR DE COMBO POUR UN ID UNIQUE
	------------------------------------------------------------------------*/
	public function countCombo(id:Dynamic)  untyped {
		if ( comboList[id]==null ) {
			comboList[id] = 0;
		}
		return ++comboList[id];
	}


	/*------------------------------------------------------------------------
	RENVOIE TRUE SI LE POP D'ITEM EST ENCORE AUTORISÉ
	------------------------------------------------------------------------*/
	public function canAddItem()  untyped {
		return !fl_clear || world?.current?.__S_badList?.length==0;
	}


	/*------------------------------------------------------------------------
	LANCE UN EFFET BULLET TIME
	------------------------------------------------------------------------*/
	public function bulletTime(d:Dynamic)  untyped {
		if ( !fl_bullet ) {
			return;
		}
		bulletTimer = d;
	}


	/*------------------------------------------------------------------------
	MISE À JOUR DES VARIABLES DE FRICTIONS AU SOL
	------------------------------------------------------------------------*/
	public function updateGroundFrictions()  untyped {
		gFriction = Math.pow(RootData.FRICTION_GROUND, Timer.tmod) ; // x au sol
		sFriction = Math.pow(RootData.FRICTION_SLIDE, Timer.tmod) ; // x sur sol glissant
	}


	/*------------------------------------------------------------------------
	COMPTAGE D'ITEMS
	------------------------------------------------------------------------*/
	public function pickUpSpecial(id:Dynamic)  untyped {
		if ( specialPicks[id]==null ) {
			specialPicks[id]=0;
		}
		return ++specialPicks[id];
	}

	public function pickUpScore(id:Dynamic,subId:Dynamic)  untyped {
		if ( scorePicks[id]==null ) {
			scorePicks[id]=0;
		}
		return ++scorePicks[id];
	}

	public function getPicks()  untyped {
		var s:Dynamic = "";
		{ var i:Dynamic=0; while (i<specialPicks?.length) {
			if ( specialPicks[i]!=null ) {
				s+=i+"="+specialPicks[i]+"|";
			}
		
i++; } }
		{ var i:Dynamic=0; while (i<scorePicks?.length) {
			if ( scorePicks[i]!=null ) {
				s+=(i+1000)+"="+scorePicks[i]+"|";
			}
		
i++; } }
		if ( s?.length>0 ) {
			s = s?.substr(0,s?.length-1);
		}

		return s;
	}


	public function getPicks2()  untyped {
		var s : Array<Int> = new Array();
		{ var i:Dynamic=0; while (i<specialPicks?.length) {
			if ( specialPicks[i]!=null ) {
				s[i] = specialPicks[i];
			}
		
i++; } }
		{ var i:Dynamic=0; while (i<scorePicks?.length) {
			if ( scorePicks[i]!=null ) {
				s[i+1000] = scorePicks[i];
			}
		
i++; } }


		return s;
	}


	/*------------------------------------------------------------------------
	RENVOIE TRUE SI LE LEVEL COMPORTE UN BOSS
	------------------------------------------------------------------------*/
	public function isBossLevel(id:Dynamic)  untyped {
		return false;
	}


	/*------------------------------------------------------------------------
	FLIP HORIZONTAL D'UN X, SI NÉCESSAIRE
	------------------------------------------------------------------------*/
	public function flipCoordReal(x:Dynamic)  untyped {
		if ( fl_mirror ) {
			return RootData.GAME_WIDTH-x-1;
		}
		else {
			return x;
		}
	}

	public function flipCoordCase(cx:Dynamic)  untyped {
		if ( fl_mirror ) {
			return RootData.LEVEL_WIDTH-cx-1;
		}
		else {
			return cx;
		}
	}


	/*------------------------------------------------------------------------
	AJOUTE UN ÉVÈNEMENT À LA CARTE
	------------------------------------------------------------------------*/
	public function registerMapEvent( eid:Dynamic, misc:Dynamic )  untyped {
		var lid:Dynamic = dimensions[0]?.currentId;

		if ( !world?.fl_mainWorld ) {
			return;
		}

		// Filtre infos inutiles
		{ var i:Dynamic=0; while (i<mapEvents?.length) {
			var e:Dynamic = mapEvents[i];

			// aller-retour au meme level
			if ( e?.lid==lid && e?.eid==RootData.EVENT_EXIT_RIGHT && eid==RootData.EVENT_BACK_RIGHT ) {
				return;
			}
			if ( e?.lid==lid && e?.eid==RootData.EVENT_EXIT_LEFT && eid==RootData.EVENT_BACK_LEFT ) {
				return;
			}

			// sorti plusieurs fois au meme level
			if ( e?.lid==lid && e?.eid==RootData.EVENT_EXIT_RIGHT && eid==RootData.EVENT_EXIT_RIGHT ) {
				return;
			}
			if ( e?.lid==lid && e?.eid==RootData.EVENT_EXIT_LEFT && eid==RootData.EVENT_EXIT_LEFT ) {
				return;
			}
		
i++; } }


		var e:Dynamic = {
			lid		: lid,
			eid		: eid,
			misc	: misc,
		};
		if ( eid==RootData.EVENT_EXIT_LEFT || eid==RootData.EVENT_EXIT_RIGHT || eid==RootData.EVENT_BACK_LEFT || eid==RootData.EVENT_BACK_RIGHT || eid==RootData.EVENT_TIME ) {
			mapTravels?.push(e);
		}
		else {
			mapEvents?.push(e);
		}

	}


	/*------------------------------------------------------------------------
	RENVOIE LE Y SUR LA MAP POUR UN ID LEVEL DONNÉ
	------------------------------------------------------------------------*/
	public function getMapY(lid:Dynamic)  untyped {
		return 84 + Math.min(350, lid*3.5);
	}



	/*------------------------------------------------------------------------
	DÉFINI UNE VARIABLE DYNAMIQUE
	------------------------------------------------------------------------*/
	public function setDynamicVar(name:Dynamic,value:Dynamic)  untyped {
		dvars?.set(name?.toLowerCase(),value);
	}

	/*------------------------------------------------------------------------
	LIT UNE VARIABLE DYNAMIQUE
	------------------------------------------------------------------------*/
	public function getDynamicVar(name:Dynamic)  untyped {
		return dvars?.get( name?.substring(1)?.toLowerCase() ); // le $ est retiré en interne
	}

	public function getDynamicInt(name:Dynamic):Int  untyped {
		return MtStd.parseInt(getDynamicVar(name),10);
	}


	/*------------------------------------------------------------------------
	EFFACE LES VARIABLES DYNAMIQUES
	------------------------------------------------------------------------*/
	public function clearDynamicVars()  untyped {
		dvars = new Hash();
	}


	/*------------------------------------------------------------------------
	ENVOI DU RÉSULTAT DE LA PARTIE
	------------------------------------------------------------------------*/
	public function saveScore()  untyped {
		// do nothing
	}


	/*------------------------------------------------------------------------
	MÉMORISE LE SCORE D'UN JOUEUR
	------------------------------------------------------------------------*/
	public function registerScore(pid:Dynamic,score:Dynamic)  untyped {
		if ( savedScores[pid]==null || savedScores[pid]<=0 ) {
			savedScores[pid] = score;
		}
	}


	/*------------------------------------------------------------------------
	DÉFINI UN FILTRE DE COULEUR (HEXADÉCIMAL)
	------------------------------------------------------------------------*/
	public function setColorHex( a:Dynamic, col:Dynamic )  untyped {
		var coo:Dynamic = {
			r:col>>16,
			g:(col>>8)&0xFF,
			b:col&0xFF
		};
		var ratio:Dynamic  = a/100;
		var ct:Dynamic = {
			ra:Int(100-a),
			ga:Int(100-a),
			ba:Int(100-a),
			aa:100,
			rb:Int(ratio*coo?.r),
			gb:Int(ratio*coo?.g),
			bb:Int(ratio*coo?.b),
			ab:0
		};
		color = new Color(root);
		color?.setTransform( ct );
		colorHex = col;
	}

	/*------------------------------------------------------------------------
	ANNULE UN FILTRE DE COULEUR
	------------------------------------------------------------------------*/
	public function resetCol()  untyped {
		if ( color!=null ) {
			colorHex = null;
			color?.reset();
			color = null;
		}
	}


	/*------------------------------------------------------------------------
	GESTION DES WORLD KEYS
	------------------------------------------------------------------------*/
	public function giveKey(id:Dynamic)  untyped {
		worldKeys[id] = true;
	}

	public function hasKey(id:Dynamic)  untyped {
		return worldKeys[id]==true || MtStd.isNaN(id);
	}



	// *** DIMENSIONS

	/*------------------------------------------------------------------------
	CHANGEMENT DE DIMENSION
	------------------------------------------------------------------------*/
	public function switchDimensionById(id:Dynamic,lid:Dynamic,pid:Dynamic)  untyped {
//		if ( currentDim==id ) {
//			return;
//		}

		if ( !fl_clear ) {
			return;
		}

		resetHurry();

		latePlayers = new Array();
		var l:Dynamic = getPlayerList();
		{ var i:Dynamic=0; while (i<l?.length) {
			var p:Dynamic = l[i];
			p?.specialMan?.clearTemp();
			p?.specialMan?.clearRec();
			{ if (p != null) p._xscale = p?.scaleFactor*100; }
			{ if (p != null) p._yscale = p?._xscale; }
			{ if (p != null) p.lockTimer = 0; }
			{ if (p != null) p.fl_lockControls = false; }
			{ if (p != null) p.fl_gravity = true; }
			{ if (p != null) p.fl_friction = true; }
			if ( !p?.fl_kill ) {
				{ if (p != null) p.fl_hitWall = true; }
				{ if (p != null) p.fl_hitGround = true; }
			}
			p?.changeWeapon(RootData.WEAPON_B_CLASSIC);
			if ( world?.getCase( {x:p.cx,y:p.cy} )!=RootData.FIELD_PORTAL ) {
				latePlayers?.push(p);
			}
			p?.hide();
		
i++; } }

		holeUpdate();


		clearExtraHoles();
		clearLevel();
		killPortals();
		fxMan?.clear();
		cleanKills();
		currentDim = id;
		var ss:Dynamic = world?.getSnapShot();
		world?.suspend();
		world = dimensions[currentDim];
		{ if (world != null) world.darknessFactor = dfactor; }
		lock();
		fl_clear = false;
		if ( pid<0 ) {
			{ if (world != null) world.fl_fadeNextTransition = true; }
		}
		world?.restoreFrom(ss,lid);
		updateEntitiesWorld();
		if ( !world?.fl_mainWorld ) {
			fakeLevelId = 0;
		}
		else {
			fakeLevelId = null;
		}

		portalId = pid;
		nextLink = null;
	}


	/*------------------------------------------------------------------------
	INITIALISE ET AJOUTE UNE DIMENSION
	------------------------------------------------------------------------*/
	public function addWorld(name:Dynamic)  untyped {
		var dim:Dynamic;
		dim = new levels.GameMechanics(manager,name);
		{ if (dim != null) dim.fl_mirror = fl_mirror; }
		dim?.setDepthMan(depthMan);
		dim?.setGame(this);
		if ( dimensions?.length>0 ) {
			dim?.suspend();
			{ if (dim != null) dim.fl_mainWorld = false; }
		}
		else {
			world = dim;
		}
		dimensions?.push(dim);
		return dim;
	}


	/*------------------------------------------------------------------------
	RENVOIE LE PT D'ENTRÉE APRES UN SWITCH DIMENSION
	------------------------------------------------------------------------*/
	public function getPortalEntrance(pid:Dynamic)  untyped {
		var px:Dynamic = world?.current?.__S_playerX;
		var py:Dynamic = world?.current?.__S_playerY;
		var fl_unstable:Dynamic = false;

		if ( pid>=0 && world?.portalList[pid]!=null ) {
			px = world?.portalList[pid]?.cx;
			py = world?.portalList[pid]?.cy;

			// Vertical
			if ( world?.getCase({x:px,y:py+1})==RootData.FIELD_PORTAL ) {
				while ( world?.getCase({x:px,y:py+1})==RootData.FIELD_PORTAL ) {
					py++;
				}
				// gauche
				if ( world?.getCase({x:px-1,y:py})<=0 ) {
					px-=1;
				}
				else {
					if ( world?.getCase({x:px+1,y:py})<=0 ) {
						px+=1;
					}
				}
			}
			else {
				// Horizontal
				if ( world?.getCase({x:px+1,y:py})==RootData.FIELD_PORTAL ) {
					py+=2;
				}
				fl_unstable = true;
			}
		}
		else {
			fl_unstable = true;
			// todo: vortex d'arrivée d'un portal
		}

		return {x:px, y:py, fl_unstable:fl_unstable};
	}


	/*------------------------------------------------------------------------
	UTILISE UN PORTAL (renvoie false si pas de correspondance)
	------------------------------------------------------------------------*/
	public function usePortal(pid:Dynamic, e:entity.Physics)  untyped {
		if ( nextLink!=null ) {
			return false;
		}
		var link:Dynamic = RootData.getLink(currentDim, world?.currentId, pid);
		if ( link==null ) {
			return false;
		}

		var name:Dynamic = Lang.getLevelName(link?.to_did, link?.to_lid);

		if ( flipCoordReal(e?.x)>=RootData.GAME_WIDTH*0.5 ) {
			fl_rightPortal = true;
			registerMapEvent( RootData.EVENT_EXIT_RIGHT, (world?.currentId+1)+". "+name);
		}
		else {
			fl_rightPortal = false;
			registerMapEvent( RootData.EVENT_EXIT_LEFT, (world?.currentId+1)+". "+name);
		}

		if ( e==null ) {
			var pl:Dynamic = getPlayerList();
			{ var i:Dynamic=0; while (i<pl?.length) {
				var p:Dynamic = pl[i];
				{ if (p != null) p.dx = (portalMcList[pid]?.x-p?.x)*0.018; }
				{ if (p != null) p.dy = (portalMcList[pid]?.y-p?.y)*0.018; }
				{ if (p != null) p.fl_hitWall = false; }
				{ if (p != null) p.fl_hitGround = false; }
				{ if (p != null) p.fl_gravity = false; }
				{ if (p != null) p.fl_friction = false; }
				p?.specialMan?.clearTemp();
				p?.unshield();
				p?.lockControls(RootData.SECOND*9999);
				p?.playAnim(RootData.ANIM_PLAYER_DIE);
			
i++; } }
			nextLink = link;
		}
		else {
			switchDimensionById( link?.to_did, link?.to_lid, link?.to_pid );
		}
		return true;
	}


	/*------------------------------------------------------------------------
	OUVRE UN PORTAIL FLOTTANT
	------------------------------------------------------------------------*/
	public function openPortal(cx:Dynamic,cy:Dynamic,pid:Dynamic)  untyped {
		if ( portalMcList[pid]!=null ) {
			return false;
		}
		else {
			world?.scriptEngine?.insertPortal(cx,cy,pid);
			var x:Dynamic = Entity.x_ctr(flipCoordCase(cx));
			var y:Dynamic = Entity.y_ctr(cy)-RootData.CASE_HEIGHT*0.5;
			var p:Dynamic = depthMan?.attach("hammer_portal",RootData.DP_SPRITE_BACK_LAYER);
			{ if (p != null) p._x = x; }
			{ if (p != null) p._y = y; }
			fxMan?.attachExplosion(x,y, 40);
			fxMan?.inGameParticles(RootData.PARTICLE_PORTAL, x,y, 5);
			fxMan?.attachShine(x,y);
			portalMcList[pid] = {x:x, y:y, mc:p, cpt:0};
			return true;
		}
	}



	// *** LISTES


	/*-----------------------------------------------------------------------
	RENVOIE UN ID DE LISTE D'ENTITÉ CALCULÉ SELON LE TYPE
	------------------------------------------------------------------------*/
	public function getListId(type:Dynamic):Int  untyped {
		var i:Dynamic = 0;
		var bin:Dynamic = 1<<i;
		while (type!=bin) {
			i++;
			bin = 1<<i;
		}
		return i;
	}


	/*------------------------------------------------------------------------
	RENVOIE LA LISTE D'ENTITÉS DU TYPE DEMANDÉ
	------------------------------------------------------------------------*/
	public function getList(type:Dynamic) : Array<Entity>  untyped {
		return lists[getListId(type)];
	}

	public function getListAt(type:Dynamic,cx:Dynamic,cy:Dynamic) : Array<Entity>  untyped {
		var l:Dynamic = getList(type);
		var res:Dynamic = new Array();
		{ var i:Dynamic=0; while (i<l?.length) {
			if ( l[i]?.cx==cx && l[i]?.cy==cy ) {
				res?.push(l[i]);
			}
		
i++; } }
		return res;
	}


	/*------------------------------------------------------------------------
	RENVOIE LE NOMBRE D'ENTITÉS DU TYPE DEMANDÉ
	------------------------------------------------------------------------*/
	public function countList(type:Dynamic) : Int  untyped {
		return lists[getListId(type)]?.length;
	}



	/*------------------------------------------------------------------------
	RENVOIE DES LISTES SPÉCIFIQUES TYPÉES
	------------------------------------------------------------------------*/
	public function getBadList() : Array<entity.Bad>  untyped {
		return (cast (getList(RootData.BAD)));
	}
	public function getBadClearList() : Array<entity.Bad>  untyped {
		return (cast (getList(RootData.BAD_CLEAR)));
	}
	public function getPlayerList() : Array<entity.Player>  untyped {
		return (cast (getList(RootData.PLAYER)));
	}


	/*------------------------------------------------------------------------
	RENVOIE UNE DUPLICATION D'UNE LISTE D'ENTITÉS
	------------------------------------------------------------------------*/
	public function getListCopy(type:Dynamic) : Array<Entity>  untyped {
		var l:Dynamic = getList(type);
		var out:Dynamic = new Array();
		{ var i:Dynamic=0; while (i<l?.length) {
			out[i] = l[i];
		
i++; } }

		return out;
	}


	/*------------------------------------------------------------------------
	RENVOIE LES ENTITÉS À PROXIMITÉ D'UN POINT DONNÉ
	------------------------------------------------------------------------*/
	public function getClose(type:Dynamic, x:Dynamic,y:Dynamic, radius:Dynamic, fl_onGround:Bool) : Array<Entity>  untyped {
		var l:Dynamic = getList(type);
		var out:Dynamic = new Array();
		var sqrRad:Dynamic = Math.pow(radius,2);

		{ var i:Dynamic=0; while (i<l?.length) {
			var e:Dynamic = l[i];
			var square:Dynamic = Math.pow(e?.x-x,2) + Math.pow(e?.y-y,2);
			if ( square <= sqrRad ) {
				if ( Math.sqrt(square) <= radius ) {
					if ( !fl_onGround || ( fl_onGround && e?.y<=y+RootData.CASE_HEIGHT) ) {
						out?.push(e);
					}
				}
			}
		
i++; } }

		return out;
	}



	/*------------------------------------------------------------------------
	RETOURNE UNE ENTITÉ AU HASARD D'UN TYPE DONNÉ, OU NULL
	------------------------------------------------------------------------*/
	public function getOne(type:Dynamic) : Entity  untyped {
		var l:Dynamic = getList(type);
		return l[MtStd.random(l?.length)];
	}


	/*------------------------------------------------------------------------
	RETOURNE UNE ENTITÉ AU HASARD D'UN TYPE DONNÉ, OU NULL
	------------------------------------------------------------------------*/
	public function getAnotherOne(type:Dynamic,e:Entity) : Entity  untyped {
		var l:Dynamic = getList(type);
		if ( l?.length<=1 ) {
			return null;
		}

		var i : Int;
		do {
			i=MtStd.random(l?.length);
		}
		while (l[i]==e);

		return l[i];
	}


	/*------------------------------------------------------------------------
	AJOUTE À UNE LISTE D'UPDATE
	------------------------------------------------------------------------*/
	public function addToList( type:Dynamic, e:Entity )  untyped {
		lists[getListId(type)]?.push(e);
	}


	/*------------------------------------------------------------------------
	RETIRE D'UNE LISTE D'UPDATE
	------------------------------------------------------------------------*/
	public function removeFromList( type:Dynamic, e:Entity )  untyped {
		lists[getListId(type)]?.remove(e);
	}


	/*------------------------------------------------------------------------
	DÉTRUIT TOUS LES MCS D'UNE LISTE
	------------------------------------------------------------------------*/
	public function destroyList( type:Dynamic )  untyped {
		var list:Dynamic = getList(type);
		{ var i:Dynamic=0; while (i<list?.length) {
			list[i]?.destroy();
		
i++; } }
	}


	/*------------------------------------------------------------------------
	DÉTRUIT N ENTITÉ AU HASARD D'UNE LISTE
	------------------------------------------------------------------------*/
	public function destroySome( type:Dynamic, n:Dynamic)  untyped {
		var l:Dynamic = getListCopy(type);
		while (l?.length>0 && n>0) {
			var i:Dynamic = MtStd.random(l?.length);
			l[i]?.destroy();
			l?.splice(i,1);
			n--;
		}
	}


	/*------------------------------------------------------------------------
	NETTOIE LES LISTES DE DESTRUCTION
	------------------------------------------------------------------------*/
	public function cleanKills()  untyped {
		// Dés-enregistrement d'entités détruites dans ce tour
		{ var i:Dynamic=0; while (i<unregList?.length) {
			removeFromList( unregList[i]?.type, unregList[i]?.ent );
		
i++; } }
		unregList = new Array();

		// Suppression d'entités en fin de tour
		{ var i:Dynamic=0; while (i<killList?.length) {
			var e:Dynamic = killList[i];
//			if ( (e.types&Data.BAD_CLEAR) > 0 && !fl_lock) {
//				checkLevelClear();
//			}
			e?.removeMovieClip();
		
i++; } }
		killList = new Array();
	}


	/*------------------------------------------------------------------------
	FIN DE MODE
	------------------------------------------------------------------------*/
	public function exitGame()  untyped {
		var codec:Dynamic = new PersistCodec();
		var out:Dynamic = codec?.encode( codec?.encode(specialPicks)+":"+codec?.encode(scorePicks) );
		manager?.redirect("endGame.html",out);
	}



	/*------------------------------------------------------------------------
	DESTRUCTION
	------------------------------------------------------------------------*/
	override public function destroy()  untyped {
		resetCol();
		killPortals();
		super.destroy();
	}


	// *** ATTACHEMENTS

	/*------------------------------------------------------------------------
	ATTACHE UN JOUEUR
	------------------------------------------------------------------------*/
	public function insertPlayer(cx:Dynamic,cy:Dynamic)  untyped {
		// Calcul du PID
		var pid:Dynamic = 0;
		var pl:Dynamic = getPlayerList();
		{ var i:Dynamic=0; while (i<pl?.length) {
			if ( !pl[i]?.fl_destroy ) {
				pid++;
			}
		
i++; } }

		var p:Dynamic = entity.Player.attach( this, Entity.x_ctr(cx) ,Entity.y_ctr(cy) );
		p?.hide();
		{ if (p != null) p.pid = pid; }

		return p;
	}

	/*------------------------------------------------------------------------
	ATTACH: ENNEMI
	------------------------------------------------------------------------*/
	public function attachBad(id:Dynamic,x:Dynamic,y:Dynamic):entity.Bad  untyped {
		var bad:Dynamic=null;
		{ var __sw:Dynamic = id;
if (__sw == (RootData.BAD_POMME)) { bad = entity.bad.walker.Pomme.attach(this,x,y) ; 
			}
else if (__sw == (RootData.BAD_CERISE)) { bad = entity.bad.walker.Cerise.attach(this,x,y) ; 
			}
else if (__sw == (RootData.BAD_BANANE)) { bad = entity.bad.walker.Banane.attach(this,x,y) ; 
			}
else if (__sw == (RootData.BAD_ANANAS)) { bad = entity.bad.walker.Ananas.attach(this,x,y) ; 
			}
else if (__sw == (RootData.BAD_ABRICOT)) { bad = entity.bad.walker.Abricot.attach(this,x,y,true) ; 
			}
else if (__sw == (RootData.BAD_ABRICOT2)) { bad = entity.bad.walker.Abricot.attach(this,x,y,false) ; 
			}
else if (__sw == (RootData.BAD_POIRE)) { bad = entity.bad.walker.Poire.attach(this,x,y) ; 
			}
else if (__sw == (RootData.BAD_BOMBE)) { bad = entity.bad.walker.Bombe.attach(this,x,y) ; 
			}
else if (__sw == (RootData.BAD_ORANGE)) { bad = entity.bad.walker.Orange.attach(this,x,y) ; 
			}
else if (__sw == (RootData.BAD_FRAISE)) { bad = entity.bad.walker.Fraise.attach(this,x,y) ; 
			}
else if (__sw == (RootData.BAD_CITRON)) { bad = entity.bad.walker.Citron.attach(this,x,y) ; 
			}
else if (__sw == (RootData.BAD_BALEINE)) { bad = entity.bad.flyer.Baleine.attach(this,x,y) ; 
			}
else if (__sw == (RootData.BAD_SPEAR)) { bad = entity.bad.Spear.attach(this,x,y) ; 
			}
else if (__sw == (RootData.BAD_CRAWLER)) { bad = entity.bad.ww.Crawler.attach(this,x,y) ; 
			}
else if (__sw == (RootData.BAD_TZONGRE)) { bad = entity.bad.flyer.Tzongre.attach(this,x,y) ; 
			}
else if (__sw == (RootData.BAD_SAW)) { bad = entity.bad.ww.Saw.attach(this,x,y) ; 
			}
else if (__sw == (RootData.BAD_LITCHI)) { bad = entity.bad.walker.Litchi.attach(this,x,y) ; 
			}
else if (__sw == (RootData.BAD_KIWI)) { bad = entity.bad.walker.Kiwi.attach(this,x,y) ; 
			}
else if (__sw == (RootData.BAD_LITCHI_WEAK)) { bad = entity.bad.walker.LitchiWeak.attach(this,x,y) ; 
			}
else if (__sw == (RootData.BAD_FRAMBOISE)) { bad = entity.bad.walker.Framboise.attach(this,x,y) ; 

			}
else {
				GameManager.fatal("(attachBad) unknown bad "+id);
			
		}
}

		if ( bad?.isType(RootData.BAD_CLEAR) ) {
			badCount++;
		}


		return bad;
	}


	/*------------------------------------------------------------------------
	ATTACH: POP UP IN-GAME
	------------------------------------------------------------------------*/
	public function attachPop(msg:Dynamic,fl_tuto:Dynamic)  untyped {
		killPop();
		popMC = (( depthMan.attach("hammer_interf_pop", RootData.DP_INTERF) ):Dynamic);
		{ if (popMC != null) popMC._x = RootData.GAME_WIDTH*0.5; }

		if ( fl_tuto ) {
			popMC?.sub?.gotoAndStop("2");
			{ if (popMC?.sub?.header != null) popMC.sub.header.text = Lang.get(2); }
		}
		else {
			popMC?.sub?.gotoAndStop("1");
		}

		// Trims leading endLines
		while ( msg?.charCodeAt(0)==10 || msg?.charCodeAt(0)==13 ) {
			msg = msg?.substring(1);
		}

		{ if (popMC?.sub?.field != null) popMC.sub.field.html = true; }
		{ if (popMC?.sub?.field != null) popMC.sub.field.htmlText = RootData.replaceTag(msg, "*","<font color=\"#f7e8d5\">","</font>"); }

		// Vertical centering
		var h:Dynamic = popMC?.sub?.field?.textHeight;
		{ if (popMC?.sub?.field != null) popMC.sub.field._y = -h*0.5 - 2; }
	}


	/*------------------------------------------------------------------------
	ATTACH: POINTEUR DE CIBLAGE
	------------------------------------------------------------------------*/
	public function attachPointer(cx:Dynamic,cy:Dynamic, ocx:Dynamic,ocy:Dynamic)  untyped {
		killPointer();
		var x:Dynamic = Entity.x_ctr(cx);
		var y:Dynamic = Entity.y_ctr(cy);
		var ox:Dynamic = Entity.x_ctr(ocx);
		var oy:Dynamic = Entity.y_ctr(ocy);
		pointerMC = depthMan?.attach("hammer_fx_pointer", RootData.DP_INTERF);
		{ if (pointerMC != null) pointerMC._x = x; }
		{ if (pointerMC != null) pointerMC._y = y; }
		var ang:Dynamic = Math.atan2(oy-y, ox-x) * 180 / Math.PI;
		{ if (pointerMC != null) pointerMC._rotation = ang-90; }
	}


	/*------------------------------------------------------------------------
	ATTACH: CERCLE DE DEBUG
	------------------------------------------------------------------------*/
	public function attachRadius(x:Dynamic,y:Dynamic,r:Dynamic)  untyped {
		killRadius();
		radiusMC = depthMan?.attach("debug_radius", RootData.DP_INTERF);
		{ if (radiusMC != null) radiusMC._x = x; }
		{ if (radiusMC != null) radiusMC._y = y; }
		{ if (radiusMC != null) radiusMC._width = r*2; }
		{ if (radiusMC != null) radiusMC._height = radiusMC?._width; }
	}


	/*------------------------------------------------------------------------
	AFFICHE UN NOM D'ITEM SPÉCIAL RAMASSÉ
	------------------------------------------------------------------------*/
	public function attachItemName(family:Array<Array<ItemFamilySet>>,id)  untyped {
		if ( id==null ) {// || popMC._name!=null ) {
			return;
		}

		// Recherche du nom
		var s:Dynamic	= null;
		var i:Dynamic	= 0;
		while (s==null && i<family?.length) {
			var j:Dynamic=0;
			while (s==null && (j:Float) < (family[i]?.length:Float)) {
				if ( MtStd.ix(family[i], j)?.id == id ) {
					s = MtStd.ix(family[i], j)?.name;
				}
				j++;
			}
			i++;
		}

		if ( s!="" && s!=null ) {
			// Affichage
			killItemName();
			itemNameMC = (( depthMan.attach("hammer_interf_item_name", RootData.DP_TOP) ):Dynamic);
			{ if (itemNameMC != null) itemNameMC._x = RootData.GAME_WIDTH*0.5 + 20; } // icon width
			{ if (itemNameMC != null) itemNameMC._y = 15; }//Data.GAME_HEIGHT-20; // 15;
			{ if (itemNameMC?.field != null) itemNameMC.field.text = s; }

			// Item icon
			var icon:Dynamic;
			if ( id<1000 ) {
				icon = MtStd.attachMC( itemNameMC, "hammer_item_special",manager.uniq++);
				icon?.gotoAndStop(""+(id+1));
			}
			else {
				icon = MtStd.attachMC( itemNameMC, "hammer_item_score",manager.uniq++);
				icon?.gotoAndStop(""+(id-1000+1));
			}
			{ if (icon != null) icon._x -= itemNameMC?.field?.textWidth*0.5 + 20; }
			{ if (icon != null) icon._y = 10; }
			{ if (icon != null) icon._xscale = 75; }
			{ if (icon != null) icon._yscale = icon?._xscale; }
			((icon):Dynamic)?.sub?.stop();
		}
	}


	/*------------------------------------------------------------------------
	DETACHEMENTS
	------------------------------------------------------------------------*/
	public function killPop()  untyped {
		popMC?.removeMovieClip();
	}

	public function killPointer()  untyped {
		pointerMC?.removeMovieClip();
	}

	public function killRadius()  untyped {
		radiusMC?.removeMovieClip();
	}

	public function killItemName()  untyped {
		itemNameMC?.removeMovieClip();
	}


	public function killPortals()  untyped {
		{ var i:Dynamic=0; while (i<portalMcList?.length) {
			portalMcList[i]?.mc?.removeMovieClip();
		
i++; } }
		portalMcList = new Array();
	}


	/*------------------------------------------------------------------------
	ATTACH: ICON SUR LA CARTE
	------------------------------------------------------------------------*/
	public function attachMapIcon(eid:Dynamic,lid:Dynamic, txt:Dynamic, offset:Dynamic, offsetTotal:Dynamic)  untyped {
		var x:Dynamic = RootData.GAME_WIDTH*0.5;
		var y:Dynamic = getMapY(lid);
		if ( offset!=null ) {
			var wid:Dynamic = 8;
			x += offset*wid - 0.5*(offsetTotal-1)*wid;
		}

		if ( eid==RootData.EVENT_EXIT_LEFT || eid==RootData.EVENT_BACK_LEFT ) {
			x = RootData.GAME_WIDTH*0.5 - 5;
		}
		if ( eid==RootData.EVENT_EXIT_RIGHT || eid==RootData.EVENT_BACK_RIGHT ) {
			x = RootData.GAME_WIDTH*0.5 + 5;
		}

		var mc:Dynamic = depthMan?.attach("hammer_interf_mapIcon", RootData.DP_INTERF);
		mc?.gotoAndStop(""+eid);
		{ if (mc != null) mc._x = Math.floor(x); }
		{ if (mc != null) mc._y = Math.floor(y); }

		if ( txt==null ) {
			txt = "?";
		}
		((mc):Dynamic).field.text = txt;
		mapIcons?.push(mc);
	}


	/*------------------------------------------------------------------------
	BOULE DE FEU DE HURRY UP
	------------------------------------------------------------------------*/
	public function callEvilOne(baseAnger:Dynamic)  untyped {
		var lp:Dynamic = getPlayerList();
		{ var i:Dynamic=0; while (i<lp?.length) {
			if ( !lp[i]?.fl_kill ) {
				var mc:Dynamic = entity.bad.FireBall.attach(this, lp[i]);
				{ if (mc != null) mc.anger = baseAnger-1; }
				if ( baseAnger>0 ) {
					{ if (mc != null) mc.fl_summon = false; }
					mc?.stopBlink();
				}
				mc?.angerMore();
			}
		
i++; } }
	}


	// *** EVENTS

	/*------------------------------------------------------------------------
	EVENT: LEVEL PRÊT À ÊTRE JOUÉ (APRÈS SCROLLING)
	------------------------------------------------------------------------*/
	public function onLevelReady()  untyped {
//		if ( world.currentId==0 ) {
//			gameChrono.reset();
//		}
		unlock();
		initLevel();
		startLevel();

		updateEntitiesWorld();

		var l:Dynamic = getList(RootData.PLAYER);
		{ var i:Dynamic=0; while (i<l?.length) {
			l[i]?.show();
		
i++; } }
	}

	public function onBadsReady()  untyped {
		if ( fl_ninja && getBadClearList()?.length>1 ) {
			var foe : entity.Bad = (( getOne(RootData.BAD_CLEAR) ):Dynamic);
			{ if (foe != null) foe.fl_ninFoe = true; }

			if ( fl_nightmare || !world?.fl_mainWorld || world?.fl_mainWorld && world?.currentId>=20 ) {
				var lid:Dynamic = dimensions[0]?.currentId;
				friendsLimit = Math.floor( Math.max( 2, Math.floor( (lid-20)/10 ) ) );
			}
			else {
				friendsLimit = 1;
			}
			if ( fl_nightmare ) {
				friendsLimit++;
			}
			friendsLimit = Math.round( Math.min( getBadClearList()?.length-1, friendsLimit ) );
			while( friendsLimit>0 ) {
				var b : entity.Bad = (( getAnotherOne( RootData.BAD_CLEAR, foe ) ):Dynamic);
				if ( !b?.fl_ninFriend ) {
					{ if (b != null) b.fl_ninFriend = true; }
					friendsLimit--;
				}
			}
		}
	}


	/*------------------------------------------------------------------------
	EVENT: LEVEL RESTAURÉ, PRÊT À ÊTRE JOUÉ
	------------------------------------------------------------------------*/
	public function onRestore()  untyped {
		unlock();


		var pt:Dynamic = getPortalEntrance(portalId); // coordonnées case
		var l:Dynamic = getPlayerList();
		{ var i:Dynamic=0; while (i<l?.length) {
			var p:Dynamic = l[i];
			p?.moveToCase( pt?.x,pt?.y );
			p?.show();
			p?.unshield();
			if ( pt?.fl_unstable ) {
				p?.knock(RootData.SECOND*0.6);
//				fxMan.attachExplosion( p.x,p.y-Data.CASE_HEIGHT, 45 );
			}
		
i++; } }

		{ var i:Dynamic=0; while (i<latePlayers?.length) {
			var p:Dynamic = latePlayers[i];
			p?.knock(RootData.SECOND*1.3);
			{ if (p != null) p.dx = 0; }
		
i++; } }


		if ( world?.fl_mainWorld ) {
			if ( pt?.x>=RootData.LEVEL_WIDTH*0.5 ) {
				registerMapEvent( RootData.EVENT_BACK_RIGHT, null);
			}
			else {
				registerMapEvent( RootData.EVENT_BACK_LEFT, null);
			}
		}
	}


	/*------------------------------------------------------------------------
 	MISE À JOUR VARIABLE WORLD DES ENTITÉS
	------------------------------------------------------------------------*/
	public function updateEntitiesWorld()  untyped {
		var l:Dynamic;
		l = getList(RootData.ENTITY);
		{ var i:Dynamic=0; while (i<l?.length) {
			{ if (l[i] != null) l[i].world = world; }
		
i++; } }
	}


	/*------------------------------------------------------------------------
	EVENT: NIVEAU TERMINÉ
	------------------------------------------------------------------------*/
	public function onLevelClear()  untyped {
		if ( fl_clear ) {
			return;
		}

		world?.scriptEngine?.clearEndTriggers();

//		destroyList( Data.SUPA );
//		destroyList( Data.BAD_BOMB );
//		destroyList( Data.SPECIAL_ITEM );

		var l:Dynamic = getList(RootData.SPECIAL_ITEM);
		{ var i:Dynamic=0; while (i<l?.length) {
			var it : entity.Item = ((l[i]):Dynamic);
			if ( it?.id==0 ) {
				it?.destroy();
			}
		
i++; } }

		fl_clear = true;
		fxMan?.attachExit();

		// Pile d'appel post-clear
		{ var i:Dynamic=0; while (i<endLevelStack?.length) {
			endLevelStack[i]();
		
i++; } }
		endLevelStack = new Array();
	}


	/*------------------------------------------------------------------------
	EVENT: HURRY UP!
	------------------------------------------------------------------------*/
	public function onHurryUp()  untyped {
		huState++;
		huTimer = 0;

		// Énervement de tous les bads
		var lb:Dynamic = getBadList();
		{ var i:Dynamic=0; while (i<lb?.length) {
			lb[i]?.onHurryUp();
		
i++; } }

		// Annonce
		var mc:Dynamic = fxMan?.attachHurryUp();

		if ( huState==1 ) {
			soundMan?.playSound("sound_hurry", RootData.CHAN_INTERF);
		}
		if ( huState==2 ) {
			callEvilOne(0);
		}
		return mc;
	}


	/*------------------------------------------------------------------------
	EVENT: FIN DE PARTIE
	------------------------------------------------------------------------*/
	public function onGameOver()  untyped {
		fl_gameOver = true;
	}


	/*------------------------------------------------------------------------
	EVENT: MORT D'UN BAD
	------------------------------------------------------------------------*/
	public function onKillBad(b:entity.Bad)  untyped {
		// do nothing
	}


	/*------------------------------------------------------------------------
	EVENT: PAUSE
	------------------------------------------------------------------------*/
	public function onPause()  untyped {
		if ( fl_lock ) {
			return;
		}
		fl_pause = true;
		lock();
		world?.lock();

		pauseMC?.removeMovieClip();
		pauseMC = ((  depthMan.attach("hammer_interf_instructions", RootData.DP_INTERF)  ):Dynamic);
		pauseMC?.gotoAndStop("1");
		{ if (pauseMC != null) pauseMC._x = RootData.GAME_WIDTH*0.5; }
		{ if (pauseMC != null) pauseMC._y = RootData.GAME_HEIGHT*0.5; }
		{ if (pauseMC?.click != null) pauseMC.click.text	= ""; }
		{ if (pauseMC?.title != null) pauseMC.title.text	= Lang.get(5); }
		{ if (pauseMC?.move != null) pauseMC.move.text	= Lang.get(7); }
		{ if (pauseMC?.attack != null) pauseMC.attack.text	= Lang.get(8); }
		{ if (pauseMC?.pause != null) pauseMC.pause.text	= Lang.get(9); }
		{ if (pauseMC?.space != null) pauseMC.space.text	= Lang.get(10); }
		{ if (pauseMC?.sector != null) pauseMC.sector.text	= Lang.get(14)+"«"+Lang.getSectorName(currentDim, world?.currentId)+"»"; }

		if ( !fl_mute ) {
			setMusicVolume(0.5);
		}

		// Tool tip
		var tip:Dynamic	= Lang.get(301 + tipId++);
		if ( tip==null ) {
			tipId = 0;
			tip	= Lang.get(301 + tipId++);
		}

		{ if (pauseMC?.tip != null) pauseMC.tip.html = true; }
		{ if (pauseMC?.tip != null) pauseMC.tip.htmlText = "<b>" + Lang.get(300) +"</b>"+ tip; }

	}


	/*------------------------------------------------------------------------
	EVENT: WORLD MAP
	------------------------------------------------------------------------*/
	public function onMap()  untyped {
		fl_pause = true;
		lock();
		world?.lock();
		if ( !fl_mute ) {
			setMusicVolume(0.5);
		}

		mapMC?.removeMovieClip();
		mapMC = (( depthMan.attach("hammer_map", RootData.DP_INTERF) ):Dynamic);
		{ if (mapMC?.field != null) mapMC.field.text = Lang.getSectorName(currentDim, world?.currentId); }
		{ if (mapMC != null) mapMC._x = -xOffset; }

		var lid:Dynamic = dimensions[0]?.currentId;
		if ( lid==0 ) {
			{ if (mapMC?.ptr != null) mapMC.ptr._y = 70; }
			{ if (mapMC?.pit != null) mapMC.pit._visible = false; }
		}
		else {
			{ if (mapMC?.ptr != null) mapMC.ptr._y = getMapY(lid); }
			{ if (mapMC?.pit != null) mapMC.pit.blendMode	= BlendMode.OVERLAY; }
			{ if (mapMC?.pit != null) mapMC.pit._alpha	= 75; }
			{ if (mapMC?.pit != null) mapMC.pit._yscale	= Math.min(100, 100 * (lid/100) ); }
		}


		// Traversées de portails
		{ var i:Dynamic=0; while (i<mapTravels?.length) {
			var e:Dynamic = mapTravels[i];
			attachMapIcon( e?.eid, e?.lid, e?.misc, null,null );
		
i++; } }

		// Icones
		{ var i:Dynamic=0; while (i<mapEvents?.length) {
			var e:Dynamic = mapEvents[i];
			var list:Dynamic = new Array();

			// Sélection sur le level courant
			{ var j:Dynamic=0; while (j<mapEvents?.length) {
				if ( mapEvents[j]?.lid == e?.lid ) {
					list?.push(mapEvents[j]);
				}
			
j++; } }

			{ var j:Dynamic=0; while (j<list?.length) {
				attachMapIcon(
					list[j]?.eid,
					list[j]?.lid,
					list[j]?.misc,
					j,
					list?.length
				);
			
j++; } }
		
i++; } }

	}


	/*------------------------------------------------------------------------
	EVENT: FIN DE PAUSE
	------------------------------------------------------------------------*/
	public function onUnpause()  untyped {
		if ( !fl_pause ) {
			return;
		}
		fl_pause = false;
		unlock();
		world?.unlock();
		pauseMC?.removeMovieClip();
		mapMC?.removeMovieClip();
		if ( !fl_mute ) {
			setMusicVolume(1);
		}
		{ var i:Dynamic=0; while (i<mapIcons?.length) {
			mapIcons[i]?.removeMovieClip();
		
i++; } }
		mapIcons = new Array();
	}


	/*------------------------------------------------------------------------
	EVENT: RÉSURRECTION
	------------------------------------------------------------------------*/
	public function onResurrect()  untyped {
		registerMapEvent( RootData.EVENT_DEATH, null );
		destroyList(RootData.SUPA);
		resetHurry() ;
		updateDarkness();
		world?.scriptEngine?.onPlayerBirth();
		world?.scriptEngine?.onPlayerDeath();
	}


	/*------------------------------------------------------------------------
	EVENT: EXPLOSION D'UNE BOMBE (event pour les scripts)
	------------------------------------------------------------------------*/
	public function onExplode(x:Dynamic,y:Dynamic,radius:Dynamic)  untyped {
		world?.scriptEngine?.onExplode(x,y,radius);
	}


	/*------------------------------------------------------------------------
	EVENT: FIN DU SET DE LEVELS
	------------------------------------------------------------------------*/
	public function onEndOfSet()  untyped {
		// do nothing
	}


	/*------------------------------------------------------------------------
	GÈRE L'OBSCURITÉ
	------------------------------------------------------------------------*/
	public function updateDarkness()  untyped {


//		if ( forcedDarkness==null ) {
//
//			if ( world.fl_mainWorld && world.currentId<Data.MIN_DARKNESS_LEVEL ) {
//				darknessMC.removeMovieClip();
//				world.darknessFactor = 0;
//				return;
//			}
//			if ( world.fl_mainWorld && world.currentId>101 ) {
//				darknessMC.removeMovieClip();
//				world.darknessFactor = 0;
//				return;
//			}
////			if ( !world.fl_mainWorld ) {
////				darknessMC.removeMovieClip();
////				return;
////			}
//		}

		// Calcul darkness
		if ( forcedDarkness!=null ) {
			targetDark = forcedDarkness;
		}
		else {
			if ( world?.fl_mainWorld ) {
				if ( world?.currentId<RootData.MIN_DARKNESS_LEVEL || world?.currentId>101 ) {
					darknessMC?.removeMovieClip();
					{ if (world != null) world.darknessFactor = 0; }
					dfactor = 0;
					return;
				}
				else {
					targetDark = world?.currentId;
				}
			}
			else {
				targetDark = world?.darknessFactor;
			}
		}



		// Attachement
//		dfactor = (forcedDarkness==null) ? world.currentId*1.0 : forcedDarkness*1.0;
		if ( darknessMC?._name==null ) {
			darknessMC = (cast ( depthMan.attach("hammer_fx_darkness",RootData.DP_BORDERS) ));
			{ if (darknessMC != null) darknessMC._x -= xOffset; }
			{ if (darknessMC != null) darknessMC.blendMode = BlendMode.LAYER; }
			{ if (darknessMC != null) darknessMC.holes = new Array(); }
			darknessMC?.holes?.push( (cast (darknessMC))?.hole1 );
			darknessMC?.holes?.push( (cast (darknessMC))?.hole2 );
			{ var i:Dynamic=0; while (i<2) {
				{ if (darknessMC?.holes[i] != null) darknessMC.holes[i].blendMode = BlendMode.ERASE; }
				{ if (darknessMC?.holes[i] != null) darknessMC.holes[i]._y = -500; }
			
i++; } }
		}

		// Dimensions de base
		{ var i:Dynamic=0; while (i<2) {
			{ if (darknessMC?.holes[i] != null) darknessMC.holes[i]._xscale = 100; }
			{ if (darknessMC?.holes[i] != null) darknessMC.holes[i]._yscale = darknessMC?.holes[i]?._xscale; }
		
i++; } }

		// Spots de lumière supplémentaires
		detachExtraHoles();
		{ var i:Dynamic=0; while (i<extraHoles?.length) {
			var hole:Dynamic = MtStd.attachMC(darknessMC, "hammer_fx_darknessHole", manager.uniq++);
			{ if (hole != null) hole._x = extraHoles[i]?.x; }
			{ if (hole != null) hole._y = extraHoles[i]?.y; }
			{ if (hole != null) hole._width = extraHoles[i]?.d; }
			{ if (hole != null) hole._height = extraHoles[i]?.d; }
			{ if (hole != null) hole.blendMode = BlendMode.ERASE; }
			darknessMC?.holes?.push(hole);
			{ if (extraHoles[i] != null) extraHoles[i].mc = hole; }
		
i++; } }

		// Effets des évolutions des joueurs
		var l:Dynamic = getPlayerList();
		{ var i:Dynamic=0; while (i<l?.length) {
			if ( l[i]?.fl_candle || l[i]?.specialMan?.actives[68] ) { // bougie
				{ if (darknessMC?.holes[i] != null) darknessMC.holes[i]._xscale = 150; }
				{ if (darknessMC?.holes[i] != null) darknessMC.holes[i]._yscale = darknessMC?.holes[i]?._xscale; }
			}
			if ( l[i]?.fl_torch || l[i]?.specialMan?.actives[26] ) { // ampoule
				if ( forcedDarkness==null ) {
					targetDark*=0.5;
				}
				else {
					targetDark*=0.75; // l'obscurité forcée est plus "opaque"
				}
			}
		
i++; } }

		holeUpdate();
	}


	/*------------------------------------------------------------------------
	AJOUTE UN SPOT DE LUMIÈRE
	------------------------------------------------------------------------*/
	public function addHole(x:Dynamic,y:Dynamic,diameter:Dynamic)  untyped {
		extraHoles?.push( {x:x, y:y, d:diameter, mc:null} );
	}


	public function detachExtraHoles()  untyped {
		{ var i:Dynamic=0; while (i<extraHoles?.length) {
			extraHoles[i]?.mc?.removeMovieClip();
		
i++; } }
		darknessMC?.holes?.splice(2,9999);
	}


	public function clearExtraHoles()  untyped {
		detachExtraHoles();
		extraHoles = new Array();
	}


	/*------------------------------------------------------------------------
	MAIN: DARKNESS HALO
	------------------------------------------------------------------------*/
	public function holeUpdate()  untyped {
		if ( darknessMC?._name == null ) {
			return;
		}

		// Placements trous
		var l:Dynamic = getPlayerList();
		{ var i:Dynamic=0; while (i<l?.length) {
			var p:Dynamic = l[i];
			var tx:Dynamic = p?.x + RootData.CASE_WIDTH*0.5;
			var ty:Dynamic = p?.y - RootData.CASE_HEIGHT;
			var hole:Dynamic = darknessMC?.holes[i];
			if ( p?._visible ) {
				{ if (hole != null) hole._visible = true; }
				{ if (hole != null) hole._x += ( tx - hole?._x )*0.5; }
				{ if (hole != null) hole._y += ( ty - hole?._y )*0.5; }
			}
			else {
				{ if (hole != null) hole._visible = false; }
				{ if (hole != null) hole._x = tx; }
				{ if (hole != null) hole._y = ty; }
			}
		
i++; } }

		// Tweening luminosité
		dfactor = Math.round(dfactor);
		targetDark = Math.round(targetDark);
		if ( dfactor==null ) {
			dfactor = 0;
		}
		if ( dfactor<targetDark ) {
			dfactor+=2;
			if ( dfactor>targetDark ) {
				dfactor = targetDark;
			}
		}
		if ( dfactor>targetDark ) {
			dfactor-=2;
			if ( dfactor<targetDark ) {
				dfactor = targetDark;
			}
		}

		{ if (world != null) world.darknessFactor = dfactor; }
		{ if (darknessMC != null) darknessMC._alpha = dfactor; }
	}


	/*------------------------------------------------------------------------
	MAIN
	------------------------------------------------------------------------*/
	override public function main()  untyped {
		// FPS
		if ( GameManager.CONFIG.fl_detail ) {
			if ( Timer.fps()<=16 ) { // lag manager
				lagCpt+=Timer.tmod;
				if ( lagCpt>=RootData.SECOND*30 ) {
					GameManager.CONFIG.setLowDetails();
					GameManager.CONFIG.fl_shaky = false;
				}
			}
			else {
				lagCpt = 0;
			}
		}

		// Chrono
		gameChrono?.update();

		// Pause
		if ( fl_pause ) {
			if ( manager?.fl_debug ) {
				printDebugInfos();
			}
		}

		// Bullet time
		if ( fl_bullet && bulletTimer>0 ) {
			bulletTimer-=Timer.tmod;
			if ( bulletTimer>0 ) {
				Timer.tmod = 0.3;
			}
		}

		// Item name
		if ( itemNameMC?._name!=null ) {
			{ if (itemNameMC != null) itemNameMC._alpha -= (105 - itemNameMC?._alpha)*0.01; }
			if ( itemNameMC?._alpha<=5 ) {
				itemNameMC?.removeMovieClip();
			}
		}

		// Variables
		updateGroundFrictions();
		fl_ice = ( getDynamicVar("$ICE")!=null );
		fl_aqua = ( getDynamicVar("$AQUA")!=null );
//		if ( fl_aqua ) {
//			if ( GameManager.CONFIG.fl_detail && colorHex!=WATER_COLOR ) {
//				setColorHex(20, WATER_COLOR);
//			}
//		}
//		else {
//			resetCol();
//		}

		// Super
		super.main();


		// Level
		world?.update();

		// Interface
		gi?.update();

		// Lock
		if (fl_lock) {
			return;
		}

		if( getBadList()?.length>0 && fl_badsCallback==false) {
			onBadsReady();
			fl_badsCallback = true;
		}

		// Flottement des portails
		{ var i:Dynamic=0; while (i<portalMcList?.length) {
			var p:Dynamic = portalMcList[i];
			if ( p!=null ) {
				{ if (p?.mc != null) p.mc._y = p?.y + 2 * Math.sin(p?.cpt); }
				{ if (p != null) p.cpt+=Timer.tmod*0.1; }
				if ( MtStd.random(5)==0 ) {
					var a:Dynamic = fxMan?.attachFx(
						p?.x + MtStd.random(25)*(MtStd.random(2)*2-1),
						p?.y + MtStd.random(25)*(MtStd.random(2)*2-1),
						"hammer_fx_star"
					);
					{ if (a?.mc != null) a.mc._xscale	= MtStd.random(70)+30; }
					{ if (a?.mc != null) a.mc._yscale	= a?.mc?._xscale; }
				}
			}
		
i++; } }


		duration += Timer.tmod;

		// Timer de fin de mode auto
		if ( endModeTimer>0 ) {
			endModeTimer-=Timer.tmod;
			if ( endModeTimer<=0 ) {
				var pl:Dynamic = getPlayerList();
				{ var i:Dynamic=0; while (i<pl?.length) {
					registerScore(pl[i]?.pid,pl[i]?.score);
				
i++; } }
				onGameOver();
			}
		}

		// FX manager
		fxMan?.main();

		// Hurry up!
		huTimer += Timer.tmod;
		if ( Key.isDown(72) && manager?.fl_debug ) { // H
			huTimer += Timer.tmod*20;
		}
		if ( huState<RootData.HU_STEPS.length && huTimer>=RootData.HU_STEPS[huState]/diffFactor ) {
			onHurryUp();
		}
		// RAZ status hurry up si la fireball a été détruite
		if ( huState>=RootData.HU_STEPS.length ) {
			if ( countList(RootData.HU_BAD)==0 ) {
				callEvilOne( Math.round(huTimer/RootData.AUTO_ANGER) );
			}
		}

		// Mouvement des entités
		var l:Dynamic = getList(RootData.ENTITY);
		{ var i:Dynamic=0; while (i<l?.length) {
			l[i]?.update();
			l[i]?.endUpdate();
		
i++; } }
		holeUpdate();

		cleanKills();
		if ( !world?.fl_lock ) {
			checkLevelClear();
		}

		// Joueurs en téléportation portail
		if ( nextLink!=null ) {
			var pl:Dynamic = getPlayerList();
			{ var i:Dynamic=0; while (i<pl?.length) {
				var p:Dynamic = pl[i];
				{ if (p != null) p._xscale*=0.85; }
				{ if (p != null) p._yscale=Math.abs(p?._xscale); }
				if ( Math.abs(p?._xscale)<=2 ) {
					switchDimensionById( nextLink?.to_did, nextLink?.to_lid, nextLink?.to_pid );
					i = 9999;
					nextLink = null;
				}
			
i++; } }
		}

		// Tremblement
		if ( shakeTimer>0 ) {
			shakeTimer-=Timer.tmod;
			if ( shakeTimer<=0 ) {
				shakeTimer = 0;
				shakePower = 0;
			}
			if ( fl_flipX ) {
				{ if (mc != null) mc._x = RootData.GAME_WIDTH+xOffset - Math.round( (MtStd.random(2)*2-1) * (MtStd.random(Math.round(shakePower*10))/10) * shakeTimer/shakeTotal ); }
			}
			else {
				{ if (mc != null) mc._x = Math.round( xOffset + (MtStd.random(2)*2-1) * (MtStd.random(Math.round(shakePower*10))/10) * shakeTimer/shakeTotal ); }
			}
			if ( fl_flipY ) {
				{ if (mc != null) mc._y = RootData.GAME_HEIGHT + 20 + Math.round( yOffset + (MtStd.random(2)*2-1) * (MtStd.random(Math.round(shakePower*10))/10) * shakeTimer/shakeTotal ); }
			}
			else {
				{ if (mc != null) mc._y = Math.round( yOffset + (MtStd.random(2)*2-1) * (MtStd.random(Math.round(shakePower*10))/10) * shakeTimer/shakeTotal ); }
			}
		}

		if ( fl_aqua ) {
			aquaTimer += 0.03*Timer.tmod;
			if ( !fl_flipY ) {
				{ if (mc != null) mc._y = -7 + 7*Math.cos(aquaTimer); }
				{ if (mc != null) mc._yscale = 102 - 2*Math.cos(aquaTimer); }
			}
		}
		else {
			if ( aquaTimer!=0 ) {
				aquaTimer = 0;
				flipY(fl_flipY);
			}
		}


		// Vent
		if ( windTimer>0 ) {
			windTimer-=Timer.tmod;
			if ( windTimer<=0 ) {
				wind(null,null);
			}
		}

		// Indication de sortie fausse
		if ( countList(RootData.BAD_CLEAR)>0 ) {
			if ( fxMan?.mc_exitArrow?._name!=null ) {
				fxMan?.detachExit();
			}
		}

		// Pas d'indicateur de sortie en tuto
		if ( fxMan?.mc_exitArrow?._name!=null ) {
			if ( manager?.isTutorial() ) {
				fxMan?.detachExit();
			}
		}


		// Enervement minimum
		if ( fl_nightmare ) {
			var bl:Dynamic = getBadList();
			{ var i:Dynamic=0; while (i<bl?.length) {
				var b:Dynamic = bl[i];
				if ( b?.isType(RootData.BAD_CLEAR) && b?.anger==0 ) {
					b?.angerMore();
				}
			
i++; } }
		}

	}

}

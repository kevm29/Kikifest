// Converti automatiquement depuis hammer/GameManager.mt (Motion Twin)
package;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
class GameManager
{
	public static var BASE_VOLUME:Int	= 50;
	public static var CONFIG		= null;
	public static var KEY			= MtStd.random(999999)*MtStd.random(999999);
	public static var HH			= new Hash();

	public static var SELF			= null; // "this" context for fatal static call

	public var fVersion	: Int;
	public var fps			: Float;
	public var uniq		: Int;
	public var fileServ	: FileServer;

	public var current		: Mode;
	public var child		: Mode;

	public var root		: MovieClip;
	public var progressBar	: MovieClip;
	public var csKey		: Int;

	public var depthMan	: DepthManager;
	public var soundMan	: SoundManager;

	public var fl_flash8	: Bool;
	public var fl_cookie	: Bool;
	public var fl_debug	: Bool;
	public var fl_local	: Bool;

//	var fl_tutorial	: bool;
//	var fl_soccer	: bool;
//	var fl_multiCoop: bool;
//	var fl_ta		: bool;
//	var fl_taMulti	: bool;
//	var fl_bossRush	: bool;

	public var cookie		: Cookie;

	public var history		: Array<String>;

	public var musics		: Array<Sound>;


	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new(mc:Dynamic, initObj:Dynamic)  untyped {
		root			= mc;
		uniq			= 666;
		SELF			= this;

		this.fl_local	= initObj?.fl_local;
		musics			= initObj?.musics;
		history			= new Array();

		logAction("$B"+"kikifest");

		Lang.init(initObj?.rawLang);
		Data.init(this);

		// Dev mode
		if ( isDev() ) {
			fl_debug = true;
		}

		if ( isTutorial() || Loader.BASE_SCRIPT_URL==null ) {
			logAction("$using sysfam");
			{ if (initObj != null) initObj.families="0,7,1000,18"; }
			if ( isDev() ) {
				{ if (initObj != null) initObj.families="0,7,1000,1001,1002,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19"; }
			}
		}

		CONFIG = new GameParameters( MtStd.getRoot(), this, initObj?.families, initObj?.options );
		if ( fl_local ) {
			cookie = new Cookie(this);
		}

		Log.setColor(0xcccccc);
		Log.tprint._x = Data.DOC_WIDTH*0.7;
		Log.tprint._y = 4;
		Log.tprint.textColor = 0xffff00;

		depthMan	= new DepthManager(root);
		fl_cookie	= fl_debug && fl_local;

		// Flash 8 features
		var strVersion:Dynamic = ((MtStd.getRoot()):Dynamic)?.__S_version;
		fVersion = MtStd.parseInt( strVersion?.split(" ")[1]?.split(",")[0],10 );
		fl_flash8 = (fVersion!=null && !MtStd.isNaN(fVersion) && fVersion>=8);
		if ( !fl_flash8 ) {
			fatal(Lang.get(15)+"\nhttp://www.macromedia.com/go/getflash");
			return;
		}
		mtflash.Init.init();

		if (  isMode(null) || isMode("") ) {
			fatal("Veuillez vider votre cache internet (voir page Support Technique en bas du site).");
			return;
//			Std.setVar(Std.getRoot(),"$mode", "$solo".substring(1));
		}

		// Sounds channels
		var volume:Dynamic = CONFIG.soundVolume*100;
		soundMan = new SoundManager( depthMan?.empty(Data.DP_SOUNDS), 0 );
		soundMan?.setVolume( Data.CHAN_MUSIC,	CONFIG.musicVolume*100 );
		soundMan?.setVolume( Data.CHAN_PLAYER,	volume );
		soundMan?.setVolume( Data.CHAN_BOMB,		volume );
		soundMan?.setVolume( Data.CHAN_ITEM,		volume );
		soundMan?.setVolume( Data.CHAN_FIELD,	volume );
		soundMan?.setVolume( Data.CHAN_BAD,		Math.max(0,volume-10) );
		soundMan?.setVolume( Data.CHAN_INTERF,	Math.max(0,volume-10) );
		{ var i:Dynamic=0; while (i<musics?.length) {
			musics[i]?.setVolume( CONFIG.musicVolume*100 );
		
i++; } }
		if ( !CONFIG.hasMusic() ) {
			soundMan?.loop("sound_kick", Data.CHAN_MUSIC);
			soundMan?.setVolume( Data.CHAN_MUSIC,	0);
		}

		registerClasses();

		var h:Dynamic = HH;
h?.set("$8d6fff6186db2e4f436852f16dcfbba8","$4768dc07c5f8a02389dd5bc1ab2e8cf4");h?.set("$3bb529b9fb9f62833d42c0c1a7b36a43","$53d55e84334a88faa7699ef49647028d");h?.set("$9fa2a5eb602c6e8df97aeff54eecce7b","$0d3258c27fa25f609757dbec3c4d5b40");h?.set("$041ccec10a38ecef7d4f5d7acb7b7c46","$9004f8d219ddeaf70d806031845b81a8");h?.set("$51cc93b000b284de6097c9319221e891","$b04ce150619f8443c69122877c18abb9");h?.set("$38fe1fbe22565c2f6691f1f666a600d9","$05a8015ab342ed46b92ef29b88d30069");h?.set("$0255841255b29dd91b88a57b4a27f422","$14460ca82946da41bc53c89e6670b8c0");h?.set("$1def3777b79eb80048ebf70a0ae83b77","$8783468478de453e70eeb3b3cb1327cf");h?.set("$a1a9405afb4576a3bceb75995ad17d09","$d4a546d78441aba69dc043b9b23dc068");h?.set("$8c49e07bc65be554538effb12eced2c2","$3c5fee37f81ebe52a1dc76d7bbdd2c07");h?.set("$bfe3df5761159d38a6419760d8613c26","$e701d0c9283358ab44c899db4f13a3fb");

		// Lance le mode correspondant aux données disponibles
		startDefaultGame();

	}



	/*------------------------------------------------------------------------
	REGISTER CLASSES
	------------------------------------------------------------------------*/
	public function registerClasses()  untyped {
		// *** Items
		MtStd.registerClass("hammer_item_score", entity.item.ScoreItem);
		MtStd.registerClass("hammer_item_special", entity.item.SpecialItem);

		// *** Bads
		MtStd.registerClass(Data.LINKAGES[Data.BAD_POMME],	entity.bad.walker.Pomme);
		MtStd.registerClass(Data.LINKAGES[Data.BAD_CERISE],	entity.bad.walker.Cerise);
		MtStd.registerClass(Data.LINKAGES[Data.BAD_BANANE],	entity.bad.walker.Banane);
		MtStd.registerClass(Data.LINKAGES[Data.BAD_ANANAS],	entity.bad.walker.Ananas);
		MtStd.registerClass(Data.LINKAGES[Data.BAD_BOMBE],	entity.bad.walker.Bombe);
		MtStd.registerClass(Data.LINKAGES[Data.BAD_ORANGE],	entity.bad.walker.Orange);
		MtStd.registerClass(Data.LINKAGES[Data.BAD_FRAISE],	entity.bad.walker.Fraise);
		MtStd.registerClass(Data.LINKAGES[Data.BAD_ABRICOT],	entity.bad.walker.Abricot);
		MtStd.registerClass(Data.LINKAGES[Data.BAD_POIRE],	entity.bad.walker.Poire);
		MtStd.registerClass(Data.LINKAGES[Data.BAD_CITRON],	entity.bad.walker.Citron);
		MtStd.registerClass(Data.LINKAGES[Data.BAD_FIREBALL],	entity.bad.FireBall);
		MtStd.registerClass(Data.LINKAGES[Data.BAD_BALEINE],	entity.bad.flyer.Baleine);
		MtStd.registerClass(Data.LINKAGES[Data.BAD_SPEAR],	entity.bad.Spear);
		MtStd.registerClass(Data.LINKAGES[Data.BAD_CRAWLER],	entity.bad.ww.Crawler);
		MtStd.registerClass(Data.LINKAGES[Data.BAD_TZONGRE],	entity.bad.flyer.Tzongre);
		MtStd.registerClass(Data.LINKAGES[Data.BAD_SAW],	entity.bad.ww.Saw);
		MtStd.registerClass(Data.LINKAGES[Data.BAD_KIWI],		entity.bad.walker.Kiwi);
		MtStd.registerClass(Data.LINKAGES[Data.BAD_LITCHI],	entity.bad.walker.Litchi);
		MtStd.registerClass(Data.LINKAGES[Data.BAD_LITCHI_WEAK],	entity.bad.walker.LitchiWeak);
		MtStd.registerClass(Data.LINKAGES[Data.BAD_FRAMBOISE],entity.bad.walker.Framboise);
		MtStd.registerClass("hammer_boss_bat",				entity.boss.Bat);
		MtStd.registerClass("hammer_boss_human",				entity.boss.Tuberculoz);

		// *** Shoots
		MtStd.registerClass("hammer_shoot_pepin", entity.shoot.Pepin);
		MtStd.registerClass("hammer_shoot_fireball", entity.shoot.FireBall);
		MtStd.registerClass("hammer_shoot_arrow", entity.shoot.PlayerArrow);
		MtStd.registerClass("hammer_shoot_ball", entity.shoot.Ball);
		MtStd.registerClass("hammer_shoot_zest", entity.shoot.Zeste);
		MtStd.registerClass("hammer_shoot_player_fireball", entity.shoot.PlayerFireBall);
		MtStd.registerClass("hammer_shoot_player_pearl", entity.shoot.PlayerPearl);
		MtStd.registerClass("hammer_shoot_boss_fireball", entity.shoot.BossFireBall);
		MtStd.registerClass("hammer_shoot_firerain", entity.shoot.FireRain);
		MtStd.registerClass("hammer_shoot_hammer", entity.shoot.Hammer);
		MtStd.registerClass("hammer_shoot_framBall2", entity.shoot.FramBall);

		// *** Bombs
		MtStd.registerClass("hammer_bomb_classic", entity.bomb.player.Classic);
		MtStd.registerClass("hammer_bomb_black", entity.bomb.player.Black);
		MtStd.registerClass("hammer_bomb_blue", entity.bomb.player.Blue);
		MtStd.registerClass("hammer_bomb_green", entity.bomb.player.Green);
		MtStd.registerClass("hammer_bomb_red", entity.bomb.player.Red);
		MtStd.registerClass("hammer_bomb_poire_frozen", entity.bomb.player.PoireBombFrozen);
		MtStd.registerClass("hammer_bomb_mine_frozen", entity.bomb.player.MineFrozen);
		MtStd.registerClass("hammer_bomb_soccer", entity.bomb.player.SoccerBall);
		MtStd.registerClass("hammer_bomb_repel", entity.bomb.player.RepelBomb);

		MtStd.registerClass("hammer_bomb_poire", entity.bomb.bad.PoireBomb);
		MtStd.registerClass("hammer_bomb_mine", entity.bomb.bad.Mine);
		MtStd.registerClass("hammer_bomb_boss", entity.bomb.bad.BossBomb);

		// *** Supas
		MtStd.registerClass("hammer_supa_icemeteor", entity.supa.IceMeteor);
		MtStd.registerClass("hammer_supa_smoke", entity.supa.Smoke);
		MtStd.registerClass("hammer_supa_ball", entity.supa.Ball);
		MtStd.registerClass("hammer_supa_bubble", entity.supa.Bubble);
		MtStd.registerClass("hammer_supa_tons", entity.supa.Tons);
		MtStd.registerClass("hammer_supa_item", entity.supa.SupaItem);
		MtStd.registerClass("hammer_supa_arrow", entity.supa.Arrow);

		// *** Misc
		MtStd.registerClass("hammer_player", entity.Player);
		MtStd.registerClass("hammer_player_wbomb", entity.WalkingBomb);
		MtStd.registerClass("hammer_fx_particle", entity.fx.Particle);

		// *** GUI
		MtStd.registerClass("hammer_editor_button", gui.SimpleButton);
		MtStd.registerClass("hammer_editor_label", gui.Label);
		MtStd.registerClass("hammer_editor_field", gui.Field);
	}



	/*------------------------------------------------------------------------
	RENVOIE TRUE SI UN SET XML DE LEVEL EXISTE
	------------------------------------------------------------------------*/
	public function setExists(n:Dynamic)  untyped {
		var data:Dynamic = MtStd.getVar(root, n);
		return (data!=null);
	}




	/*------------------------------------------------------------------------
	AFFICHE UNE BARRE DE PROGRESSION
	------------------------------------------------------------------------*/
	public function progress(ratio:Dynamic)  untyped {
		// remove
		if ( ratio==null || ratio>=1 ) {
			progressBar?.removeMovieClip();
			progressBar = null;
			return;
		}
		// attach
		if ( progressBar==null ) {
			progressBar = depthMan?.attach("lifeBar",Data.DP_INTERF);
			{ if (progressBar != null) progressBar._x = Data.GAME_WIDTH/2; }
			{ if (progressBar != null) progressBar._y = Data.GAME_HEIGHT-40; }
		}

		{ if (((progressBar):Dynamic)?.bar != null) ((progressBar):Dynamic).bar._xscale = ratio*100; }
	}


	/*------------------------------------------------------------------------
	ERREUR CRITIQUE
	------------------------------------------------------------------------*/
	public static function fatal(msg:String)  untyped {
		Log.setColor(0xff0000);
		Log.trace("*** CRITICAL ERROR *** "+msg);
		SELF.current.destroy();
		SELF.root.stop();
		SELF.root.removeMovieClip();
	}


	/*------------------------------------------------------------------------
	AVERTISSEMENT
	------------------------------------------------------------------------*/
	public static function warning(msg:String)  untyped {
		Log.trace("* WARNING * "+msg);
	}


	/*------------------------------------------------------------------------
	REDIRECTION HTTP
	------------------------------------------------------------------------*/
	public function redirect(url:Dynamic,params:String)  untyped {
		current?.lock();
		MtStd.getGlobal("exitGame")(url,params);
	}


	/*------------------------------------------------------------------------
	SIGNALE UNE OPÉRATION ILLÉGALE
	------------------------------------------------------------------------*/
	public function logIllegal(str:Dynamic)  untyped {
		logAction("$!"+str);
	}

	/*------------------------------------------------------------------------
	LOG DE PARTIE
	------------------------------------------------------------------------*/
	public function logAction(str:Dynamic)  untyped {
		str = Tools.replace(str,"$","");
		str = Tools.replace(str,":",".");
		history?.push(str);
	}




	// *** MODES

	/*------------------------------------------------------------------------
	LANCE UN MODE
	------------------------------------------------------------------------*/
	public function transition(prev:Mode,next:Mode)  untyped {
		next?.init();


		if ( prev==null ) {
			current = next;
		}
		else {
			// skips transition animation
			prev?.destroy();
			current = next;
//			var m = new mode.ModeSwitcher(this);
//			m.initSwitcher(prev,next);
//			current = upcast(m);
		}
	}


	/*------------------------------------------------------------------------
	LANCE UN MODE "ENFANT"
	------------------------------------------------------------------------*/
	public function startChild(c:Mode)  untyped {
		if ( child!=null ) {
			fatal("another child process is running!");
		}
		if ( current?.fl_lock ) {
			fatal("process is locked, can't create a child");
		}
		current?.lock();
		current?.onSleep();
		current?.hide();
		child = c;
		{ if (child != null) child.fl_runAsChild = true; }
		child?.init();
		return child;
	}

	/*------------------------------------------------------------------------
	INTERROMPT LE PROCESS ENFANT (AVEC RETOUR OPTIONNEL)
	------------------------------------------------------------------------*/
	public function stopChild(data:Dynamic)  //'
	 untyped {
		var n:Dynamic = child?._name;
		child?.destroy();
		child = null;
		current?.unlock();
		current?.show();
		current?.onWakeUp(n, data);
	}


	/*------------------------------------------------------------------------
	LANCE UN MODE
	------------------------------------------------------------------------*/
	public function startMode( m:Mode )  untyped {
		transition(current,m);
	}

	/*------------------------------------------------------------------------
	LANCE UN MODE DE JEU
	------------------------------------------------------------------------*/
	public function startGameMode(m:mode.GameMode)  untyped {
		transition(current,m);
	}


	/*------------------------------------------------------------------------
	MODES DE JEU
	------------------------------------------------------------------------*/
	public function isAdventure()  untyped {
		return isMode("$solo");
	}

	public function isTutorial()  untyped {
		return isMode("$tutorial");
	}

	public function isSoccer()  untyped {
		return isMode("$soccer");
	}

	public function isMultiCoop()  untyped {
		return isMode("$multicoop");
	}

	public function isTimeAttack()  untyped {
		return isMode("$timeattack");
	}

	public function isMultiTime()  untyped {
		return isMode("$multitime");
	}

	public function isBossRush()  untyped {
		return isMode("$bossrush");
	}

	public function isDev()  untyped {
		return setExists("xml_dev") && !isFjv();
	}

	public function isFjv()  untyped {
		return false; // hack anti fjv
		return setExists("xml_fjv");
	}


	public function isMode(modeName:Dynamic)  untyped {
		return MtStd.getVar(MtStd.getRoot(),"$mode") == (modeName == null ? null : modeName.substring(1));
	}



	/*------------------------------------------------------------------------
	LANCE LE MODE DE JEU PAR DÉFAUT, SELON LES SETS DISPONIBLES
	------------------------------------------------------------------------*/
	public function startDefaultGame()  untyped {
		if ( isTutorial() ) {
			startGameMode( new mode.Tutorial(this) );
			return;
		}
		if ( isSoccer() ) {
			startMode( new mode.Soccer(this,0) );
			return;
		}
		if ( isMultiCoop() ) {
			startGameMode( new mode.MultiCoop(this,0) );
			return;
		}
		if ( isTimeAttack() ) {
			startGameMode( new mode.TimeAttack(this,0) );
			return;
		}
		if ( isMultiTime() ) {
			startGameMode( new mode.TimeAttackMulti(this,0) );
			return;
		}
		if ( isBossRush() ) {
			startGameMode( new mode.BossRush(this,0) );
			return;
		}
		if ( isFjv() ) {
			startMode( new mode.FjvEnd(this,false) );
			return;
		}
		if ( isAdventure() ) {
			startGameMode( new mode.Adventure(this,0) );
//			startGameMode( new mode.Tutorial(this) );
//			startGameMode( new mode.Fjv(this,0) );
//			startGameMode( new mode.MultiCoop(this,0) );
//			startGameMode( new mode.BossRush(this, 0) );
//			startGameMode( new mode.TimeAttack(this,0) );
//			startMode( new mode.Test(this) );
//			startMode( new mode.SoccerSelector(this) );
			return;
		}

		fatal("Invalid mode '"+MtStd.getVar(MtStd.getRoot(),"$mode")+"' found.");
	}



	// *** MAIN

	/*------------------------------------------------------------------------
	MAIN
	------------------------------------------------------------------------*/
	public function main()  untyped {
		// Timer
		Timer.update();
		fps = Timer.fps();
		Timer.tmod = Math.min(2.8,Timer.tmod);
		MtStd.setGlobal("tmod",Timer.tmod);
		MtStd.setGlobal("Debug",Log);

		// Sons
		soundMan?.main();

		// Modes
		current?.main();
		if ( child!=null ) {
			child?.main();
		}

	}
}

// Converti automatiquement depuis hammer/mode/Tutorial.mt (Motion Twin)
package mode;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
import Data as RootData;
class Tutorial extends mode.GameMode {


	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new(m:Dynamic)  untyped {
		super(m);
		_name = "$tutorial";
	}


	/*------------------------------------------------------------------------
	INITIALISATION
	------------------------------------------------------------------------*/
	override public function init()  untyped {
		super.init();

		initGame();
		initInterface();
	}


	/*------------------------------------------------------------------------
	INITIALISATION DU JEU
	------------------------------------------------------------------------*/
	override public function initGame()  untyped {
		super.initGame();
		world?.goto(0);

		var p:Dynamic = insertPlayer(world?.current?.__S_playerX, world?.current?.__S_playerY);
		{ if (p != null) p.lives = 99999; }
	}

	/*------------------------------------------------------------------------
	INITIALISATION INTERFACE
	------------------------------------------------------------------------*/
	override public function initInterface()  untyped {
		super.initInterface();
		gi?.lightMode();
	}


	/*------------------------------------------------------------------------
	INIT DU MONDE
	------------------------------------------------------------------------*/
	override public function initWorld()  untyped {
		super.initWorld();
		world = new levels.GameMechanics(manager,"xml_tutorial") ;
		world?.setDepthMan(depthMan);
		world?.setGame(this);
		{ if (world != null) world.fl_shadow = false; }
		if(world?.setName!="xml_tutorial") { GameManager.fatal("world.setName!=xml_tutorial");return; }
	}



	/*------------------------------------------------------------------------
	FIN DU MODE
	------------------------------------------------------------------------*/
	override public function endMode()  untyped {
		stopMusic();
		manager?.startGameMode(  new mode.Shareware(manager,0)  );
	}

	/*------------------------------------------------------------------------
	EVENT: GAME OVER (APPUI SUR "ECHAP")
	------------------------------------------------------------------------*/
	override public function onGameOver()  untyped {
		if(world?.setName!="xml_tutorial") { GameManager.fatal("");return; }
		fl_gameOver = true;
		lock();
		var url:Dynamic = MtStd.getVar( MtStd.getRoot(), "$out" );
		manager?.redirect(url,null);
	}


	/*------------------------------------------------------------------------
	EVENT: PAUSE
	------------------------------------------------------------------------*/
	override public function onPause()  untyped {
		super.onPause();
		{ if (pauseMC?.sector != null) pauseMC.sector.text = Lang.get(14)+" �"+Lang.get(16)+"�"; }
	}


	/*------------------------------------------------------------------------
	FONCTIONS D�SACTIV�ES
	------------------------------------------------------------------------*/
	override public function onHurryUp()  untyped { return null; }
	public function darknessManager()  untyped {}


	/*------------------------------------------------------------------------
	EVENT: LEVEL PR�T
	------------------------------------------------------------------------*/
	override public function onLevelReady()  untyped {
		super.onLevelReady();
		if ( world?.currentId==0 ) {
			fxMan?.attachLevelPop( Lang.get(16), false );
		}
	}


	/*------------------------------------------------------------------------
	EVENT: FIN DU SET DE LEVELS
	------------------------------------------------------------------------*/
	override public function onEndOfSet()  untyped {
		super.onEndOfSet();
		manager?.startGameMode( new mode.Shareware(manager,0) );
	}

}
// Converti automatiquement depuis hammer/mode/Shareware.mt (Motion Twin)
package mode;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
import Data as RootData;
class Shareware extends mode.Adventure {


	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new(m:Dynamic,id:Dynamic)  untyped {
		super(m,id);
		_name = "$shareware";
	}


	/*------------------------------------------------------------------------
	INITIALISATION DU MONDE
	------------------------------------------------------------------------*/
	override public function initWorld()  untyped {
//		super.initWorld();

		world = new levels.GameMechanics(manager,"xml_shareware");
		world?.setDepthMan(depthMan);
		world?.setGame(this);
	}

	/*------------------------------------------------------------------------
	INITIALISATION D'UNE PARTIE
	------------------------------------------------------------------------*/
	override public function initGame()  untyped {
		super.initGame();
		var p : entity.Player = (( getOne(RootData.PLAYER) ):Dynamic);
		{ if (p != null) p.lives = 2; }
		gi?.setLives(p?.pid, p?.lives);
	}

	/*------------------------------------------------------------------------
	RETOUR AU SITE
	------------------------------------------------------------------------*/
	override public function endMode()  untyped {
		lock();
		var url:Dynamic = MtStd.getVar( MtStd.getRoot(), "$out" );
		manager?.redirect(url,null);
	}


	/*------------------------------------------------------------------------
	EVENT: FIN DU SET
	------------------------------------------------------------------------*/
	override public function onEndOfSet()  untyped {
		endMode();
	}

	/*------------------------------------------------------------------------
	EVENT: GAME OVER
	------------------------------------------------------------------------*/
	override public function onGameOver()  untyped {
		endMode();
	}

	/*------------------------------------------------------------------------
	EVENT: LEVEL PRÊT
	------------------------------------------------------------------------*/
	override public function onLevelReady()  untyped {
		super.onLevelReady();
		if ( world?.currentId==0 ) {
			fxMan?.attachLevelPop( Lang.get(17), true );
		}
	}

	/*------------------------------------------------------------------------
	EVENT: PAUSE
	------------------------------------------------------------------------*/
	override public function onPause()  untyped {
		super.onPause();
		{ if (pauseMC?.sector != null) pauseMC.sector.text = Lang.get(14)+" «"+Lang.get(17)+"»"; }
	}

	/*------------------------------------------------------------------------
	FONCTIONS DÉSACTIVÉES
	------------------------------------------------------------------------*/
	public function darknessManager()  untyped {}
}

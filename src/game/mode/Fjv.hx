// Converti automatiquement depuis hammer/mode/Fjv.mt (Motion Twin)
package mode;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
import Data as RootData;
class Fjv extends mode.Adventure {

	public var fCookie			: SharedObject;
	public var scr				: Dynamic;
	public var bg				: MovieClip;


	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new(m:Dynamic,id:Dynamic)  untyped {
		super(m,id);
		fCookie = SharedObject.getLocal("$fjv_data");
		_name = "$fjv_special";
	}


	/*------------------------------------------------------------------------
	INITIALISATION DU MONDE
	------------------------------------------------------------------------*/
	override public function initWorld()  untyped {
//		super.initWorld();

		world = new levels.GameMechanics(manager,"xml_fjv");
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
		MtStd.setVar( ((fCookie?.data):Dynamic), "score", getPlayerList()[0]?.score );
		stopMusic();
		manager?.startMode( new mode.FjvEnd(manager,false) );
	}


	/*------------------------------------------------------------------------
	EVENT: FINAL PORTAL
	------------------------------------------------------------------------*/
	override public function usePortal(pid:Dynamic,e:Dynamic)  untyped {
		stopMusic();
		MtStd.setVar( ((fCookie?.data):Dynamic), "score", getPlayerList()[0]?.score );
		manager?.startMode( new mode.FjvEnd(manager,true) );
		return true;
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
		else {
			fxMan?.levelName?.removeMovieClip();
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

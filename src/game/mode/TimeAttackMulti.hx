// Converti automatiquement depuis hammer/mode/TimeAttackMulti.mt (Motion Twin)
package mode;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
import Data as RootData;
class TimeAttackMulti extends mode.TimeAttack
{

	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new(m:Dynamic,id:Dynamic)  untyped {
		super(m,id) ;
		_name = "$timeMulti";
	}


	/*------------------------------------------------------------------------
	RÉCUPÈRE L'ID DE COURSE
	------------------------------------------------------------------------*/
	override public function initRunId()  untyped {
		if ( GameManager.CONFIG.hasOption(RootData.OPT_SET_MTA_0) ) {	runId = 0;	}
		if ( GameManager.CONFIG.hasOption(RootData.OPT_SET_MTA_1) ) {	runId = 1;	}
		if ( GameManager.CONFIG.hasOption(RootData.OPT_SET_MTA_2) ) {	runId = 2;	}
	}


	/*------------------------------------------------------------------------
	INITIALISATION DU MONDE
	------------------------------------------------------------------------*/
	override public function initWorld()  untyped {
		addWorld("xml_multitime");
	}


	/*------------------------------------------------------------------------
	INITIALISATION PARTIE
	------------------------------------------------------------------------*/
	override public function initGame()  untyped {
		super.initGame();

		destroyList(RootData.PLAYER);
		cleanKills();

		var px:Dynamic = world?.current?.__S_playerX;
		var py:Dynamic = world?.current?.__S_playerY;

		var p1:Dynamic = insertPlayer(px,py);
		p1?.ctrl?.setKeys(Key.UP, Key.DOWN, Key.LEFT, Key.RIGHT, Key.ENTER) ;

		var p2:Dynamic = insertPlayer(RootData.LEVEL_WIDTH*0.5+(RootData.LEVEL_WIDTH*0.5-px),py);
		p2?.ctrl?.setKeys(90/*Z*/, 83/*S*/, 81/*A*/, 68/*D*/, 65/*A*/) ;


		initializePlayers();
	}


	/*------------------------------------------------------------------------
	INITIALISATION JOUEUR
	------------------------------------------------------------------------*/
	override public function initPlayer(p:Dynamic)  untyped {
		super.initPlayer(p);

		{ if (p != null) p.baseColor = RootData.BASE_COLORS[p?.pid]; }
		if ( p?.pid==1 ) {
			{ if (p != null) p.skin = 2; }
			{ if (p != null) p.defaultHead = RootData.HEAD_SANDY; }
			{ if (p != null) p.head = p?.defaultHead; }
		}
	}
}

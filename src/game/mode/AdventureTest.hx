// Converti automatiquement depuis hammer/mode/AdventureTest.mt (Motion Twin)
package mode;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
import Data as RootData;
class AdventureTest extends mode.Adventure {
	public var testData : levels.Data;



	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new(m:Dynamic, l: levels.Data)  untyped {
		super(m,1);

		testData	= l;
		_name		= "$advTest";
	}


	/*------------------------------------------------------------------------
	DÉBUT DE NIVEAU
	------------------------------------------------------------------------*/
	override public function startLevel()  untyped {
		super.startLevel();
		var l:Dynamic = getPlayerList() ;
		{ var i:Dynamic=0; while (i<l?.length) {
			l[i]?.moveToCase( world?.current?.__S_playerX, world?.current?.__S_playerY );
		
i++; } }


	}


	/*------------------------------------------------------------------------
	INITIALISATION MONDE
	------------------------------------------------------------------------*/
	override public function initWorld()  untyped {
		super.initWorld();
		{ if (world != null) world.raw[1] = world?.serializeExternal(testData); }
	}

	/*------------------------------------------------------------------------
	CHANGER DE NIVEAU MET FIN AU MODE
	------------------------------------------------------------------------*/
	override public function nextLevel()  untyped {
		endMode();
	}

	/*------------------------------------------------------------------------
	FIN DU MODE DE JEU
	------------------------------------------------------------------------*/
	override public function endMode()  untyped {
		stopMusic();
		world?.destroy();
		manager?.stopChild(null);
	}


	/*------------------------------------------------------------------------
	EVENT: FIN DE SET
	------------------------------------------------------------------------*/
	override public function onEndOfSet()  untyped {
		endMode();
	}

	/*------------------------------------------------------------------------
	EVENT: MORT
	------------------------------------------------------------------------*/
	override public function onGameOver()  untyped {
		endMode();
	}


	/*------------------------------------------------------------------------
	MAIN LOOP
	------------------------------------------------------------------------*/
	override public function main()  untyped {
		Log.print( Math.round(Timer.fps())+"fps") ;
		super.main();
	}
}


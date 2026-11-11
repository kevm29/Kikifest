// Converti automatiquement depuis hammer/mode/BossRush.mt (Motion Twin)
package mode;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
import Data as RootData;
class BossRush extends mode.Adventure
{
	public var chrono			: Chrono;
	public var levelAvg		: Float;
	public var levelCount		: Int;
	public var levelTimer		: Int;
	public var lastLevelTimer	: Int;



	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new(m:Dynamic,id:Dynamic)  untyped {
		super(m,id);
		_name			= "$bossRush";
		fl_disguise		= false;
		fl_map			= true;
		fl_mirror		= false;
		fl_nightmare	= false;

		levelTimer		= 0;
		levelAvg		= 0;
		lastLevelTimer	= null;

		chrono		= new Chrono();
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
	INITIALISATION DU JOUEUR
	------------------------------------------------------------------------*/
	override public function initPlayer(p:Dynamic)  untyped {
		super.initPlayer(p);
		upgradePlayer(p);
	}

	public function upgradePlayer(p:Dynamic)  untyped {
		{ if (p != null) p.speedFactor = 1.5; }
		{ if (p != null) p.maxBombs = 2; }
		{ if (p?.ctrl != null) p.ctrl.fl_upKick = true; }
	}


	/*------------------------------------------------------------------------
	EVENT: PAUSE
	------------------------------------------------------------------------*/
	override public function onPause()  untyped {
		super.onPause();
		pauseMC?.gotoAndStop("4");
		{ if (pauseMC?.title != null) pauseMC.title.text	= Lang.get(36); }
		((pauseMC):Dynamic).timeLabel.text = Lang.get(37);
		((pauseMC):Dynamic).time.text = chrono?.getStrShort();
		((pauseMC):Dynamic).timeAvgLabel.text = Lang.get(38);
		if ( levelAvg>0 ) {
			((pauseMC):Dynamic).timeAvg.text = chrono?.formatTimeShort( Math.round(levelAvg) );
		}
		else {
			((pauseMC):Dynamic).timeAvg.text = "--";
		}
	}


	/*------------------------------------------------------------------------
	EVENT: RÉSURRECTION
	------------------------------------------------------------------------*/
	override public function onResurrect()  untyped {
		super.onResurrect();
		var pl:Dynamic = getPlayerList();
		{ var i:Dynamic=0; while (i<pl?.length) {
			upgradePlayer(pl[i]);
		
i++; } }
	}


	/*------------------------------------------------------------------------
	LANCE UN NIVEAU DONNÉ
	------------------------------------------------------------------------*/
	override public function goto(id:Dynamic)  untyped {
		if ( ((id-1)%10)==0 && id>1 ) {
			registerMapEvent( RootData.EVENT_TIME, chrono?.getStrShort() );
		}

		registerLevelTime();

		super.goto(id);
	}


	/*------------------------------------------------------------------------
	CHANGE DE DIMENSION
	------------------------------------------------------------------------*/
	override public function switchDimensionById( did:Dynamic, lid:Dynamic, pid:Dynamic )  untyped {
		registerLevelTime();
		super.switchDimensionById(did,lid,pid);
	}


	/*------------------------------------------------------------------------
	STOCKE LE TEMPS DU LEVEL
	------------------------------------------------------------------------*/
	public function registerLevelTime()  untyped {
		lastLevelTimer = chrono?.get()-levelTimer;
		if ( levelAvg==0 ) {
			levelAvg = lastLevelTimer;
		}
		levelAvg = 0.5 * (levelAvg+lastLevelTimer);
	}


	/*------------------------------------------------------------------------
	DÉMARRE LE NIVEAU
	------------------------------------------------------------------------*/
	override public function startLevel()  untyped {
		super.startLevel();
		if ( !chrono?.fl_init ) {
			chrono?.reset();
		}
		else {
			displayTime( lastLevelTimer );
			lastLevelTimer = null;
		}
		levelTimer = chrono?.get();
		levelCount++;
	}


	/*------------------------------------------------------------------------
	AFFICHE LE TEMPS EN COURS
	------------------------------------------------------------------------*/
	public function displayTime(t:Dynamic)  untyped {
		var mc:Dynamic = fxMan?.attachFx( 5, RootData.DOC_HEIGHT-45, "hammer_interf_time" )?.mc;
//		var mc : {>MovieClip, sub:{field:TextField}};
//		mc = downcast( depthMan.attach("hammer_interf_time", Data.DP_INTERF) );
//		mc._x = 5;
//		mc._y = Data.DOC_HEIGHT - 45;
		((mc):Dynamic).sub.field.text = Lang.get(39)+" +"+chrono?.formatTimeShort(t);
		FxManager.addGlow(mc,RootData.DARK_COLORS[0],2);
	}



	/*------------------------------------------------------------------------
	BOUCLE MAIN
	------------------------------------------------------------------------*/
	override public function main()  untyped {
		chrono?.update();

		if ( manager?.isDev() ) {
//			Log.print( chrono.getStr() );
		}

		super.main();
	}

}
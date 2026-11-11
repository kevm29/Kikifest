// Converti automatiquement depuis hammer/mode/TimeAttack.mt (Motion Twin)
package mode;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
import Data as RootData;
class TimeAttack extends mode.Adventure
{
	public static var INFINITY	= 59*60*1000 + 59*1000 + 999;


	public var gameTimer		: Int;
	public var suspendTimer	: Int;
	public var last			: Int;
	public var fl_chronoStop	: Bool;
	public var times			: Array<Int>;
	public var fl_alerts		: Array<Bool>;

	public var starter			: Float;
	public var mcStarter		: Dynamic;

	public var frameTimer		: Int; // currentframe time
	public var prevFrameTimer	: Int;

	public var runId			: Int;



	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new(m:Dynamic,id:Dynamic)  untyped {
		super(m,id) ;

		runId = null;
		initRunId();
		if ( runId==null ) {
			GameManager.fatal("unknown run ID");
			return;
		}
		firstLevel = runId*9;

		_name			= "$time" ;
		suspendTimer	= null;
		times			= new Array();
		frameTimer		= MtStd.getTimer();
		fl_alerts		= new Array();
		fl_static		= true;
		fl_bullet		= false;
		fl_mirror		= false;
		fl_nightmare	= false;
	}


	/*------------------------------------------------------------------------
	RÉCUPÈRE L'ID DE COURSE
	------------------------------------------------------------------------*/
	public function initRunId()  untyped {
		if ( GameManager.CONFIG.hasOption(RootData.OPT_SET_TA_0) ) {	runId = 0;	}
		if ( GameManager.CONFIG.hasOption(RootData.OPT_SET_TA_1) ) {	runId = 1;	}
		if ( GameManager.CONFIG.hasOption(RootData.OPT_SET_TA_2) ) {	runId = 2;	}
	}


	/*------------------------------------------------------------------------
	INITIALISATION DU MONDE
	------------------------------------------------------------------------*/
	override public function initWorld()  untyped {
		addWorld("xml_time");
	}


	/*------------------------------------------------------------------------
	INITIALISATION PARTIE
	------------------------------------------------------------------------*/
	override public function initGame()  untyped {
		super.initGame();

		initializePlayers();
		resetChrono();
	}


	/*------------------------------------------------------------------------
	PRÉPARE LES JOUEURS AU MODE MULTI
	------------------------------------------------------------------------*/
	public function initializePlayers()  untyped {
		var l:Dynamic = getPlayerList();
		{ var i:Dynamic=0; while (i<l?.length) {
			var p:Dynamic = l[i];
			{ if (p != null) p.getScore = null; }
			{ if (p != null) p.getScoreHidden = null; }
			{ if (p != null) p.lives = 3; }
			gi?.setLives(p?.pid, p?.lives);
		
i++; } }
	}


	/*------------------------------------------------------------------------
	OBJET À POINTS RAMASSÉ
	------------------------------------------------------------------------*/
	override public function pickUpScore(id:Dynamic,sid:Dynamic)  untyped {
		var ret:Dynamic = super.pickUpScore(id,sid);
		if ( id==0 ) {

			var bonus:Dynamic = RootData.getCrystalTime(sid);
			timeShift(bonus);

			var l:Dynamic = getPlayerList();
			{ var i:Dynamic=0; while (i<l?.length) {
				var p:Dynamic = l[i];
				fxMan?.attachScorePop( p?.baseColor, p?.darkColor, p?.x, p?.y, "-"+bonus+" sec" );
			
i++; } }

		}

		return ret;
	}


	/*------------------------------------------------------------------------
	FONCTIONS DÉSACTIVÉES
	------------------------------------------------------------------------*/
	override public function addLevelItems()  untyped {}


	/*------------------------------------------------------------------------
	LANCE UN NIVEAU
	------------------------------------------------------------------------*/
	override public function goto(id:Dynamic)  untyped {
		if ( world?.isEmptyLevel(id,this) ) {
			onEndOfSet();
			return;
		}
		stopChrono();
		var t:Dynamic = Math.floor( prevFrameTimer-gameTimer );
		var lt:Dynamic = t;
		{ var i:Dynamic=0; while (i<times?.length) {
			lt-=times[i];
		
i++; } }
		times?.push(lt);
		display(formatTime(t));

		super.goto(id);
	}


	/*------------------------------------------------------------------------
	ENREGISTRE LE TEMPS
	------------------------------------------------------------------------*/
	override public function saveScore()  untyped {
		var t:Dynamic = 0;
		{ var i:Dynamic=0; while (i<times?.length) {
			t+=times[i];
		
i++; } }
		MtStd.getGlobal("gameOver") (
			t,
			runId,
			{
				__S_reachedLevel	: 0,
				__S_item2			: null,
				__S_data			: null,
			}
		);
	}


	/*------------------------------------------------------------------------
	EVENT: FIN DE PARTIE
	------------------------------------------------------------------------*/
	override public function onEndOfSet()  untyped {
		saveScore();
	}


	/*------------------------------------------------------------------------
	EVENT: MORT
	------------------------------------------------------------------------*/
	override public function onGameOver()  untyped {
		times = [ 3599999 ];
		saveScore();
	}


	/*------------------------------------------------------------------------
	EVENT: FIN DE LEVEL
	------------------------------------------------------------------------*/
	override public function onLevelClear()  untyped {
		perfectOrder = null;  // pas de supa item
		super.onLevelClear();
	}


	/*------------------------------------------------------------------------
	EVENT: DEBUT DE LEVEL
	------------------------------------------------------------------------*/
	override public function onLevelReady()  untyped {
		super.onLevelReady();

		fxMan?.levelName?.removeMovieClip();

		// Indicateur de temps du level précédent
		if ( world?.currentId!=firstLevel ) {
			displayLastTime();
		}


		if ( world?.currentId==firstLevel ) {
			lock();
			display( formatTime(0) );
			starter = RootData.SECOND*3.5;
			mcStarter = (( depthMan.attach("hammer_interf_starter",RootData.DP_INTERF) ):Dynamic);
			{ if (mcStarter != null) mcStarter._x = RootData.DOC_WIDTH*0.5; }
			{ if (mcStarter != null) mcStarter._y = RootData.DOC_HEIGHT*0.5; }
			{ if (mcStarter?.field != null) mcStarter.field.text = ""; }
			resetChrono();
		}

	}


	/*------------------------------------------------------------------------
	EVENT: RÉSURRECTION
	------------------------------------------------------------------------*/
	override public function onResurrect()  untyped {
		super.onResurrect();
//		var l = getPlayerList();
//		for (var i=0;i<l.length;i++) {
//			l[i].speedFactor = 1.5;
//		}
	}


	/*------------------------------------------------------------------------
	RENVOIE LA VALEUR DU CHRONO ACTUEL (millisecondes)
	------------------------------------------------------------------------*/
	public function getChrono()  untyped {
		return Math.floor( frameTimer-gameTimer );
	}


	/*------------------------------------------------------------------------
	MET À JOUR LE(s) CHRONO(s) DE L'INTERFACE
	------------------------------------------------------------------------*/
	public function display(str:Dynamic)  untyped {
		var l:Dynamic = getPlayerList();
		{ var i:Dynamic=0; while (i<l?.length) {
			var p:Dynamic = l[i];
			gi?.print( 0,str );
			gi?.print( 1,str );
		
i++; } }
	}


	/*------------------------------------------------------------------------
	AFFICHE LE TEMPS DU NIVEAU PRÉCÉDENT
	------------------------------------------------------------------------*/
	public function displayLastTime()  untyped {
		var t:Dynamic = times[times?.length-1];
		if ( t!=null ) {
			var mc : Dynamic;
			mc = (( depthMan.attach("hammer_interf_time", RootData.DP_INTERF) ):Dynamic);
			{ if (mc != null) mc._x = 20; }
			{ if (mc != null) mc._y = RootData.DOC_HEIGHT - 50; }
			{ if (mc?.sub?.field != null) mc.sub.field.text = "+ " + formatTime(t); }
			FxManager.addGlow(mc,RootData.DARK_COLORS[0],2);
	    }
	}


	/*------------------------------------------------------------------------
	RENVOIE LE CHRONO FORMATTÉ
	------------------------------------------------------------------------*/
	public function formatTime(t:Dynamic)  untyped {
		var d:Dynamic = new js.lib.Date();
		d?.setTime( t );
		return
			RootData.leadingZeros( d?.getMinutes()+(d?.getHours()-1)*60, 2 ) +"\" "+
			RootData.leadingZeros( d?.getSeconds(), 2 ) +"' "+
			RootData.leadingZeros( d?.getMilliseconds(),3 );
	}



	/*------------------------------------------------------------------------
	GESTION DU CHRONO
	------------------------------------------------------------------------*/
	public function resetChrono()  untyped {
		last			= getChrono();
		fl_chronoStop	= false;
		suspendTimer	= null;
		gameTimer		= frameTimer;
	}

	public function startChrono()  untyped {
		if ( suspendTimer!=null ) {
			var d:Dynamic = frameTimer-suspendTimer;
			gameTimer+=d;
		}
		fl_chronoStop = false;
		suspendTimer = null;
	}

	public function stopChrono()  untyped {
		if ( fl_chronoStop ) {
			return;
		}
		fl_chronoStop = true;
		suspendTimer = frameTimer;
	}


	/*------------------------------------------------------------------------
	ARRÊTS / REPRISES
	------------------------------------------------------------------------*/
	override public function lock()  untyped {
		super.lock();
		stopChrono();
	}


	override public function unlock()  untyped {
		super.unlock();
		startChrono();
	}

	override public function switchDimensionById(id:Dynamic,lid:Dynamic,pid:Dynamic)  untyped {
		stopChrono();
		super.switchDimensionById(id,lid,pid);
	}



	/*------------------------------------------------------------------------
	GAIN DE TEMPS
	------------------------------------------------------------------------*/
	public function timeShift(n:Dynamic)  untyped {
		gameTimer = Std.int( Math.min( frameTimer, gameTimer+n*1000 ) );
	}


	/*------------------------------------------------------------------------
	BOUCLE MAIN
	------------------------------------------------------------------------*/
	override public function main()  untyped {

		// Pas de hurryup
		huTimer = 0;


		// Timer de départ
		if ( starter>0 ) {
			var old:Dynamic = Math.ceil(starter/32);
			starter-=Timer.tmod;
			var now:Dynamic = Math.ceil(starter/32);
			{ if (mcStarter != null) mcStarter._xscale	*= 0.99; }
			{ if (mcStarter != null) mcStarter._yscale	= mcStarter?._xscale; }
			{ if (mcStarter != null) mcStarter._alpha	*= 0.95; }
			if ( old!=now ) {
				{ if (mcStarter?.field != null) mcStarter.field.text = "" + now; }
				{ if (mcStarter != null) mcStarter._alpha	= 100; }
				{ if (mcStarter != null) mcStarter._xscale	= 70 + 120-now*40; }
				{ if (mcStarter != null) mcStarter._yscale	= mcStarter?._xscale; }
			}
			if ( starter<=0 ) {
				mcStarter?.removeMovieClip();
				fxMan?.attachAlert(Lang.get(20));
				unlock();
				resetChrono();
			}
		}

		prevFrameTimer = frameTimer;
		frameTimer = MtStd.getTimer();
		super.main();


		if ( !fl_chronoStop ) {
			// warning minutes
			if ( Math.floor(getChrono()/60000) != Math.floor(last/60000) ) {
				var m:Dynamic = Math.floor(getChrono()/60000);
				if ( m>0 && fl_alerts[m]!=true ) {
					var mc:Dynamic;
					fl_alerts[m] = true;
					if ( m>1 ) {
						mc = fxMan?.attachAlert( m + " " + Lang.get(19) );
					}
					else {
						mc = fxMan?.attachAlert( m + " " + Lang.get(18) ); // sans s
					}
					{ if (mc != null) mc._y += 40; }
				}
			}
			last = getChrono();

			// update d'interface
			if ( !fl_lock && starter<=0 ) {
				display( formatTime(getChrono()) );
			}
		}
	}


}

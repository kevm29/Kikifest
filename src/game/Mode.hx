// Converti automatiquement depuis hammer/Mode.mt (Motion Twin)
package;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
class Mode
{

	public var root			: MovieClip ;
	public var mc				: MovieClip ;

	public var xFriction		: Float ;
	public var yFriction		: Float ;

	public var manager			: GameManager ;
	public var depthMan		: DepthManager ;
	public var soundMan		: SoundManager;

	public var fl_music		: Bool;
	public var currentTrack	: Int;
	public var fl_mute			: Bool;

	public var fl_lock			: Bool;
	public var fl_switch		: Bool;
	public var fl_hide			: Bool;
	public var fl_runAsChild	: Bool;

	public var cycle			: Float ;
	public var uniqId			: Int ;

	public var xOffset			: Float ; // décalage du mc du jeu
	public var yOffset			: Float ;

	public var _name			: String ;


	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new(m:Dynamic)  untyped {
		manager = m ;
		root = manager?.root ;
		mc = MtStd.createEmptyMC(root,manager.uniq++) ;
		depthMan = new DepthManager(mc) ;
		soundMan = manager?.soundMan;

		lock() ;

		fl_switch		= false;
		fl_music		= false;
		fl_mute			= false;
		fl_runAsChild	=false;
		currentTrack	= null;
		xOffset			= 0 ;
		yOffset			= 0 ;
		uniqId			= 1 ;
		cycle			= 0 ;

		_name = "$abstractMode" ;
		show();
	}


	/*------------------------------------------------------------------------
	AFFICHE / MASQUE LE MC ROOT DU MODE
	------------------------------------------------------------------------*/
	public function show()  untyped {
		{ if (mc != null) mc._visible = true; }
		fl_hide = false;
	}

	public function hide()  untyped {
		{ if (mc != null) mc._visible = false; }
		fl_hide = true;
	}


	/*------------------------------------------------------------------------
	INITIALISATION
	------------------------------------------------------------------------*/
	public function init()  untyped {
		{ if (mc != null) mc._x = xOffset ; }
		{ if (mc != null) mc._y = yOffset ; }
	}


	/*------------------------------------------------------------------------
	RENVOIE UN ID UNIQUE INCRÉMENTAL
	------------------------------------------------------------------------*/
	public function getUniqId() : Int  untyped {
		return uniqId++ ;
	}


	/*------------------------------------------------------------------------
	VERROUILLE / DÉVERROUILLE LE MODE
	------------------------------------------------------------------------*/
	public function lock()  untyped {
		fl_lock = true ;
	}
	public function unlock()  untyped {
		fl_lock = false ;
	}


	/*------------------------------------------------------------------------
	RENVOIE LE NOM DU MODE
	------------------------------------------------------------------------*/
	public function short()  untyped {
		return _name ;
	}


	/*------------------------------------------------------------------------
	DESTRUCTEUR
	------------------------------------------------------------------------*/
	public function destroy()  untyped {
		depthMan?.destroy() ;
		lock() ;
	}


	/*------------------------------------------------------------------------
	update des valeurs constantes diverses
	------------------------------------------------------------------------*/
	public function updateConstants()  untyped {
		if (xFriction == null) {
			xFriction = Math.pow(Data.FRICTION_X, Timer.tmod);
			yFriction = Math.pow(Data.FRICTION_Y, Timer.tmod);
		}
		if (fl_lock) {
			return ;
		}

		// Variables
		xFriction = Math.pow(Data.FRICTION_X, Timer.tmod) ; // x
		yFriction = Math.pow(Data.FRICTION_Y, Timer.tmod) ; // y
		cycle += Timer.tmod ;
	}


	/*------------------------------------------------------------------------
	SAISIE DES CONTROLES DE DEBUG
	------------------------------------------------------------------------*/
	public function getDebugControls()  untyped {
		// Clear debug
		if ( Key.isDown(Key.BACKSPACE) ) {
			Log.clear() ;
		}
	}

	public function getControls()  untyped {
		// do nothing yet
	}


	/*------------------------------------------------------------------------
	EVENT: LE MODE EST MIS EN ATTENTE PAR LE MANAGER (MODE ENFANT LANCÉ)
	------------------------------------------------------------------------*/
	public function onSleep()  untyped {
		// do nothing
	}

	public function onWakeUp(modeName:String, data:Dynamic) //'
	 untyped {
		// do nothing
	}

	/*------------------------------------------------------------------------
	MUSICS MANAGEMENT
	------------------------------------------------------------------------*/
	public function playMusic(id:Dynamic)  untyped {
		if ( !GameManager.CONFIG.hasMusic() ) {
			return;
		}
		playMusicAt(id,0);
	}

	public function playMusicAt(id:Dynamic,pos:Dynamic)  untyped {
		if ( !GameManager.CONFIG.hasMusic() ) {
			return;
		}
		if ( fl_music ) {
			stopMusic();
		}
		currentTrack = id;
		manager?.musics[currentTrack]?.start(pos/1000,99999);
		fl_music = true;
		if ( fl_mute ) {
			setMusicVolume(0);
		}
		else {
			setMusicVolume(1);
		}
	}

	public function stopMusic()  untyped {
		if ( !GameManager.CONFIG.hasMusic() ) {
			return;
		}

		manager?.musics[currentTrack]?.stop();
		fl_music = false;
	}

	public function setMusicVolume(n:Dynamic)  untyped {
		if ( !fl_music || !GameManager.CONFIG.hasMusic() ) {
			return;
		}
		n *= GameManager.CONFIG.musicVolume*100;
		manager?.musics[currentTrack]?.setVolume( Math.round(n) );

	}


	/*------------------------------------------------------------------------
	FIN DU MODE DE JEU
	------------------------------------------------------------------------*/
	public function endMode()  untyped {
		stopMusic();
	}


	/*------------------------------------------------------------------------
	MAIN
	------------------------------------------------------------------------*/
	public function main()  untyped {
		// Debug
		if ( manager?.fl_debug ) {
			getDebugControls() ;
		}
		getControls();

		updateConstants() ;
	}

}

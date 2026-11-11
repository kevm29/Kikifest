// Converti automatiquement depuis hammer/Chrono.mt (Motion Twin)
package;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
class Chrono {

	public var gameTimer		: Int;
	public var suspendTimer	: Int;
	public var haltedTimer		: Int;
	public var fl_stop			: Bool;
	public var fl_init			: Bool;

	public var frameTimer		: Int; // currentframe time
	public var prevFrameTimer	: Int;


	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new()  untyped {
		suspendTimer	= null;
		frameTimer		= MtStd.getTimer();
		gameTimer		= frameTimer;
		haltedTimer		= get();

		reset();
		fl_stop			= true;
		fl_init			= false;
	}


	/*------------------------------------------------------------------------
	RENVOIE UN TEMPS FORMATTÉ
	------------------------------------------------------------------------*/
	public function formatTime(t:Dynamic)  untyped {
		var d:Dynamic = new js.lib.Date();
		d?.setTime( t );
		return
			Data.leadingZeros( d?.getMinutes()+(d?.getHours()-1)*60, 2 ) +"\" "+
			Data.leadingZeros( d?.getSeconds(), 2 ) +"' "+
			Data.leadingZeros( d?.getMilliseconds(),3 );
	}

	public function formatTimeShort(t:Dynamic)  untyped {
		var d:Dynamic = new js.lib.Date();
		d?.setTime( t );
		var arrond:Dynamic = 0;
		if ( d?.getMilliseconds()>=500 ) {
			arrond = 1;
		}
		return
			Data.leadingZeros( d?.getMinutes()+(d?.getHours()-1)*60, 2 ) +"\" "+
			Data.leadingZeros( d?.getSeconds()+arrond, 2 );
	}


	/*------------------------------------------------------------------------
	RENVOIE LA VALEUR DU CHRONO ACTUEL (millisecondes)
	------------------------------------------------------------------------*/
	public function get()  untyped {
		if ( fl_stop ) {
			return haltedTimer;
		}
		else {
			return Math.floor( frameTimer-gameTimer );
		}
	}


	/*------------------------------------------------------------------------
	RENVOIE LA VALEUR FORMATTÉE
	------------------------------------------------------------------------*/
	public function getStr()  untyped {
		return formatTime( get() );
	}

	public function getStrShort()  untyped {
		return formatTimeShort( get() );
	}



	/*------------------------------------------------------------------------
	GESTION DU CHRONO
	------------------------------------------------------------------------*/
	public function reset()  untyped {
		fl_init			= true;
		fl_stop			= false;
		suspendTimer	= null;
		gameTimer		= frameTimer;
	}

	public function start()  untyped {
		if ( suspendTimer!=null ) {
			var d:Dynamic = frameTimer-suspendTimer;
			gameTimer+=d;
		}
		haltedTimer = null;
		fl_stop = false;
		suspendTimer = null;
	}

	public function stop()  untyped {
		if ( fl_stop ) {
			return;
		}
		haltedTimer = get();
		fl_stop = true;
		suspendTimer = frameTimer;
	}



	/*------------------------------------------------------------------------
	GAIN DE TEMPS
	------------------------------------------------------------------------*/
	public function timeShift(n:Dynamic)  untyped {
		gameTimer = Std.int( Math.min( frameTimer, gameTimer+n*1000 ) );
	}



	/*------------------------------------------------------------------------
	MAIN
	------------------------------------------------------------------------*/
	public function update()  untyped {
		prevFrameTimer = frameTimer;
		frameTimer = MtStd.getTimer();
	}

}
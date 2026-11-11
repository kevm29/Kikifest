// Converti automatiquement depuis hammer/Animation.mt (Motion Twin)
package;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
class Animation
{
	public var game			: mode.GameMode ;
	public var mc				: MovieClip ;
	public var fl_kill			: Bool ;
	public var fl_loop			: Bool ;
	public var fl_loopDone		: Bool ;
	public var fl_blink		: Bool;

	public var frame			: Float;
	public var lifeTimer		: Float ;
	public var blinkTimer		: Float;


	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new(g:mode.GameMode)  untyped {
		game		= g ;
		frame		= 0 ;
		lifeTimer	= 0 ;
		blinkTimer	= 0;
		fl_kill		= false ;
		fl_loop		= false ;
		fl_loopDone	= false ;
		fl_blink	= false;
	}


	/*------------------------------------------------------------------------
	ATTACHEMENT
	------------------------------------------------------------------------*/
	public function attach(x:Dynamic,y:Dynamic, link:Dynamic, depth:Dynamic)  untyped {
		mc = game?.depthMan?.attach(link,depth) ;
		{ if (mc != null) mc._x = x ; }
		{ if (mc != null) mc._y = y ; }
	}


	/*------------------------------------------------------------------------
	INITIALISATION
	------------------------------------------------------------------------*/
	public function init(g:mode.GameMode)  untyped {
		game = g ;
	}


	/*------------------------------------------------------------------------
	DESTRUCTION
	------------------------------------------------------------------------*/
	public function destroy()  untyped {
		mc?.removeMovieClip() ;
		fl_kill = true ;
	}


	/*------------------------------------------------------------------------
	CLIGNOTTEMENT
	------------------------------------------------------------------------*/
	public function blink()  untyped {
		fl_blink = true;
	}
	public function stopBlink()  untyped {
		fl_blink = false;
		{ if (mc != null) mc._alpha = 100; }
	}


	/*------------------------------------------------------------------------
	RENVOIE LES INFOS DE CET OBJET
	------------------------------------------------------------------------*/
	public function short()  untyped {
		return mc?._name+" @"+mc?._x+","+mc?._y;
	}


	/*------------------------------------------------------------------------
	MAIN
	------------------------------------------------------------------------*/
	public function update()  untyped {
		if ( fl_loopDone ) {
			lifeTimer -= Timer.tmod ;
			if ( lifeTimer<=0 ) {
				destroy() ;
			}
		}

		if ( fl_blink ) {
			blinkTimer-=Timer.tmod;
			if ( blinkTimer<=0 ) {
				{ if (mc != null) mc._alpha	= (mc?._alpha==100)?30:100; }
				blinkTimer	= Data.BLINK_DURATION_FAST;
			}
		}

		frame += Timer.tmod ;
		while (frame>=1) {
			mc?.nextFrame() ;
			if ( mc?._currentframe == mc?._totalframes ) {
				if (fl_loop) {
					mc?.gotoAndStop("1") ;
				}
				fl_loopDone = true ;
			}
			frame-- ;
		}
	}
}



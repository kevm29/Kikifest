// Converti automatiquement depuis hammer/mode/ModeSwitcher.mt (Motion Twin)
package mode;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
import Data as RootData;
class ModeSwitcher extends Mode
{
	public var prev : Mode;
	public var next : Mode;

	public var prevMask : MovieClip;
	public var nextMask : MovieClip;

	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new(m:Dynamic)  untyped {
		super(m);
		_name = "$switcher";
	}


	/*------------------------------------------------------------------------
	ATTACH: MASQUE DE TRANSITION
	------------------------------------------------------------------------*/
	public function attachMask(link:Dynamic,mode:Mode)  untyped {
		var mask:Dynamic = mode.depthMan.attach(link,RootData.DP_INTERF);
		{ if (mask != null) mask._x -= mode.xOffset; }
		mode.mc.setMask(mask);
		return mask;
	}


	/*------------------------------------------------------------------------
	INITIALISATION
	------------------------------------------------------------------------*/
	public function initSwitcher(p:Mode,n:Mode)  untyped {
		prev = p;
		next = n;
		{ if (next != null) next.fl_switch = true; }
		{ if (prev != null) prev.fl_switch = true; }
		prevMask = attachMask("modeMaskOut",prev);
		nextMask = attachMask("modeMaskIn",next);
	}


	/*------------------------------------------------------------------------
	DESTRUCTION
	------------------------------------------------------------------------*/
	override public function destroy()  untyped {
		prev?.mc?.setMask(null);
		prevMask?.removeMovieClip();
		next?.mc?.setMask(null);
		nextMask?.removeMovieClip();

		prev?.destroy();
		{ if (next != null) next.fl_switch = false; }
		{ if (manager != null) manager.current = next; }

		super.destroy();
	}


	/*------------------------------------------------------------------------
	MAIN
	------------------------------------------------------------------------*/
	override public function main()  untyped {
		super.main();

		prev?.main();
		next?.main();

		// Fin
		if ( prevMask?._currentframe==prevMask?._totalframes ) {
			destroy();
		}
	}
}


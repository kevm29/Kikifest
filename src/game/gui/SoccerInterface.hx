// Converti automatiquement depuis hammer/gui/SoccerInterface.mt (Motion Twin)
package gui;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
import Data as RootData;
class SoccerInterface
{
	public static var GLOW_COLOR	= gui.GameInterface.GLOW_COLOR;

	public var mc				: MovieClip;

	public var game			: mode.GameMode;
	public var scores			: Array<TextField>;
	public var time			: TextField;


	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new(game:Dynamic)  untyped {
		this.game	= game;
		init();
	}


	/*------------------------------------------------------------------------
	INITIALISATION
	------------------------------------------------------------------------*/
	public function init()  untyped {
		mc		= game?.depthMan?.attach("hammer_interf_game",RootData.DP_TOP);
		{ if (mc != null) mc._x	= -game?.xOffset; }
		{ if (mc != null) mc._y	= RootData.DOC_HEIGHT; }
		mc?.gotoAndStop("3");
		{ if (mc != null) mc.cacheAsBitmap = true; }

		scores		= [ ((mc):Dynamic)?.score0, ((mc):Dynamic)?.score1 ];
		time		= ((mc):Dynamic)?.time;

		FxManager.addGlow( ((scores[0]):Dynamic), GLOW_COLOR, 2);
		FxManager.addGlow( ((scores[1]):Dynamic), GLOW_COLOR, 2);
		FxManager.addGlow( ((time):Dynamic), GLOW_COLOR, 2);

		setScore(0, 0);
		setScore(1, 0);
	}


	/*------------------------------------------------------------------------
	MET À JOUR UN SCORE
	------------------------------------------------------------------------*/
	public function setScore(pid:Dynamic,n:Dynamic)  untyped {
		{ if (scores[pid] != null) scores[pid].text = ""+n; }
	}


	/*------------------------------------------------------------------------
	MET À JOUR LE TEMPS
	------------------------------------------------------------------------*/
	public function setTime(str:String)  untyped {
		{ if (time != null) time.text = str; }
	}


	/*------------------------------------------------------------------------
	DESTRUCTION
	------------------------------------------------------------------------*/
	public function destroy()  untyped {
		mc?.removeMovieClip();
	}


	/*------------------------------------------------------------------------
	MAIN
	------------------------------------------------------------------------*/
	public function update()  untyped {
	}

}

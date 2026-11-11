// Converti automatiquement depuis hammer/entity/supa/Smoke.mt (Motion Twin)
package entity.supa;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
import Data as RootData;
class Smoke extends entity.Supa
{

	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new()  untyped {
		super();
		fl_blink = false;
	}


	/*------------------------------------------------------------------------
	INIT
	------------------------------------------------------------------------*/
	override public function initSupa(g:Dynamic,x:Dynamic,y:Dynamic)  untyped {
		super.initSupa(g,x,y);
		scale(265);
		setLifeTimer(RootData.SECOND*3);
	}


	/*------------------------------------------------------------------------
	ATTACH
	------------------------------------------------------------------------*/
	public static function attach(g:mode.GameMode)  untyped {
		var linkage:Dynamic = "hammer_supa_smoke";
		var mc : entity.supa.Smoke = (( g.depthMan.attach(linkage,RootData.DP_SUPA) ):Dynamic);
		mc?.initSupa(g, RootData.GAME_WIDTH/2,RootData.GAME_HEIGHT/2 );
		return mc;
	}

}


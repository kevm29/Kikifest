// Converti automatiquement depuis hammer/entity/bad/flyer/Baleine.mt (Motion Twin)
package entity.bad.flyer;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
import Data as RootData;
class Baleine extends entity.bad.Flyer
{

	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new()  untyped {
		super() ;
	}


	/*------------------------------------------------------------------------
	ATTACHEMENT
	------------------------------------------------------------------------*/
	public static function attach(g:mode.GameMode,x:Dynamic,y:Dynamic)  untyped {
		var linkage:Dynamic = RootData.LINKAGES[RootData.BAD_BALEINE];
		var mc : entity.bad.flyer.Baleine = (( g.depthMan.attach(linkage,RootData.DP_BADS) ):Dynamic) ;
		mc?.initBad(g,x,y) ;
		return mc ;
	}
}


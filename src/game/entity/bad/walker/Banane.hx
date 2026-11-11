// Converti automatiquement depuis hammer/entity/bad/walker/Banane.mt (Motion Twin)
package entity.bad.walker;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
import Data as RootData;
class Banane extends entity.bad.Jumper
{

	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new()  untyped {
		super() ;
		setJumpUp(5) ;
		setJumpDown(5) ;
		setJumpH(100) ;
		setClimb(100,RootData.IA_CLIMB);
		setFall(5) ;
	}


	/*------------------------------------------------------------------------
	INITIALISATION
	------------------------------------------------------------------------*/
	override public function init(g:Dynamic)  untyped {
		super.init(g) ;
	}


	/*------------------------------------------------------------------------
	ATTACHEMENT
	------------------------------------------------------------------------*/
	public static function attach(g:mode.GameMode,x:Dynamic,y:Dynamic)  untyped {
		var linkage:Dynamic = RootData.LINKAGES[RootData.BAD_BANANE];
		var mc : entity.bad.walker.Banane = (( g.depthMan.attach(linkage,RootData.DP_BADS) ):Dynamic) ;
		mc?.initBad(g,x,y) ;
		return mc ;
	}


}


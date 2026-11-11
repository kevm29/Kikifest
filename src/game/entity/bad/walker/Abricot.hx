// Converti automatiquement depuis hammer/entity/bad/walker/Abricot.mt (Motion Twin)
package entity.bad.walker;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
import Data as RootData;
class Abricot extends entity.bad.Jumper
{

	public var fl_spawner : Bool ;

	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new()  untyped {
		super() ;
		animFactor = 0.65 ;
		setJumpUp(5) ;
		setJumpH(100) ;
		setClimb(100,3);
		setFall(20) ;
	}


	/*------------------------------------------------------------------------
	INITIALISATION
	------------------------------------------------------------------------*/
	override public function init(g:Dynamic)  untyped {
		super.init(g) ;
		if ( !fl_spawner ) {
			scale(75) ;
		}
		dir = -1 ;
	}


	/*------------------------------------------------------------------------
	ATTACHEMENT
	------------------------------------------------------------------------*/
	public static function attach(g:mode.GameMode,x:Dynamic,y:Dynamic, spawner:Dynamic)  untyped {
		var linkage:Dynamic = RootData.LINKAGES[RootData.BAD_ABRICOT];
		var mc : entity.bad.walker.Abricot = (( g.depthMan.attach(linkage,RootData.DP_BADS) ):Dynamic) ;
		{ if (mc != null) mc.fl_spawner = spawner ; }
		mc?.initBad(g,x,y) ;
		return mc ;
	}


	/*------------------------------------------------------------------------
	EVENT: LIGNE DU BAS
	------------------------------------------------------------------------*/
	override public function onDeathLine()  untyped {
		if ( fl_spawner ) {
			game?.attachBad( RootData.BAD_ABRICOT2, x-RootData.CASE_WIDTH,-30);
			game?.attachBad( RootData.BAD_ABRICOT2, x+RootData.CASE_WIDTH,-30);
//			entity.bad.walker.Abricot.attach( game, x-Data.CASE_WIDTH,-30, false ) ;
//			entity.bad.walker.Abricot.attach( game, x+Data.CASE_WIDTH,-30, false ) ;
		}
		super.onDeathLine() ;
	}

}


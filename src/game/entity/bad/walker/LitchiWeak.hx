// Converti automatiquement depuis hammer/entity/bad/walker/LitchiWeak.mt (Motion Twin)
package entity.bad.walker;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
import Data as RootData;
class LitchiWeak extends entity.bad.Jumper {

	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new()  untyped {
		super() ;
		setJumpH(100) ;
		setJumpUp(10);
		setJumpDown(6);
		setClimb(25,3);
		setFall(25);
	}


	/*------------------------------------------------------------------------
	EVENT: FIN D'ANIM
	------------------------------------------------------------------------*/
	override public function onEndAnim(id:Dynamic)  untyped {
		super.onEndAnim(id);
		if ( id==RootData.ANIM_BAD_SHOOT_START.id ) {
			playAnim(RootData.ANIM_BAD_WALK);
			walk();
		}
	}

	/*------------------------------------------------------------------------
	MARCHER
	------------------------------------------------------------------------*/
	override public function walk()  untyped {
		if ( animId!=RootData.ANIM_BAD_SHOOT_START.id ) {
			super.walk();
		}
	}


	/*------------------------------------------------------------------------
	ATTACHEMENT
	------------------------------------------------------------------------*/
	public static function attach(g:mode.GameMode,x:Dynamic,y:Dynamic)  untyped {
		var linkage:Dynamic = RootData.LINKAGES[RootData.BAD_LITCHI_WEAK];
		var mc : entity.bad.walker.LitchiWeak = (( g.depthMan.attach(linkage,RootData.DP_BADS) ):Dynamic) ;
		mc?.initBad(g,x,y) ;
		return mc ;
	}


}


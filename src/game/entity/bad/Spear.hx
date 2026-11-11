// Converti automatiquement depuis hammer/entity/bad/Spear.mt (Motion Twin)
package entity.bad;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
import Data as RootData;
class Spear extends entity.Bad
{
	public var skin			: Int;


	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new()  untyped {
		super();
		disablePhysics();
		disableAnimator();
		skin = 2;
		realRadius = RootData.CASE_WIDTH * 0.7;
	}


	/*------------------------------------------------------------------------
	INITIALISATION
	------------------------------------------------------------------------*/
	override public function init(g:Dynamic)  untyped {
		super.init(g);
		unregister( RootData.BAD_CLEAR );
		register( RootData.SPEAR );
	}


	/*------------------------------------------------------------------------
	INITIALISATION BADS
	------------------------------------------------------------------------*/
	override public function initBad(g:Dynamic,x:Dynamic,y:Dynamic)  untyped {
		super.initBad(g,x,y);
		if ( world?.getCase( {x:cx,y:cy+1} )>0 ) {
			this.gotoAndStop("1");
		}
		else {
			if ( world?.getCase( {x:cx,y:cy-1} )>0 ) {
				this.gotoAndStop("3");
			}
			else {
				if ( world?.getCase( {x:cx-1,y:cy} )>0 ) {
					this.gotoAndStop("2");
				}
				else {
					if ( world?.getCase( {x:cx+1,y:cy} )>0 ) {
						this.gotoAndStop("4");
					}
				}
			}
		}

		var ss:Dynamic = game?.getDynamicVar("$SPEAR_SKIN");
		if ( ss==null ) {
			sub?.gotoAndStop("1");
		}
		else {
			sub?.gotoAndStop( ss );
		}

		if ( game?.world?.scriptEngine?.cycle>RootData.SECOND ) {
			game?.fxMan?.attachFx(x+RootData.CASE_WIDTH*0.5,y+RootData.CASE_HEIGHT*0.5, "hammer_fx_pop");
		}
	}

	override public function freeze(d:Dynamic)  untyped {}
	override public function knock(d:Dynamic)  untyped {}
	override public function killHit(dx:Dynamic)  untyped {}

	override public function burn()  untyped {
		var fx:Dynamic = game?.fxMan?.attachFx( x,y, "hammer_fx_pop" );
	}


	/*------------------------------------------------------------------------
	TOUCHE UNE ENTITÉ
	------------------------------------------------------------------------*/
	override public function hit(e:Dynamic)  untyped {
		super.hit(e);
		if ( (e?.types & RootData.BAD_CLEAR)>0 ) {
			var b : entity.Bad = ((e):Dynamic);
			if ( b?.fl_physics && b?.fl_trap ) {
				b?.killHit(null);
			}
		}
	}


	/*------------------------------------------------------------------------
	ATTACHEMENT
	------------------------------------------------------------------------*/
	public static function attach(g:mode.GameMode,x:Dynamic,y:Dynamic)  untyped {
		var linkage:Dynamic = RootData.LINKAGES[RootData.BAD_SPEAR];
		var mc : entity.bad.Spear = (( g.depthMan.attach(linkage,RootData.DP_SPEAR) ):Dynamic);
		mc?.initBad(g,x,y);
		return mc;
	}

}


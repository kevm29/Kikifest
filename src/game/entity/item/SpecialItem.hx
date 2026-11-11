// Converti automatiquement depuis hammer/entity/item/SpecialItem.mt (Motion Twin)
package entity.item;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
import Data as RootData;
class SpecialItem extends entity.Item
{

	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new()  untyped {
		super() ;
	}

	/*------------------------------------------------------------------------
	INITIALISATION
	------------------------------------------------------------------------*/
	override public function init(g:Dynamic)  untyped {
		super.init(g) ;
		register(RootData.SPECIAL_ITEM) ;
	}


	/*------------------------------------------------------------------------
	ATTACHEMENT
	------------------------------------------------------------------------*/
	public static function attach(g:mode.GameMode,x:Dynamic,y:Dynamic, id:Dynamic, subId:Dynamic)  untyped {
		if ( g?.fl_clear && id==0 ) { // pas d'extend si level clear
			return null;
		}
		var mc : entity.item.ScoreItem = (( g?.depthMan?.attach("hammer_item_special",RootData.DP_ITEMS) ):Dynamic);
		mc?.initItem(g,x,y,id,subId) ;
		return mc;
	}


	/*------------------------------------------------------------------------
	ACTIVE L'ITEM AU PROFIT DE "P"
	------------------------------------------------------------------------*/
	override public function execute(p:entity.Player)  untyped {
		if ( id>0 ) {
			game?.manager?.logAction("$S"+id);
		}
		game?.pickUpSpecial(id);
		p?.specialMan?.execute(this) ;
		game?.soundMan?.playSound("sound_item_special", RootData.CHAN_ITEM);

		if ( id>0 ) {
			game?.attachItemName( RootData.SPECIAL_ITEM_FAMILIES, id );
		}
		super.execute(p) ;
	}


	/*------------------------------------------------------------------------
	MAIN
	------------------------------------------------------------------------*/
	override public function update()  untyped {
		super.update();
		if ( id!=0 ) {
			if ( MtStd.random(4)==0 ) {
				var a:Dynamic = game?.fxMan?.attachFx(
					x + MtStd.random(15)*(MtStd.random(2)*2-1),
					y - MtStd.random(10),
					"hammer_fx_star"
				);
				{ if (a?.mc != null) a.mc._xscale	= MtStd.random(70)+30; }
				{ if (a?.mc != null) a.mc._yscale	= a?.mc?._xscale; }
			}
		}
	}

}


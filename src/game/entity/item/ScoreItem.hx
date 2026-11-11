// Converti automatiquement depuis hammer/entity/item/ScoreItem.mt (Motion Twin)
package entity.item;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
import Data as RootData;
class ScoreItem extends entity.Item
{

	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new()  untyped {
		super();
	}

	/*------------------------------------------------------------------------
	INITIALISATION
	------------------------------------------------------------------------*/
	override public function init(g:Dynamic)  untyped {
		super.init(g);
	}

	override public function initItem(g:Dynamic,x:Dynamic,y:Dynamic,i:Dynamic,si:Dynamic)  untyped {
		super.initItem(g,x,y,i,si);
		if ( id==RootData.CONVERT_DIAMANT ) {
			register(RootData.PERFECT_ITEM);
		}
	}


	/*------------------------------------------------------------------------
	ATTACHEMENT
	------------------------------------------------------------------------*/
	public static function attach(g:mode.GameMode,x:Dynamic,y:Dynamic, id:Dynamic, subId:Dynamic)  untyped {
		var mc : entity.item.ScoreItem = (( g.depthMan.attach("hammer_item_score",RootData.DP_ITEMS) ):Dynamic);
		if ( id>=1000 ) {
			id -= 1000;
		}
		mc?.initItem(g,x,y,id,subId);
		return mc;
	}


	/*------------------------------------------------------------------------
	ACTIVE L'ITEM AU PROFIT DE "E"
	------------------------------------------------------------------------*/
	override public function execute(p:entity.Player)  untyped {
		var value : Int = RootData.ITEM_VALUES[id+1000];

		game?.soundMan?.playSound("sound_item_score", RootData.CHAN_ITEM);

		if ( value==0 || value==null ) {

			{ var __sw:Dynamic = id;
if (__sw == (0)) { // Cristaux
					value = RootData.getCrystalValue(subId);
				
				}
else if (__sw == (RootData.DIAMANT)) { // Diamant par défaut
					value = 2000;
				
				}
else if (__sw == (RootData.CONVERT_DIAMANT)) { // Diamant de conversion de niveau
					value = Math.round(  Math.min( 10000, 75*Math.pow(subId+1,4) )  );
				
				}
else {
					GameManager.fatal("null value");
				
			}
}
		}

		p?.getScore(this,value);
		game?.pickUpScore(id,subId);

		// Recherche rarity
		var r:Dynamic		= null;
		var i:Dynamic		= 0;
		var family:Dynamic	= RootData.SCORE_ITEM_FAMILIES;
		while (r==null && i<family?.length) {
			var j:Dynamic=0;
			while (r==null && (j:Float) < (family[i]?.length:Float)) {
				if ( MtStd.ix(family[i], j)?.id == id+1000 ) {
					r = MtStd.ix(family[i], j)?.r;
				}
				j++;
			}
			i++;
		}

		if ( r>0 ) {
			game?.attachItemName( RootData.SCORE_ITEM_FAMILIES, id+1000 );
		}

		super.execute(p);
	}

}


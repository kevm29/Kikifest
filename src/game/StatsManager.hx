// Converti automatiquement depuis hammer/StatsManager.mt (Motion Twin)
package;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
class StatsManager
{

	public var game : mode.GameMode;
	public var stats : Array<Stat>;
	public var extendList : Array<Int>;


	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new(g:mode.GameMode)  untyped {
		game = g;
		stats = new Array();
		{ var i:Dynamic=0; while (i<50) {
			stats[i] = new Stat();
		
i++; } }
	}


	/*------------------------------------------------------------------------
	LECTURE
	------------------------------------------------------------------------*/
	public function read(id:Dynamic)  untyped {
		return stats[id]?.current;
	}
	public function getTotal(id:Dynamic)  untyped {
		return stats[id]?.total;
	}

	/*------------------------------------------------------------------------
	ÉCRITURE
	------------------------------------------------------------------------*/
	public function write(id:Dynamic,n:Dynamic)  untyped {
		{ if (stats[id] != null) stats[id].current = n; }
	}
	public function inc(id:Dynamic,n:Dynamic)  untyped {
		stats[id]?.inc(n);
	}


	/*------------------------------------------------------------------------
	REMISE À 0 DES CURRENTS
	------------------------------------------------------------------------*/
	public function reset()  untyped {
		{ var i:Dynamic=0; while (i<stats?.length) {
			stats[i]?.reset();
		
i++; } }
	}


	/*------------------------------------------------------------------------
	DISTRIBUTION DES EXTENDS POUR LE NIVEAU EN COURS
	------------------------------------------------------------------------*/
	public function countExtend()  untyped {
		var nb:Dynamic = 1;
//		if ( read(Data.STAT_SUPAITEM)>=1 ) {
//			nb++;
//		}
		if ( read(Data.STAT_MAX_COMBO)>=2 ) {
			nb += read(Data.STAT_MAX_COMBO)-1;
		}
		return Math.min(7,nb);
	}


	/*------------------------------------------------------------------------
	CALCULE LES EXTENDS POUR LE NIVEAU EN COURS
	------------------------------------------------------------------------*/
	public function spreadExtend()  untyped {
		var nb:Dynamic = countExtend();

		if ( nb>0 ) {
			game?.world?.scriptEngine?.insertExtend();

			extendList = new Array();
			var l:Dynamic = new Array();

			{ var i:Dynamic=0; while (i<nb) {
				var id:Dynamic;
				do {
					id = game?.randMan?.draw(Data.RAND_EXTENDS_ID);
				}
				while (l[id]==true);
				l[id]=true;
				extendList?.push(id);
			
i++; } }
		}
	}


	/*------------------------------------------------------------------------
	ATTACH: LETTRE D'EXTEND
	------------------------------------------------------------------------*/
	public function attachExtend() : entity.item.SpecialItem  untyped {
		if ( game?.fl_clear ) {
			return null;
		}
		var pt:Dynamic = game?.world?.getGround( MtStd.random(Data.LEVEL_WIDTH), MtStd.random(Data.LEVEL_HEIGHT) );
		var x:Dynamic = Entity.x_ctr(pt?.x);
		var y:Dynamic = Entity.y_ctr(pt?.y);
		var id:Dynamic = extendList[MtStd.random(extendList?.length)];
		var mc:Dynamic = entity.item.SpecialItem.attach(game, x,y, 0, id );
		return mc;
	}


}


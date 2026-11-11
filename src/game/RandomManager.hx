// Converti automatiquement depuis hammer/RandomManager.mt (Motion Twin)
package;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
class RandomManager
{
	public var bulks		: Array<Array<Int>>;
	public var expanded	: Array<Array<Int>>;

	public var sums		: Array<Int>;


	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new()  untyped {
		bulks		= new Array();
		expanded	= new Array();
		sums 		= new Array();
	}


	/*------------------------------------------------------------------------
	AJOUTE UN TABLEAU
	------------------------------------------------------------------------*/
	public function register(id:Dynamic, bulk:Dynamic)  untyped {
		bulks[id] = bulk;
		computeSum(id);
//		expand(id);
	}


	/*------------------------------------------------------------------------
	COMPUTE SUM OF ALL ELEMENTS IN A BULK ARRAY
	------------------------------------------------------------------------*/
	public function computeSum(id:Dynamic)  untyped {
		sums[id]=0;
		{ var i:Dynamic=0; while (i<bulks[id]?.length) {
			if ( MtStd.ix(bulks[id], i)==null ) {
				bulks[id][i]=0;
			}
			sums[id] += MtStd.ix(bulks[id], i);
		
i++; } }
	}


	/*------------------------------------------------------------------------
	CRÉATION DU CACHE
	------------------------------------------------------------------------*/
	public function expand(id:Dynamic)  untyped {
		expanded[id] = new Array();
		{ var i:Dynamic=0; while (i<bulks[id]?.length) {
			{ var j:Dynamic=0; while (j<MtStd.ix(bulks[id], i)) {
				expanded[id]?.push(i);
			
j++; } }
		
i++; } }
	}


	/*------------------------------------------------------------------------
	TIRAGE
	------------------------------------------------------------------------*/
	public function draw(id:Dynamic)  untyped {
		// light system
		var tab:Dynamic		= bulks[id];
		var i:Dynamic		= 0;
		var target:Dynamic	= MtStd.random(sums[id]);
		var sum:Dynamic		= 0;
		var result:Dynamic	= null;
		while (i<tab?.length && result==null) {
			sum+=tab[i];
			if ( target<sum ) {
				result = i;
			}
			i++;
		}

		if ( result==null ) {
			GameManager.warning("null draw in array "+id);
		}

		return result;

		// deprecated expanded system
//		return expanded[id][ Std.random(expanded[id].length) ];
	}


	/*------------------------------------------------------------------------
	RENVOIE LES CHANCES DE TIRER LA VALEUR DONNÉE (ratio / 1)
	------------------------------------------------------------------------*/
	public function evaluateChances(id:Dynamic,value:Dynamic)  untyped {
//		var chance	= 1;
//		var tab		= bulks[id];
//		var i		= 0;
//		var sum		= 0;
//		var total	= sums[id];
		Log.trace("item="+value);
		Log.trace(MtStd.ix(bulks[id], value));
		Log.trace(sums[id]);
		return MtStd.ix(bulks[id], value) / sums[id];
	}


	public function remove(rid:Dynamic, id:Dynamic)  untyped {
		bulks[rid][id] = 0;
		computeSum(rid);
	}



	public function drawSpecial()  untyped {
		//
	}
}

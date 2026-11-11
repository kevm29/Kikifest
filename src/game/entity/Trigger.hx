// Converti automatiquement depuis hammer/entity/Trigger.mt (Motion Twin)
package entity;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
import Data as RootData;
class Trigger extends Entity
{

	public var fl_largeTrigger	: Bool ;

	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new()  untyped {
		super() ;
		fl_largeTrigger = false;
	}


	/*------------------------------------------------------------------------
	S'AJOUTE À UNE CASE DONNÉE
	------------------------------------------------------------------------*/
	public function tAddSingle(cx:Dynamic,cy:Dynamic)  untyped {
		if ( cx<0 || cx>=RootData.LEVEL_WIDTH || cy<0 || cy>=RootData.LEVEL_HEIGHT ) {
			return ;
		}
		MtStd.ix(world?.triggers[cx], cy)?.push(this) ;
	}


	/*------------------------------------------------------------------------
	QUITTE UNE CASE DONNÉE
	------------------------------------------------------------------------*/
	public function tRemSingle(cx:Dynamic,cy:Dynamic)  untyped {
		if ( cx<0 || cx>=RootData.LEVEL_WIDTH || cy<0 || cy>=RootData.LEVEL_HEIGHT ) {
			return ;
		}
		var list:Dynamic = MtStd.ix(world?.triggers[cx], cy) ;
		{ var i:Dynamic=0; while (i<list?.length) {
			if ( list[i]==this ) {
				list?.splice(i,1) ;
				i-- ;
			}
		
i++; } }
	}


	/*------------------------------------------------------------------------
	AJOUTE L'ENTITÉ À L'ENSEMBLE DES CASES QU'ELLE OCCUPE
	------------------------------------------------------------------------*/
	public function tAdd(cx:Dynamic,cy:Dynamic)  untyped {
		if ( cx==null || cy==null ) return ;
		tAddSingle(cx,cy) ;
		tAddSingle(cx-1,cy) ;
		tAddSingle(cx+1,cy) ;
		tAddSingle(cx,cy-1) ;
		if ( fl_largeTrigger ) {
			tAddSingle(cx,cy+1) ;
		}
	}

	/*------------------------------------------------------------------------
	RETIRE L'ENTITÉ DE L'ENSEMBLE DES CASES QU'ELLE OCCUPE
	------------------------------------------------------------------------*/
	public function tRem(cx:Dynamic,cy:Dynamic)  untyped {
		if ( cx==null || cy==null ) return ;
		tRemSingle(cx,cy) ;
		tRemSingle(cx-1,cy) ;
		tRemSingle(cx+1,cy) ;
		tRemSingle(cx,cy-1) ;
		if ( fl_largeTrigger ) {
			tRemSingle(cx,cy+1) ;
		}
	}


	/*------------------------------------------------------------------------
	TÉLÉPORTE L'ENTITÉ À UN AUTRE POINT
	------------------------------------------------------------------------*/
	public function moveTo(x:Dynamic,y:Dynamic)  untyped {
		tRem(cx,cy) ;
		this.x=x ;
		this.y=y-1 ;
		updateCoords() ;
		tAdd(cx,cy) ;
	}


	/*------------------------------------------------------------------------
	TÉLÉPORTE L'ENTITÉ À UN AUTRE POINT (PAR CASE)
	------------------------------------------------------------------------*/
	public function moveToCase(cx:Dynamic,cy:Dynamic)  untyped {
		moveTo( Entity.x_ctr(cx), Entity.y_ctr(cy) );
	}


	/*------------------------------------------------------------------------
	RENVOIE LA LISTE DES ENTITÉS D'UN TYPE DONNÉ DANS LA CASE COURANTE
	------------------------------------------------------------------------*/
	public function getByType(type:Dynamic) : Array<Entity>  untyped {
		var list:Dynamic = MtStd.ix(world?.triggers[cx], cy) ;
		var out:Dynamic = new Array() ;
		{ var i:Dynamic=0; while (i<list?.length) {
			if ( (list[i]?.types & type) != 0 ) {
				out?.push(list[i]) ;
			}
		
i++; } }

		return out ;
	}
}


// Converti automatiquement depuis hammer/entity/bad/walker/Kiwi.mt (Motion Twin)
package entity.bad.walker;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
import Data as RootData;
class Kiwi extends entity.bad.Shooter
{
	public var mineList		: Array<entity.bomb.bad.Mine>;

	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new()  untyped {
		super() ;
		setJumpUp(10) ;
		setJumpDown(20);//6) ;
		setJumpH(50) ;
		setClimb(100,3);

		setShoot(3) ;
		initShooter(RootData.SECOND*1, RootData.SECOND*0.6) ;

		speed *= 0.7;
		angerFactor *= 2.5;
		calcSpeed();
		shootCD = 0;

		mineList = new Array();
	}


	/*------------------------------------------------------------------------
	ATTACHEMENT
	------------------------------------------------------------------------*/
	public static function attach(g:mode.GameMode,x:Dynamic,y:Dynamic)  untyped {
		var linkage:Dynamic = RootData.LINKAGES[RootData.BAD_KIWI];
		var mc : entity.bad.walker.Kiwi = (( g.depthMan.attach(linkage,RootData.DP_BADS) ):Dynamic) ;
		mc?.initBad(g,x,y) ;
		return mc ;
	}


	/*------------------------------------------------------------------------
	EVENT: POSE DE MINE
	------------------------------------------------------------------------*/
	override public function onShoot()  untyped {
		var m:Dynamic = entity.bomb.bad.Mine.attach(
			game,
			x+dir*RootData.CASE_WIDTH*1.1,
			y
		);
		mineList?.push(m);
	}


	/*------------------------------------------------------------------------
	EFFACE TOUTES LES MINES POSÉES PAR CE BAD
	------------------------------------------------------------------------*/
	public function clearMines()  untyped {
		{ var i:Dynamic=0; while (i<mineList?.length) {
			var m:Dynamic = mineList[i];
			if ( !m?.fl_trigger ) {
				m?.setLifeTimer( MtStd.random( Math.round(RootData.SECOND*0.7) ) );
			}
		
i++; } }
		mineList = new Array();
	}
}


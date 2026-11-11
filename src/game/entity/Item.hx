// Converti automatiquement depuis hammer/entity/Item.mt (Motion Twin)
package entity;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
import Data as RootData;
class Item extends entity.Physics
{

	public var id : Int ;
	public var subId : Int ;


	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new()  untyped {
		super() ;
		disableAnimator() ;
		fl_alphaBlink		= true;
		fl_largeTrigger		= true;
		fl_strictGravity	= false;
		minAlpha			= 0;
	}


	/*------------------------------------------------------------------------
	INIT
	------------------------------------------------------------------------*/
	override public function init(g:mode.GameMode)  untyped {
		super.init(g) ;
		setLifeTimer(RootData.ITEM_LIFE_TIME) ;
		register(RootData.ITEM) ;
	}


	/*------------------------------------------------------------------------
	INIT D'ITEM
	------------------------------------------------------------------------*/
	public function initItem(g:mode.GameMode,x:Dynamic,y:Dynamic,id:Dynamic,subId:Dynamic)  untyped {
		if (MtStd.isNaN(id)) {
			id = null ;
		}
		if (MtStd.isNaN(subId)) {
			subId = null ;
		}
		if (id==null) {
			GameManager.fatal("null item ID !");
		}

		init(g) ;
		moveTo(x,y) ;
		this.id = id ;
		this.subId = subId ;
		if ( id>=1000 ) {
			this.gotoAndStop(""+(id-1000+1)) ;
		}
		else {
			this.gotoAndStop(""+(id+1)) ;
		}
		this.sub?.gotoAndStop(""+(subId+1)) ;
		game?.fxMan?.attachFx(x,y-RootData.CASE_HEIGHT,"hammer_fx_shine") ;
		endUpdate() ;
	}


	/*------------------------------------------------------------------------
	ACTIVE L'ITEM AU PROFIT DE "E"
	------------------------------------------------------------------------*/
	public function execute(p:entity.Player):Void  untyped {
		destroy() ;
	}


	/*------------------------------------------------------------------------
	EVENT: LIGNE DU BAS
	------------------------------------------------------------------------*/
	override public function onDeathLine()  untyped {
		super.onDeathLine() ;
		moveTo(x,-30) ;
		dy = 0 ;
	}


	/*------------------------------------------------------------------------
	DESTRUCTION
	------------------------------------------------------------------------*/
	override public function onLifeTimer()  untyped {
		super.onLifeTimer() ;
		game?.fxMan?.attachFx(x,y-RootData.CASE_HEIGHT/2,"hammer_fx_pop") ;
		game?.soundMan?.playSound("sound_pop",RootData.CHAN_ITEM);
	}


	/*------------------------------------------------------------------------
	MAIN
	------------------------------------------------------------------------*/
	override public function update()  untyped {
		super.update() ;
	}

}

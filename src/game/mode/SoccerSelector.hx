// Converti automatiquement depuis hammer/mode/SoccerSelector.mt (Motion Twin)
package mode;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
import Data as RootData;
class SoccerSelector extends Mode {
	public var world		: levels.SetManager;
	public var views		: Array<levels.View>;


	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new(m:Dynamic)  untyped {
		super(m);

		world = new levels.SetManager(manager, "xml_soccer");
		var bg:Dynamic = depthMan?.attach("hammer_special_bg", RootData.DP_BACK_LAYER);
		bg?.gotoAndStop( ""+(RootData.BG_SOCCER+1) );
		{ if (bg != null) bg._width	= RootData.DOC_WIDTH; }
		{ if (bg != null) bg._height	= RootData.DOC_HEIGHT; }


		views = new Array();
		{ var i:Dynamic=0; while (i<4) {
			world?.goto(i);
			var v:Dynamic = new levels.View(world,depthMan);
			{ if (v != null) v.fl_fast = false; }
			{ if (v != null) v.fl_hideBorders = true; }
			v?.display(i);
			v?.scale(0.35);
			v?.moveTo( 15+250*(i%2),  20 + 300* ((i>1)?1:0) );
			{ if (v?._back != null) v._back.onRelease = (function(){ return (this).onSelect(i); }); }
			{ if (v?._back != null) v._back.onRollOver = (function(){ return (this).onOver(i); }); }
			{ if (v?._back != null) v._back.onRollOut = (function(){ return (this).onOut(i); }); }
			views?.push(v);
		
i++; } }
	}


	/*------------------------------------------------------------------------
	EVENT: SELECTION
	------------------------------------------------------------------------*/
	public function onSelect(n:Dynamic)  untyped {
		manager?.startGameMode( new mode.Soccer(manager, n) );
	}


	/*------------------------------------------------------------------------
	EVENT: ROLLOVER
	------------------------------------------------------------------------*/
	public function onOver(n:Dynamic)  untyped {
		FxManager.addGlow( views[n]?._back, 0xffffff, 4 );
	}

	/*------------------------------------------------------------------------
	EVENT: ROLLOUT
	------------------------------------------------------------------------*/
	public function onOut(n:Dynamic)  untyped {
		{ if (views[n]?._back != null) views[n]._back.filters = []; }
	}


	/*------------------------------------------------------------------------
	BOUCLE
	------------------------------------------------------------------------*/
	override public function main()  untyped {
		super.main();
	}


}


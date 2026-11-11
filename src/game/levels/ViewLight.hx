// Converti automatiquement depuis hammer/levels/ViewLight.mt (Motion Twin)
package levels;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
import Data as RootData;
class ViewLight {
	public static var BASE_SIZE = RootData.CASE_WIDTH;

	public var world				: levels.SetManager;
	public var depthMan			: DepthManager;
	public var data				: levels.Data;

	public var levelId				: Int;
	public var size				: Float;
	public var scalef				: Float;

	public var mc					: MovieClip;
	public var bg					: MovieClip;


	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new(w:Dynamic, dm:Dynamic, lid:Dynamic)  untyped {
		world = w;
		depthMan = dm;
		levelId	= lid;
		data = world?.levels[lid];
		if ( data==null ) {
			GameManager.fatal("ERROR: null view");
		}
		scale(1);
	}


	public function scale(f:Dynamic)  untyped {
		scalef = f;
		size = BASE_SIZE*f;
	}


	public function attach(vx:Dynamic,vy:Dynamic)  untyped {
		mc?.removeMovieClip();
		mc = depthMan?.empty(RootData.DP_BACK_LAYER);
		{ if (mc != null) mc._x = vx; }
		{ if (mc != null) mc._y = vy; }

		var map:Dynamic = data?.__S_map;

		mc?.lineStyle(1,0x999999,100);
		mc?.moveTo(-5,0);
		mc?.lineTo(BASE_SIZE * RootData.LEVEL_WIDTH*scalef-5, 0);
		mc?.lineTo(BASE_SIZE * RootData.LEVEL_WIDTH*scalef-5, BASE_SIZE * RootData.LEVEL_HEIGHT*scalef);
		mc?.lineTo(-5, BASE_SIZE * RootData.LEVEL_HEIGHT*scalef);
		mc?.lineTo(-5, 0);


		{ var cy:Dynamic=0; while (cy<RootData.LEVEL_HEIGHT) {
			{ var cx:Dynamic=0; while (cx<RootData.LEVEL_WIDTH) {
				if ( MtStd.ix(map[cx], cy)>0 ) {
					var x:Dynamic = cx*size + size*0.1;
					var y:Dynamic = cy*size + size*0.1;
					mc?.lineStyle(1,0xffffff,100);
					mc?.moveTo(x, y);
					mc?.lineTo(x+size*0.9, y);
					mc?.lineTo(x+size*0.9, y+size*0.9);
					mc?.lineTo(x, y+size*0.9);
					mc?.lineTo(x, y);

					mc?.lineTo(x+size*0.9, y+size*0.9);
					mc?.moveTo(x+size*0.9, y);
					mc?.lineTo(x, y+size*0.9);

				}
			
cx++; } }
		
cy++; } }
	}


	public function strike()  untyped {
		mc?.lineStyle(2,0x990000,100);
		mc?.moveTo(-5,0);
		mc?.lineTo(BASE_SIZE * RootData.LEVEL_WIDTH*scalef-5, BASE_SIZE * RootData.LEVEL_HEIGHT*scalef);
		mc?.moveTo(BASE_SIZE * RootData.LEVEL_WIDTH*scalef-5, 0);
		mc?.lineTo(-5, BASE_SIZE * RootData.LEVEL_HEIGHT*scalef);
	}


	/*------------------------------------------------------------------------
	DESTRUCTION
	------------------------------------------------------------------------*/
	public function destroy()  untyped {
		mc?.removeMovieClip();
	}
}
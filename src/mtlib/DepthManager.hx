// Converti automatiquement depuis lib/DepthManager.mt (Motion Twin)
package mtlib;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
class DepthManager {

	public var root_mc : MovieClip;
	public var plans : Array<{ tbl : Array<MovieClip>, cur : Int }>;

	public function new( mc : MovieClip )  untyped {
		root_mc = mc;
		plans = new Array();
	}

	public function getMC()  untyped {
		return root_mc;
	}

	public function getPlan( pnb:Dynamic )  untyped {
		var plan_data:Dynamic = plans[pnb];
		if( plan_data == null ) {
			plan_data = { tbl : new Array(), cur : 0 };
			plans[pnb] = plan_data;
		}
		return plan_data;
	}

	public function compact( plan : Dynamic )  untyped {
		var plan_data:Dynamic = plans[plan];
		var p:Dynamic = plan_data?.tbl;
		var max:Dynamic = plan_data?.cur;
		var i:Dynamic;
		var cur:Dynamic = 0;
		var base:Dynamic = plan * 1000;
		{ i=0; while (i<max) {if( p[i]?._name != null ) {
				p[i]?.swapDepths(base+cur);
				p[cur] = p[i];
				cur++;
			}
i++; } }
		{ if (plan_data != null) plan_data.cur = cur; }
	}

	public function attach( inst : String, plan : Dynamic ) : MovieClip  untyped {
		var plan_data:Dynamic = getPlan(plan);
		var p:Dynamic = plan_data?.tbl;
		var d:Dynamic = plan_data?.cur;
		if( d == 1000 ) {
			compact(plan);
			return attach(inst,plan);
		}
		var mc:Dynamic = MtStd.attachMC(root_mc,inst,d+plan*1000);
		//Log.trace("ATTACH " + inst + " @ " + (d+plan*1000));
		p[d] = mc;
		{ if (plan_data != null) plan_data.cur++; }
		return mc;
	}

	public function empty( plan : Dynamic ) : MovieClip  untyped {
		var plan_data:Dynamic = getPlan(plan);
		var p:Dynamic = plan_data?.tbl;
		var d:Dynamic = plan_data?.cur;
		if( d == 1000 ) {
			compact(plan);
			return empty(plan);
		}
		var mc:Dynamic = MtStd.createEmptyMC(root_mc,d+plan*1000);
		//Log.trace("EMPTY @ " + (d+plan*1000));
		p[d] = mc;
		{ if (plan_data != null) plan_data.cur++; }
		return mc;
	}

	public function reserve( mc : MovieClip, plan : Dynamic ) : Int  untyped {
		var plan_data:Dynamic = getPlan(plan);
		var p:Dynamic = plan_data?.tbl;
		var d:Dynamic = plan_data?.cur;
		if( d == 1000 ) {
			compact(plan);
			return reserve(mc,plan);
		}
		p[d] = mc;
		{ if (plan_data != null) plan_data.cur++; }
		return d + plan * 1000;
	}

	public function swap( mc : MovieClip, plan : Dynamic )  untyped {
		var src_plan:Dynamic = Math.floor(mc?.getDepth() / 1000);
		if( src_plan == plan )
			return;
		var plan_data:Dynamic = getPlan(src_plan);
		var p:Dynamic = plan_data?.tbl;
		var max:Dynamic = plan_data?.cur;
		var i:Dynamic;
		{ i=0; while (i<max) {if( p[i] == mc ) {
				p[i] = null;
				break;
			}
i++; } }
		mc?.swapDepths( reserve(mc,plan) );
	}

	public function under( mc : MovieClip )  untyped {
		var d:Dynamic = mc?.getDepth();
		var plan:Dynamic = Math.floor(d / 1000);
		var plan_data:Dynamic = getPlan(plan);
		var p:Dynamic = plan_data?.tbl;
		var pd:Dynamic = d%1000;
		if( p[pd] == mc ) {
			p[pd] = null;
			p?.unshift(mc);
			{ if (plan_data != null) plan_data.cur++; }
			compact(plan);
		}
	}

	public function over( mc : MovieClip )  untyped {
		var d:Dynamic = mc?.getDepth();
		var plan:Dynamic = Math.floor(d / 1000);
		var plan_data:Dynamic = getPlan(plan);
		var p:Dynamic = plan_data?.tbl;
		var pd:Dynamic = d%1000;
		if( p[pd] == mc ) {
			p[pd] = null;
			if( plan_data?.cur == 1000 )
				compact(plan);
			d = plan_data?.cur;
			{ if (plan_data != null) plan_data.cur++; }
			mc?.swapDepths(d + plan * 1000);
			p[d] = mc;
		}
	}

	public function clear( plan : Dynamic )  untyped {
		var plan_data:Dynamic = getPlan(plan);
		var i:Dynamic;
		var p:Dynamic = plan_data?.tbl;
		{ i=0; while (i<plan_data?.cur) {p[i]?.removeMovieClip();
i++; } }
		{ if (plan_data != null) plan_data.cur = 0; }
	}

	public function ysort( plan : Dynamic )  untyped {
		var plan_data:Dynamic = getPlan(plan);
		var p:Dynamic = plan_data?.tbl;
		var len:Dynamic = plan_data?.cur;
		var i:Dynamic,j:Dynamic;
		var y:Dynamic = -99999999;
		{ i=0; while (i<len) {
			var mc:Dynamic = p[i];
			var mcy:Dynamic = mc?._y;
			if( mcy >= y )
				y = mcy;
			else {
				{ j=i; while (j>0) {
					var mc2:Dynamic = p[j-1];
					if( mc2?._y > mcy ) {
						p[j] = mc2;
						mc?.swapDepths((cast (mc2)));
					} else {
						p[j] = mc;
						break;
					}
				
j--; } }
				if( j == 0 )
					p[0] = mc;
			}
		
i++; } }
	}

	public function destroy()  untyped {
		var i:Dynamic;
		{ i=0; while (i<plans?.length) {clear(i);
i++; } }
	}

}
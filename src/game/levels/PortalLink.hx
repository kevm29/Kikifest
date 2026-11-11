// Converti automatiquement depuis hammer/levels/PortalLink.mt (Motion Twin)
package levels;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
import Data as RootData;
class PortalLink
{

	// from
	public var from_did	: Int;
	public var from_lid	: Int;
	public var from_pid	: Int;

	// to
	public var to_did		: Int;
	public var to_lid		: Int;
	public var to_pid		: Int;



	public function new()  untyped {
	}


	public function cleanUp()  untyped {
		if ( MtStd.isNaN(from_pid) )  {
			from_pid = 0;
		}
		if ( MtStd.isNaN(to_pid) )  {
			to_pid = 0;
		}
	}


	public function trace()  untyped {
		Log.trace("link: "+from_did+","+from_lid+"("+from_pid+")  > "+to_did+","+to_lid+"("+to_pid+")");
	}
}


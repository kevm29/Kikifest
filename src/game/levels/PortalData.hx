// Converti automatiquement depuis hammer/levels/PortalData.mt (Motion Twin)
package levels;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
import Data as RootData;
class PortalData
{

	public var mc		: MovieClip;
	public var cx		: Int ;
	public var cy		: Int ;

	public var x		: Float; // for animation purpose only
	public var y		: Float;
	public var cpt		: Float;


	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new( mc:Dynamic, cx:Dynamic,cy:Dynamic )  untyped {
		this.mc = mc;
		this.cx = cx ;
		this.cy = cy ;

		x = mc?._x;
		y = mc?._y;
		cpt = 0;
	}

}


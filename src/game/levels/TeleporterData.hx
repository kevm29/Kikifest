// Converti automatiquement depuis hammer/levels/TeleporterData.mt (Motion Twin)
package levels;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
import Data as RootData;
class TeleporterData
{

	public var mc		: Dynamic ;
	public var podA	: MovieClip;
	public var podB	: MovieClip;
	public var cx		: Int ;
	public var cy		: Int ;

	public var centerX	: Float ;
	public var centerY	: Float ;
	public var startX	: Float;
	public var startY	: Float;
	public var endX	: Float;
	public var endY	: Float;

	public var dir		: Int ;
	public var length	: Int ;

	public var fl_on	: Bool;

	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new( x:Dynamic,y:Dynamic, len:Dynamic, dir:Dynamic )  untyped {
		cx = x ;
		cy = y ;
		this.dir = dir ;
		length = len ;

		fl_on = false;


		// Calcul du point central
		centerX	= cx * RootData.CASE_WIDTH + RootData.CASE_WIDTH/2 ;
		centerY	= cy * RootData.CASE_HEIGHT + RootData.CASE_HEIGHT ;
		startX	= Entity.x_ctr(x);
		startY	= Entity.y_ctr(y);

		if ( dir==RootData.HORIZONTAL ) {
			centerX += length/2*RootData.CASE_WIDTH ;
			startX -= RootData.CASE_WIDTH*0.5;
		}
		if ( dir==RootData.VERTICAL ) {
			centerY += length/2*RootData.CASE_HEIGHT ;
			startY -= RootData.CASE_HEIGHT;
		}

		endX	= startX;
		endY	= startY;
		if ( dir==RootData.HORIZONTAL ) {
			endX += length*RootData.CASE_WIDTH;
		}
		else {
			endY += length*RootData.CASE_HEIGHT;
		}
	}

}


// Converti automatiquement depuis hammer/levels/Data.mt (Motion Twin)
package levels;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
import Data as RootData;
class Data
{
	public var __S_map			: Array<Array<Int>>;
	public var __S_badList		: Array< levels.BadData >;

	public var __S_playerX		: Int;
	public var __S_playerY		: Int;

	public var __S_skinTiles		: Int;
	public var __S_skinBg			: Int;

	public var __S_specialSlots	: Array< {__S_x:Int,__S_y:Int} >;
	public var __S_scoreSlots		: Array< {__S_x:Int,__S_y:Int} >;

	public var __S_script			: String;


	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new()  untyped {
		__S_map = new Array();
		{ var x:Dynamic=0; while (x<RootData.LEVEL_WIDTH) {
			__S_map[x] = new Array();
			{ var y:Dynamic=0; while (y<RootData.LEVEL_HEIGHT) {
				__S_map[x][y] = 0;
			
y++; } }
		
x++; } }

		__S_playerX		= 0;
		__S_playerY		= 0;
		__S_skinBg			= 1;
		__S_skinTiles		= 1;
		__S_badList		= new Array();

		__S_specialSlots	= new Array();
		__S_scoreSlots		= new Array();

		__S_script			= "";
	}
}


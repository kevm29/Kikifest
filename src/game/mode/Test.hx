// Converti automatiquement depuis hammer/mode/Test.mt (Motion Twin)
package mode;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
import Data as RootData;
class Test extends Mode {

	public var world : levels.SetManager;

	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new(m:Dynamic)  untyped {
		super(m);
		_name = "$test";
	}




	/*------------------------------------------------------------------------
	BOUCLE PRINCIPALE
	------------------------------------------------------------------------*/
	override public function main()  untyped {
		super.main();
		Log.print(_name);
		if ( Key.isDown(Key.ESCAPE) ) {
			endMode();
		}
	}

}
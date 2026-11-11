// Converti automatiquement depuis hammer/Stat.mt (Motion Twin)
package;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
class Stat
{
	public var current : Float ;
	public var total : Float ;


	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new()  untyped {
		current = 0 ;
		total = 0 ;
	}


	/*------------------------------------------------------------------------
	OPÉRATIONS COURANTES
	------------------------------------------------------------------------*/
	public function inc(n:Dynamic)  untyped {
		current+=n ;
	}


	public function reset()  untyped {
		total+=current ;
		current = 0 ;
	}
}

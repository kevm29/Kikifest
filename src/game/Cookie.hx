// Converti automatiquement depuis hammer/Cookie.mt (Motion Twin)
package;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
class Cookie {
	public static var NAME:String = "$hammerfest_data";
	public static var VERSION:Int = 4;


	public var cookie	: SharedObject;
	public var manager	: GameManager;
	public var data : {
		version		: Int,
		lastModified: Int,
		// ... following level bulk data (setVar/getVar)
	};



	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new(m:Dynamic)  untyped {
		manager	= m;
		cookie	= SharedObject.getLocal(NAME);
		data	= ((cookie?.data):Dynamic);

		checkVersion();
	}


	/*------------------------------------------------------------------------
	INITIALISATION
	------------------------------------------------------------------------*/
	public function reset()  untyped {
		cookie?.clear();
		data			= ((cookie?.data):Dynamic);
		{ if (data != null) data.version	= VERSION; }
		flush();
	}

	/*------------------------------------------------------------------------
	ENREGISTRE LE COOKIE
	------------------------------------------------------------------------*/
	public function flush()  untyped {
		{ if (data != null) data.lastModified = new js.lib.Date().getTime(); }
		cookie?.flush();
	}


	/*------------------------------------------------------------------------
	VÉRIFIE LA VERSION DU COOKIE
	------------------------------------------------------------------------*/
	public function checkVersion()  untyped {
		var ver : Int = data?.version;
		if (  ver!=VERSION || Key.isDown(Key.CONTROL)  ) {
			if (  ver==null || Key.isDown(Key.CONTROL)  ) {
				if ( manager?.fl_debug ) {
					GameManager.warning("Cookie initialized to version "+VERSION);
				}
				reset();
			}
			else {
				GameManager.fatal("invalid cookie version (compiled="+VERSION+" local="+ver+")");
				GameManager.fatal("note: Hold CTRL at start-up to clear cookie");
			}
		}
	}


	/*------------------------------------------------------------------------
	RUNTIME => COOKIE
	------------------------------------------------------------------------*/
	public function saveSet(name:String, raw:String)  untyped {
		MtStd.setVar( ((data):Dynamic), name, raw);
		flush();
	}


	/*------------------------------------------------------------------------
	COOKIE => RUNTIME
	------------------------------------------------------------------------*/
	public function readSet(name:String) : String  untyped {
		return MtStd.getVar( ((data):Dynamic), name );
	}
}


// Converti automatiquement depuis hammer/GameParameters.mt (Motion Twin)
package;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
class GameParameters {
	public var manager				: GameManager;

	public var specialItemFamilies	: Array<Int>;
	public var scoreItemFamilies	: Array<Int>;
	public var soundVolume			: Float;
	public var musicVolume			: Float;
	public var generalVolume		: Float;
	public var fl_detail			: Bool;
	public var fl_shaky			: Bool;

	public var root				: MovieClip;
	public var families			: Array<String>;
	public var options				: Hash<Bool>;
	public var optionList			: Array<String>; // for toString() output only


	/*------------------------------------------------------------------------
	GETTERS
	------------------------------------------------------------------------*/
	public function getStr(n:Dynamic) : String  untyped {
		return MtStd.getVar(root,n);
	}
	public function getInt(n:Dynamic) : Int  untyped {
		return MtStd.parseInt( MtStd.getVar(root,n), 10 );
	}
	public function getBool(n:Dynamic) : Bool  untyped {
		return MtStd.getVar(root,n) != "0" && MtStd.getVar(root,n) != null;
	}


	/*------------------------------------------------------------------------
	CONSTRUCTEUR (default values)
	------------------------------------------------------------------------*/
	public function new(mc:Dynamic, man:Dynamic, f:Dynamic, opt:Dynamic)  untyped {
		root = mc;
		manager = man;
		if ( MtStd.isNaN(getInt("$volume")) ) {
			GameManager.warning("missing parameters");
		}

		// Options de jeu (mirror, nightmare...)
		options = new Hash();
		optionList = new Array();
		if ( opt?.length>0 ) {
			optionList = opt?.split(",");
			{ var i:Dynamic=0; while (i<optionList?.length) {
				options?.set( optionList[i], true );
			
i++; } }
		}

		// Families
		families			= f?.split(",");
		scoreItemFamilies	= new Array();
		specialItemFamilies	= new Array();
		{ var i:Dynamic=0; while (i<families?.length) {
			var id:Dynamic = MtStd.parseInt( families[i], 10 );
			if ( id>=1000 ) {
				scoreItemFamilies?.push(id);
			}
			else {
				specialItemFamilies?.push(id);
			}
		
i++; } }

		// Misc data
		generalVolume		= getInt("$volume") * 0.5 / 100 ;
		soundVolume			= getInt("$sound") * generalVolume;
		musicVolume			= getInt("$music") * generalVolume * 0.65;
		fl_detail			= getBool("$detail");
		fl_shaky			= getBool("$shake");

		if (!fl_detail) {
			setLowDetails();
		}

	}


	/*------------------------------------------------------------------------
	MODE BASSE QUALITÉ
	------------------------------------------------------------------------*/
	public function setLowDetails()  untyped {
		fl_detail = false;
		{ if ((( MtStd.getRoot() ):Dynamic) != null) (( MtStd.getRoot() ):Dynamic)._quality = "$medium".substring(1); }
		Data.MAX_FX = Math.ceil( Data.MAX_FX*0.5 );
	}



	/*------------------------------------------------------------------------
	RENVOIE TRUE SI LA FAMILLE ID EST DÉBLOQUÉE
	------------------------------------------------------------------------*/
	public function hasFamily(id:Dynamic)  untyped {
		var fl_found:Dynamic = false;
		{ var i:Dynamic=0; while (i<specialItemFamilies?.length) {
			if ( specialItemFamilies[i]==id ) {
				fl_found = true;
			}
		
i++; } }
		{ var i:Dynamic=0; while (i<scoreItemFamilies?.length) {
			if ( scoreItemFamilies[i]==id ) {
				fl_found = true;
			}
		
i++; } }

		return fl_found;
	}


	/*------------------------------------------------------------------------
	RENVOIE TRUE SI L'OPTION DEMANDÉE EST ACTIVÉE
	------------------------------------------------------------------------*/
	public function hasOption(oid:String)  untyped {
		return options?.get(oid)==true;
	}


	/*------------------------------------------------------------------------
	RENVOIE UN RÉSUMÉ DE LA CONFIG
	------------------------------------------------------------------------*/
	public function toString()  untyped {
		var str:Dynamic = "";
		str += "fam="+families?.join(", ")+"\n";
		str += "opt="+optionList?.join("\n  ")+"\n";
		str += "mus="+musicVolume +"\n";
		str += "snd="+soundVolume +"\n";
		str += "detail="+fl_detail +"\n";
		str += "shaky ="+fl_shaky +"\n";
		return str;
	}


	public function hasMusic()  untyped {
		return manager?.musics[0]!=null;
	}
}


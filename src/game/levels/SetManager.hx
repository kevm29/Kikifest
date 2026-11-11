// Converti automatiquement depuis hammer/levels/SetManager.mt (Motion Twin)
package levels;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
import Data as RootData;
class SetManager
{

	public var manager				: GameManager;

	public var levels				: Array< levels.Data >;
	public var raw					: Array<String>;
	public var fl_read				: Array<Bool>;
	public var fl_mirror			: Bool;
	public var csum				: Int;

	public var setName				: String;

	public var teleporterList		: Array<levels.TeleporterData> ;
	public var portalList			: Array<levels.PortalData>;

	public var current		: levels.Data;
	public var currentId	: Int;
	public var _previous	: levels.Data;
	public var _previousId	: Int;

	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new( m:Dynamic, s:String )  untyped {
		manager			= m;
		fl_read			= new Array();
		fl_mirror		= false;
		setName			= s;
		teleporterList	= new Array() ;
		portalList		= new Array();

		// Lecture niveaux
		var data:Dynamic = MtStd.getVar( manager?.root, setName );
		raw = data?.split(":");
		if ( MtStd.getVar( manager?.root, setName+"_back_xml" ) == null ) {
			MtStd.setVar( manager?.root, setName+"_back_xml", raw?.join(":") );
		}
		/*
		csum = 0;
		var list = data.split("0");
		var cc = setName.charCodeAt(3);
		for (var n=0;n<list.length;n++) {
			var l = list[n];
			if(l.length>30)
				csum += l.charCodeAt(cc%5) + l.charCodeAt(cc%9) * l.charCodeAt(cc%15) + l.charCodeAt(cc%19) + l.charCodeAt(cc%22);
		}
//		Log.trace(Md5.encode(setName)+" => "+Md5.encode(""+csum));
		if(GameManager.HH.get("$"+Md5.encode(setName))!="$"+Md5.encode(""+csum)) {GameManager.fatal(""); return;}
		*/

		importCookie();
		if ( raw == null ) {
			GameManager.fatal("Error reading "+setName+" (null value)");
			return;
		}
		levels = new Array();
		levels[raw?.length-1] = null; // fix for correct .length attribute
	}


	/*------------------------------------------------------------------------
	DESTRUCTEUR
	------------------------------------------------------------------------*/
	public function destroy()  untyped {
		suspend();
		levels = new Array();
		fl_read = new Array();
	}


	/*------------------------------------------------------------------------
	�CRASE LE CONTENU DU XML EN M�MOIRE
	------------------------------------------------------------------------*/
	public function overwrite( sdata : String )  untyped {
		if ( MtStd.getVar( manager?.root, setName+"_back" ) == null ) {
			MtStd.setVar( manager?.root, setName+"_back", raw?.join(":") );
		}
		raw = sdata?.split(":");
		MtStd.setVar( manager?.root, setName, sdata );
	}

	/*------------------------------------------------------------------------
	RELIS LA DERNI�RE VERSION SAUVEGARD�E
	------------------------------------------------------------------------*/
	public function rollback()  untyped {
		if ( MtStd.getVar( manager?.root, setName+"_back" ) != null ) {
			var rawStr:Dynamic = MtStd.getVar( manager?.root, setName+"_back" );
			MtStd.setVar( manager?.root, setName, rawStr );
			raw = rawStr?.split(":");
		}
	}


	/*------------------------------------------------------------------------
	RELIS LA VERSION XML COMPIL�E
	------------------------------------------------------------------------*/
	public function rollback_xml()  untyped {
		var rawStr:Dynamic = MtStd.getVar( manager?.root, setName+"_back_xml" );
		MtStd.setVar( manager?.root, setName, rawStr );
		raw = rawStr?.split(":");
	}


	/*------------------------------------------------------------------------
	ALLUME / �TEINT UN FIELD DE T�L�PORTATION
	------------------------------------------------------------------------*/
	public function showField(td:levels.TeleporterData)  untyped {
		if ( td?.fl_on ) {
			return;
		}
		{ if (td != null) td.fl_on = true; }
		td?.mc?.skin?.sub?.gotoAndStop("2");
		td?.podA?.gotoAndStop("2");
		td?.podB?.gotoAndStop("2");
	}

	public function hideField(td:Dynamic)  untyped {
		if ( !td?.fl_on ) {
			return;
		}
		{ if (td != null) td.fl_on = false; }
		td?.mc?.skin?.sub?.gotoAndStop("1");
		td?.podA?.gotoAndStop("1");
		td?.podB?.gotoAndStop("1");
	}


	/*------------------------------------------------------------------------
	GESTION VERROU
	------------------------------------------------------------------------*/
	public function suspend()  untyped {
		// do nothing
	}
	public function restore(lid:Dynamic)  untyped {
		// do nothing
	}


	/*------------------------------------------------------------------------
	D�FINI LE NIVEAU COURANT
	------------------------------------------------------------------------*/
	public function setCurrent(id:Dynamic)  untyped {
		//if(GameManager.HH.get("$"+Md5.encode(setName))!="$"+Md5.encode(""+csum)) {GameManager.fatal(""); return;}
		_previous = current;
		_previousId = currentId;
		current = levels[id];
		currentId = id;
	}


	/*------------------------------------------------------------------------
	RENVOIE TRUE SI LES DONN�ES SONT PRETES � ETRE UTILIS�ES
	------------------------------------------------------------------------*/
	public function isDataReady()  untyped {
		return fl_read[currentId];
	}

	public function checkDataReady()  untyped {
		if ( isDataReady() ) {
			onDataReady();
		}
	}


	/*------------------------------------------------------------------------
	ACTIVE UN NIVEAU DONN�
	------------------------------------------------------------------------*/
	public function goto(id:Dynamic)  untyped {
		teleporterList = new Array() ;
		if ( id>=levels.length ) {
			onEndOfSet();
			id = currentId;
			return;
		}
		if ( !fl_read[id] ) {
			levels[id] = unserialize(id);
		}
		setCurrent(id);
		onReadComplete();
	}

	public function next()  untyped {
		//if(GameManager.HH.get("$"+Md5.encode(setName))!="$"+Md5.encode(""+csum)) {GameManager.fatal(""); return;}
		goto(currentId+1);
	}


	/*------------------------------------------------------------------------
	D�TRUIT UN NIVEAU DU SET
	------------------------------------------------------------------------*/
	public function delete(id:Dynamic)  untyped {
		if ( id>=levels.length ) {
			GameManager.fatal("delete after end");
		}
		raw?.splice(id,1);
		levels.splice(id,1);
		fl_read?.splice(id,1);
	}


	/*------------------------------------------------------------------------
	INS�RE UN NIVEAU DANS LE SET
	------------------------------------------------------------------------*/
	public function insert(id:Dynamic,data:levels.Data)  untyped {
		raw?.insert( 	id,	serializeExternal(data) );
		levels.insert(	id,	data );
		fl_read?.insert(	id,	true );
	}

	public function push(data:levels.Data)  untyped {
		raw?.push( 		serializeExternal(data) );
		levels.push(	data );
		fl_read?.push(	true );
	}


	/*------------------------------------------------------------------------
	INVERSION HORIZONTALE D�FINITIVE
	------------------------------------------------------------------------*/
	public function flip( l:levels.Data )  untyped {
		if ( !fl_mirror ) {
			return l;
		}

		var lf:Dynamic			= new levels.Data();
		{ if (lf != null) lf.__S_playerX		= RootData.LEVEL_WIDTH-l?.__S_playerX-1; }
		{ if (lf != null) lf.__S_playerY		= l?.__S_playerY; }
		{ if (lf != null) lf.__S_skinTiles	= l?.__S_skinTiles; }
		{ if (lf != null) lf.__S_skinBg		= l?.__S_skinBg; }
		{ if (lf != null) lf.__S_script		= l?.__S_script; }
		{ if (lf != null) lf.__S_badList		= l?.__S_badList; }
		{ if (lf != null) lf.__S_specialSlots= l?.__S_specialSlots; }
		{ if (lf != null) lf.__S_scoreSlots	= l?.__S_scoreSlots; }

		// map
		{ if (lf != null) lf.__S_map = new Array(); }
		{ var x:Dynamic=0; while (x<RootData.LEVEL_WIDTH) {
			{ if (lf != null) lf.__S_map[x] = new Array(); }
			{ var y:Dynamic=0; while (y<RootData.LEVEL_HEIGHT) {
				{ if (lf != null) lf.__S_map[x][y] = MtStd.ix(l?.__S_map[RootData.LEVEL_WIDTH-x-1], y); }
			
y++; } }
		
x++; } }



		/*
		// bads
		for (var i=0;i<l.$badList.length;i++) {
			var b = l.$badList[i];
			lf.$badList.push(
				new levels.BadData(Data.LEVEL_WIDTH-b.$x-1, b.$y, b.$id)
			);
		}

		// special slots
		for (var i=0;i<l.$specialSlots.length;i++) {
			var s = l.$specialSlots[i];
			lf.$specialSlots.push(
				{ $x:Data.LEVEL_WIDTH-s.$x-1,		$y:s.$y }
			);
		}

		// score slots
		for (var i=0;i<l.$scoreSlots.length;i++) {
			var s = l.$scoreSlots[i];
			lf.$scoreSlots.push(
				{ $x:Data.LEVEL_WIDTH-s.$x-1,		$y:s.$y }
			);
		}
		*/

		return lf;
	}


	/*------------------------------------------------------------------------
	INVERSION HORIZONTALE DES PORTALS
	------------------------------------------------------------------------*/
	public function flipPortals()  untyped {
		var ylist:Dynamic = new Array();
		var list:Dynamic = new Array();
		{ var i:Dynamic=0; while (i<portalList?.length) {
			var p:Dynamic = portalList[i];
			if ( ylist[p?.cy]==null ) {
				ylist[p?.cy] = new Array();
			}
			ylist[p?.cy]?.push(p);
		
i++; } }

		{ var y:Dynamic=0; while (y<ylist?.length) {
			if ( ylist[y]!=null ) {
				{ var i:Dynamic=ylist[y]?.length-1; while (i>=0) {
					var p:Dynamic = MtStd.ix(ylist[y], i);
					list?.push(p);
				
i--; } }
			}
		
y++; } }

		portalList = list;
	}


	/*------------------------------------------------------------------------
	RENVOIE TRUE SI L'ID DE LEVEL SP�CIFI� EST VIDE
	------------------------------------------------------------------------*/
	public function isEmptyLevel(id:Dynamic, g:mode.GameMode)  untyped {
		if ( id>=levels.length ) {
			return true;
		}
		if ( !fl_read[id] ) {
			levels[id] = unserialize(id);
		}
		var ld:Dynamic = levels[id];
		var def:Dynamic = new levels.Data();
		var defX:Dynamic;
		var defY:Dynamic = def?.__S_playerY;

		if ( g==null ) {
			defX = def?.__S_playerX;
		}
		else {
			defX = g?.flipCoordCase(def?.__S_playerX);
		}
		return
			ld?.__S_playerX==defX &&
			ld?.__S_playerY==defY &&
			ld?.__S_skinBg==def?.__S_skinBg &&
			ld?.__S_skinTiles==def?.__S_skinTiles &&
			ld?.__S_badList?.length==0 &&
			ld?.__S_specialSlots?.length==0 &&
			ld?.__S_scoreSlots?.length==0;
	}


	// *** ACCESSEURS *****

	/*------------------------------------------------------------------------
	RETOURNE UNE CASE DE LA MAP
	------------------------------------------------------------------------*/
	public function getCase(pt:Dynamic)  untyped {
		var cx:Int=pt?.x ;
		var cy:Int=pt?.y ;
		if (inBound(cx,cy)) {
			if ( cy==0 ) {
				// Les tiles en haut n'agissent pas comme des sols
				if ( MtStd.ix(current?.__S_map[cx], 0)>0 ) {
					return RootData.WALL;
				}
				else {
					return 0;
				}
			}
			else {
				return MtStd.ix(current?.__S_map[cx], cy) ; // dans la zone de jeu
			}
		}
		else
		if ( cy<0 ) {
			if ( MtStd.ix(current?.__S_map[cx], 0)>0 ) {
				return RootData.WALL;
			}
			else {
				return 0; // hors �cran haut
			}
		}
		else {
			return RootData.OUT_WALL ; // hors �cran bas/gauche/droite
		}
	}

	/*------------------------------------------------------------------------
	MODIFIE DYNAMIQUEMENT UNE CASE
	------------------------------------------------------------------------*/
	public function forceCase(cx:Dynamic,cy:Dynamic, t:Dynamic)  untyped {
		if ( inBound(cx,cy) ) {
			if (  t<=0  &&  getCase({x:cx,y:cy})>0  &&  getCase({x:cx,y:cy+1})==RootData.WALL  ) {
				forceCase( cx, cy+1, RootData.GROUND );
			}
			{ if (current != null) current.__S_map[cx][cy]=t; }
		}
	}


	/*------------------------------------------------------------------------
	RENVOIE TRUE SI LES COORDONN�ES DE CASE SONT DANS L'AIRE DE JEU
	------------------------------------------------------------------------*/
	public function inBound(cx:Dynamic,cy:Dynamic):Bool  untyped {
		return cx>=0 && cx<RootData.LEVEL_WIDTH && cy>=0 && cy<RootData.LEVEL_HEIGHT ;
	}


	/*------------------------------------------------------------------------
	RENVOIE TRUE SI LA BOUNDING BOX EST DANS L'AIRE DE JEU
	------------------------------------------------------------------------*/
	public function shapeInBound(e:Entity):Bool  untyped {
		return (
			e?.x >= -e?._width &&
			e?.x < RootData.GAME_WIDTH &&
			e?.y >= -e?._height &&
			e?.y < RootData.GAME_HEIGHT
		);
	}

	/*------------------------------------------------------------------------
	RENVOIE LE PREMIER SOL RENCONTR� A PARTIR D'UNE CASE DONN�E
	------------------------------------------------------------------------*/
	public function getGround(cx:Dynamic,cy:Dynamic) : {x:Int,y:Int}  untyped {
		var ty:Dynamic,n:Dynamic;
		{ n=0; ty=cy ; while (n<=RootData.LEVEL_HEIGHT) {
			if ( ty>0 && getCase( {x:cx,y:ty} ) == RootData.GROUND ) {
				return {x:cx,y:ty-1};
			}
			if ( ty>=RootData.LEVEL_HEIGHT ) {
				ty=0;
			}
		
n++;ty++; } }

		return {x:cx,y:cy};

	}


	// *** CALLBACKS *****

	/*------------------------------------------------------------------------
	EVENT: LECTURE DES NIVEAUX TERMIN�E
	------------------------------------------------------------------------*/
	public function onReadComplete()  untyped {
		checkDataReady();
	}


	/*------------------------------------------------------------------------
	EVENT: DONN�ES PR�TES
	------------------------------------------------------------------------*/
	public function onDataReady()  untyped {
		// do nothing
	}


	/*------------------------------------------------------------------------
	EVENT: FIN DU SET DE LEVELS
	------------------------------------------------------------------------*/
	public function onEndOfSet()  untyped {
		// do nothing
	}


	public function onRestoreReady()  untyped {
		// do nothing
	}



	// *** ENCODING *****

	/*------------------------------------------------------------------------
	FONCTIONS DE SERIALIZATION
	------------------------------------------------------------------------*/
	public function unserialize(id:Dynamic) : levels.Data  untyped {
		//if(GameManager.HH.get("$"+Md5.encode(setName))!="$"+Md5.encode(""+csum)) {GameManager.fatal(""); return null;}
		var l : levels.Data = (cast (  (new PersistCodec()).decode(raw[id])  ));
		if ( fl_mirror ) {
			l = flip(l);
		}
		convertWalls(l);
		if ( l?.__S_specialSlots==null || l?.__S_scoreSlots==null ) {
			GameManager.warning("empty slot array found ! spec="+l?.__S_specialSlots?.length+" score="+l?.__S_scoreSlots?.length);
		}
		fl_read[id]=true;
		return l;
	}

	public function serialize(id:Dynamic) : String  untyped {
		convertWalls(levels[id]);
		var l:Dynamic = (new PersistCodec())?.encode( levels[id] );
		return l;
	}

	public function serializeExternal(l : levels.Data)  untyped {
		convertWalls(l);
		return (new PersistCodec()).encode( l );
	}

	public function convertWalls(l:Dynamic)  untyped {
		var map:Dynamic = l?.__S_map;
		{ var cy:Dynamic=0; while (cy<RootData.LEVEL_HEIGHT) {
			{ var cx:Dynamic=0; while (cx<RootData.LEVEL_WIDTH) {
				if (MtStd.ix(map[cx], cy)==RootData.WALL) {
					map[cx][cy] = RootData.GROUND;
					GameManager.warning("found wall @ "+cx+","+cy);
				}
			
cx++; } }
		
cy++; } }
	}



	// *** COOKIES ***

	/*------------------------------------------------------------------------
	EXPORT
	------------------------------------------------------------------------*/
	public function exportCookie()  untyped {
		if ( !manager?.fl_cookie ) {
			return;
		}
		manager?.cookie?.saveSet(  setName, raw?.join(":")  );
	}

	/*------------------------------------------------------------------------
	IMPORT
	------------------------------------------------------------------------*/
	public function importCookie()  untyped {
		if ( !manager?.fl_cookie ) {
			return;
		}
		var rawStr:Dynamic = manager?.cookie?.readSet(  setName  );
		if ( rawStr!=null ) {
			raw = rawStr?.split(":");
		}
		else {
			exportCookie();
		}
	}



	// *** MISC ***


	/*------------------------------------------------------------------------
	DEBUG
	------------------------------------------------------------------------*/
	public function trace(id:Dynamic)  untyped {
		Log.trace("Total size: "+levels.length+" level(s)");
		if (id!=null) {
			Log.trace("Level "+id+":");
			Log.trace("player: "+current?.__S_playerX+","+current?.__S_playerY);
			Log.trace(current?.__S_map);
		}
	}


	/*------------------------------------------------------------------------
	BOUCLE PRINCIPALE
	------------------------------------------------------------------------*/
	public function update()  untyped {
		// do nothing
	}

}
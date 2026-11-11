// Converti automatiquement depuis hammer/levels/View.mt (Motion Twin)
package levels;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
import Data as RootData;
import mtflash.display.BitmapData;

class View
{
	public var fl_cache	: Bool;
	public var fl_fast		: Bool; // mode brouillon

	public var viewX		: Float;
	public var viewY		: Float;

	public var world		: levels.SetManager;
	public var data		: levels.Data;
	public var depthMan	: DepthManager;

	public var _top_dm			: DepthManager; // bitmap cache
	public var _back_dm		: DepthManager; // bitmap cache
	public var _field_dm		: DepthManager; // no cache
	public var _sprite_top_dm	: DepthManager; // no cache
	public var _sprite_back_dm	: DepthManager; // no cache

	public var xOffset			: Float;
	public var fl_attach		: Bool;
	public var fl_shadow		: Bool;
	public var fl_hideTiles	: Bool;
	public var fl_hideBorders	: Bool;
	public var levelId			: Int;
	public var topCache		: BitmapData;
	public var viewCache		: BitmapData;
	public var tileCache		: BitmapData;

	public var snapShot		: BitmapData;


	// Movies
	public var _top		: Dynamic;
	public var _back		: Dynamic;
	public var _field		: Dynamic;
	public var _sprite_top : MovieClip;
	public var _sprite_back: MovieClip;

	public var _tiles		: MovieClip;
	public var _bg			: MovieClip;
	public var _leftBorder	: MovieClip;
	public var _rightBorder: MovieClip;
	public var _specialBg	: Dynamic;
	public var tileList			: Array<levels.TileMC>;
	public var gridList			: Array<MovieClip>;
	public var mcList				: Array<MovieClip>;

//	var thumb				: BitmapData;
//	var fl_thumb			: bool;

	public var _fieldMap	: Array<Array<Bool>>;



	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new(world:Dynamic, dm:Dynamic)  untyped {
		this.world = world;

		depthMan	= dm;
		xOffset		= 10;

		fl_attach		= false;
		fl_shadow		= true;
		fl_hideTiles	= false;
		fl_hideBorders	= false;

		tileList	= new Array();
		gridList	= new Array();
		mcList		= new Array();

		_sprite_top		= depthMan?.empty(RootData.DP_SPRITE_TOP_LAYER);
		{ if (_sprite_top != null) _sprite_top._x	-= xOffset; }
		_sprite_back	= depthMan?.empty(RootData.DP_SPRITE_BACK_LAYER);
		{ if (_sprite_back != null) _sprite_back._x	-= xOffset; }
		_sprite_top_dm	= new DepthManager(_sprite_top);
		_sprite_back_dm	= new DepthManager(_sprite_back);

		fl_cache	= world?.manager?.fl_flash8;
		fl_fast		= false;
	}



	/*------------------------------------------------------------------------
	VUE D'UN NIVEAU DU SET INTERNE
	------------------------------------------------------------------------*/
	public function display(id:Dynamic)  untyped {
		this.data = this.world?.levels[id];
		levelId = id;
		if (this.data==null) {
			GameManager.warning("null view");
		}
		attach();
	}

	/*------------------------------------------------------------------------
	VUE DU NIVEAU EN COURS DANS LE SET
	------------------------------------------------------------------------*/
	public function displayCurrent()  untyped {
		display(world?.currentId);
	}


	/*------------------------------------------------------------------------
	UTILISE UN OBJET CUSTOM POUR LA VUE
	------------------------------------------------------------------------*/
	public function displayExternal(d:levels.Data)  untyped {
		this.data = d;
		levelId = null;
		detachLevel();
		attach();
	}


	/*------------------------------------------------------------------------
	SCALE DU NIVEAU
	------------------------------------------------------------------------*/
	public function scale(ratio:Dynamic)  untyped {
		var scale:Dynamic = Math.round(ratio*100);
		{ if (_tiles != null) _tiles._xscale	= scale; }
		{ if (_tiles != null) _tiles._yscale	= scale; }
		{ if (_bg != null) _bg._xscale		= scale; }
		{ if (_bg != null) _bg._yscale		= scale; }
		{ if (_sprite_back != null) _sprite_back._xscale	= scale; }
		{ if (_sprite_back != null) _sprite_back._yscale	= scale; }
		{ if (_sprite_top != null) _sprite_top._xscale		= scale; }
		{ if (_sprite_top != null) _sprite_top._yscale		= scale; }

		{ if (_leftBorder != null) _leftBorder._visible = (ratio==1); }
		{ if (_rightBorder != null) _rightBorder._visible = (ratio==1); }
		if ( fl_cache ) {
			{ if (_top?.bitmapMC != null) _top.bitmapMC._xscale = scale; }
			{ if (_top?.bitmapMC != null) _top.bitmapMC._yscale = scale; }
			{ if (_back?.bitmapMC != null) _back.bitmapMC._xscale = scale; }
			{ if (_back?.bitmapMC != null) _back.bitmapMC._yscale = scale; }
			if ( ratio!=1 ) {
				{ if (_field != null) _field._visible = false; }
			}
			else {
				{ if (_field != null) _field._visible = true; }
			}
		}
	}


	/*------------------------------------------------------------------------
	EFFACE LES OMBRES SOUS LES DALLES
	------------------------------------------------------------------------*/
	public function removeShadows()  untyped {
		fl_shadow = false;
	}


	/*------------------------------------------------------------------------
	RETOURNE SI UNE CASE EST UN MUR
	------------------------------------------------------------------------*/
	public function isWall(cx:Dynamic,cy:Dynamic)  untyped {
		return
			MtStd.ix(data?.__S_map[cx], cy)>0 &&
			( MtStd.ix(data?.__S_map[cx-1], cy)<=0 || MtStd.ix(data?.__S_map[cx-1], cy)==null ) &&
			( MtStd.ix(data?.__S_map[cx+1], cy)<=0 || MtStd.ix(data?.__S_map[cx+1], cy)==null );
	}


	/*------------------------------------------------------------------------
	CALCUL DES ID DE SKIN TILES / COLUMN
	------------------------------------------------------------------------*/
	public static function getTileSkinId(id:Dynamic)  untyped {
		if ( id>=100 ) {
			id = id - Math.floor(id/100)*100;
			return id;
		}
		else {
			return id;
		}
	}

	public static function getColumnSkinId(id:Dynamic)  untyped {
		if ( id>=100 ) {
			id = Math.floor( id/100 );
		}
		return id;
	}

	public static function buildSkinId( tile:Dynamic, column:Dynamic )  untyped {
		if ( column==tile ) {
			return tile;
		}
		else {
//			if ( column<10 ) {
				return column*100 + tile;
//			}
//			else {
//				return column*100 + tile;
//			}
		}
	}


	/*------------------------------------------------------------------------
	ATTACHE UN PLATEAU
	------------------------------------------------------------------------*/
	public function attachTile(sx:Dynamic,sy:Dynamic,wid:Dynamic, skin:Dynamic)  untyped {
		skin = getTileSkinId(skin);
		if ( fl_fast ) {
			skin = 30;
		}
		var tile : levels.TileMC;
		tile = (( MtStd.attachMC( _tiles, "tile", sy*RootData.LEVEL_WIDTH+sx ) ):Dynamic);

		{ if (tile != null) tile._x = sx*RootData.CASE_WIDTH; }
		{ if (tile != null) tile._y = sy*RootData.CASE_HEIGHT; }
		{ if (tile?.maskTile != null) tile.maskTile._width = wid*RootData.CASE_WIDTH; }
		{ if (tile?.endTile != null) tile.endTile._x = wid*RootData.CASE_WIDTH; }

		tile?.skin?.gotoAndStop(Std.string(skin));
		tile?.endTile?.gotoAndStop(Std.string(skin));

		if ( !fl_shadow || fl_fast ) {
			{ if (tile?.ombre != null) tile.ombre._visible = false; }
			{ if (tile?.endTile?.ombre != null) tile.endTile.ombre._visible = false; }
		}

		tileList?.push(tile);
	}

	/*------------------------------------------------------------------------
	ATTACHE UNE COLONNE
	------------------------------------------------------------------------*/
	public function attachColumn(sx:Dynamic,sy:Dynamic,wid:Dynamic, skin:Dynamic)  untyped {
		var tile : levels.TileMC;
		skin = getColumnSkinId(skin);
		if ( fl_fast ) {
			skin = 30;
		}
		tile = (( MtStd.attachMC( _tiles, "tile", sy*RootData.LEVEL_WIDTH+sx ) ):Dynamic);

		{ if (tile != null) tile._yscale = -100; }
		{ if (tile != null) tile._rotation = 90; }
		{ if (tile != null) tile._x = sx*RootData.CASE_WIDTH; }
		{ if (tile != null) tile._y = sy*RootData.CASE_HEIGHT; }
		{ if (tile?.maskTile != null) tile.maskTile._width = wid*RootData.CASE_WIDTH; }
		{ if (tile?.endTile != null) tile.endTile._x = wid*RootData.CASE_WIDTH; }

		tile?.skin?.gotoAndStop(Std.string(skin));
		tile?.endTile?.gotoAndStop(Std.string(skin));

		if ( !fl_shadow || fl_fast ) {
			{ if (tile?.ombre != null) tile.ombre._visible = false; }
			{ if (tile?.endTile?.ombre != null) tile.endTile.ombre._visible = false; }
		}

		tileList?.push(tile);
	}


	/*------------------------------------------------------------------------
	ATTACHE UN CHAMP D'ÉNERGIE
	------------------------------------------------------------------------*/
	public function attachField(sx:Dynamic,sy:Dynamic)  untyped {
		if ( fl_fast ) {
			return;
		}
		var fl_flip:Dynamic = false;
		var mc : MovieClip;
		var id:Dynamic = MtStd.ix(data?.__S_map[sx], sy);
		var td : levels.TeleporterData = null;

		// attachement
		mc = _field_dm?.attach("field",1);
//		mc = Std.attachMC( _field_dm, "field", sy*Data.LEVEL_WIDTH+sx );
		{ if (mc != null) mc._x = sx*RootData.CASE_WIDTH; }
		{ if (mc != null) mc._y = sy*RootData.CASE_HEIGHT; }



		if ( MtStd.ix(data?.__S_map[sx+1], sy) == id ) {
			// horizontal
			mc?.gotoAndStop("2");
			var i:Dynamic = sx;
			while ( MtStd.ix(data?.__S_map[i], sy) == id ) {
				_fieldMap[i][sy]=true;
				i++;
			}

			if ( id == RootData.FIELD_TELEPORT ) {
				td = new levels.TeleporterData(sx,sy, i-sx, RootData.HORIZONTAL);
				{ if (td != null) td.mc = ((mc):Dynamic); }
			}
			{ if (mc != null) mc._width = RootData.CASE_WIDTH * (i-sx); }
		}
		else {
			if ( MtStd.ix(data?.__S_map[sx], sy+1) == id ) {
				// vertical
				mc?.gotoAndStop("1");
				var i:Dynamic = sy;
				while ( MtStd.ix(data?.__S_map[sx], i) == id ) {
					_fieldMap[sx][i]=true;
					i++;
				}

				if ( id==RootData.FIELD_TELEPORT ) {
					td = new levels.TeleporterData(sx,sy, i-sy, RootData.VERTICAL);
					{ if (td != null) td.mc = ((mc):Dynamic); }
				}
				if ( id==RootData.FIELD_PORTAL ) {
					if ( MtStd.ix(data?.__S_map[sx+1], sy)>0 ) {
						fl_flip = true;
					}
				}
				{ if (mc != null) mc._height = RootData.CASE_HEIGHT * (i-sy); }
			}
			else {
				mc?.gotoAndStop("2");
				{ if (mc != null) mc._width = RootData.CASE_WIDTH; }
			}
		}

		// skin
		((mc):Dynamic)?.skin?.gotoAndStop( ""+Math.abs(id) );
		((mc):Dynamic)?.skin?.sub?.stop();
		if ( fl_flip ) {
			((mc):Dynamic).skin.sub._xscale *= -1;
		}

		// téléporteur
		if ( id == RootData.FIELD_TELEPORT ) {
			{ if (td != null) td.podA		= _field_dm?.attach( "hammer_pod", RootData.DP_INTERF ); }
			{ if (td?.podA != null) td.podA._x	= td?.startX; }
			{ if (td?.podA != null) td.podA._y	= td?.startY; }
			td?.podA?.stop();

			{ if (td != null) td.podB		= _field_dm?.attach( "hammer_pod", RootData.DP_INTERF ); }
			{ if (td?.podB != null) td.podB._x	= td?.endX; }
			{ if (td?.podB != null) td.podB._y	= td?.endY; }
			{ if (td?.podB != null) td.podB._rotation = 180; }
			td?.podB?.stop();

			td?.mc?.stop();

			if ( td?.dir==RootData.HORIZONTAL ) {
				{ if (td?.podA != null) td.podA._y -= RootData.CASE_HEIGHT*0.5; }
				{ if (td?.podB != null) td.podB._y -= RootData.CASE_HEIGHT*0.5; }
			}
			else {
				{ if (td?.podA != null) td.podA._rotation += 90; }
				{ if (td?.podB != null) td.podB._rotation += 90; }
			}
//			td.podB = world.game.fxMan.attachFx( td.endX,td.endY, "hammer_fx_shine" );
//			td.podB.gotoAndStop("2");
			world?.teleporterList?.push(td);
		}

		// portal
		if ( id == RootData.FIELD_PORTAL ) {
			world?.portalList?.push( new levels.PortalData(mc,sx,sy) );
		}

	}


	/*------------------------------------------------------------------------
	ATTACHE LE BG DE BASE DU LEVEL
	------------------------------------------------------------------------*/
	public function attachBg()  untyped {
		_bg?.removeMovieClip();
		_bg = _back_dm?.attach("hammer_bg", 0);
		{ if (_bg != null) _bg._x = xOffset; }
		_bg?.gotoAndStop(""+data?.__S_skinBg);
		if ( world?.fl_mirror ) {
			{ if (_bg != null) _bg._xscale *= -1; }
			{ if (_bg != null) _bg._x += RootData.GAME_WIDTH; }
		}
	}


	/*------------------------------------------------------------------------
	ATTACHE UN BACKGROUND SPÉCIAL EN REMPLACEMENT TEMPORAIRE DE L'ACTUEL
	------------------------------------------------------------------------*/
	public function attachSpecialBg( id:Dynamic, subId:Dynamic )  untyped {
		_specialBg = (( depthMan.attach("hammer_special_bg", RootData.DP_SPECIAL_BG) ):Dynamic);
		_specialBg?.gotoAndStop(Std.string(id+1));

		if ( subId!=null ) {
			_specialBg?.sub?.gotoAndStop(Std.string(subId+1));
		}
		if ( fl_cache ) {
			{ if (_specialBg != null) _specialBg.cacheAsBitmap = true; }
			_back_dm?.destroy();
			{ if (_back != null) _back.bitmapMC = _back_dm?.empty(0); }
			_back?.bitmapMC?.attachBitmap(tileCache,0);
		}
		else {
			{ if (_bg != null) _bg._visible = false; }
		}

		return _specialBg;
	}


	/*------------------------------------------------------------------------
	DETACHE LE FOND SPÉCIAL EN COURS
	------------------------------------------------------------------------*/
	public function detachSpecialBg()  untyped {
		_specialBg?.removeMovieClip();
		if ( fl_cache ) {
			_back?.bitmapMC?.attachBitmap(viewCache,0);
		}
		else {
			{ if (_bg != null) _bg._visible = true; }
		}
	}


	/*------------------------------------------------------------------------
	ATTACHE CE LEVEL
	------------------------------------------------------------------------*/
	public function attach()  untyped {
		var startX:Int = 0;
		var startY:Int = 0;
		var tracing:Bool = false;

		{ if (world != null) world.teleporterList = new Array(); }
		{ if (world != null) world.portalList = new Array(); }

		// Containers généraux
		_top		= (( depthMan.empty(RootData.DP_TOP_LAYER) ):Dynamic);
		_field		= (( depthMan.empty(RootData.DP_FIELD_LAYER) ):Dynamic);
		_back		= (( depthMan.empty(RootData.DP_BACK_LAYER) ):Dynamic);
		_top_dm		= new DepthManager(_top);
		_field_dm	= new DepthManager(_field);
		_back_dm	= new DepthManager(_back);

		{ if (_top != null) _top._x		= xOffset; }

		// Container pour les dalles
		_tiles = _back_dm?.empty( 2 );
		{ if (_tiles != null) _tiles._x = xOffset; }
		{ if (_tiles != null) _tiles._visible = !fl_hideTiles; }
		if ( fl_cache ) {
			{ if (_tiles != null) _tiles.cacheAsBitmap = true; }
		}


		_fieldMap = new Array();
		{ var i:Dynamic=0; while (i<RootData.LEVEL_WIDTH) {
			_fieldMap[i] = new Array();
		
i++; } }

		// Background
		if ( !fl_fast ) {
			attachBg();
		}


		// Tiles
		{ var y:Dynamic=0; while (y<RootData.LEVEL_HEIGHT) {
			{ var x:Dynamic=0; while (x<=RootData.LEVEL_WIDTH) {

				if ( !tracing ) {
					if ( MtStd.ix(data?.__S_map[x], y) > 0 ) {
						startX = x;
						startY = y;
						tracing = true;
					}
				}

				// Fin de trace
				if (tracing) {
					if ( MtStd.ix(data?.__S_map[x], y) <= 0 || x == RootData.LEVEL_WIDTH ) {
						var wid:Dynamic;
						wid = x-startX;
//						if ( x==Data.LEVEL_WIDTH && data.map[x-1][y] > 0 ) {
//							wid ++;
//						}
						// Sol ou colonne ?
						if ( wid==1 && isWall(x-1,y) ) {
							var hei:Dynamic=0;
							var vtx:Dynamic = x-1 ; // vertical tracer
							var vty:Dynamic = y;
							if ( !isWall(vtx,vty-1) ) {
								while (isWall(vtx,vty)) {
									hei++;
									vty++;
								}
								if ( hei==1 ) {
									attachTile( startX, startY, 1, data?.__S_skinTiles );
								}
								else {
									attachColumn( startX, startY, hei, data?.__S_skinTiles );
								}
							}
						}
						else {
							attachTile( startX, startY, wid, data?.__S_skinTiles );
						}
						tracing = false;
					}
				}
			
x++; } }
		
y++; } }


		// Fields
		{ var y:Dynamic=0; while (y<RootData.LEVEL_HEIGHT) {
			{ var x:Dynamic=0; while (x<RootData.LEVEL_WIDTH) {
				if ( MtStd.ix(data?.__S_map[x], y) < 0 && MtStd.ix(_fieldMap[x], y)==null ) {
					attachField(x,y);
				}
			
x++; } }
		
y++; } }


		// Colonnes de pierre
		if ( !fl_fast ) {
			_leftBorder = _top_dm?.attach("hammer_sides", 2);
			{ if (_leftBorder != null) _leftBorder._x = 5; }
			_rightBorder = _top_dm?.attach("hammer_sides", 2);
			{ if (_rightBorder != null) _rightBorder._x = RootData.GAME_WIDTH+15; }

			{ if (_leftBorder != null) _leftBorder._visible = !fl_hideBorders; }
			{ if (_rightBorder != null) _rightBorder._visible = !fl_hideBorders; }
		}

		// Mise en cache bitmap
		if ( fl_cache ) {
			// _top		: mc for top-elements
			// _top_dm	: depthManager for _top
			// topCache	: bitmap data for _top

			topCache?.dispose();
			viewCache?.dispose();
			tileCache?.dispose();

			topCache = new BitmapData( RootData.DOC_WIDTH, RootData.DOC_HEIGHT, true, 0xff0000);
			viewCache = new BitmapData( RootData.DOC_WIDTH, RootData.DOC_HEIGHT, true, 0xff0000);
			tileCache = new BitmapData( RootData.DOC_WIDTH, RootData.DOC_HEIGHT, true, 0xff0000);
			topCache?.drawMC(_top,0,0);
			{ if (_bg != null) _bg._visible = false; }
			tileCache?.drawMC(_back,0,0);
			{ if (_bg != null) _bg._visible = true; }
			viewCache?.drawMC(_back,0,0);
			_top_dm?.destroy(); // aka: _top
			_back_dm?.destroy();
			{ if (_top != null) _top.bitmapMC = _top_dm?.empty(0); }
			{ if (_back != null) _back.bitmapMC = _back_dm?.empty(0); }
			_top?.bitmapMC?.attachBitmap(topCache,0);
			_back?.bitmapMC?.attachBitmap(viewCache,0);

			_top_dm		= new DepthManager(_top);
		}

		if ( _specialBg?._name!=null ) {
			_back_dm?.destroy();
			{ if (_back != null) _back.bitmapMC = _back_dm?.empty(0); }
			_back?.bitmapMC?.attachBitmap(tileCache,0);
		}

		fl_attach = true;

	}


	/*------------------------------------------------------------------------
	AFFICHE LES SPOTS DES BADS
	------------------------------------------------------------------------*/
	public function attachBadSpots()  untyped {
		{ var i:Dynamic=0; while (i<data?.__S_badList?.length) {
			var sp:Dynamic = data?.__S_badList[i];
			var mc:Dynamic = _sprite_top_dm?.attach("hammer_editor_bad", RootData.DP_BADS);
			{ if (mc != null) mc._x = Entity.x_ctr(sp?.__S_x) + RootData.CASE_WIDTH*0.5; }
			{ if (mc != null) mc._y = Entity.y_ctr(sp?.__S_y); }
			mc?.gotoAndStop(  ""+(sp?.__S_id+1)  );
//			Log.trace(sp.$x+","+sp.$y+" id="+sp.$id+" --> "+mc._name);
		
i++; } }
	}



	/*------------------------------------------------------------------------
	AFFICHE LA GRILLE DE DEBUG
	------------------------------------------------------------------------*/
	public function attachGrid(flag:Dynamic, over:Bool)  untyped {
		var depth:Dynamic = RootData.DP_SPECIAL_BG;
		if (over) {
			depth = RootData.DP_INTERF;
		}

		{ var cx:Dynamic=0; while (cx<RootData.LEVEL_WIDTH) {
			{ var cy:Dynamic=0; while (cy<RootData.LEVEL_HEIGHT) {
				var mc:Dynamic = (( _top_dm.attach("debugGrid",depth) ):Dynamic);
				{ if (mc != null) mc._x = cx*RootData.CASE_WIDTH+xOffset; }
				{ if (mc != null) mc._y = cy*RootData.CASE_HEIGHT; }
//				mc.fieldA.text = downcast(world).fallMap[cx][cy];
//				mc.fieldB.text = cy;
				if ( (MtStd.ix(((world):Dynamic)?.flagMap[cx], cy) & flag) == 0 ) {
					mc?.gotoAndStop("1");
				}
				else {
					mc?.gotoAndStop("2");
				}
				gridList?.push((cast (mc)));
			
cy++; } }
		
cx++; } }
	}


	/*------------------------------------------------------------------------
	DÉTACHE LA GRILLE DE DEBUG
	------------------------------------------------------------------------*/
	public function detachGrid()  untyped {
		{ var i:Dynamic=0; while (i<gridList?.length) {
			gridList[i]?.removeMovieClip();
		
i++; } }
		gridList = new Array();
	}


	/*------------------------------------------------------------------------
	AFFICHE UN SPRITE STATIQUE DE DÉCOR
	------------------------------------------------------------------------*/
	public function attachSprite(link:Dynamic,x:Dynamic,y:Dynamic,fl_back:Dynamic)  untyped {
		var dm:Dynamic = fl_back?_sprite_back_dm:_sprite_top_dm;
		var mc:Dynamic = dm?.attach(link,10);
		{ if (mc != null) mc._x = x; }
		{ if (mc != null) mc._y = y; }
		mcList?.push(mc);

		return mc;
	}


	/*------------------------------------------------------------------------
	DÉTACHEMENT
	------------------------------------------------------------------------*/
	public function detach()  untyped {
		detachLevel();
		detachSprites();
		fl_attach = false;
		snapShot?.dispose();
	}


	public function detachLevel()  untyped {
		{ var i:Dynamic=0; while (i<tileList?.length) {
			tileList[i]?.removeMovieClip();
		
i++; } }
		tileList = new Array();

		detachGrid();

		topCache?.dispose();
		viewCache?.dispose();
		tileCache?.dispose();

		_top?.removeMovieClip();
		_back?.removeMovieClip();
		_field?.removeMovieClip();
	}


	public function detachSprites()  untyped {
		{ var i:Dynamic=0; while (i<mcList?.length) {
			mcList[i]?.removeMovieClip();
		
i++; } }
		mcList = new Array();
		_sprite_back_dm?.destroy();
		_sprite_top_dm?.destroy();
	}



	/*------------------------------------------------------------------------
	DÉPLACE LE NIVEAU À UN POINT DONNÉ
	------------------------------------------------------------------------*/
	public function moveTo(x:Dynamic,y:Dynamic)  untyped {
		viewX		= x;
		viewY		= y;
		{ if (_top != null) _top._x		= x - xOffset; }
		{ if (_top != null) _top._y		= y; }
		{ if (_back != null) _back._x	= _top?._x; }
		{ if (_back != null) _back._y	= _top?._y; }
		{ if (_field != null) _field._x	= _top?._x+xOffset; }
		{ if (_field != null) _field._y	= _top?._y; }
		{ if (_sprite_back != null) _sprite_back._x	= _top?._x; }
		{ if (_sprite_back != null) _sprite_back._y	= _top?._y; }
		{ if (_sprite_top != null) _sprite_top._x	= _top?._x; }
		{ if (_sprite_top != null) _sprite_top._y	= _top?._y; }
	}


	/*------------------------------------------------------------------------
	APPLIQUE UN FILTRE À TOUT LE NIVEAU
	------------------------------------------------------------------------*/
	public function setFilter(f:Dynamic)  untyped {
		{ if (_top != null) _top.filters = [f]; }
		{ if (_back != null) _back.filters = [f]; }
		{ if (_field != null) _field.filters = [f]; }
		{ if (_sprite_back != null) _sprite_back.filters = [f]; }
		{ if (_sprite_top != null) _sprite_top.filters = [f]; }
	}


	/*------------------------------------------------------------------------
	REPLACE LA VUE EN POSITION
	------------------------------------------------------------------------*/
	public function moveToPreviousPos()  untyped {
		if ( viewX!=null ) {
			moveTo(viewX,viewY);
		}
		else {
			moveTo(0,0);
		}
	}


	/*------------------------------------------------------------------------
	RENVOIE UN BITMAP DE LA VUE
	------------------------------------------------------------------------*/
	public function getSnapShot(x:Dynamic,y:Dynamic)  untyped {
		var ss:Dynamic;
		ss = new BitmapData(RootData.DOC_WIDTH, RootData.DOC_HEIGHT, true, 0xff0000);
		ss?.drawMC(_back,x,y);
		ss?.drawMC(_sprite_back,x,y);
		ss?.drawMC(_top,x,y);
		ss?.drawMC(_sprite_top,x,y);
		return ss;
	}


	/*------------------------------------------------------------------------
	MET À JOUR LE SCREEN INTERNE
	------------------------------------------------------------------------*/
	public function updateSnapShot()  untyped {
		if ( fl_attach ) {
			snapShot?.dispose();
			snapShot = getSnapShot(0,0);
		}
		else {
			GameManager.warning("WARNING: updateSnapShot while not attached");
		}
	}


	/*------------------------------------------------------------------------
	DÉTRUIT LA VUE
	------------------------------------------------------------------------*/
	public function destroy()  untyped {
		detach();
	}

}


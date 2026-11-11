// Converti automatiquement depuis hammer/Entity.mt (Motion Twin)
package;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
class Entity extends MovieClip
{
	public var game		: mode.GameMode ;


	public var x			: Float ; // real coords
	public var y			: Float ;

	public var oldX		: Float ; // previous real coords
	public var oldY		: Float ;

	public var cx			: Int ; // bottom entity case coords
	public var cy			: Int ;

	public var fcx			: Int ; // under feet case coords
	public var fcy			: Int ;

	public var _xOffset	: Float ; // graphical offset of mc (for shoots)
	public var _yOffset	: Float ;

	public var rotation	: Float ;
	public var alpha		: Float ;
	public var minAlpha	: Float ;
	public var scaleFactor	: Float ; // facteur (1.0)
	public var defaultBlend: BlendMode;
	public var blendId		: Int; // int value of blendMode

	public var types		: Int ;

	public var scriptId	: Int ;

	public var lifeTimer	: Float ;
	public var totalLife	: Float ;

	public var fl_kill		: Bool ;
	public var fl_destroy	: Bool ;
	public var world		: levels.GameMechanics ;

	public var uniqId		: Int ;
	public var parent		: Entity ;
	public var color		: Color ;

	public var sticker			: MovieClip ;
	public var stickerX		: Float ;
	public var stickerY		: Float ;
	public var elaStickFactor	: Float;
	public var stickTimer		: Float;
	public var fl_stick		: Bool;
	public var fl_stickRot		: Bool;
	public var fl_stickBound	: Bool;
	public var fl_elastick		: Bool;
	public var fl_softRecal	: Bool;

	public var softRecalFactor	: Float;



	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new()  untyped { super();
		types = 0; //new Array() ;

		x = 0 ;
		y = 0 ;
		alpha = 100 ;
		rotation = 0 ;
		minAlpha = 35 ;
		defaultBlend = BlendMode.NORMAL;
		stickTimer	= 0;

		_xOffset = 0 ;
		_yOffset = 0 ;

		updateCoords() ;

		fl_kill			= false ;
		fl_destroy		= false ;
		fl_stickRot		= false ;
		fl_stickBound	= false;
		fl_softRecal	= false;

		if ( game?.manager?.fl_debug ) {
			this.onRelease	= release;
			this.onRollOver	= rollOver;
			this.onRollOut	= rollOut;
		}
	}



	/*------------------------------------------------------------------------
	INIT
	------------------------------------------------------------------------*/
	public function init(g:mode.GameMode)  untyped {
		game = g ;
		uniqId = game?.getUniqId() ;
		register(Data.ENTITY) ;
		world = game?.world;
		scale(100) ;
	}


	/*------------------------------------------------------------------------
	ENREGISTRE UN NOUVEL ÉLÉMENT
	------------------------------------------------------------------------*/
	public function register( type:Dynamic )  untyped {
		game?.addToList( type, this ) ;
		types |= type ;
	}

	/*------------------------------------------------------------------------
	ENREGISTRE UN NOUVEL ÉLÉMENT
	------------------------------------------------------------------------*/
	public function unregister( type:Dynamic )  untyped {
		game?.removeFromList( type, this ) ;
		types ^= type ;
	}

	/*------------------------------------------------------------------------
	RENVOIE TRUE SI L'ENTITÉ EST DU TYPE SPÉCIFIÉ
	------------------------------------------------------------------------*/
	public function isType(t:Dynamic)  untyped {
		return (types&t) > 0;
	}

	/*------------------------------------------------------------------------
	DÉFINI L'ENTITÉ PARENTE
	------------------------------------------------------------------------*/
	public function setParent( e:Entity )  untyped {
		parent = e ;
	}


	/*------------------------------------------------------------------------
	DÉFINI LE TEMPS DE VIE
	------------------------------------------------------------------------*/
	public function setLifeTimer(t:Dynamic)  untyped {
		lifeTimer = t ;
		totalLife = t ;
	}

	/*------------------------------------------------------------------------
	MET À JOUR LE TEMPS DE VIE (SANS CHANGER LE TOTAL INITIAL)
	------------------------------------------------------------------------*/
	public function updateLifeTimer(t:Dynamic)  untyped {
		if ( totalLife==null ) {
			setLifeTimer(t);
		}
		else {
			lifeTimer = t;
		}
	}


	/*------------------------------------------------------------------------
	EVENT: FIN DE TIMER DE VIE
	------------------------------------------------------------------------*/
	public function onLifeTimer()  untyped {
		destroy() ;
	}


	/*------------------------------------------------------------------------
	HIT TEST DE BOUNDING BOX
	------------------------------------------------------------------------*/
	public function hitBound(e:Entity) : Bool  untyped {
		var res:Dynamic =(
			x+_width/2 > e?.x-e?._width/2 &&
			y > e?.y-e?._height &&
			x-_width/2 < e?.x+e?._width/2 &&
			y-_height < e?.y
			) ;
		return res ;
	}


	/*------------------------------------------------------------------------
	L'ENTITÉ EN RENCONTRE UNE AUTRE
	------------------------------------------------------------------------*/
	public function hit(e: Entity)  untyped {
		// do nothing
	}


	/*------------------------------------------------------------------------
	DESTRUCTEUR
	------------------------------------------------------------------------*/
	public function destroy()  untyped {
		fl_kill = true ;
		fl_destroy = true ;
		unstick() ;
		{ var i:Dynamic=0; while (i<32) {
			if ( (types&(1<<i)) > 0 ) {
				game?.unregList?.push( {type:Math.round(Math.pow(2,i)), ent:this} ) ;
			}
		
i++; } }
		game?.killList?.push(this) ;
	}


	/*------------------------------------------------------------------------
	COLLE UN MC À L'ENTITÉ
	------------------------------------------------------------------------*/
	public function stick(mc:MovieClip,ox:Dynamic,oy:Dynamic)  untyped {
		if (sticker?._name!=null) {
			unstick();
		}
		sticker = mc ;
		stickerX = ox ;
		stickerY = oy ;
		fl_stick = true;
		fl_stickRot = false ;
		fl_stickBound = false;
		fl_elastick = false;
	}

	/*------------------------------------------------------------------------
	ACTIVE L'ELASTICITÉ DU STICKER (algo du cameraman bourré)
	------------------------------------------------------------------------*/
	public function setElaStick(f:Dynamic)  untyped {
		if ( fl_elastick ) {
			return;
		}
		elaStickFactor	= f;
		fl_elastick		= true;
		stickerX		*= elaStickFactor;
		stickerY		*= elaStickFactor;
	}


	/*------------------------------------------------------------------------
	DÉCOLLE LE STICKER
	------------------------------------------------------------------------*/
	public function unstick()  untyped {
		fl_stick = false;
		sticker?.removeMovieClip() ;
	}


	/*------------------------------------------------------------------------
	ACTIVE LE SOFT-RECAL (coordonnées graphiques en retard sur les réelles)
	------------------------------------------------------------------------*/
	public function activateSoftRecal()  untyped {
		fl_softRecal = true;
		softRecalFactor = 0.1;
	}


	// *** DEBUG ***
	public function release()  untyped {
		if ( Key.isDown(Key.SHIFT) ) {
			if ( Key.isDown(Key.CONTROL) ) {
				Log.trace("Full serialization: "+short());
				System.setClipboard( Log.toString(this) );
			}
			else {
				Log.clear();
				Log.trace( short() );
				Log.trace("----------");
				Log.trace("dir="+(cast (this))?.dir+" dx="+(cast (this))?.dx+" dy="+(cast (this))?.dy+" xscale="+_xscale);
			}
		}
	}

	public function rollOver()  untyped {
		if ( Key.isDown(Key.SHIFT) ) {
			var filter:Dynamic = new mtflash.filters.GlowFilter();
			{ if (filter != null) filter.quality = 1; }
			{ if (filter != null) filter.color = 0xffffff; }
			{ if (filter != null) filter.strength = 200; }
			filters = [filter];
		}
	}

	public function rollOut()  untyped {
		if ( filters != null ) {
			filters = null;
		}
	}



	// *** DÉFORMATIONS ET TRANSFORMATIONS

	/*------------------------------------------------------------------------
	MASQUE/AFFICHE L'ENTITÉ
	------------------------------------------------------------------------*/
	public function hide()  untyped {
		_visible = false ;
		if ( sticker?._name!=null ) {
			{ if (sticker != null) sticker._visible = _visible ; }
		}
	}
	public function show()  untyped {
		_visible = true ;
		if ( sticker?._name!=null ) {
			{ if (sticker != null) sticker._visible = _visible ; }
		}
	}


	/*------------------------------------------------------------------------
	RE-SCALE DE L'ENTITÉ
	------------------------------------------------------------------------*/
	public function scale(n:Dynamic)  untyped {
		scaleFactor = n/100 ;
		_xscale = n ;
		_yscale = _xscale ;
	}


	/*------------------------------------------------------------------------
	DÉFINI UN FILTRE DE COULEUR (HEXADÉCIMAL)
	------------------------------------------------------------------------*/
	public function setColorHex( a:Dynamic, col:Dynamic )  untyped {
		var coo:Dynamic = {
			r:col>>16,
			g:(col>>8)&0xFF,
			b:col&0xFF
		};
		var ratio:Dynamic  = a/100;
		var ct:Dynamic = {
			ra:Int(100-a),
			ga:Int(100-a),
			ba:Int(100-a),
			aa:100,
			rb:Int(ratio*coo?.r),
			gb:Int(ratio*coo?.g),
			bb:Int(ratio*coo?.b),
			ab:0
		};
		color = new Color(this);
		color?.setTransform( ct );
	}


	/*------------------------------------------------------------------------
	ANNULE LE FILTRE DE COULEUR
	------------------------------------------------------------------------*/
	public function resetColor()  untyped {
		color?.reset();
		color = null;
	}


	/*------------------------------------------------------------------------
	MODIFIE LE BLEND MODE
	------------------------------------------------------------------------*/
	public function setBlend(m:BlendMode)  untyped {
		defaultBlend	= m;
		blendMode		= m;
		blendId			= (cast (m));
	}



	// *** COORDONNÉES

	/*------------------------------------------------------------------------
	MISE À JOUR DES COORDONNÉES DE CASE
	------------------------------------------------------------------------*/
	public function updateCoords()  untyped {
		cx = Entity.x_rtc(x) ;
		cy = Entity.y_rtc(y) ;
		fcx = Entity.x_rtc(x) ;
		fcy = Entity.y_rtc(y+Math.floor(Data.CASE_HEIGHT/2)) ;
	}


	/*------------------------------------------------------------------------
	CONVERSION REAL -> CASE
	------------------------------------------------------------------------*/
	public static function rtc(x:Dynamic,y:Dynamic)  untyped {
		return {
			x : Entity.x_rtc(x),
			y : Entity.y_rtc(y)
		} ;
	}
	public static function x_rtc(n:Dynamic):Int  untyped {
		return Math.floor(n/Data.CASE_WIDTH) ;
	}
	public static function y_rtc(n:Dynamic):Int  untyped {
		return Math.floor((n-Data.CASE_HEIGHT/2)/Data.CASE_HEIGHT) ;
	}


	/*------------------------------------------------------------------------
	CONVERSION CASE -> REAL
	------------------------------------------------------------------------*/
	public static function x_ctr(n:Dynamic):Float  untyped {
		return n*Data.CASE_WIDTH + Data.CASE_WIDTH*0.5 ;
	}
	public static function y_ctr(n:Dynamic):Float  untyped {
		return n*Data.CASE_HEIGHT + Data.CASE_HEIGHT;
	}


	/*------------------------------------------------------------------------
	NORMALISE UN ANGLE (EN DEGRÉ) DANS L'INTERVAL 0-360
	------------------------------------------------------------------------*/
	public function adjustAngle(a:Dynamic)  untyped {
		while (a<0) {
			a+=360 ;
		}
		while (a>=360) {
			a-=360 ;
		}
		return a ;
	}


	public function adjustToLeft()  untyped {
		x = x_ctr(cx) ;
		y = y_ctr(cy) ;
		x-=Data.CASE_WIDTH*0.5+1;
	}
	public function adjustToRight()  untyped {
		x = x_ctr(cx) ;
		y = y_ctr(cy) ;
		x+=Data.CASE_WIDTH*0.5-1;
	}
	public function centerInCase()  untyped {
		x = x_ctr(cx) ;
		y = y_ctr(cy) ;
	}


	/*------------------------------------------------------------------------
	RENVOIE LA DISTANCE DE L'ENTITÉ À UNE CASE
	------------------------------------------------------------------------*/
	public function distanceCase(cx:Dynamic,cy:Dynamic)  untyped {
		return Math.sqrt( Math.pow(cy-this.cy,2) + Math.pow(cx-this.cx,2) );
	}

	public function distance(x:Dynamic,y:Dynamic)  untyped {
		return Math.sqrt( Math.pow(y-this.y,2) + Math.pow(x-this.x,2) );
	}


	// *** UPDATES

	/*------------------------------------------------------------------------
	MAIN
	------------------------------------------------------------------------*/
	public function update()  untyped {
		// Durée de vie
		if ( lifeTimer>0 ) {
			lifeTimer-=Timer.tmod ;
			if ( lifeTimer<=0 ) {
				onLifeTimer() ;
			}
		}

		if ( stickTimer>0 ) {
			stickTimer-=Timer.tmod;
			if ( stickTimer<=0 ) {
				unstick();
			}
		}
	}


	/*------------------------------------------------------------------------
	RENVOIE LE NOM COURT DU MOVIE
	------------------------------------------------------------------------*/
	public function short():String  untyped {
		var str : String = ""+(cast (this)) ;
		str = str?.slice(str?.lastIndexOf(".",9999)+1,9999);
		str = str + "(@"+cx+","+cy+")";
		return str ;
	}

	/*------------------------------------------------------------------------
	renvoie tous les types
	------------------------------------------------------------------------*/
	public function printTypes()  untyped {
		var l:Dynamic = new Array();
		var b:Dynamic = 0;
		{ var i:Dynamic=0; while (i<30) {
			var fl:Dynamic = ((types&(1<<b++))>0);
			if ( fl ) {
				l?.push(i);
			}
		
i++; } }
		return l?.join(",");
	}


	/*------------------------------------------------------------------------
	CLOTURE DES UPDATES
	------------------------------------------------------------------------*/
	public function endUpdate()  untyped {
		updateCoords() ;
		if ( fl_softRecal ) {
			var tx:Dynamic = x+_xOffset;
			var ty:Dynamic = y+_yOffset;
			_x = _x + (tx-_x)*softRecalFactor;
			_y = _y + (ty-_y)*softRecalFactor;
			softRecalFactor += 0.02*Timer.tmod;
			if ( softRecalFactor>=1 || ( Math.abs(tx-_x)<=1.5 && Math.abs(ty-_y)<=1.5 ) ) {
				fl_softRecal = false;
			}
		}
		if ( !fl_softRecal ) {
			_x = x+_xOffset ;
			_y = y+_yOffset ;
		}
		_rotation = rotation ;
		_alpha = Math.max(minAlpha, alpha) ;
		if ( alpha!=100 && blendId<=2 ) {
			blendMode = BlendMode.LAYER;
		}
		else {
			blendMode = defaultBlend;
		}
		oldX = x ;
		oldY = y ;
		if ( fl_stick ) {
			if ( fl_elastick ) {
				{ if (sticker != null) sticker._x = sticker?._x + (x-sticker?._x)*elaStickFactor + stickerX; }
				{ if (sticker != null) sticker._y = sticker?._y + (y-sticker?._y)*elaStickFactor + stickerY; }
			}
			else {
				{ if (sticker != null) sticker._x = x + stickerX; }
				{ if (sticker != null) sticker._y = y + stickerY; }
			}
			if ( fl_stickRot ) {
				{ if (sticker != null) sticker._rotation+=8*Timer.tmod; }
			}
			if ( fl_stickBound ) {
				{ if (sticker != null) sticker._x = Math.max( sticker?._x, sticker?._width*0.5 ); }
				{ if (sticker != null) sticker._x = Math.min( sticker?._x, Data.GAME_WIDTH-sticker?._width*0.5 ); }
			}
		}
	}

}

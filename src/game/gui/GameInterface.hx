// Converti automatiquement depuis hammer/gui/GameInterface.mt (Motion Twin)
package gui;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
import Data as RootData;
class GameInterface
{
	public static var GLOW_COLOR:Int	= 0x70658d;

	public static var BASE_X:Int		= 92; // lives
	public static var BASE_X_RIGHT:Int	= 300;
	public static var BASE_WIDTH:Int	= 20;

	public static var MAX_LIVES:Int	= 8;


	public var mc				: MovieClip;

	public var game			: mode.GameMode;
	public var currentLives	: Array<Int>;
	public var level			: TextField;
	public var scores			: Array<TextField>;

	public var realScores		: Array<Int>;
	public var fakeScores		: Array<Int>;

	public var fl_light		: Bool;
	public var fl_print		: Bool;
	public var fl_multi		: Bool;

	public var lives			: Array<Array<MovieClip>>;
	public var letters			: Array<Array<MovieClip>>;
	public var more			: Array<MovieClip>;

	public var baseColor		: Int;

	// Kikifest (étude 3-4 joueurs) : 2e barre, placée sous la 1re (le canevas est agrandi d'autant)
	public var mc2				: MovieClip;
	public static var ROW2_DY:Int	= 20;
	public static var LEVEL_ARROW:Int	= 3971; // forme de la flèche rouge du niveau (barre du solo)
	public static var LIFE_TINTS:Array<Dynamic> = [
		null,
		{ra:100, ga:25, ba:25, rb:20, gb:0, bb:0},		// Sandy : cornet rouge
		{ra:30, ga:100, ba:60, rb:0, gb:20, bb:0},		// joueur 3 : vert
		{ra:25, ga:45, ba:100, rb:0, gb:10, bb:150},	// joueur 4 : bleu
	];

	/** Kikifest : place un champ de la barre Coop et lui donne la taille de police du solo. **/
	function kikiField(tf:Dynamic, x:Float, w:Float, align:Int) {
		if ( tf == null || tf.__def == null ) return;
		var d:Dynamic = Reflect.copy(tf.__def);
		d.size = 14;
		d.align = align;
		d.b = [0, -2, w, 20.15];
		tf.__def = d;
		tf._x = x;
		tf._y = -19.2;
	}

	/** Kikifest : à plusieurs, au-delà de 4 cornets on affiche le « + » (les scores sont au milieu). **/
	function maxLives():Int {
		return fl_multi ? 4 : MAX_LIVES;
	}

	function tintLife(m:Dynamic, pid:Dynamic) {
		if ( m == null ) return;
		if ( mc2 != null ) { m._xscale = 80; m._yscale = 80; m._y = m._y + 2; }
		if ( LIFE_TINTS[pid] != null ) new Color(m).setTransform(LIFE_TINTS[pid]);
	}


	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new(game:Dynamic)  untyped {
		this.game = game;
		more = new Array();

		if ( game?._name=="$time" || game?._name=="$timeMulti" ) {
			initTime();
		}
		else {
			if ( game?.countList(RootData.PLAYER) == 1 ) {
				initSingle();
			}
			else {
				initMulti();
			}
		}

		FxManager.addGlow( ((level):Dynamic), GLOW_COLOR, 2);

		setLevel(game?.world?.currentId);
		fl_light		= false;
		fl_print		= false;
		baseColor		= RootData.BASE_COLORS[0];

		update();
	}


	/*------------------------------------------------------------------------
	INIT: INTERFACE SOLO
	------------------------------------------------------------------------*/
	public function initSingle()  untyped {
		fl_multi = false;

		// skin
		mc = game?.depthMan?.attach("hammer_interf_game",RootData.DP_TOP);
		{ if (mc != null) mc._x = -game?.xOffset; }
		{ if (mc != null) mc._y = RootData.DOC_HEIGHT; }
		mc?.gotoAndStop("1");
		{ if (mc != null) mc.cacheAsBitmap = true; }
		scores	= [ ((mc):Dynamic)?.score0 ];
		level	= ((mc):Dynamic)?.level;


		// Lettres Extend
		letters = new Array();
		letters[0] = new Array();
		letters[0]?.push( ((mc):Dynamic)?.letter0_0 );
		letters[0]?.push( ((mc):Dynamic)?.letter0_1 );
		letters[0]?.push( ((mc):Dynamic)?.letter0_2 );
		letters[0]?.push( ((mc):Dynamic)?.letter0_3 );
		letters[0]?.push( ((mc):Dynamic)?.letter0_4 );
		letters[0]?.push( ((mc):Dynamic)?.letter0_5 );
		letters[0]?.push( ((mc):Dynamic)?.letter0_6 );

		fakeScores		= [0];
		realScores		= [0];
		currentLives	= [0];
		lives			= [[]];

		var p:Dynamic = game?.getPlayerList()[0];
		setScore(0, p?.score);
		setLives(0, p?.lives);
		clearExtends(0);

		{ if (scores[0] != null) scores[0].textColor = RootData.BASE_COLORS[0]; }
		FxManager.addGlow( ((scores[0]):Dynamic), GLOW_COLOR, 2);
	}


	/*------------------------------------------------------------------------
	INIT: INTERFACE MULTIPLAYER
	------------------------------------------------------------------------*/
	public function initMulti()  untyped {
		fl_multi = true;

		// skin
		mc = game?.depthMan?.attach("hammer_interf_game",RootData.DP_TOP);
		{ if (mc != null) mc._x = -game?.xOffset; }
		{ if (mc != null) mc._y = RootData.DOC_HEIGHT; }
		mc?.gotoAndStop("2");
		{ if (mc != null) mc.cacheAsBitmap = true; }
		scores	= [ ((mc):Dynamic)?.score0, ((mc):Dynamic)?.score1 ];
		level	= ((mc):Dynamic)?.level;


		// Lettres Extend
		letters = new Array();
		letters[0] = new Array();
		letters[0]?.push( ((mc):Dynamic)?.letter0_0 );
		letters[0]?.push( ((mc):Dynamic)?.letter0_1 );
		letters[0]?.push( ((mc):Dynamic)?.letter0_2 );
		letters[0]?.push( ((mc):Dynamic)?.letter0_3 );
		letters[0]?.push( ((mc):Dynamic)?.letter0_4 );
		letters[0]?.push( ((mc):Dynamic)?.letter0_5 );
		letters[0]?.push( ((mc):Dynamic)?.letter0_6 );

		letters[1] = new Array();
		letters[1]?.push( ((mc):Dynamic)?.letter1_0 );
		letters[1]?.push( ((mc):Dynamic)?.letter1_1 );
		letters[1]?.push( ((mc):Dynamic)?.letter1_2 );
		letters[1]?.push( ((mc):Dynamic)?.letter1_3 );
		letters[1]?.push( ((mc):Dynamic)?.letter1_4 );
		letters[1]?.push( ((mc):Dynamic)?.letter1_5 );
		letters[1]?.push( ((mc):Dynamic)?.letter1_6 );


		// Kikifest (étude 3-4 joueurs) : une 2e barre en dessous pour les joueurs 3 et 4
		if ( game?.countList(RootData.PLAYER) > 2 ) {
			mc2 = game?.depthMan?.attach("hammer_interf_game",RootData.DP_TOP);
			{ if (mc2 != null) mc2._x = -game?.xOffset; }
			{ if (mc2 != null) mc2._y = RootData.DOC_HEIGHT + ROW2_DY; }
			mc2?.gotoAndStop("2");
			{ if (mc2 != null) mc2.cacheAsBitmap = true; }
			var npl:Dynamic = game?.countList(RootData.PLAYER);
			scores[2] = ((mc2):Dynamic)?.score0;
			{ var k:Dynamic=2; while (k<4) {
				if ( k<npl ) {
					letters[k] = new Array();
					{ var j:Dynamic=0; while (j<7) { letters[k]?.push( MtStd.getVar(mc2, "letter"+(k-2)+"_"+j) ); j++; } }
				}
				else {
					// à 3 joueurs, la moitié droite de la 2e ligne reste vide
					{ var j:Dynamic=0; while (j<7) { var l:Dynamic = MtStd.getVar(mc2, "letter"+(k-2)+"_"+j); if (l != null) l._visible = false; j++; } }
					{ if (((mc2):Dynamic)?.score1 != null) ((mc2):Dynamic).score1._visible = false; }
				}
			k++; } }
			if ( npl>3 ) scores[3] = ((mc2):Dynamic)?.score1;
		}

		// Kikifest : comme la barre du solo, numéro du niveau dans l'angle gauche et scores
		// côte à côte au milieu, dans la police du solo (14 px au lieu de 13)
		kikiField(scores[0], 122, 80, 1);
		kikiField(scores[1], 220, 80, 0);
		kikiField(scores[2], 122, 80, 1);
		kikiField(scores[3], 220, 80, 0);
		// niveau : flèche rouge du solo + numéro, dans l'angle en haut à gauche de l'écran
		var top:Dynamic = -RootData.DOC_HEIGHT;
		var arrow:Dynamic = new DisplayObject(LEVEL_ARROW);
		{ if (arrow != null) arrow._x = game?.xOffset + 4 - 261; }
		{ if (arrow != null) arrow._y = top + 22; }
		mc?.__addChildAt(arrow, 949);
		var lv:Dynamic = mc?.createTextField("$kikiLevel", 950, 0, 0, 40, 20);
		{ if (lv != null) lv.__def = Reflect.copy(scores[0]?.__def); }
		kikiField(lv, game?.xOffset + 24, 40, 0);
		{ if (lv != null) lv._y = top + 2; }
		level = lv;

		// Init spécifiques aux players
		fakeScores		= new Array();
		realScores		= new Array();
		currentLives	= new Array();
		lives			= new Array();
		var pl:Dynamic = game?.getPlayerList();
		{ var i:Dynamic=0; while (i<pl?.length) {
			var p:Dynamic = pl[i];
			var pid:Dynamic = p?.pid;

			fakeScores[pid]		= 0;
			realScores[pid]		= 0;
			currentLives[pid]	= 0;
			lives[pid]			= new Array();

			setScore(pid, p?.score);
			setLives(pid, p?.lives);

			clearExtends(pid);
			{ if (scores[pid] != null) scores[pid].textColor = RootData.BASE_COLORS[0]; }
			FxManager.addGlow( ((scores[pid]):Dynamic), GLOW_COLOR, 2);
		
i++; } }

	}


	/*------------------------------------------------------------------------
	INIT: INTERFACE TIME ATTACK
	------------------------------------------------------------------------*/
	public function initTime()  untyped {
		BASE_X = 8;
		BASE_X_RIGHT = 386;
		BASE_WIDTH *= 0.75;

		// skin
		mc = game?.depthMan?.attach("hammer_interf_game",RootData.DP_TOP);
		{ if (mc != null) mc._x = -game?.xOffset; }
		{ if (mc != null) mc._y = RootData.DOC_HEIGHT; }
		mc?.gotoAndStop("3");
		{ if (mc != null) mc.cacheAsBitmap = true; }
		scores	= [ ((mc):Dynamic)?.time ];
		level	= ((mc):Dynamic)?.level;


		// Lettres Extend
		letters = new Array();

		fakeScores		= [0,0];
		realScores		= [0,0];
		currentLives	= [0,0];
		lives			= [[],[]];

		var pl:Dynamic = game?.getPlayerList();
		{ var i:Dynamic=0; while (i<pl?.length) {
			var p:Dynamic = pl[i];
			var pid:Dynamic = p?.pid;

			fakeScores[pid]		= 0;
			realScores[pid]		= 0;
			currentLives[pid]	= 0;
			lives[pid]			= new Array();

			setScore(pid, p?.score);
			setLives(pid, p?.lives);
		
i++; } }
		clearExtends(0);
		{ if (scores[0] != null) scores[0].textColor = RootData.BASE_COLORS[0]; }
		FxManager.addGlow( ((scores[0]):Dynamic), GLOW_COLOR, 2);
	}


	/*------------------------------------------------------------------------
	MODE MINIMALISTE
	------------------------------------------------------------------------*/
	public function lightMode()  untyped {
		{ if (scores[0] != null) scores[0]._visible = false; }
		setLives(0,0);
		more[0]?.removeMovieClip();
		more[1]?.removeMovieClip();
		fl_light = true;
	}


	/*------------------------------------------------------------------------
	MODIFIE LE SCORE
	------------------------------------------------------------------------*/
	public function setScore(pid:Dynamic,v:Dynamic)  untyped {
		realScores[pid] = v;
	}


	public function getScoreTxt(v:Dynamic)  untyped {
		var tab:Dynamic=(v+"")?.split("");
		{ var i:Dynamic=tab?.length-3; while (i>=0) {
			tab?.insert(i," ");
		
i-=3; } }
		return tab?.join("");
	}

	/*------------------------------------------------------------------------
	MODIFIE LE LEVEL COURANT
	------------------------------------------------------------------------*/
	public function setLevel(id:Dynamic)  untyped {
		{ if (level != null) level.text = ""+id; }
		{ if (level != null) level.textColor = baseColor; }
	}

	public function hideLevel()  untyped {
		{ if (level != null) level.text = "?"; }
		{ if (level != null) level.textColor = baseColor; }
	}

	/*------------------------------------------------------------------------
	MODIFIE LE NOMBRE DE VIES
	------------------------------------------------------------------------*/
	public function setLives(pid:Dynamic,v:Dynamic)  untyped {
		var host:Dynamic	= pid>=2 ? mc2 : mc; // Kikifest (étude) : joueurs 3-4 sur la 2e barre
		var baseX:Dynamic	= BASE_X;
		var baseWid:Dynamic	= BASE_WIDTH;
		if ( fl_multi ) {
			baseWid	= 0.6 * BASE_WIDTH;
		}
		if ( pid%2==1 ) {
			baseWid	*= -1;
			baseX	= BASE_X_RIGHT;
		}

		var plives:Dynamic		= lives[pid];
		if ( fl_light ) {
			return;
		}
		if ( currentLives[pid]>v ) {
			game?.manager?.logAction("$LL");
			while ( currentLives[pid]>v ) {
				plives[currentLives[pid]-1]?.removeMovieClip();
				currentLives[pid]--;
			}
		}
		else {
			while ( currentLives[pid]<v && currentLives[pid]<maxLives() ) {
				var mc:Dynamic = MtStd.attachMC(host, "hammer_interf_life", game.manager.uniq++);
				{ if (mc != null) mc._x = baseX+currentLives[pid]*baseWid; }
				{ if (mc != null) mc._y = -19; }
				tintLife(mc, pid);
				plives[currentLives[pid]]=mc;
				currentLives[pid]++;
			}
			if ( v>maxLives() && more[pid]?._name==null ) {
				more[pid] = MtStd.attachMC(host,"hammer_interf_more", game.manager.uniq++);
				{ if (more[pid] != null) more[pid]._x = baseX + baseWid*maxLives() - 4; }
				if ( pid%2==1 ) {
					{ if (more[pid] != null) more[pid]._x-=baseWid; }
				}
				{ if (more[pid] != null) more[pid]._y = -25; }
			}
			if ( v<=maxLives() && more[pid]?._name!=null ) {
				more[pid]?.removeMovieClip();
			}
		}
	}


	/*------------------------------------------------------------------------
	AFFICHE UN TEXTE FORCÉ DANS LE CHAMP SCORE
	------------------------------------------------------------------------*/
	public function print(pid:Dynamic,s:String)  untyped {
		{ if (scores[pid] != null) scores[pid].text	= s; }
		fl_print			= true;
	}

	public function cls()  untyped {
		fl_print	= false;
	}


	/*------------------------------------------------------------------------
	GESTION EXTEND LETTERS
	------------------------------------------------------------------------*/
	public function getExtend(pid:Dynamic,id:Dynamic)  untyped {
		var l:Dynamic = MtStd.ix(letters[pid], id);
		if ( !l?._visible ) {
			var fx:Dynamic = MtStd.attachMC(mc, "hammer_fx_letter_pop", game.manager.uniq++);
			{ if (fx != null) fx._x = l?._x+l?._width*0.5; }
			{ if (fx != null) fx._y = l?._y; }
			{ if (l != null) l._visible = true; }
		}
	}

	public function clearExtends(pid:Dynamic)  untyped {
		{ var i:Dynamic=0; while (i<letters[pid]?.length) {
			{ if (letters[pid][i] != null) letters[pid][i]._visible = false; }
		
i++; } }
	}


	/*------------------------------------------------------------------------
	DESTRUCTION
	------------------------------------------------------------------------*/
	public function destroy()  untyped {
		mc?.removeMovieClip();
		mc2?.removeMovieClip();
	}


	/*------------------------------------------------------------------------
	MAIN
	------------------------------------------------------------------------*/
	public function update()  untyped {
		if ( !fl_print ) {
			{ var pid:Dynamic=0; while (pid<scores?.length) {
				if( scores[pid]!=null ) {
					if ( fakeScores[pid]<realScores[pid] ) {
						fakeScores[pid] += Math.round( Math.max(90, (realScores[pid]-fakeScores[pid])/5 ) );
					}
					if ( fakeScores[pid]>realScores[pid] ) {
						fakeScores[pid] = realScores[pid];
					}
					{ if (scores[pid] != null) scores[pid].text = getScoreTxt(fakeScores[pid]); }
				}
			
pid++; } }
		}

		// Couleurs
//		for (var pid=0;pid<2;pid++) {
//			scores[pid].textColor = Data.BASE_COLORS[pid];
//			FxManager.addGlow( downcast(scores[pid]), Data.DARK_COLORS[pid], 2);
//		}
//		FxManager.addGlow( downcast(level), 0x4f4763, 2);
	}

}

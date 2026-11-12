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


		// Kikifest (étude 3-4 joueurs) : scores des joueurs 3 et 4 au milieu de la barre
		var npl:Dynamic = game?.countList(RootData.PLAYER);
		{ var k:Dynamic=2; while (k<npl && k<4) {
			var s0:Dynamic = scores[0];
			var tf:Dynamic = mc?.createTextField("$score"+k, 900+k, 32+(k-2)*88, s0?._y, 80, s0?.__h);
			{ if (tf != null) tf.__def = s0?.__def; }
			{ if (tf != null) tf.format = s0?.format; }
			scores[k] = tf;
		k++; } }

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
			{ if (scores[pid] != null) scores[pid].textColor = pid==2 ? 0x8cf09a : (pid==3 ? 0xa8b8ff : RootData.BASE_COLORS[0]); }
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
		if ( pid>=2 ) { currentLives[pid] = v; return; } // Kikifest (étude) : vies des joueurs 3-4 écrites avec le score
		var baseX:Dynamic	= BASE_X;
		var baseWid:Dynamic	= BASE_WIDTH;
		if ( fl_multi ) {
			baseWid	= 0.6 * BASE_WIDTH;
		}
		if ( pid==1 ) {
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
			while ( currentLives[pid]<v && currentLives[pid]<MAX_LIVES ) {
				var mc:Dynamic = MtStd.attachMC(mc, "hammer_interf_life", game.manager.uniq++);
				{ if (mc != null) mc._x = baseX+currentLives[pid]*baseWid; }
				{ if (mc != null) mc._y = -19; }
				plives[currentLives[pid]]=mc;
				currentLives[pid]++;
			}
			if ( v>MAX_LIVES && more[pid]?._name==null ) {
				more[pid] = MtStd.attachMC(mc,"hammer_interf_more", game.manager.uniq++);
				{ if (more[pid] != null) more[pid]._x = baseX + baseWid*MAX_LIVES - 4; }
				if ( pid>0 ) {
					{ if (more[pid] != null) more[pid]._x-=baseWid; }
				}
				{ if (more[pid] != null) more[pid]._y = -25; }
			}
			if ( v<=MAX_LIVES && more[pid]?._name!=null ) {
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
					{ if (scores[pid] != null) scores[pid].text = getScoreTxt(fakeScores[pid]) + (pid>=2 ? " ♥"+currentLives[pid] : ""); }
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

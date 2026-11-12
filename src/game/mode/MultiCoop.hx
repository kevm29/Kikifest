// Converti automatiquement depuis hammer/mode/MultiCoop.mt (Motion Twin)
package mode;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
import Data as RootData;
class MultiCoop extends mode.Adventure
{

	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new(m:Dynamic,id:Dynamic)  untyped {
		super(m,id) ;
		_name			= "$multi" ;
		fl_bullet		= false;
		fl_disguise		= false;
		fl_nightmare	= GameManager.CONFIG.hasOption(RootData.OPT_NIGHTMARE_MULTI);
		fl_mirror		= GameManager.CONFIG.hasOption(RootData.OPT_MIRROR_MULTI);
		fl_map			= true;
		fl_bombControl	= GameManager.CONFIG.hasOption(RootData.OPT_BOMB_CONTROL);
	}


	/*------------------------------------------------------------------------
	INITIALISATION PARTIE
	------------------------------------------------------------------------*/
	override public function initGame()  untyped {
		super.initGame();

		destroyList(RootData.PLAYER);
		cleanKills();

		var p1:Dynamic = insertPlayer(5,-2);
		p1?.ctrl?.setKeys(Key.UP, Key.DOWN, Key.LEFT, Key.RIGHT, Key.ENTER) ;

		if ( !fl_bombControl ) {
			var p2:Dynamic = insertPlayer(14,-2);
			p2?.ctrl?.setKeys(82/*R*/, 70/*F*/, 68/*D*/, 71/*G*/, 65/*A*/) ;
			// Kikifest (étude) : 3e et 4e joueurs, ?joueurs=3 ou 4
			var n:Dynamic = Std.parseInt(""+MtStd.getVar(MtStd.getRoot(),"$joueurs"));
			var cols:Array<Int> = [9, 10];
			{ var k:Dynamic=2; while (n!=null && k<n && k<4) { insertPlayer(cols[k-2],-2); k++; } }
		}
		else {
			p1?.ctrl?.setAlt(p1?.ctrl?.attack, Key.CONTROL);
		}
	}

	/*------------------------------------------------------------------------
	EVENT: MISE EN PAUSE
	------------------------------------------------------------------------*/
	override public function onPause()  untyped {
		super.onPause();

		pauseMC?.gotoAndStop("3");
		{ if (pauseMC?.move != null) pauseMC.move.text			= Lang.get(29); }
		{ if (pauseMC?.attack != null) pauseMC.attack.text			= Lang.get(42); }
		{ if (pauseMC?.click != null) pauseMC.click.text			= ""; }

		var tip:Dynamic	= Lang.get(301 + tipId++);
		if ( tip==null ) {
			tipId = 0;
			tip	= Lang.get(301 + tipId++);
		}

		{ if (pauseMC?.tip != null) pauseMC.tip.html = true; }
		{ if (pauseMC?.tip != null) pauseMC.tip.htmlText = "<b>" + Lang.get(300) +"</b>"+ tip; }
	}


	/*------------------------------------------------------------------------
	INITIALISATION JOUEUR
	------------------------------------------------------------------------*/
	override public function initPlayer(p:Dynamic)  untyped {
		super.initPlayer(p);

		{ if (p != null) p.baseColor = RootData.BASE_COLORS[p?.pid]; }
		{ if (p != null) p.darkColor = RootData.DARK_COLORS[p?.pid]; }
		{ if (p != null) p.lives = Math.ceil(p?.lives*0.5); }
		if ( p?.pid==1 ) {
			{ if (p != null) p.name			= "$Sandy".substring(1); }
			{ if (p != null) p.skin			= 2; }
			{ if (p != null) p.defaultHead	= RootData.HEAD_SANDY; }
			{ if (p != null) p.head			= p?.defaultHead; }
		}
		if ( p?.pid>=2 ) {
			// Kikifest (étude) : joueurs 3 et 4 = Igor vert et Igor bleu
			{ if (p != null) p.name			= p?.pid==2 ? "Joueur 3" : "Joueur 4"; }
			{ if (p != null) p.darkColor		= p?.pid==2 ? 0x1f6a2a : 0x22227a; }
		}
//		p.ctrl.fl_upKick = false;
	}


	/*------------------------------------------------------------------------
	Kikifest (étude) : teinte des joueurs 3 et 4 (remise après un clignotement)
	------------------------------------------------------------------------*/
	override public function main()  untyped {
		super.main();
		var pl:Dynamic = getPlayerList();
		{ var i:Dynamic=0; while (i<pl?.length) {
			var p:Dynamic = pl[i];
			if ( p?.pid>=2 && p?.color==null && (p?.fl_alphaBlink || !p?.fl_blinked) ) {
				p?.setColorHex( 45, p?.pid==2 ? 0x2a9a3a : 0x3a5cff );
			}
		i++; } }
	}


	/*------------------------------------------------------------------------
	ENVOI DU RÉSULTAT DE LA PARTIE
	------------------------------------------------------------------------*/
	override public function saveScore()  untyped {
		var pl:Dynamic = getPlayerList();
		MtStd.getGlobal("gameOver") (
			-1,
			null,
			{
				__S_reachedLevel	: dimensions[0].currentId,
				__S_item2			: getPicks2(),
				__S_data			: { __S_s0:savedScores[0], __S_s1:savedScores[1] },
			}
		);
	}


}

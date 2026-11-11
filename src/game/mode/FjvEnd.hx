// Converti automatiquement depuis hammer/mode/FjvEnd.mt (Motion Twin)
package mode;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
import Data as RootData;
class FjvEnd extends Mode
{
	public var fCookie			: SharedObject;
	public var scr				: Dynamic;
	public var bg				: MovieClip;
	public var timer			: Float;
	public var fxList			: Array<MovieClip>;
	public var fl_name			: Bool;
	public var fl_win			: Bool;

	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new(m:Dynamic,win:Dynamic)  untyped {
		super(m);
		var baseTime:Dynamic = MtStd.parseInt( MtStd.getVar(MtStd.getRoot(),"$time"), 10 );
		if ( MtStd.isNaN(baseTime) ) baseTime = 30;
		fl_win = win;
		fCookie = SharedObject.getLocal("$fjv_data");
		_name = "$fjv_end";
		scr = (( depthMan.attach("hammer_fjv_end",RootData.DP_INTERF) ):Dynamic);
		bg = depthMan?.attach("hammer_fjv_bg",RootData.DP_SPECIAL_BG);
		if ( fl_win ) {
			scr?.gotoAndStop("2");
		}
		else {
			scr?.gotoAndStop("1");
		}
		fCookie = SharedObject.getLocal("$fjv_data");
		timer = MtStd.parseInt( MtStd.getVar( ((fCookie.data):Dynamic), "timer" ), 10 );
		var list:Dynamic = MtStd.getVar( ((fCookie.data):Dynamic), "list" );
		var name:Dynamic = MtStd.getVar( ((fCookie.data):Dynamic), "name" );
		if ( list==null ) {
			list = new Array();
		}
		if ( name!=null ) {
			var score:Dynamic = MtStd.parseInt( MtStd.getVar( ((fCookie.data):Dynamic), "score" ), 10 );
			list?.push( {name:name, win:fl_win, score:score} );
			MtStd.setVar( ((fCookie.data):Dynamic), "name", null );
		}
		while (list?.length>50) {
			list?.splice(0,1);
		}
		MtStd.setVar( ((fCookie.data):Dynamic), "list", list );
		var txt:Dynamic = "";
		{ var i:Dynamic=0; while (i<list?.length) {
			txt+=list[i]?.name+" -> "+list[i]?.win+" ("+list[i]?.score+")\r\n";
		
i++; } }
		System.setClipboard(txt);
		if ( timer<=0 || timer==null || MtStd.isNaN(timer) ) {
			timer = baseTime*RootData.SECOND;
		}
		if ( fl_win ) {
			timer = 2*baseTime*RootData.SECOND;
		}
//		if ( timer>0 ) {
//			playMusic(1);
//		}
		fxList = new Array();
		fl_name = (timer<=0);
	}


	/*------------------------------------------------------------------------
	FIN DE MODE
	------------------------------------------------------------------------*/
	override public function endMode()  untyped {
		scr?.removeMovieClip();
		bg?.removeMovieClip();
		super.endMode();
	}

	public function focus()  untyped {
		var path:Dynamic = (cast (scr.field));
		Selection.setFocus(path);
		Selection.setSelection(scr?.field?.text?.length,scr?.field?.text?.length);
	}



	/*------------------------------------------------------------------------
	BOUCLE PRINCIPALE
	------------------------------------------------------------------------*/
	override public function main()  untyped {
		super.main();
		if ( fl_win && MtStd.random(2)==0 && fxList?.length<40 ) {
			var fx:Dynamic = depthMan?.attach("hammer_fx_fjv", RootData.DP_FX);
			{ if (fx != null) fx._x = MtStd.random(RootData.DOC_WIDTH); }
			{ if (fx != null) fx._y = -15; }
			{ if (fx != null) fx._xscale = MtStd.random(50)+10; }
			{ if (fx != null) fx._yscale = fx?._xscale; }
			fxList?.push(fx);
		}

		{ var i:Dynamic=0; while (i<fxList?.length) {
			var fx:Dynamic = fxList[i];
			{ if (fx != null) fx._y += Timer.tmod * (MtStd.random(20)/10) + 3*(100-fx?._alpha)/100; }
			{ if (fx != null) fx._x += Timer.tmod * MtStd.random(3) * (MtStd.random(2)*2-1); }
			{ if (fx != null) fx._alpha -= Timer.tmod * 2; }
			if ( fx?._alpha<=0 ) {
				fx?.removeMovieClip();
				fxList?.splice(i,1);
				i--;
			}
		
i++; } }


		if ( !fl_name ) {

			timer-=Timer.tmod;
			MtStd.setVar( ((fCookie.data):Dynamic), "timer", timer );
			var sec:Dynamic = Math.ceil(timer/RootData.SECOND);
			if ( sec>=60 ) {
				var min:Dynamic = Math.floor(sec/60);
				{ if (scr?.field != null) scr.field.text = min+":"+RootData.leadingZeros(sec-min*60,2); }
			}
			else {
				{ if (scr?.field != null) scr.field.text = "0:"+RootData.leadingZeros(sec,2); }
			}

			if ( timer<=0 ) {
				fl_name = true;
				scr?.gotoAndStop("3");
				focus();
			}
		}
		else {
			var name:Dynamic = Tools.replace( scr?.field?.text, "\r", "" );
			name = Tools.replace( name, "\n", "" );
			name = RootData.cleanLeading(name);
			if ( name?.length>0 && Key.isDown(Key.ENTER) ) {
				MtStd.setVar( ((fCookie.data):Dynamic), "name", name );
				manager?.startGameMode( new mode.Fjv(manager,0) );
			}
		}


	}

}


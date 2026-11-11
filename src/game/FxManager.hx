// Converti automatiquement depuis hammer/FxManager.mt (Motion Twin)
package;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
import entity.fx.Particle;

class FxManager
{
	public var game		: mode.GameMode;

	public var mcList		: Array<MovieClip>;
	public var animList	: Array<Animation>;
	public var lastAlert	: MovieClip;
	public var bgList		: Array< {id:Int,subId:Int,timer:Float} >;
	public var levelName	: Dynamic;
	public var nameTimer	: Float;
	public var igMsg		: Dynamic;


	public var mc_exitArrow: Dynamic;
	public var fl_bg		: Bool;
//	var bg			: { > MovieClip, sub:MovieClip };

	public var stack		: Array< {t:Float, link:String, x:Float, y:Float} >;



	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new(g:mode.GameMode)  untyped {
		game = g;
		animList = new  Array();
		bgList = new Array();
		mcList = new Array();
		stack = new Array();
		fl_bg = false;
	}


	/*------------------------------------------------------------------------
	ATTACH: INDICATEUR DE LEVEL
	------------------------------------------------------------------------*/
	public function attachLevelPop(name:Dynamic, fl_label:Dynamic)  untyped {
		if ( name!=null ) {
			levelName?.removeMovieClip();
			levelName = ((game.depthMan.attach("hammer_interf_zone",Data.DP_INTERF)):Dynamic);
			{ if (levelName != null) levelName._x = -10; }
			{ if (levelName != null) levelName._y = Data.GAME_HEIGHT-1; }
			{ if (levelName?.field != null) levelName.field.text = name; }
			addGlow(levelName, 0x0, 2);
			if ( fl_label ) {
				{ if (levelName?.label != null) levelName.label.text = Lang.get(13); }
			}
			else {
				{ if (levelName?.label != null) levelName.label.text = ""; }
			}
			nameTimer = Data.SECOND * 5;
		}
	}


	/*------------------------------------------------------------------------
	ATTACH: ALERTE CENTRALE (hurry, boss...etc)
	------------------------------------------------------------------------*/
	public function attachAlert(str:Dynamic)  untyped {
		var mc:Dynamic = game?.depthMan?.attach("hurryUp",Data.DP_INTERF);
		{ if (mc != null) mc._x = Data.GAME_WIDTH/2; }
		{ if (mc != null) mc._y = Data.GAME_HEIGHT/2; }
		((mc):Dynamic).label = str;
		mcList?.push(mc);
		lastAlert = mc;
		return mc;
	}

	public function detachLastAlert()  untyped {
		{ var i:Dynamic=0; while (i<mcList?.length) {
			if (mcList[i]?._name==lastAlert?._name) {
				mcList?.splice(i,1);
				i--;
			}
		
i++; } }
		lastAlert?.removeMovieClip();
	}

	/*------------------------------------------------------------------------
	ATTACH: INDICATEUR DE LEVEL
	------------------------------------------------------------------------*/
	public function attachHurryUp()  untyped {
		return attachAlert( Lang.get(4) );
	}


	/*------------------------------------------------------------------------
	ATTACH: INDICATEUR DE BOSS
	------------------------------------------------------------------------*/
	public function attachWarning()  untyped {
		return attachAlert( Lang.get(12) );
	}



	/*------------------------------------------------------------------------
	ATTACH: INDICATEUR DE LEVEL
	------------------------------------------------------------------------*/
	public function attachExit()  untyped {
		detachExit();
		var mc:Dynamic = (( game.depthMan.attach("hammer_fx_exit",Data.DP_INTERF) ):Dynamic);
		{ if (mc != null) mc._x = Data.GAME_WIDTH/2; }
		{ if (mc != null) mc._y = Data.GAME_HEIGHT; }
		{ if (mc != null) mc.label = Lang.get(3); }
		mc_exitArrow = mc;
	}


	public function detachExit()  untyped {
		mc_exitArrow?.removeMovieClip();
	}


	/*------------------------------------------------------------------------
	ATTACH: INDICATEUR DE LEVEL
	------------------------------------------------------------------------*/
	public function attachEnter(x:Dynamic, pid:Dynamic)  untyped {
		var mc:Dynamic = game?.depthMan?.attach("hammer_fx_enter",Data.DP_INTERF);
		{ if (mc != null) mc._x = x; }
		{ if (mc != null) mc._y = 0; }
		var field : TextField = ((mc):Dynamic)?.field;
		if ( pid==0 ) {
			{ if (field != null) field.text = ""; }
		}
		else {
			{ if (field != null) field.text = "Player "+pid; }
			{ if (field != null) field.textColor = Data.BASE_COLORS[pid-1]; }
		}
		mcList?.push(mc);
	}


	/*------------------------------------------------------------------------
	ATTACH: SCORE GAGNÉ
	------------------------------------------------------------------------*/
	public function attachScorePop(color:Dynamic, glowColor:Dynamic, x:Dynamic,y:Dynamic, txt:String)  untyped {
		var anim:Dynamic = attachFx(x,y,"popScore");
		{ if (anim != null) anim.fl_loop = false; }

		txt = Data.formatNumberStr(txt);

		addGlow(anim?.mc, glowColor, 2);

		((anim.mc):Dynamic).label.field.textColor = color;
		((anim.mc):Dynamic).value = txt;
	}


	/*------------------------------------------------------------------------
	ATTACH: EXPLOSION
	------------------------------------------------------------------------*/
	public function attachExplodeZone(x:Dynamic,y:Dynamic,radius:Dynamic)  untyped {
		if ( game?.fl_lock ) {
			return null;
		}
		var a:Dynamic = attachFx(x,y,"explodeZone");
		{ if (a?.mc != null) a.mc._width = radius*2; }
		{ if (a?.mc != null) a.mc._height = a?.mc?._width; }
		return a;
	}


	public function attachExplosion(x:Dynamic,y:Dynamic,radius:Dynamic)  untyped {
		if ( game?.fl_lock ) {
			return null;
		}
		var a:Dynamic = attachFx(x,y,"explodeZone");
		{ if (a?.mc != null) a.mc._width = radius*2; }
		{ if (a?.mc != null) a.mc._height = a?.mc?._width; }
		{ if (a?.mc != null) a.mc.blendMode	= BlendMode.OVERLAY; }
		return a;
	}


	/*------------------------------------------------------------------------
	ATTACH: PARTICULES S'ENVOLANT
	------------------------------------------------------------------------*/
	public function attachShine(x:Dynamic,y:Dynamic)  untyped {
		if ( game?.fl_lock ) {
			return null;
		}
		var fx:Dynamic = attachFx(x,y,"shine");
		{ if (fx?.mc != null) fx.mc._xscale *= 1.5; }
		{ if (fx?.mc != null) fx.mc._yscale = fx?.mc?._xscale; }
		{ if (fx?.mc != null) fx.mc._xscale *= MtStd.random(2)*2-1; }
		return fx;
	}


	/*------------------------------------------------------------------------
	AFFICHE UN MESSAGE EN JEU
	------------------------------------------------------------------------*/
	public function keyRequired(kid:Dynamic)  untyped {
		igMsg?.removeMovieClip();
		igMsg = (( game.depthMan.attach("hammer_interf_inGameMsg",Data.DP_TOP) ):Dynamic);
		{ if (igMsg?.label != null) igMsg.label.text = Lang.get(40); }
		{ if (igMsg?.field != null) igMsg.field.text = Lang.getKeyName(kid); }
		addGlow(igMsg,0x0, 2);
		{ if (igMsg != null) igMsg.timer = Data.SECOND*2; }
	}


	/*------------------------------------------------------------------------
	AFFICHE UN MESSAGE EN JEU
	------------------------------------------------------------------------*/
	public function keyUsed(kid:Dynamic)  untyped {
		igMsg?.removeMovieClip();
		igMsg = (( game.depthMan.attach("hammer_interf_inGameMsg",Data.DP_TOP) ):Dynamic);
		{ if (igMsg?.label != null) igMsg.label.text = Lang.get(41); }
		{ if (igMsg?.field != null) igMsg.field.text = Lang.getKeyName(kid); }
		addGlow(igMsg,0x0, 2);
		{ if (igMsg != null) igMsg.timer = Data.SECOND*3; }
	}


	/*------------------------------------------------------------------------
	ATTACH: ANIMATION TEMPORAIRE À DURÉE DE VIE LIMITÉE
	------------------------------------------------------------------------*/
	public function attachFx(x:Dynamic,y:Dynamic, link:String) : Animation  untyped {
		if ( game?.fl_lock ) {
			return null;
		}
		var a:Dynamic = new Animation(game);
		a?.attach(x,y, link, Data.DP_FX);
		animList?.push(a);
		return a;
	}


	/*------------------------------------------------------------------------
	PARTICULES DE POUSSIÈRE TOMBANT D'UNE DALLE
	------------------------------------------------------------------------*/
	public function dust(cx:Dynamic,cy:Dynamic)  untyped {
		if ( !GameManager.CONFIG.fl_detail ) {
			return;
		}

		var x:Dynamic = Entity.x_ctr(cx);
		var y:Dynamic = Entity.y_ctr(cy);
		var n:Dynamic = 7;
		var xMin:Dynamic = x - Data.CASE_WIDTH*0.5;
		var xMax:Dynamic = x + Data.CASE_WIDTH*0.5;
		if ( game?.world?.getCase( {x:cx-1,y:cy} )==Data.GROUND ) {
			xMin -= Data.CASE_WIDTH;
		}
		if ( game?.world?.getCase( {x:cx+1,y:cy} )==Data.GROUND ) {
			xMax += Data.CASE_WIDTH;
		}
		var wid:Dynamic = Math.round(xMax-xMin);
		{ var i:Dynamic=0; while (i<n) {
			var fx:Dynamic = attachFx(
				xMin + MtStd.random(wid) ,
				y,
				"hammer_fx_dust"
			);
//			fx.mc._x = Std.random( Math.round(Data.CASE_WIDTH*0.5) ) * (Std.random(2)*2-1);
			{ if (fx?.mc != null) fx.mc._xscale = MtStd.random(50)+50 * (MtStd.random(2)*2-1); }
			{ if (fx?.mc != null) fx.mc._yscale = MtStd.random(80)+10; }
			{ if (fx?.mc != null) fx.mc._alpha = MtStd.random(50)+50; }
			fx?.mc?.gotoAndStop( ""+(MtStd.random(5)+5) );
		
i++; } }
	}


	/*------------------------------------------------------------------------
	AJOUTE UN FX LANCÉ AVEC UN DÉCALAGE DANS LE TEMPS
	------------------------------------------------------------------------*/
	public function delayFx(t:Dynamic, x:Dynamic,y:Dynamic,link:Dynamic)  untyped {
		stack?.push( {t:t, x:x,y:y,link:link} );
	}


	/*------------------------------------------------------------------------
	PARTICULES BONDISSANTES AVEC COLLISION AU DÉCOR (LENTES !!)
	------------------------------------------------------------------------*/
	public function inGameParticles(id:Dynamic, x:Dynamic,y:Dynamic, n:Dynamic)  untyped {
		inGameParticlesDir(id, x,y, n, null);
	}


	public function inGameParticlesDir(id:Dynamic, x:Dynamic,y:Dynamic, n:Dynamic, dir:Dynamic)  untyped {
		if ( game?.fl_lock ) {
			return;
		}
		if ( !GameManager.CONFIG.fl_detail ) {
			return;
		}

		// Epuration des fx
		var l:Dynamic = game?.getList(Data.FX);
		if ( l?.length+n>Data.MAX_FX ) {
			n = Math.ceil(n*0.5);
			game?.destroySome(Data.FX, n+l?.length-Data.MAX_FX);
		}

		var fl_left:Dynamic = (MtStd.random(2)==0)?true:false;
		{ var i:Dynamic=0; while (i<n) {
			var mc:Dynamic = Particle.attach(game, id, x,y);
			if ( x<=Data.CASE_WIDTH ) {
				fl_left = false;
			}
			if ( x>=Data.GAME_WIDTH-Data.CASE_WIDTH ) {
				fl_left = true;
			}
			fl_left = (dir!=null) ? dir<0 : fl_left;

			if (fl_left) {
				{ if (mc?.next != null) mc.next.dx = -Math.abs(mc?.next?.dx); }
			}
			else {
				{ if (mc?.next != null) mc.next.dx = Math.abs(mc?.next?.dx); }
			}
			fl_left = !fl_left;
		
i++; } }
	}


	/*------------------------------------------------------------------------
	ATTACH UN FOND TEMPORAIRE SPÉCIAL
	------------------------------------------------------------------------*/
	public function attachBg(id:Dynamic, subId:Dynamic, timer:Dynamic)  untyped {
		if (timer==null) {
			timer=15;
		}
		bgList?.push( {id:id, subId:subId, timer:timer} );
	}

	public function detachBg()  untyped {
		fl_bg = false;
		game?.world?.view?.detachSpecialBg();
	}


	/*------------------------------------------------------------------------
	DÉTRUIT LES FONDS TEMPORAIRES
	------------------------------------------------------------------------*/
	public function clearBg()  untyped {
		bgList = new Array();
		detachBg();
	}


	/*------------------------------------------------------------------------
	DÉTRUIT TOUS LES FX
	------------------------------------------------------------------------*/
	public function clear()  untyped {
		mc_exitArrow?.removeMovieClip();
		levelName?.removeMovieClip();
		clearBg();
		game?.destroyList(Data.FX);

		{ var i:Dynamic=0; while (i<animList?.length) {
			animList[i]?.destroy();
		
i++; } }
		animList = new Array();

		{ var i:Dynamic=0; while (i<mcList?.length) {
			mcList[i]?.removeMovieClip();
		
i++; } }
		mcList = new Array();

		game?.cleanKills();
	}



	/*------------------------------------------------------------------------
	EVENT: LEVEL SUIVANT
	------------------------------------------------------------------------*/
	public function onNextLevel()  untyped {
		stack = new Array();
		clear();
		levelName?.removeMovieClip();
		detachExit();
	}


	/*------------------------------------------------------------------------
	STATIC: AFFICHE UN CONTOUR SUR UN MC
	------------------------------------------------------------------------*/
	public static function addGlow(mc:MovieClip, color:Dynamic, length:Dynamic)  untyped {
    	var f:Dynamic = new mtflash.filters.GlowFilter();
		{ if (f != null) f.color = color; }
    	{ if (f != null) f.quality	= 1; }
    	{ if (f != null) f.strength	= 100; }
    	{ if (f != null) f.blurX		= length; }
    	{ if (f != null) f.blurY		= f?.blurX; }
    	{ if (mc != null) mc.filters = [f]; }
	}



	/*------------------------------------------------------------------------
	MAIN
	------------------------------------------------------------------------*/
	public function main()  untyped {
		// Gestion des BGs
		if ( bgList?.length>0 ) {
			var b:Dynamic = bgList[0];
			if ( !fl_bg ) {
				fl_bg = true;
				game?.world?.view?.attachSpecialBg(b?.id,b?.subId);
			}
			{ if (b != null) b.timer-=Timer.tmod; }
			if ( b?.timer<=0 ) {
				bgList?.splice(0,1);
				detachBg();
			}
		}

		// Level name life-timer
		if ( levelName?._name!=null ) {
			nameTimer-=Timer.tmod;
			if ( nameTimer<=0 ) {
				{ if (levelName != null) levelName._y+=Timer.tmod*0.7; }
				if ( levelName?._y>=Data.GAME_HEIGHT+30 ) {
					levelName?.removeMovieClip();
				}
			}
		}

		// FX delayés
		{ var i:Dynamic=0; while (i<stack?.length) {
			{ if (stack[i] != null) stack[i].t-=Timer.tmod; }
			if ( stack[i]?.t<=0 ) {
				attachFx( stack[i]?.x, stack[i]?.y, stack[i]?.link );
				stack?.splice(i,1);
				i--;
			}
		
i++; } }

		// Joue les anims
		{ var i:Dynamic=0; while (i<animList?.length) {
			var a:Dynamic = animList[i];
			a?.update();
			if ( a?.fl_kill ) {
				animList[i] = null;
				animList?.splice(i,1);
				i--;
			}
		
i++; } }

		// In-game message
		if ( igMsg?._name!=null ) {
			{ if (igMsg != null) igMsg.timer-=Timer.tmod; }
			if ( igMsg?.timer<=0 ) {
				{ if (igMsg != null) igMsg._alpha-=Timer.tmod*2; }
			}
			if ( igMsg?._alpha<=0 ) {
				igMsg?.removeMovieClip();
			}
		}
	}
}

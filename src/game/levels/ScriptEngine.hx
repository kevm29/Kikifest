// Converti automatiquement depuis hammer/levels/ScriptEngine.mt (Motion Twin)
package levels;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
import Data as RootData;
class ScriptEngine {
	public static var T_TIMER:String			= "$t_timer";
	public static var T_POS:String			= "$t_pos";
	public static var T_ATTACH:String			= "$attach";
	public static var T_DO:String				= "$do";
	public static var T_END:String			= "$end";
	public static var T_BIRTH:String			= "$birth";
	public static var T_DEATH:String			= "$death";
	public static var T_EXPLODE:String		= "$exp";
	public static var T_ENTER:String			= "$enter";
	public static var T_NIGHTMARE:String		= "$night";
	public static var T_MIRROR:String			= "$mirror";
	public static var T_MULTI:String			= "$multi";
	public static var T_NINJA:String			= "$ninja";

	public static var E_SCORE:String			= "$e_score";
	public static var E_SPECIAL:String		= "$e_spec";
	public static var E_EXTEND:String			= "$e_ext";
	public static var E_BAD:String			= "$e_bad";
	public static var E_KILL:String			= "$e_kill";
	public static var E_TUTORIAL:String		= "$e_tuto";
	public static var E_MESSAGE:String		= "$e_msg";
	public static var E_KILLMSG:String		= "$e_killMsg";
	public static var E_POINTER:String		= "$e_pointer";
	public static var E_KILLPTR:String		= "$e_killPt";
	public static var E_MC:String				= "$e_mc";
	public static var E_PLAYMC:String			= "$e_pmc";
	public static var E_MUSIC:String			= "$e_music";
	public static var E_ADDTILE:String		= "$e_add";
	public static var E_REMTILE:String		= "$e_rem";
	public static var E_ITEMLINE:String		= "$e_itemLine";
	public static var E_GOTO:String			= "$e_goto";
	public static var E_HIDE:String			= "$e_hide";
	public static var E_HIDEBORDERS:String	= "$e_hideBorders";
	public static var E_CODETRIGGER:String	= "$e_ctrigger";
	public static var E_PORTAL:String			= "$e_portal";
	public static var E_SETVAR:String			= "$e_setVar";
	public static var E_OPENPORTAL:String		= "$e_openPortal";
	public static var E_DARKNESS:String		= "$e_darkness";
	public static var E_FAKELID:String		= "$e_fakelid";

	public static var VERBOSE_TRIGGERS = [
		T_POS,
		T_EXPLODE,
		T_ENTER,
	];


	public var game			 : mode.GameMode;

	public var script			: MtXml;
	public var extraScript		: String;
	public var baseScript		: String;
	public var data			: levels.Data;
	public var bads			: Int;
	public var cycle			: Float;

	public var mcList			: Array< {sid:Int, mc:MovieClip} >; // script attached MCs

	public var fl_compile		: Bool;
	public var fl_birth		: Bool;
	public var fl_death		: Bool;
	public var fl_safe			: Bool; // safe mode: blocks bads & items spawns

	public var fl_redraw		: Bool; // true=ré-attache le level en fin de frame

	public var fl_elevatorOpen	: Bool; // flag fin de jeu
	public var fl_firstTorch	: Bool;

	public var history			: Array<String>;

	public var recentExp		: Array< {x:Float, y:Float, r:Float} >;
	public var fl_onAttach		: Bool;
	public var bossDoorTimer	: Float;
	public var entries			: Array< {cx:Int,cy:Int} >;


	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new(g:Dynamic, d:levels.Data)  untyped {
		game			= g;
		data			= d;
		baseScript		= data?.__S_script;
		bossDoorTimer	= RootData.SECOND*1.2;
		extraScript		= "";
		cycle			= 0;
		bads			= 0;
		fl_birth		= false;
		fl_death		= false;
		fl_safe			= false;
		fl_elevatorOpen	= false;
		fl_onAttach		= false;
		fl_firstTorch	= false;
		recentExp		= new Array();
		mcList			= new Array();
		history			= new Array();
		entries			= new Array();
	}


	/*------------------------------------------------------------------------
	DESTRUCTION
	------------------------------------------------------------------------*/
	public function destroy()  untyped {
		script = null;
		fl_compile = false;
	}


	/*------------------------------------------------------------------------
	AJOUTE UNE LIGNE À L'HISTORIQUE
	------------------------------------------------------------------------*/
	public function traceHistory(str:Dynamic)  untyped {
		history?.push("@"+Math.round(cycle*10)/10+"\t: "+str);
	}



	// *** EVENTS ***

	/*------------------------------------------------------------------------
	EVENT: RESURRECTION D'UN JOUEUR OU DÉBUT DE NIVEAU
	------------------------------------------------------------------------*/
	public function onPlayerBirth()  untyped {
		fl_birth = true;
	}

	public function onPlayerDeath()  untyped {
		fl_death = true;
	}

	/*------------------------------------------------------------------------
	EVENT: EXPLOSION D'UNE BOMBE D'UN JOUEUR
	------------------------------------------------------------------------*/
	public function onExplode(x:Dynamic,y:Dynamic,radius:Dynamic)  untyped {
		recentExp?.push( {
			x : x,
			y : y,
			r : radius
		} );
	}

	/*------------------------------------------------------------------------
	EVENT: ENTRÉE D'UN JOUEUR DANS UNE CASE
	------------------------------------------------------------------------*/
	public function onEnterCase(cx:Dynamic,cy:Dynamic)  untyped {
		entries?.push( {cx:cx,cy:cy} );
	}

	/*------------------------------------------------------------------------
	ATTACHEMENT DE LA VUE DU NIVEAU
	------------------------------------------------------------------------*/
	public function onLevelAttach()  untyped {
		fl_onAttach = true;
	}


	/*------------------------------------------------------------------------
	GESTION MODE SAFE
	------------------------------------------------------------------------*/
	public function safeMode()  untyped {
		fl_safe = true;
	}

	public function normalMode()  untyped {
		fl_safe	= false;
	}


	/*------------------------------------------------------------------------
	RENVOIE TRUE SI LE TRIGGER AFFICHE UNE ALERTE EN CAS DE KEY MANQUANTE
	------------------------------------------------------------------------*/
	public function isVerbose(t:Dynamic)  untyped {
		var fl_verbose:Dynamic = false;
		{ var i:Dynamic=0; while (VERBOSE_TRIGGERS != null && i<VERBOSE_TRIGGERS.length) {
			if (t==VERBOSE_TRIGGERS[i]) {
				fl_verbose = true;
			}
		
i++; } }
		return fl_verbose;
	}


	// *** ACCESSEURS ***/

	/*------------------------------------------------------------------------
	LECTURE D'UN CHAMP TYPÉ D'UNE NODE
	------------------------------------------------------------------------*/
	public function getInt( node:Dynamic, name:Dynamic ) : Int  untyped {
		if ( node?.get(name)==null ) {
			return null;
		}
		else {
			return Math.floor(  MtStd.parseInt( node?.get(name),10 )  );
		}
	}

	public function getFloat( node:Dynamic, name:Dynamic ) : Float  untyped {
		if ( node?.get(name)==null ) {
			return null;
		}
		else {
			return MtStd.parseInt( node?.get(name),10 );
		}
	}

	public function getString( node:Dynamic, name:Dynamic )  untyped {
		if ( node?.get(name)==null ) {
			return null;
		}
		else {
			return node?.get(name);
		}
	}



	// *** GESTION DU SCRIPT ***

	/*------------------------------------------------------------------------
	SCRIPT: AJOUTE UN CODE DE SCRIPT
	------------------------------------------------------------------------*/
	public function addScript(str: String)  untyped {
		if ( fl_compile ) {
			var xml:Dynamic = new MtXml(str);
			if ( xml==null ) {
				GameManager.fatal("invalid XML !");
			}
			else {
				script?.appendChild( xml?.firstChild );
			}
		}
		else {
			extraScript+=" "+str;
		}


		// Debug: trace dans le log
		var node:Dynamic = new MtXml(str).firstChild;
		traceHistory("+"+node?.nodeName);
		node = node?.firstChild;
		while ( node!=null ) {
			traceHistory("  +"+node?.nodeName);
			node = node?.nextSibling;
		}

	}


	public function addNode(name:Dynamic, att:Dynamic, inner:Dynamic)  untyped {
		addScript("<"+name+" "+att+">"+inner+"</"+name+">");
	}


	public function addShortNode(name:Dynamic,att:Dynamic)  untyped {
		addScript("<"+name+" "+att+"/>");
	}


	/*------------------------------------------------------------------------
	SCRIPT: LANCE UN EVENT
	------------------------------------------------------------------------*/
	public function executeEvent( event:MtXmlNode )  untyped {
		if ( event?.nodeName==null ) {
			return;
		}

		traceHistory(" |--"+event?.nodeName);

		{ var __sw:Dynamic = event?.nodeName;
if (__sw == (E_SCORE)) { // score item
				var x:Dynamic = Entity.x_ctr(  getInt(event, "$x")  );
				var y:Dynamic = Entity.y_ctr(  getInt(event, "$y")  );
				x = game?.flipCoordReal(x);
				var id:Dynamic = getInt(event, "$i");
				var subId:Dynamic = getInt(event, "$si");
				var mc:Dynamic = entity.item.ScoreItem.attach(game, x,y, id, subId );
				var inf:Dynamic = getInt(event, "$inf");
				if ( inf==1 ) {
					mc?.setLifeTimer(-1);
				}
				var scriptId:Dynamic = getInt(event, "$sid");
				killById( scriptId );
				{ if (mc != null) mc.scriptId = scriptId; }
			

			}
else if (__sw == (E_SPECIAL)) { // special item
				if ( game?.canAddItem() && !fl_safe ) {
					var x:Dynamic = Entity.x_ctr(  getInt(event, "$x")  );
					x = game?.flipCoordReal(x);
					var y:Dynamic = Entity.y_ctr(  getInt(event, "$y")  );
					var id:Dynamic = getInt(event, "$i");
					var subId:Dynamic = getInt(event, "$si");
					var mc:Dynamic = entity.item.SpecialItem.attach(game, x,y, id, subId );
					var inf:Dynamic = getInt(event, "$inf");
					if ( inf==1 ) {
						mc?.setLifeTimer(-1);
					}
					var scriptId:Dynamic = getInt(event, "$sid");
					killById( scriptId );
					{ if (mc != null) mc.scriptId = scriptId; }
				}
			

			}
else if (__sw == (E_EXTEND)) { // extend
				if ( game?.canAddItem() && !fl_safe ) {
					game?.statsMan?.attachExtend();
				}
			

			}
else if (__sw == (E_BAD)) { do { // bad
				if ( !fl_safe ) { //&& !game.world.isVisited() ) {
					var x:Dynamic = Entity.x_ctr( game?.flipCoordCase( getInt(event, "$x") ) ) - RootData.CASE_WIDTH*0.5;
					var y:Dynamic = Entity.y_ctr( getInt(event, "$y")-1 );
					var id:Dynamic = getInt(event, "$i");
					var fl_sys:Dynamic = ( getInt(event, "$sys")!=0 && getInt(event, "$sys")!=null );
					var mc:Dynamic = game?.attachBad( id, x,y );
					if ( (mc?.types&RootData.BAD_CLEAR)>0 ) {
						if ( fl_sys && game?.world?.isVisited() ) {
							mc?.destroy();
							{ if (game != null) game.badCount--; }
							break;
						}
						else {
							bads++;
							{ if (game != null) game.fl_clear = false; }
						}
					}
					var scriptId:Dynamic = getInt(event, "$sid");
					killById( scriptId );
					{ if (mc != null) mc.scriptId = scriptId; }
				}
			

			} while (false); }
else if (__sw == (E_KILL)) { // kill by id
				var id:Dynamic = getInt(event, "$sid");
				killById(id);
			

			}
else if (__sw == (E_TUTORIAL)) { // message tutorial
				var id:Dynamic = getInt(event, "$id");
				var msg:Dynamic;
				if ( id==null ) {
					msg = event?.firstChild?.nodeValue;
					GameManager.warning("@ level "+game?.world?.currentId+", script still using inline text value");
				}
				else {
					msg = Lang.get(id);
				}
				if ( msg!=null ) {
					game?.attachPop("\n"+msg,true);
				}
			

			}
else if (__sw == (E_MESSAGE)) { // message standard
				var id:Dynamic = getInt(event, "$id");
				var msg:Dynamic;
				if ( id==null ) {
					msg = event?.firstChild?.nodeValue;
					GameManager.warning("@ level "+game?.world?.currentId+", script still using inline text value");
				}
				else {
					msg = Lang.get(id);
				}
				if ( msg!=null ) {
					game?.attachPop("\n"+msg,false);
				}
			

			}
else if (__sw == (E_KILLMSG)) {
				game.killPop();
			

			}
else if (__sw == (E_POINTER)) {
				var p:Dynamic = game?.getOne(RootData.PLAYER);
				var cx:Dynamic = getInt(event, "$x");
				var cy:Dynamic = getInt(event, "$y");
				cx = game?.flipCoordCase(cx);
				game?.attachPointer( cx,cy, p?.cx,p?.cy );
			

			}
else if (__sw == (E_KILLPTR)) {
				game.killPointer();
			

			}
else if (__sw == (E_MC)) {
				var cx:Dynamic = getInt(event, "$x");
				var cy:Dynamic = getInt(event, "$y");
				var xr:Dynamic = getInt(event, "$xr");
				var yr:Dynamic = getInt(event, "$yr");
				var sid:Dynamic = getInt(event, "$sid");
				var back:Dynamic = getInt(event, "$back");
				var name:Dynamic = getString(event, "$n");
				var p:Dynamic = getInt(event, "$p");
				// WARNING: "name" must be "$"-escaped against obfu
				killById(sid);
				var x:Dynamic,y:Dynamic;
				if  ( xr==null ) {
					x = Entity.x_ctr(cx);
					y = Entity.y_ctr(cy);
				}
				else {
					x = xr;
					y = yr;
				}
				x = game?.flipCoordReal(x);
				if ( game?.fl_mirror ) {
					x += RootData.CASE_WIDTH;
				}
				var mc:Dynamic = game?.world?.view?.attachSprite(  name, x, y, (back==1)?true:false );
				if ( game?.fl_mirror ) {
					{ if (mc != null) mc._xscale *= -1; }
				}
				if ( p>0 ) {
					mc?.play();
				}
				else {
					mc?.stop();
				}
				((mc):Dynamic)?.sub?.stop();
				if ( name=="$torch" ) {
					if ( !fl_firstTorch ) {
						game?.clearExtraHoles();
					}
					game?.addHole(x+RootData.CASE_WIDTH*0.5,y-RootData.CASE_HEIGHT*0.5,180);
					game?.updateDarkness();
					fl_firstTorch = true;
				}
				mcList?.push(  {sid:sid, mc:mc}  );
			

			}
else if (__sw == (E_PLAYMC)) {
				var sid:Dynamic = getInt(event,"$sid");
				playById(sid);
			

			}
else if (__sw == (E_MUSIC)) {
				var id:Dynamic = getInt(event, "$id");
				game?.playMusic(id);
			

			}
else if (__sw == (E_ADDTILE)) {
				var cx1:Dynamic	= getInt(event, "$x1");
				var cy1:Dynamic	= getInt(event, "$y1");
				var cx2:Dynamic	= getInt(event, "$x2");
				var cy2:Dynamic	= getInt(event, "$y2");
				cx1 = game?.flipCoordCase(cx1);
				cx2 = game?.flipCoordCase(cx2);
				var id:Dynamic	= getInt(event, "$type");
				if ( id > 0 ) {
					id = -id;
				}
				else {
					id = RootData.GROUND;
				}
				while ( cx1!=cx2 || cy1!=cy2 ) {
					game?.world?.forceCase( cx1,cy1, id );
					if ( cx1 < cx2 )	{ cx1++; }
					if ( cx1 > cx2 )	{ cx1--; }
					if ( cy1 < cy2 )	{ cy1++; }
					if ( cy1 > cy2 )	{ cy1--; }
				}
				game?.world?.forceCase( cx1,cy1, id );
				fl_redraw = true;
			

			}
else if (__sw == (E_REMTILE)) {
				var cx1:Dynamic = getInt(event, "$x1");
				var cy1:Dynamic = getInt(event, "$y1");
				var cx2:Dynamic = getInt(event, "$x2");
				var cy2:Dynamic = getInt(event, "$y2");
				cx1 = game?.flipCoordCase(cx1);
				cx2 = game?.flipCoordCase(cx2);
				while ( cx1!=cx2 || cy1!=cy2 ) {
					game?.world?.forceCase( cx1,cy1, 0 );
					if ( cx1 < cx2 )	{ cx1++; }
					if ( cx1 > cx2 )	{ cx1--; }
					if ( cy1 < cy2 )	{ cy1++; }
					if ( cy1 > cy2 )	{ cy1--; }
				}
				game?.world?.forceCase( cx1,cy1, 0 );
				fl_redraw = true;
			

			}
else if (__sw == (E_ITEMLINE)) {
				var cx1:Dynamic	= getInt(event, "$x1");
				var cx2:Dynamic	= getInt(event, "$x2");
				var cy:Dynamic	= getInt(event, "$y");
				var id:Dynamic	= getInt(event, "$i");
				var subId:Dynamic	= getInt(event, "$si");
				var time:Dynamic	= getInt(event, "$t");
				var i:Dynamic=0;
				var fl_done:Dynamic = false;
				while ( !fl_done ) {
					addScript(
						"<"+T_TIMER+" $t=\""+(cycle+i*time)+"\">"+
						"<"+E_SCORE+" $i=\""+id+"\" $si=\""+subId+"\" $x=\""+cx1+"\" $y=\""+cy+"\" $inf=\"1\" />"+
						"</$"+T_TIMER+">"
					);

					if ( cx1==cx2 ) {
						fl_done = true;
					}
					if ( cx1 < cx2 )	{ cx1++; }
					if ( cx1 > cx2 )	{ cx1--; }
					i++;
				}
			

			}
else if (__sw == (E_GOTO)) {
				var id:Dynamic = getInt(event,"$id");
				game?.forcedGoto(id);
			

			}
else if (__sw == (E_HIDE)) {
				var fl_t:Dynamic = (getInt(event, "$tiles")==1)?true:false;
				var fl_b:Dynamic = (getInt(event, "$borders")==1)?true:false;
				{ if (game?.world?.view != null) game.world.view.fl_hideTiles = fl_t; }
				{ if (game?.world?.view != null) game.world.view.fl_hideBorders = fl_b; }
				game?.world?.view?.detach();
				game?.world?.view?.attach();
				game?.world?.view?.moveToPreviousPos();
			

			}
else if (__sw == (E_HIDEBORDERS)) {
				game.world.view.fl_hideTiles = true;
				game?.world?.view?.detach();
				game?.world?.view?.attach();
				game?.world?.view?.moveToPreviousPos();
			


			}
else if (__sw == (E_CODETRIGGER)) {
				var id:Dynamic = getInt(event,"$id");
				codeTrigger(id);
			


			}
else if (__sw == (E_PORTAL)) {
				if ( game?.fl_clear && cycle>10 ) {
					var pid:Dynamic = getInt(event,"$pid");
					if ( !game?.usePortal(pid, null) ) {
						// do nothing ?
					}
				}
			


			}
else if (__sw == (E_SETVAR)) {
				var name:Dynamic = getString(event,"$var");
				var value:Dynamic = getString(event,"$value");
				game?.setDynamicVar(name,value);
			

			}
else if (__sw == (E_OPENPORTAL)) {
				var cx:Dynamic = getInt(event,"$x");
				var cy:Dynamic = getInt(event,"$y");
				var pid:Dynamic = getInt(event,"$pid");
				game?.openPortal(cx,cy,pid);
			

			}
else if (__sw == (E_DARKNESS)) {
				var v:Dynamic = getInt(event, "$v");
				{ if (game != null) game.forcedDarkness = v; }
				game?.updateDarkness();
			

			}
else if (__sw == (E_FAKELID)) {
				var lid:Dynamic = getInt(event, "$lid");
				if ( MtStd.isNaN(lid) ) {
					{ if (game != null) game.fakeLevelId = null; }
					game?.gi?.hideLevel();
				}
				else {
					{ if (game != null) game.fakeLevelId = lid; }
					game?.gi?.setLevel(lid);
				}
			


			}
else {
				// Event inconnu ? Peut etre un trigger ?
				if ( isTrigger(event?.nodeName) ) {
					script?.appendChild(event);
				}
				else {
					GameManager.warning("unknown event: "+event?.nodeName+" (not a trigger)");
				}
			
		}
}
	}


	/*------------------------------------------------------------------------
	RENVOIE TRUE SI LE NOM DE NODE DONNÉ EST UN TRIGGER
	------------------------------------------------------------------------*/
	public function isTrigger(n:String)  untyped {
		return (n==T_TIMER || n==T_POS || n==T_ATTACH || n==T_DO || n==T_END || n==T_BIRTH || n==T_DEATH ||
				n==T_EXPLODE || n==T_ENTER || n==T_NIGHTMARE || n==T_MIRROR || n==T_MULTI || n==T_NINJA );
	}

	/*------------------------------------------------------------------------
	SCRIPT: TESTE SI UN TRIGGER EST ACTIVÉ
	------------------------------------------------------------------------*/
	public function checkTrigger( trigger:MtXmlNode ) : Bool  untyped {
		if ( trigger?.nodeName==null || trigger?.nodeName=="" ) {
			return false;
		}


		{ var __sw:Dynamic = trigger?.nodeName;
if (__sw == (T_TIMER)) { // timer
				if ( cycle >= getInt(trigger,"$t") ) {
					return true;
				}
			
			}
else if (__sw == (T_POS)) { // player position
				var l:Dynamic = game?.getPlayerList();
				var x:Dynamic = getInt(trigger,"$x");
				var y:Dynamic = getInt(trigger,"$y");
				x = game?.flipCoordCase(x);
				var dist:Dynamic = getInt(trigger,"$d");
				{ var i:Dynamic=0; while (i<l?.length) {
					if ( !l[i]?.fl_kill && !l[i]?.fl_destroy ) {
						var d:Dynamic = l[i]?.distanceCase(x,y);
						if ( d<=dist && !MtStd.isNaN(d) ) {
							return true;
						}
					}
				
i++; } }
			
			}
else if (__sw == (T_ATTACH)) { // attachement du niveau
				if ( fl_onAttach ) {
					return true;
				}
			
			}
else if (__sw == (T_DO)) { // exécution inconditionnelle d'events
				return true;
			
			}
else if (__sw == (T_END)) { // level terminé
				if ( game?.fl_clear && cycle>10 ) {
					return true;
				}
			
			}
else if (__sw == (T_BIRTH)) { // le joueur depuis le dernier cycle
				if ( fl_birth ) {
					return true;
				}
			
			}
else if (__sw == (T_DEATH)) {
				if ( fl_death ) {
					return true;
				}
			
			}
else if (__sw == (T_EXPLODE)) {
				var x:Dynamic = Entity.x_ctr(  getInt(trigger,"$x")  );
				var y:Dynamic = Entity.y_ctr(  getInt(trigger,"$y")  );
				x = game?.flipCoordReal(x);
				{ var i:Dynamic=0; while (i<recentExp?.length) {
					var expl:Dynamic = recentExp[i];
					var sqrDist:Dynamic = Math.pow(x-expl?.x, 2) + Math.pow(y-expl?.y, 2);
					if ( sqrDist <= Math.pow(expl?.r, 2) ) {
						if ( Math.sqrt(sqrDist) <= expl?.r ) {
							return true;
						}
					}
				
i++; } }
			
			}
else if (__sw == (T_ENTER)) {
				var cx:Dynamic = getInt(trigger,"$x");
				var cy:Dynamic = getInt(trigger,"$y");
				cx = game?.flipCoordCase(cx);
				{ var i:Dynamic=0; while (i<entries?.length) {
					if ( entries[i]?.cx==cx && entries[i]?.cy==cy ) {
						return true;
					}
				
i++; } }
			

			}
else if (__sw == (T_NIGHTMARE)) {
				return game?.fl_nightmare;
			

			}
else if (__sw == (T_MIRROR)) {
				return game?.fl_mirror;
			

			}
else if (__sw == (T_MULTI)) {
				return game?.getPlayerList()?.length>1;
			

			}
else if (__sw == (T_NINJA)) {
				return game?.fl_ninja;
			

			}
else {
				GameManager.warning("unknown trigger "+trigger?.nodeName);
			
		}
}
		return false;
	}


	/*------------------------------------------------------------------------
	SCRIPT: LANCE UN TRIGGER
	------------------------------------------------------------------------*/
	public function executeTrigger( trigger:MtXmlNode )  untyped {
		var event:Dynamic;

		traceHistory(trigger?.nodeName);

		event = trigger?.firstChild;
		while (event!=null) {
			executeEvent(event);
			event = event?.nextSibling;
		}


		// Compteur de répétition
		var total:Dynamic = getInt(trigger,"$repeat");
		if ( !MtStd.isNaN(total) ) {
			total--;
			traceHistory("R "+trigger?.nodeName+": "+total);
			trigger?.set("$repeat",""+total);


			if ( total==0 ) {
				// Fin de répétition
				trigger?.removeNode();
			}
			else {
				// Répétition
				if ( trigger?.nodeName==T_TIMER ) {
					var str:Dynamic = trigger?.get("$base");
					if ( str==null ) {
						str = trigger?.get("$t");
						trigger?.set("$base", str);
					}
					var timer:Dynamic = MtStd.parseInt(str,10);
					timer += cycle;
					trigger?.set("$t",""+timer);
				}
			}
		}
		else {
			traceHistory("X "+trigger?.nodeName);
			trigger?.removeNode();
		}


	}


	/*------------------------------------------------------------------------
	INSERTION DE LA BADLIST DANS LE SCRIPT
	------------------------------------------------------------------------*/
	public function insertBads():Int  untyped {
//		if ( game.globalActives[12] ) { // parapluie bleu
//			game.globalActives[12] = false;
//			return 0;
//		}
//		if ( game.globalActives[108] ) { // parapluie vert
//			game.globalActives[108] = false;
//			return 0;
//		}
		var str:Dynamic="<"+T_DO+">";
		{ var i:Dynamic=0; while (i<data?.__S_badList?.length) {
			var b:Dynamic = data?.__S_badList[i];
			str+="<"+E_BAD+" $i=\""+b?.__S_id+"\" $x=\""+b?.__S_x+"\" $y=\""+b?.__S_y+"\" $sys=\"1\"/>";
		
i++; } }
		str+="</"+T_DO+">";
		addScript(str);
		return data?.__S_badList?.length;
	}


	/*------------------------------------------------------------------------
	INSERTION: ITEM
	------------------------------------------------------------------------*/
	public function insertItem(event:String, id:Dynamic,subId:Dynamic, x:Dynamic,y:Dynamic, t:Dynamic, repeat:Dynamic, fl_inf:Dynamic, fl_clearAtEnd:Dynamic)  untyped {
		var subStr:Dynamic;
		if (subId==null) {
			subStr="";
		}
		else {
			subStr=Std.string(subId);
		}

		var doStr:Dynamic = "";
		if (repeat!=null) {
			doStr = " $repeat=\""+repeat+"\"";
		}

		addScript (
			"<"+T_TIMER+" $t=\""+(cycle+t)+"\" "+doStr+" $endClear=\""+(fl_clearAtEnd?"1":"0")+"\">"+
			"<"+event+" $x=\""+x+"\" $y=\""+y+"\" $i=\""+id+"\" $si=\""+subStr+"\" $inf=\""+(fl_inf?"1":"")+"\" $sys=\"1\"/>"+
			"</"+T_TIMER+">"
		);
	}

	/*------------------------------------------------------------------------
	INSERTION: ITEM SPÉCIAL
	------------------------------------------------------------------------*/
	public function insertSpecialItem(id:Dynamic,sid:Dynamic, x:Dynamic,y:Dynamic, t:Dynamic, repeat:Dynamic, fl_inf:Dynamic, fl_clearAtEnd:Dynamic)  untyped {
		insertItem(E_SPECIAL, id,sid,x,y,t,repeat,fl_inf, fl_clearAtEnd);
	}

	/*------------------------------------------------------------------------
	INSERTION: BONUS
	------------------------------------------------------------------------*/
	public function insertScoreItem(id:Dynamic,sid:Dynamic, x:Dynamic,y:Dynamic, t:Dynamic, repeat:Dynamic, fl_inf:Dynamic, fl_clearAtEnd:Dynamic)  untyped {
		insertItem(E_SCORE, id,sid,x,y,t,repeat,fl_inf, fl_clearAtEnd);
	}


	/*------------------------------------------------------------------------
	INSERTION DES EXTENDS RÉGULIERS
	------------------------------------------------------------------------*/
	public function insertExtend()  untyped {
		var s:Dynamic = "<"+T_TIMER+" $t=\""+RootData.EXTEND_TIMER+"\" $repeat=\"-1\" $endClear=\"1\"><"+E_EXTEND+"/></"+T_TIMER+">";
		addScript(s);
	}


	public function insertPortal(cx:Dynamic,cy:Dynamic,pid:Dynamic)  untyped {
		addScript(
			"<"+T_POS+" $x=\""+cx+"\" $y=\""+cy+"\" $d=\"1\" $repeat=\"-1\">"+
			"<"+E_PORTAL+" $pid=\""+pid+"\"/>"+
			"</"+T_POS+">"
		);
	}


	/*------------------------------------------------------------------------
	SCRIPT: EXÉCUTE LE SCRIPT DU NIVEAU
	------------------------------------------------------------------------*/
	public function runScript()  untyped {
		var trigger : MtXmlNode;
		if ( script==null ) {
			return;
		}

		trigger = script?.firstChild;
		while ( trigger!=null ) {
			if ( checkTrigger(trigger) ) {
				// World keys
				var kid:Dynamic = getInt(trigger, "$key");
				if ( !game?.hasKey(kid) ) {
					if ( isVerbose(trigger?.nodeName) ) {
						game?.fxMan?.keyRequired( kid );
					}
				}
				else {
					if ( kid!=null ) {
						game?.fxMan?.keyUsed( kid );
					}
					executeTrigger(trigger);
				}
			}

			trigger = trigger?.nextSibling;
		}
		fl_birth		= false;
		fl_death		= false;
		fl_onAttach		= false;
		recentExp		= new Array();
		entries			= new Array();
		fl_onAttach		= false;
	}


	/*------------------------------------------------------------------------
	CRÉATION DE LA NODE XML DU SCRIPT
	------------------------------------------------------------------------*/
	public function compile()  untyped {
		history = new Array();

		// Debug: log
		traceHistory(baseScript);
		var node:Dynamic = new MtXml(baseScript).firstChild;
		while ( node!=null ) {
			if ( node?.nodeName!=null ) {
				traceHistory("b "+node?.nodeName);
			}
			node = node?.nextSibling;
		}
		node = new MtXml(extraScript).firstChild;
		while ( node!=null ) {
			if ( node?.nodeName!=null ) {
				traceHistory("b2 "+node?.nodeName);
			}
			node = node?.nextSibling;
		}

		// Compilation
		var doc:Dynamic = new MtXml(baseScript+" "+extraScript);
		{ if (doc != null) doc.ignoreWhite = true; }
		if ( doc==null ) {
			GameManager.fatal("compile: invalid XML");
		}
		else {
			this.script = doc;
		}


		normalMode();
		fl_compile	= true;
		traceHistory("first="+cycle);
		runScript(); // lecture du premier cycle du script
	}


	/*------------------------------------------------------------------------
	DÉTRUIT LE SCRIPT "COMPILÉ"
	------------------------------------------------------------------------*/
	public function clearScript()  untyped {
		this.script = null;
		baseScript = "";
		extraScript = "";
		cycle = 0;
		fl_compile = false;
	}


	/*------------------------------------------------------------------------
	DÉTRUIT TOUS LES TRIGGERS TIMÉS
	------------------------------------------------------------------------*/
	public function clearEndTriggers()  untyped {
		var trigger : MtXmlNode;
		trigger = script?.firstChild;
		while (trigger!=null) {
			var next:Dynamic = trigger?.nextSibling;
			if ( trigger?.get("$endClear")== "1" ) {
				traceHistory("eX "+trigger?.nodeName);
				trigger?.removeNode();
			}
			trigger = next;
		}
	}


	/*------------------------------------------------------------------------
	REMISE À ZÉRO (DÉBUT DE LEVEL)
	------------------------------------------------------------------------*/
	public function reset()  untyped {
		cycle=0;
		traceHistory("(r)");
	}


	/*------------------------------------------------------------------------
	DÉTRUIT UNE ENTITÉ CRÉÉE PAR UN SCRIPT
	------------------------------------------------------------------------*/
	public function killById(id:Dynamic)  untyped {
		if ( id==null ) {
			return;
		}
		var l:Dynamic = game?.getList(RootData.ENTITY);
		{ var i:Dynamic=0; while (i<l?.length) {
			if ( l[i]?.scriptId == id ) {
				l[i]?.destroy();
			}
		
i++; } }

		{ var i:Dynamic=0; while (i<mcList?.length) {
			if ( mcList[i]?.sid == id ) {
				mcList[i]?.mc?.removeMovieClip();
				mcList?.splice(i,1);
				i--;
			}
		
i++; } }
	}


	/*------------------------------------------------------------------------
	JOUE UNE ENTITÉ CRÉÉE PAR UN SCRIPT
	------------------------------------------------------------------------*/
	public function playById(id:Dynamic)  untyped {
		if ( id==null ) {
			return;
		}
		{ var i:Dynamic=0; while (i<mcList?.length) {
			if ( mcList[i]?.sid == id ) {
				mcList[i]?.mc?.play();
				((mcList[i]?.mc):Dynamic)?.sub?.play();
			}
		
i++; } }
	}


	/*------------------------------------------------------------------------
	CODES SPÉCIFIQUES NON-SCRIPTABLES
	------------------------------------------------------------------------*/
	public function codeTrigger(id:Dynamic)  untyped {
		{ var __sw:Dynamic = id;
if (__sw == (0)) { // Seau 1er level
				((game):Dynamic).fl_warpStart = true;
			

			}
else if (__sw == (1)) { // long hurry up
				game.huTimer -= Timer.tmod*0.5;
			

			}
else if (__sw == (2)) { // anti fleche de sortie
				game.fxMan.detachExit();
			

			}
else if (__sw == (3)) { // libération des fruits
				playById(101);
				fl_elevatorOpen = true;
				var l:Dynamic = game?.getPlayerList();
				{ var i:Dynamic=0; while (i<l?.length) {
					l[i]?.lockControls(RootData.SECOND*12.5);
					{ if (l[i] != null) l[i].dx = 0; }
				
i++; } }
				{ if (game != null) game.huTimer = 0; }
			

			}
else if (__sw == (4)) { // sortie par l'ascenseur
				if ( fl_elevatorOpen ) {
					var l:Dynamic = game?.getPlayerList();
					{ var i:Dynamic=0; while (i<l?.length) {
						l[i]?.hide();
						l[i]?.lockControls(99999);
						{ if (game != null) game.huTimer = 0; }
					
i++; } }

					{ var i:Dynamic=0; while (i<mcList?.length) {
						if ( mcList[i]?.sid == 101 ) {
							{ if (((mcList[i]?.mc):Dynamic) != null) ((mcList[i]?.mc):Dynamic).head = game?.getPlayerList()[0]?.head; }
						}
					
i++; } }
					playById(101);
					{ if (game != null) game.endModeTimer = RootData.SECOND*14; }
					fl_elevatorOpen = false;
				}
			

			}
else if (__sw == (5)) { // sortie après tuberculoz
				if ( ((game?.getOne(RootData.BOSS)):Dynamic)?.fl_defeated ) {
					bossDoorTimer-=Timer.tmod;
					if ( bossDoorTimer<=0 ) {
						game?.destroyList(RootData.BOSS);
						game?.world?.view?.destroy();
						game?.forcedGoto(102);
					}
				}
			

			}
else if (__sw == (6)) { // attachement de ballons en sur les slots spéciaux
				var s:Dynamic = game?.world?.current?.__S_specialSlots[ MtStd.random(game?.world?.current?.__S_specialSlots?.length) ];
				var b:Dynamic = entity.bomb.player.SoccerBall.attach(
					game,
					Entity.x_ctr(s?.__S_x),
					Entity.y_ctr(s?.__S_y)
				);
				{ if (b != null) b.dx = (10+MtStd.random(10)) * (MtStd.random(2)*2-1); }
				{ if (b != null) b.dy = -MtStd.random(5)-5; }
			

			}
else if (__sw == (7)) { // igor pleure
				var pl:Dynamic = game?.getPlayerList();
				{ var i:Dynamic=0; while (i<pl?.length) {
					pl[i]?.setBaseAnims( RootData.ANIM_PLAYER_WALK, RootData.ANIM_PLAYER_STOP_L );
				
i++; } }
			

			}
else if (__sw == (8)) { // igor est content
				var pl:Dynamic = game?.getPlayerList();
				{ var i:Dynamic=0; while (i<pl?.length) {
					pl[i]?.setBaseAnims( RootData.ANIM_PLAYER_WALK_V, RootData.ANIM_PLAYER_STOP_V );
				
i++; } }
			

			}
else if (__sw == (9)) { // rire tuberculoz
				game.soundMan.playSound("sound_boss_laugh", RootData.CHAN_BAD);
			

			}
else if (__sw == (10)) { // désactive les jump down sur les monstres !
				var l:Dynamic = game?.getBadList();
				{ var i:Dynamic=0; while (i<l?.length) {
					((l[i]):Dynamic)?.setJumpDown(null);
				
i++; } }
			

			}
else if (__sw == (11)) { // tue tous les bads (clear only)
				var l:Dynamic = game?.getBadClearList();
				{ var i:Dynamic=0; while (i<l?.length) {
					var b:Dynamic = l[i];
					game?.fxMan?.attachFx( b?.x, b?.y-RootData.CASE_HEIGHT, "hammer_fx_pop" );
					b?.destroy();
				
i++; } }
			

			}
else if (__sw == (12)) { // force le hurry up (à utiliser avec parcimonie)
				while ( game?.huState<2 ) {
					var mc:Dynamic = game?.onHurryUp();
					if ( game?.huState<2 ) {
						mc?.removeMovieClip();
					}
				}
			

			}
else if (__sw == (13)) { // détruit tous les items (score & special)
				var l:Dynamic = game?.getList(RootData.ITEM);
				{ var i:Dynamic=0; while (i<l?.length) {
					var it:Dynamic = l[i];
					game?.fxMan?.attachFx( it?.x, it?.y-RootData.CASE_HEIGHT, "hammer_fx_pop" );
					it?.destroy();
				
i++; } }
			

			}
else if (__sw == (14)) { // efface les lumières de torches
				game.clearExtraHoles();
			

			}
else if (__sw == (15)) { // reset hurry (dangeureux !)
				game.resetHurry();
			

			}
else {
				GameManager.fatal("code trigger #"+id+" not found!");
			
		}
}
	}


	/*------------------------------------------------------------------------
	BOUCLE PRINCIPALE
	------------------------------------------------------------------------*/
	public function update()  untyped {
		if ( fl_compile ) {
			cycle+=Timer.tmod;
			runScript();
		}

		if ( fl_redraw ) {
			fl_redraw = false;
			game?.world?.view?.detachLevel();
			game?.world?.view?.displayCurrent();
			game?.world?.view?.moveToPreviousPos();
		}
		fl_firstTorch = false;
	}

}

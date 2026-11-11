// Converti automatiquement depuis hammer/entity/Player.mt (Motion Twin)
package entity;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
import Data as RootData;
import entity.PlayerController ;

class Player extends entity.Physics
{
	public var name			: String;

	public var ctrl			: PlayerController ;
	public var specialMan		: SpecialManager ;

	public var baseColor		: Int; // hexa
	public var darkColor		: Int; // hexa

	public var baseWalkAnim	: {id:Int, loop:Bool};
	public var baseStopAnim	: {id:Int, loop:Bool};

	public var speedFactor		: Float ;
	public var fl_lockControls	: Bool ;
	public var fl_entering		: Bool;

	public var score			: Int ;
	public var scoreCS			: Int;

	public var dbg_lastKey		: Int ;
	public var dbg_grid		: Int ;

	public var currentWeapon	: Int ;
	public var maxBombs		: Int ;
	public var initialMaxBombs	: Int;
	public var dir				: Int ;
	public var coolDown		: Float ;
	public var lastBomb		: Int;

	public var lives			: Int;
	public var fl_shield		: Bool;
	public var shieldTimer		: Float;
	public var oxygen			: Float;

	public var fl_knock		: Bool;
	public var knockTimer		: Float;

	public var extendList		: Array<Bool> ;
	public var extendOrder		: Array<Int>;

	public var pid				: Int ;

	public var debugInput		: String ;

	public var shieldMC		: Animation;

	public var startX			: Float ;
	public var extraLifeCurrent: Int;

	public var edgeTimer		: Float;
	public var waitTimer		: Float;

	public var fl_chourou		: Bool;
	public var fl_carot		: Bool;
	public var fl_candle		: Bool;
	public var fl_torch		: Bool;
	public var head			: Int;
	public var defaultHead		: Int;
	public var bounceLimit		: Int;

	public var lockTimer		: Float;

	public var skin			: Int;

	public var recentKicks		: Array< {t:Float, bid:Int} >;





	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new()  untyped {
		super();
		name			= "$Igor".substring(1);

		baseWalkAnim	= RootData.ANIM_PLAYER_WALK;
		baseStopAnim	= RootData.ANIM_PLAYER_STOP;
		score			= 0;
		dir				= 1;
		speedFactor		= 1.0;
		fallFactor		= 1.1;
		extraLifeCurrent= 0;
		fl_teleport		= true;
		fl_portal		= true;
		fl_wind			= true;
		fl_strictGravity= false;
		fl_bump			= true;

		fl_chourou		= false;
		fl_carot		= false;
		fl_candle		= false;
		defaultHead		= RootData.HEAD_NORMAL;
		head			= defaultHead;

		fl_knock		= false;
		knockTimer		= 0;
		bounceLimit		= 2;
		skin			= 1;
		oxygen			= 100;

		recentKicks	= new Array();

		currentWeapon	= RootData.WEAPON_B_CLASSIC;
		lastBomb		= 1;
		initialMaxBombs	= 1;
		if ( GameManager.CONFIG.hasFamily(100) ) {	initialMaxBombs++; }
		maxBombs		= initialMaxBombs;
		coolDown		= 0;
		lives			= 1;
		if ( GameManager.CONFIG.hasFamily(102) ) {	lives++; } // coeur 1
		if ( GameManager.CONFIG.hasFamily(103) ) {	lives++; } // coeur 2
		if ( GameManager.CONFIG.hasFamily(104) ) {	lives++; } // coeur 3
		if ( GameManager.CONFIG.hasFamily(105) ) {	lives++; } // ig'or
		if ( GameManager.CONFIG.hasFamily(108) ) {	lives++; } // carotte

		if ( GameManager.CONFIG.hasFamily(106) ) {	fl_candle = true; }
		if ( GameManager.CONFIG.hasFamily(107) ) {	fl_torch = true; }
		if ( GameManager.CONFIG.hasFamily(108) ) {	fl_carot = true; }

		baseColor		= RootData.BASE_COLORS[0];
		darkColor		= RootData.DARK_COLORS[0];
		fl_lockControls	= false;
		fl_entering		= false;
		extendList		= new Array();
		extendOrder		= new Array();

		pid = 0 ;

		edgeTimer	= 0;
		waitTimer	= 0;

		dbg_grid	= 11;
		debugInput	= "";

	}


	/*------------------------------------------------------------------------
	INITIALISATION
	------------------------------------------------------------------------*/
	override public function init(g:mode.GameMode)  untyped {
		super.init(g) ;
		ctrl = new PlayerController(this) ;
		register(RootData.PLAYER) ;

//		box = downcast(game.depthMan.attach("hammer_interf_player", Data.DP_TOP)) ;
//		box.init(this) ;

		specialMan = new SpecialManager(game, this) ;
		game?.manager?.logAction("$P:"+lives);
	}


	/*------------------------------------------------------------------------
	INITIALISATION: JOUEUR
	------------------------------------------------------------------------*/
	public function initPlayer(g:mode.GameMode,x:Dynamic,y:Dynamic)  untyped {
		init(g) ;
		moveTo(x,y) ;
		if ( game?.fl_nightmare ) {
			speedFactor = 1.3;
		}
		if ( game?._name!="$time" && GameManager.CONFIG.hasOption(RootData.OPT_BOOST) ) { // cadeau quete manettes
			speedFactor = 1.3;
			if ( game?.fl_nightmare ) {
				speedFactor = 1.6;
			}
		}
		endUpdate() ;
	}


	/*------------------------------------------------------------------------
	TOUCHES DE DEBUG
	------------------------------------------------------------------------*/
	public function getDebugControls()  untyped {
		// Dernière touche enfoncée
		if ( dbg_lastKey>0 && !Key.isDown(dbg_lastKey) ) {
			dbg_lastKey = 0 ;
		}


		// Saisie d'un nb sur le pavé num
		{ var i:Dynamic=0; while (i<10) {
			if ( Key.isDown(96+i) && dbg_lastKey!=96+i ) {
				debugInput+=Std.string(i) ;
				dbg_lastKey = 96+i ;
			}
		
i++; } }
		if (debugInput?.length>=3) {
			var n:Dynamic = MtStd.parseInt(debugInput,10) ;
			if ( Key.isDown(Key.CONTROL) ) {
				game?.forcedGoto(n);
			}
			else {
				if ( Key.isDown(Key.ALT) ) {
					entity.item.ScoreItem.attach(game, x+dir*30,y, n,null) ;
				}
				else {
					entity.item.SpecialItem.attach(game, x+dir*30,y, n,null) ;
				}
			}
			debugInput = "" ;
		}
		if ( Key.isDown(Key.BACKSPACE) ) {
			debugInput="" ;
		}

		if ( debugInput?.length>0 ) {
			var str:Dynamic = debugInput ;
			while ( str?.length<3 ) {
				str+="$_".substring(1);
			}
			Log.print("INPUT: "+str) ;
			Log.print("(backspace to clear)");
		}

		// Niveau suivant "n"
		if ( Key.isDown(78) && dbg_lastKey!=78 ) {
			game?.nextLevel() ;
			dbg_lastKey = 78 ;
		}

		// Se pêter de clés "k"
		if ( Key.isDown(75) && dbg_lastKey!=75 ) {
			{ var i:Dynamic=0; while (i<50) {
				game?.giveKey(i);
			
i++; } }
			dbg_lastKey = 75;
		}

		// Spawn d'item "i"
		if ( Key.isDown(73) && dbg_lastKey!=73 ) {
			entity.item.SpecialItem.attach(
				game,
				MtStd.random(200)+200,
				20,
				game?.randMan?.draw(RootData.RAND_ITEMS_ID),
				0
			);
			dbg_lastKey = 73 ;
		}

		// Force les hurry-ups "/"
		if ( Key.isDown(111) && dbg_lastKey!=111 ) {
			{ if (game != null) game.huTimer=9999999 ; }
			{ if (game != null) game.huState++ ; }
			dbg_lastKey = 111;
		}

		// Anger more "+"
		if ( Key.isDown(107) && dbg_lastKey!=107 ) {
			var l:Dynamic = game?.getBadList() ;
			{ var i:Dynamic=0; while (i<l?.length) {
				l[i]?.angerMore() ;
			
i++; } }
			dbg_lastKey = 107 ;
		}

		// Anger more "-"
		if ( Key.isDown(109) && dbg_lastKey!=109 ) {
			var l:Dynamic = game?.getBadList() ;
			{ var i:Dynamic=0; while (i<l?.length) {
				l[i]?.calmDown() ;
			
i++; } }
			dbg_lastKey = 109 ;
		}

		// Affiche une grid de map "g"
		if ( Key.isDown(71) && dbg_lastKey!=71 ) {
			world?.view?.detachGrid() ;
			world?.view?.attachGrid( Math.round(Math.pow(2,dbg_grid)), true ) ;
			GameManager.warning("grid: "+RootData.GRID_NAMES[dbg_grid]);
			dbg_grid++ ;
			if ( RootData.GRID_NAMES[dbg_grid]==null ) {
				dbg_grid = 0;
			}
			dbg_lastKey = 71 ;
		}

		// Change d'arme "w"
		if ( Key.isDown(87) && dbg_lastKey!=87 ) {
			currentWeapon++ ;
			if ( currentWeapon>9 ) {
				currentWeapon=1;
			}
			changeWeapon(currentWeapon) ;
			dbg_lastKey = 87 ;
		}

		// Tue tous les bads "*"
		if ( Key.isDown(106) && dbg_lastKey!=106) {
			var l:Dynamic = game?.getBadList() ;
			{ var i:Dynamic=0; while (i<l?.length) {
				l[i]?.destroy() ;
			
i++; } }
			dbg_lastKey = 106 ;
		}
	}


	/*------------------------------------------------------------------------
	ATTACHEMENT
	------------------------------------------------------------------------*/
	public static function attach(g:mode.GameMode,x:Dynamic,y:Dynamic)  untyped {
		var mc : entity.Player = (( g?.depthMan?.attach("hammer_player",RootData.DP_PLAYER) ):Dynamic) ;
		mc?.initPlayer(g,x,y) ;
		return mc ;
	}


	/*------------------------------------------------------------------------
	CONTACT
	------------------------------------------------------------------------*/
	override public function hit(e:Entity)  untyped {
		if ( (e?.types & RootData.ITEM) > 0 ) {
			var et : entity.Item = ((e):Dynamic) ;
			et?.execute(this);
			if ( et?.id==RootData.CONVERT_DIAMANT ) { // perle
//				if ( specialMan.actives[81] || specialMan.actives[96] || specialMan.actives[97] || specialMan.actives[98] ) {
					specialMan?.onPickPerfectItem();
//				}
			}
		}

	}


	/*------------------------------------------------------------------------
	TUE LE JOUEUR, SI POSSIBLE
	------------------------------------------------------------------------*/
	public function forceKill(dx:Dynamic)  untyped {
		fl_shield = false ;
		killHit(dx) ;
	}


	/*------------------------------------------------------------------------
	MORT
	------------------------------------------------------------------------*/
	override public function killHit(dx:Dynamic)  untyped {
		if ( fl_kill || fl_shield ) {
			return ;
		}

		fl_knock = false;
//		game.fxMan.attachFx(x,y-Data.CASE_HEIGHT,"hammer_fx_shine");
		game?.soundMan?.playSound("sound_player_death", RootData.CHAN_PLAYER);

		// recupère le signe de dx
		var sign:Dynamic = dx/Math.abs(dx);
		if ( MtStd.isNaN(sign) ) {
			sign = MtStd.random(2)*2-1;
		}

		if ( x>=0.85*RootData.GAME_WIDTH ) {
			sign = -1;
		}
		if ( x<=0.15*RootData.GAME_WIDTH ) {
			sign = 1;
		}

		playAnim(RootData.ANIM_PLAYER_DIE) ;

		var power:Dynamic=20;
		if ( Timer.tmod<=0.6 ) {
			power=40;
		}

		super.killHit( sign*power ) ;
	}


	/*------------------------------------------------------------------------
	GAGNE DES POINTS
	------------------------------------------------------------------------*/
	public function getScore(origin:Entity,value:Dynamic)  untyped {
		if ( origin != null ) {
			if ( specialMan?.actives[95] ) { // effet sac à thunes
				game?.fxMan?.attachScorePop( baseColor, darkColor, origin?.x, origin?.y, ""+(value*2) );
			}
			else {
				game?.fxMan?.attachScorePop( baseColor, darkColor, origin?.x, origin?.y, ""+value );
			}
		}
		getScoreHidden(value);
	}

	public function getScoreHidden(value:Dynamic)  untyped {
		if ( specialMan?.actives[95] ) {
			value*=2;
		}
		var step:Dynamic = RootData.EXTRA_LIFE_STEPS[extraLifeCurrent];
		if ( step!=null && score<step && score+value>=step ) {
			lives++;
			game?.gi?.setLives( pid, lives );
			game?.manager?.logAction("$EL"+extraLifeCurrent);
			extraLifeCurrent++;
		}
		if ( score!=0 && scoreCS^GameManager.KEY != score ) {
			game?.manager?.logIllegal("$SCS");
		}
		score+=value;
		scoreCS = score^GameManager.KEY;
		game?.gi?.setScore(pid,score);
	}


	/*------------------------------------------------------------------------
	GAGNE UNE LETTRE EXTEND
	------------------------------------------------------------------------*/
	public function getExtend(id:Dynamic)  untyped {
		if ( extendList[id]!=true ) {
			game?.gi?.getExtend(pid,id);
		}

		// Perfect extend
		if ( !extendList[id] ) {
			extendOrder?.push(id);
		}

		extendList[id] = true ;

		var complete:Dynamic = true ;
		{ var i:Dynamic=0; while (RootData.EXTENDS != null && i<RootData.EXTENDS.length) {
			if ( extendList[i]!=true ) {
				complete = false ;
			}
		
i++; } }

		// Terminé !
		if ( complete ) {
			var fl_perfect:Dynamic = true;
			{ var i:Dynamic=0; while (i<extendOrder?.length) {
				if ( extendOrder[i]!=i ) {
					fl_perfect = false;
				}
			
i++; } }

			game?.gi?.clearExtends(pid);
			extendList = new Array();
			extendOrder = new Array();
			specialMan?.executeExtend(fl_perfect);
		}
	}


	/*------------------------------------------------------------------------
	INFIXE
	------------------------------------------------------------------------*/
	override public function infix()  untyped {
		super.infix() ;

//		if ( fl_stable ) {
//			if ( world.checkFlag( {x:cx,y:cy}, Data.IA_TILE_TOP) ) {
//				downcast(game).tag(Data.TAG_PLAYER,cx,cy) ;
//			}
//		}

		// Changement d'arme
		var id:Dynamic = world?.getCase( {x:cx,y:cy} ) ;
		if ( id>RootData.FIELD_TELEPORT && id < 0 ) {
			if (currentWeapon!=Std.int(Math.abs(id))) {
				var fx:Dynamic = game?.fxMan?.attachShine(x,y-RootData.CASE_HEIGHT*0.5) ;
				{ if (fx?.mc != null) fx.mc._xscale = 65 ; }
				{ if (fx?.mc != null) fx.mc._yscale = fx?.mc?._xscale ; }
				game?.soundMan?.playSound("sound_field", RootData.CHAN_FIELD);
			}
			changeWeapon(Std.int(Math.abs(id))) ;
		}

		// Champ désarmement
		if ( id==RootData.FIELD_PEACE ) {
			if (currentWeapon!=Std.int(Math.abs(id))) {
				var fx:Dynamic = game?.fxMan?.attachShine(x,y-RootData.CASE_HEIGHT*0.5) ;
				{ if (fx?.mc != null) fx.mc._xscale = 65 ; }
				{ if (fx?.mc != null) fx.mc._yscale = fx?.mc?._xscale ; }
				game?.soundMan?.playSound("sound_field", RootData.CHAN_FIELD);
			}
			changeWeapon(RootData.WEAPON_NONE);
		}


		if ( !fl_kill && !fl_destroy ) {
			game?.world?.scriptEngine?.onEnterCase(cx,cy);
		}

		showTeleporters();
	}


	/*------------------------------------------------------------------------
	MORT DU JOUEUR
	------------------------------------------------------------------------*/
	public function killPlayer()  untyped {
		// Strike fx
		game?.fxMan?.attachFx(  x, RootData.GAME_HEIGHT, "hammer_fx_death_player"  );

		game?.statsMan?.inc(RootData.STAT_DEATH,1) ;
		lives-- ;
		game?.gi?.setLives(pid,lives) ;
		if ( lives>=0 ) {
			resurrect() ;
		}
		else {
			// game over: il reste des vies chez un joueur  ?
			var fl_over:Dynamic = true;
			var l:Dynamic = game?.getPlayerList();
			{ var i:Dynamic=0; while (i<l?.length) {
				if ( l[i]?.lives>=0 ) {
					fl_over = false;
				}
			
i++; } }
			if ( !fl_over ) {
				// Partage de vies
				if ( GameManager.CONFIG.hasOption(RootData.OPT_LIFE_SHARING) ) {
					var pl:Dynamic = game?.getPlayerList();
					{ var i:Dynamic=0; while (i<pl?.length) {
						var p:Dynamic = pl[i];
						if ( p?.uniqId!=uniqId && p?.lives>0 ) {
							{ if (p != null) p.lives--; }
							game?.gi?.setLives(p?.pid,p?.lives);
							resurrect();
							return;
						}
					
i++; } }

				}
			}

			var pl:Dynamic = game?.getPlayerList();
			{ var i:Dynamic=0; while (i<pl?.length) {
				game?.registerScore(pl[i]?.pid, pl[i]?.score);
			
i++; } }
			game?.onGameOver();
//			game.fxMan.attachAlert( name+" "+Lang.get(43) );
			destroy() ;
		}
	}


	/*------------------------------------------------------------------------
	RÉSURRECTION
	------------------------------------------------------------------------*/
	override public function resurrect()  untyped {
		super.resurrect() ;
		game?.manager?.logAction("$R"+lives);
		// Joueur
		moveTo( Entity.x_ctr(world?.current?.__S_playerX), Entity.y_ctr(world?.current?.__S_playerY) ) ;
		dx = 0;
		dy = 0;
		shield(null);
		changeWeapon(1);
		oxygen = 100;
		fl_knock = false;

		// Effets actifs
		specialMan?.clearTemp();
		specialMan?.clearPerm();
		specialMan?.clearRec();

		playAnim(RootData.ANIM_PLAYER_RESURRECT);
		stickAnim();
		fl_lockControls = true;

		if ( game?.fl_nightmare ) {
			speedFactor = 1.3;
		}
		if ( game?._name!="$time" && GameManager.CONFIG.hasOption(RootData.OPT_BOOST) ) { // cadeau quete manettes
			speedFactor = 1.3;
			if ( game?.fl_nightmare ) {
				speedFactor = 1.6;
			}
		}

		game?.onResurrect();

	}


	/*------------------------------------------------------------------------
	ACTIVE LE BOUCLIER
	------------------------------------------------------------------------*/
	public function shield(duration:Dynamic)  untyped {
		if (duration==null) {
			duration = RootData.SHIELD_DURATION ;
		}


		shieldMC?.destroy();
		shieldMC = game?.fxMan?.attachFx(x,y,"hammer_player_shield");
		{ if (shieldMC != null) shieldMC.fl_loop = true; }
		shieldMC?.stopBlink();

		shieldTimer			= duration ;
		{ if (shieldMC != null) shieldMC.lifeTimer	= shieldTimer; }
		fl_shield			= true ;
	}


	/*------------------------------------------------------------------------
	RETIRE LE BOUCLIER
	------------------------------------------------------------------------*/
	public function unshield()  untyped {
		fl_shield	= false;
		shieldTimer	= 0;

		onShieldOut();
	}


	/*------------------------------------------------------------------------
	ASSOME LE JOUEUR
	------------------------------------------------------------------------*/
	public function knock(d:Dynamic)  untyped {
		if ( fl_knock ) {
			return;
		}
		fl_lockControls = true;
		fl_knock = true;
		knockTimer = d;
	}


	/*------------------------------------------------------------------------
	AFFICHE/MASQUE LE JOUEUR
	------------------------------------------------------------------------*/
	override public function hide()  untyped {
		super.hide() ;
		{ if (shieldMC?.mc != null) shieldMC.mc._visible = false ; }
	}
	override public function show()  untyped {
		super.show() ;
		{ if (shieldMC?.mc != null) shieldMC.mc._visible = true ; }
	}


	/*------------------------------------------------------------------------
	REDIMENSIONNEMENT
	------------------------------------------------------------------------*/
	override public function scale(n:Dynamic)  untyped {
		super.scale(n);
		_xscale *= dir;
	}


	/*------------------------------------------------------------------------
	DESTRUCTION
	------------------------------------------------------------------------*/
	override public function destroy()  untyped {
		game?.registerScore(pid, score);
		specialMan?.clearPerm() ;
		specialMan?.clearTemp() ;
		specialMan?.clearRec();
		super.destroy() ;
	}


	/*------------------------------------------------------------------------
	AFFICHE UNE "MALÉDICTION" AU DESSUS DU JOUEUR
	------------------------------------------------------------------------*/
	public function curse(id:Dynamic)  untyped {
		var c:Dynamic = game?.depthMan?.attach("curse", RootData.DP_FX);
		{ if (c != null) c._alpha = 70; }
		c?.gotoAndStop(""+id);
		stick(c,0,-RootData.CASE_HEIGHT*2.5);
		setElaStick(0.25);
	}


	/*------------------------------------------------------------------------
	JOUE UNE ANIMATION
	------------------------------------------------------------------------*/
	override public function playAnim( a:Dynamic )  untyped {
		if ( a?.id==baseWalkAnim?.id && speedFactor>1 ) {
			a = RootData.ANIM_PLAYER_RUN;
		}

		if ( a?.id==RootData.ANIM_PLAYER_JUMP_DOWN.id && animId==RootData.ANIM_PLAYER_AIRKICK.id ) {
			return;
		}

		if ( fl_knock ) {
			if ( a?.id!=RootData.ANIM_PLAYER_DIE.id && a?.id!=RootData.ANIM_PLAYER_KNOCK_IN.id ) {
				return;
			}
		}
		if ( animId==RootData.ANIM_PLAYER_KICK.id && a?.id==RootData.ANIM_PLAYER_JUMP_DOWN.id ) {
			return;
		}

		if ( animId==RootData.ANIM_PLAYER_CARROT.id ) {
			return;
		}

		super.playAnim( a );
	}


	/*------------------------------------------------------------------------
	CHANGE LES ANIMS DE DÉPLACEMENT DE BASE (null = pas de changement)
	------------------------------------------------------------------------*/
	public function setBaseAnims( a_walk:Dynamic, a_stop:Dynamic )  untyped {
		var fl_walk:Dynamic = false;
		var fl_stop:Dynamic = false;
		if ( animId == baseWalkAnim?.id ) {
			fl_walk = true;
		}
		if ( animId == baseStopAnim?.id ) {
			fl_stop = true;
		}
		if ( animId==RootData.ANIM_PLAYER_WAIT1.id || animId==RootData.ANIM_PLAYER_WAIT2.id ) {
			fl_stop = true;
		}

		if ( a_walk!=null ) {
			baseWalkAnim = a_walk;
		}
		if ( a_stop!=null ) {
			baseStopAnim = a_stop;
		}

		if ( fl_walk ) {
			playAnim(baseWalkAnim);
		}
		if ( fl_stop ) {
			playAnim(baseStopAnim);
		}
	}


	/*------------------------------------------------------------------------
	AUTORISE L'APPLICATION DU PATCH COLLISION AU SOL (ESCALIERS)
	------------------------------------------------------------------------*/
	override public function needsPatch()  untyped {
		return true;
	}


	/*------------------------------------------------------------------------
	ALLUME LES TÉLÉPORTEURS PROCHES DU JOUEUR
	------------------------------------------------------------------------*/
	public function showTeleporters()  untyped {
		// Téléporteurs
		var tl:Dynamic = world?.teleporterList;

		// Eteind tout
		{ var i:Dynamic=0; while (i<tl?.length) {
			world?.hideField( tl[i] );
		
i++; } }

		// Allume les téléporteurs proches
		{ var i:Dynamic=0; while (i<tl?.length) {
			var td:Dynamic = tl[i];
			var fl_close:Dynamic = false;
			if (td?.dir==RootData.VERTICAL) {
				if (  Math.abs(td?.centerX-x)<=RootData.TELEPORTER_DISTANCE && y>=td?.startY-RootData.CASE_HEIGHT*0.5 && y<=td?.endY+RootData.CASE_HEIGHT*0.5  ) {
					fl_close = true;
				}
			}
			else {
				if (  Math.abs(td?.centerY-y)<=RootData.TELEPORTER_DISTANCE && x>=td?.startX-RootData.CASE_WIDTH && x<=td?.endX+RootData.CASE_WIDTH  ) {
					fl_close = true;
				}
			}

			if ( fl_close ) {
				world?.showField(td);
				var next:Dynamic = world?.getNextTeleporter(td);
				if ( next!=null && !next?.fl_rand ) {
					world?.showField(next?.td);
				}
			}
		
i++; } }
	}


	/*------------------------------------------------------------------------
	VERROUILLAGE DES CONTROLES POUR UNE DURÉE FIXE
	------------------------------------------------------------------------*/
	public function lockControls(d:Dynamic)  untyped {
		lockTimer = d;
		playAnim(baseStopAnim);
		fl_lockControls = true;
	}


	/*------------------------------------------------------------------------
	RENVOIE TRUE SI LA BOMBE A ÉTÉ RÉCEMMENT KICKÉE PAR CE JOUEUR
	------------------------------------------------------------------------*/
	public function isRecentKick(b:entity.Bomb)  untyped {
		var fl_recent:Dynamic = false;
		{ var i:Dynamic=0; while (i<recentKicks?.length) {
			if ( b?.uniqId == recentKicks[i]?.bid ) {
				fl_recent = true;
			}
		
i++; } }
		return fl_recent;
	}



	// *** ARMES

	/*------------------------------------------------------------------------
	POSE UNE BOMBE
	------------------------------------------------------------------------*/
	public function attack():Entity  untyped {
		if ( specialMan?.actives[91] || specialMan?.actives[85] ) { // curse chapeau luffy
			return null;
		}

		{ var __sw:Dynamic = currentWeapon;
if (__sw == (RootData.WEAPON_B_CLASSIC)) { return drop(	entity.bomb.player.Classic.attach(game, x,y ) ) ; 
			}
else if (__sw == (RootData.WEAPON_B_BLACK)) { return drop(	entity.bomb.player.Black.attach(game, x,y ) ) ; 
			}
else if (__sw == (RootData.WEAPON_B_BLUE)) { return drop(	entity.bomb.player.Blue.attach(game, x,y ) ) ; 
			}
else if (__sw == (RootData.WEAPON_B_GREEN)) { return drop(	entity.bomb.player.Green.attach(game, x,y ) ) ; 
			}
else if (__sw == (RootData.WEAPON_B_RED)) { return drop(	entity.bomb.player.Red.attach(game, x,y ) ) ; 
			}
else if (__sw == (RootData.WEAPON_B_REPEL)) { return drop(	entity.bomb.player.RepelBomb.attach(game,x,y) ) ; 

			}
else if (__sw == (RootData.WEAPON_S_ARROW)) { return shoot(	entity.shoot.PlayerArrow.attach(game,x,y) ) ; 
			}
else if (__sw == (RootData.WEAPON_S_FIRE)) { return shoot(	entity.shoot.PlayerFireBall.attach(game,x,y) ) ; 
			}
else if (__sw == (RootData.WEAPON_S_ICE)) { return shoot(	entity.shoot.PlayerPearl.attach(game,x,y) ) ; 

			}
else {
				GameManager.fatal("invalid weapon id : "+currentWeapon) ;
				return null ;
			
		}
}
	}


	/*------------------------------------------------------------------------
	TESTE LE TYPE D'ARME ACTUEL
	------------------------------------------------------------------------*/
	public function isBombWeapon(id:Dynamic)  untyped {
		return
			id == RootData.WEAPON_B_CLASSIC ||
			id == RootData.WEAPON_B_BLACK ||
			id == RootData.WEAPON_B_BLUE ||
			id == RootData.WEAPON_B_GREEN ||
			id == RootData.WEAPON_B_RED ||
			id == RootData.WEAPON_B_REPEL;
	}

	public function isShootWeapon(id:Dynamic)  untyped {
		return
			id == RootData.WEAPON_S_ARROW ||
			id == RootData.WEAPON_S_FIRE ||
			id == RootData.WEAPON_S_ICE;
	}


	/*------------------------------------------------------------------------
	POSE UNE BOMBE
	------------------------------------------------------------------------*/
	public function drop(b:entity.bomb.PlayerBomb)  untyped {
		if ( !fl_stable ) {
			airJump();
		}
		game?.statsMan?.inc(RootData.STAT_BOMB,1) ;
		b?.setOwner(this);
		game?.soundMan?.playSound("sound_bomb_drop",RootData.CHAN_PLAYER);
		if ( !fl_stable ) {
			kickBomb([(cast (b))], 1.0);
		}
//		b.x+=dir*Data.CASE_WIDTH*0.5;
//		if ( dir>0 ) {
////			b.moveToAng(-65,2);
//			b.moveRight(1.5);
//		}
//		else {
////			b.moveToAng(-115,2);
//			b.moveLeft(1.5);
//		}

		return b ;
	}


	/*------------------------------------------------------------------------
	SAUT SECONDAIRE EN L'AIR
	------------------------------------------------------------------------*/
	public function airJump()  untyped {
		playAnim(RootData.ANIM_PLAYER_JUMP_UP);
		if ( dy > 0) { // descendant
			dy=-RootData.PLAYER_AIR_JUMP;
		}
		else { // ascendant
			if ( Math.abs(dy) < RootData.PLAYER_AIR_JUMP ) {
				dy=-RootData.PLAYER_AIR_JUMP;
			}
		}
	}


	/*------------------------------------------------------------------------
	TIR
	------------------------------------------------------------------------*/
	public function shoot(s:entity.Shoot)  untyped {
		game?.statsMan?.inc(RootData.STAT_SHOT,1) ;
		coolDown = s?.coolDown ;
		if (dir<0) {
			s?.moveLeft(s?.shootSpeed) ;
		}
		else {
			s?.moveRight(s?.shootSpeed) ;
		}
		return s ;
	}

	/*------------------------------------------------------------------------
	DÉFINI L'ARME DU JOUEUR
	------------------------------------------------------------------------*/
	public function changeWeapon(id:Dynamic)  untyped {
		if ( id==null ) {
			id = lastBomb;
		}

		// Pas une arme
		if ( id>0 && !isBombWeapon(id) && !isShootWeapon(id) ) {
			return;
		}

		// bombe -> tir
		if ( isBombWeapon(currentWeapon) && !isBombWeapon(id) ) {
			lastBomb = currentWeapon;
		}

		// ? -> bombe
		if ( isBombWeapon(id) ) {
			lastBomb = id;
		}

		currentWeapon = id ;
		replayAnim() ;
	}


	/*------------------------------------------------------------------------
	KICK UNE OU PLUSIEURS BOMBES
	------------------------------------------------------------------------*/
	public function kickBomb(l:Array<entity.Bomb>, powerFactor:Dynamic)  untyped {
		var i:Dynamic=0 ;
		while ( i<l?.length ) {
			var b:Dynamic = l[i] ;
			if ( !isRecentKick(b) ) {
				if (  ( b?.fl_airKick || (!b?.fl_airKick && b?.fl_stable) ) && !b?.fl_explode  )  {
					if ( !b?.isType(RootData.SOCCERBALL) ) {
						{ if (b != null) b.dx = dir * RootData.PLAYER_HKICK_X; }
					}
					else {
						{ if (b != null) b.dx = dir * RootData.PLAYER_HKICK_X * powerFactor; }
					}

					// Escalier Gauche
					if ( dir<0 && world?.checkFlag( {x:cx,y:cy}, RootData.IA_CLIMB_LEFT) ) {
						var h:Dynamic = world?.getWallHeight( cx-1,cy, RootData.IA_CLIMB );
						if ( h<=1 ) {
							b?.moveTo( b?.x, b?.y-RootData.CASE_HEIGHT*0.5 );
						}
					}

					// Escalier Droite
					if ( dir>0 && world?.checkFlag( {x:cx,y:cy}, RootData.IA_CLIMB_RIGHT) ) {
						var h:Dynamic = world?.getWallHeight( cx+1,cy, RootData.IA_CLIMB );
						if ( h<=1 ) {
							b?.moveTo( b?.x, b?.y-RootData.CASE_HEIGHT*0.5 );
						}
					}

					if ( specialMan?.actives[13] ) {
						{ if (b != null) b.dx*=2 ; } // casque de moto
					}
					if ( game?.fl_bombExpert && dx/b?.dx>0 ) {
						{ if (b != null) b.dx*=2.5; }
					}
					if ( specialMan?.actives[115] ) {
						{ if (b != null) b.dx*=1.5; } // casque volley
					}
					{ if (b != null) b.dy = -RootData.PLAYER_HKICK_Y ; }
					b?.onKick(this);
					{ if (b != null) b.next = null; }
					{ if (b != null) b.fl_bounce = true ; }
					recentKicks?.push( {t:game.cycle, bid:b.uniqId} );
	//				if ( fl_stable ) {
						playAnim(RootData.ANIM_PLAYER_KICK);
	//				}
	//				else {
	//					playAnim(Data.ANIM_PLAYER_AIRKICK);
	//				}
					game?.soundMan?.playSound("sound_kick", RootData.CHAN_PLAYER);
					game?.statsMan?.inc(RootData.STAT_KICK,1) ;
					if ( specialMan?.actives[92] ) { // chapeau rose
						if ( b?.lifeTimer>0 ) {
							var b2:Dynamic = b?.duplicate();
							if ( b2?.isType(RootData.PLAYER_BOMB) ) {
								{ if (((b2):Dynamic) != null) ((b2):Dynamic).owner = this; }
							}
							{ if (b2 != null) b2.lifeTimer = b?.lifeTimer ; }
							{ if (b2 != null) b2.dx = -b?.dx ; }
							{ if (b2 != null) b2.dy = b?.dy ; }
							{ if (b2 != null) b2.fl_bounce = true ; }
						}
					}
					if ( specialMan?.actives[70] ) {// effet trefle
						getScore(this, 10) ;
					}
				}
			}
			i++ ;
		}
	}



	/*------------------------------------------------------------------------
	UP KICK
	------------------------------------------------------------------------*/
	public function upKickBomb(l:Array<entity.Bomb>)  untyped {
		var i:Dynamic=0 ;
		while ( i<l?.length ) {
			var b:Dynamic = l[i] ;
			if ( !isRecentKick(b) ) {
				if (  ( b?.fl_airKick || (!b?.fl_airKick && b?.fl_stable) ) && !b?.fl_explode  )  {
					{ if (b != null) b.dx *= 2; }
					if ( Math.abs(b?.dx)<= 1.5 ) {
						{ if (b != null) b.dx = 0.5*dir; }
					}
					{ if (b != null) b.dy = -RootData.PLAYER_VKICK; }
					if ( specialMan?.actives[13] ) {
						{ if (b != null) b.dy*=2 ; } // casque de moto
					}
					if ( specialMan?.actives[115] ) {
						{ if (b != null) b.dy*=2; } // casque volley
						{ if (b != null) b.dx*=1.3; }
					}
					{ if (b != null) b.next = null; }
					b?.onKick(this);
					{ if (b != null) b.fl_stable = false; }
					{ if (b != null) b.fl_bounce = true; }
					recentKicks?.push( {t:game.cycle, bid:b.uniqId} );
					playAnim(RootData.ANIM_PLAYER_KICK);
					game?.soundMan?.playSound("sound_kick", RootData.CHAN_PLAYER);
					game?.statsMan?.inc(RootData.STAT_KICK,1) ;
					if ( specialMan?.actives[70] ) {// effet trefle
						getScore(this, 10) ;
					}
				}
			}
			i++ ;
		}
	}



	/*------------------------------------------------------------------------
	COMPTE LE NOMBRE DE BOMBES POSÉES
	------------------------------------------------------------------------*/
	public function countBombs():Int  untyped {
		var n:Dynamic = 0 ;
		var l:Dynamic = game?.getList(RootData.PLAYER_BOMB) ;
		{ var i:Dynamic=0; while (i<l?.length) {
			if ( !((l[i]):Dynamic)?.fl_explode && l[i]?.parent == this ) {
				n++ ;
			}
		
i++; } }
		return n ;
	}


	// *** EVENTS

	/*------------------------------------------------------------------------
	EVENT: FIN D'ANIM
	------------------------------------------------------------------------*/
	override public function onEndAnim(id:Dynamic)  untyped {
		super.onEndAnim(id) ;

		// Se relève après un knock
		if ( id == RootData.ANIM_PLAYER_KNOCK_OUT.id ) {
			fl_lockControls = false;
			playAnim(baseStopAnim);
		}

		if ( id == RootData.ANIM_PLAYER_AIRKICK.id ) {
			animId = null;
			playAnim(RootData.ANIM_PLAYER_JUMP_DOWN);
		}

		// Resurrection
		if ( id == RootData.ANIM_PLAYER_RESURRECT.id ) {
			fl_lockControls = false;
			playAnim(baseStopAnim);
		}

		// Après un air kick
		if ( id == RootData.ANIM_PLAYER_KICK.id && !fl_stable ) {
			animId = null;
			playAnim(RootData.ANIM_PLAYER_JUMP_DOWN);
			return;
		}

		// Carotte!
		if ( id == RootData.ANIM_PLAYER_CARROT.id ) {
			playAnim(baseStopAnim);
		}

		// Retour en anim normale après kick ou attack
		if ( id == RootData.ANIM_PLAYER_KICK.id ||
			id == RootData.ANIM_PLAYER_ATTACK.id ||
			id == RootData.ANIM_PLAYER_WAIT1.id ||
			id == RootData.ANIM_PLAYER_WAIT2.id ||
			id == RootData.ANIM_PLAYER_JUMP_LAND.id ) {
				playAnim(baseStopAnim) ;
		}
	}


	/*------------------------------------------------------------------------
	EVENT: LIGNE DU BAS ATTEINTE
	------------------------------------------------------------------------*/
	override public function onDeathLine()  untyped {
		super.onDeathLine() ;

		if ( fl_kill ) {
			killPlayer() ;
		}
		else {
			if ( game?.checkLevelClear() ) {
				// Passage au level suivant
				dy = 0 ;
				game?.nextLevel() ;
			}
			else {
				// Mort
				y = RootData.LEVEL_HEIGHT*RootData.CASE_HEIGHT-RootData.CASE_HEIGHT-1 ;
				dx = 0;
				forceKill(0) ;
			}
		}
	}


	/*------------------------------------------------------------------------
	EVENT: FIN DE BOUCLIER
	------------------------------------------------------------------------*/
	public function onShieldOut()  untyped {
		game?.fxMan?.attachFx(x,y,"popShield");
		shieldMC?.destroy();
		checkHits();
	}

	/*------------------------------------------------------------------------
	EVENT: FIN DE KNOCK
	------------------------------------------------------------------------*/
	public function onWakeUp()  untyped {
		fl_knock = false;
		if ( fl_stable ) {
			dx = 0;
			playAnim(RootData.ANIM_PLAYER_KNOCK_OUT);
		}
		else {
			fl_lockControls = false;
			playAnim(RootData.ANIM_PLAYER_JUMP_DOWN);
		}
	}



	/*------------------------------------------------------------------------
	EVENT: TÉLÉPORTATION
	------------------------------------------------------------------------*/
	override public function onTeleport()  untyped {
		super.onTeleport() ;
		dx = 0 ;
		dy = 0 ;
		if ( shieldMC!=null ) {
			{ if (shieldMC?.mc != null) shieldMC.mc._x = x; }
			{ if (shieldMC?.mc != null) shieldMC.mc._y = y; }
		}
	}


	/*------------------------------------------------------------------------
	EVENT: CHANGEMENT DE LEVEL
	------------------------------------------------------------------------*/
	public function onNextLevel()  untyped {
		changeWeapon(1) ;
		if ( fl_shield ) {
			shieldTimer = 1 ;
		}
		specialMan?.clearTemp() ;
		specialMan?.clearRec();
	}


	/*------------------------------------------------------------------------
	EVENT: TOUCHE LE SOL
	------------------------------------------------------------------------*/
	override public function onHitGround(h:Dynamic)  untyped {
		// Effet goldorak
		if ( specialMan?.actives[90] ) {
			if ( !fl_knock && h>=RootData.CASE_HEIGHT*2) {
				knock(RootData.SECOND);
			}
		}

		super.onHitGround(h) ;

		// Hauteur de chute
		if ( h >= RootData.DUST_FALL_HEIGHT ) {
			game?.fxMan?.dust(cx,cy+1);
		}
		game?.fxMan?.attachFx(x,y,"hammer_fx_fall");

		game?.soundMan?.playSound("sound_land",RootData.CHAN_PLAYER);

		// Effet stonehead
		if ( specialMan?.actives[39] ) {
			game?.shake(10,2) ;
			var l:Dynamic = game?.getBadClearList() ;
			{ var i:Dynamic=0; while (i<l?.length) {
				l[i]?.knock(RootData.SECOND) ;
			
i++; } }
		}

		showTeleporters();
	}


	/*------------------------------------------------------------------------
	EVENT: TOUCHE UN MUR
	------------------------------------------------------------------------*/
	override public function onHitWall()  untyped {
		if ( fl_knock ) {
			dx = -dx*0.5;
			// Gros choc
			if ( Math.abs(dx)>=10 && world?.getCase( {x:cx,y:cy} )<=0 ) {
				game?.shake(RootData.SECOND*0.7, 5);
				game?.fxMan?.inGameParticlesDir(RootData.PARTICLE_STONE, x,y, 1+MtStd.random(3), dx);
				game?.fxMan?.inGameParticlesDir(RootData.PARTICLE_CLASSIC_BOMB, x,y, 3+MtStd.random(5), dx);
			}
		}
		else {
			super.onHitWall();
		}
	}


	/*------------------------------------------------------------------------
	EVENT: DÉBUT DE NIVEAU
	------------------------------------------------------------------------*/
	public function onStartLevel()  untyped {
		this.show() ;
		game?.manager?.logAction(world?.currentId+","+Math.floor(score/1000));
		if ( game?.world?.fl_mainWorld ) {
			game?.gi?.setLevel(game?.world?.currentId);
		}
		else {
			if ( game?.fakeLevelId==null ) {
				game?.gi?.hideLevel();
			}
			else {
				game?.gi?.setLevel(game?.fakeLevelId);
			}
		}
		if ( fl_shield && shieldMC==null ) {
			shield(shieldTimer);
		}
		startX = x ;
		fl_entering = true;
	}


	/*------------------------------------------------------------------------
	EVENT: PORTAL WARP
	------------------------------------------------------------------------*/
	override public function onPortal(pid:Dynamic)  untyped {
		super.onPortal(pid);

		if ( !game?.usePortal(pid, this) ) {
			onPortalRefusal();
		}
	}


	/*------------------------------------------------------------------------
	EVENT: PORTAIL FERMÉ
	------------------------------------------------------------------------*/
	override public function onPortalRefusal()  untyped {
		super.onPortalRefusal();
		x = oldX;
		y = oldY;
		dx = -dx;
		knock(RootData.SECOND*0.5);
		game?.fxMan?.inGameParticles( RootData.PARTICLE_PORTAL, x,y, MtStd.random(5)+5 );
		game?.shake(RootData.SECOND,3);
		fl_stopStepping = true;
	}


	override public function onBump()  untyped {
		super.onBump();
		fl_knock = false;
		knock(RootData.SECOND*0.7);
	}



	// *** UPDATES

	/*------------------------------------------------------------------------
	MISE À JOUR GRAPHIQUE
	------------------------------------------------------------------------*/
	override public function endUpdate()  untyped {

		super.endUpdate() ;

		if ( shieldMC!=null ) {
			if ( shieldTimer<=RootData.SECOND*3 ) {
				shieldMC?.blink();
			}
			{ if (shieldMC?.mc != null) shieldMC.mc._x	= shieldMC?.mc?._x + (this.x - shieldMC?.mc?._x)*0.75; }
			{ if (shieldMC?.mc != null) shieldMC.mc._y	= shieldMC?.mc?._y + (this.y-20 - shieldMC?.mc?._y)*0.75; }
		}

		this._xscale = dir*Math.abs(this._xscale) ;
	}


	/*------------------------------------------------------------------------
	MAIN
	------------------------------------------------------------------------*/
	override public function update()  untyped {
		// Gestion des kicks
		{ var i:Dynamic=0; while (i<recentKicks?.length) {

			if ( game?.cycle-recentKicks[i]?.t > 2 ) {
				recentKicks?.splice(i,1);
				i--;
			}
		
i++; } }

		// Poupée Guu
		if ( specialMan?.actives[100] ) {
			game?.fxMan?.inGameParticles( RootData.PARTICLE_RAIN, x + MtStd.random(20)*(MtStd.random(2)*2-1), y-60-MtStd.random(5), MtStd.random(2)+1 );
			scale( Math.min(100, (scaleFactor+0.002*Timer.tmod)*100) );
			if ( scaleFactor<=0.60 ) {
				killHit(null);
				specialMan?.interrupt(100);
			}
		}


		// Oxygène
		if ( !fl_kill && game?.fl_aqua ) {
			oxygen -= Timer.tmod*0.1;
			game?.manager?.progress(oxygen/100);
			if ( oxygen<=0 ) {
				killHit(0);
			}
		}


		// Effets spéciaux d'items
		specialMan?.main() ;

		// Déplacement
		if ( !fl_kill && !fl_lockControls ) {
			if ( !fl_entering && _visible ) {
				ctrl?.update() ;
			}
			if ( pid==0 && game?.manager?.fl_debug ) {
				getDebugControls() ;
			}
		}
		if ( fl_entering ) {
			if ( cy >= 0 ) {
				fl_entering = false;
			}
		}

		// Refroidissement du tir
		if ( coolDown>0 ) {
			coolDown-=Timer.tmod ;
			if ( coolDown<=0 ) {
				coolDown=0 ;
			}
		}

		// Sonné
		if ( fl_knock ) {
			knockTimer-=Timer.tmod;
			if ( knockTimer<=0 ) {
				onWakeUp();
			} else {
				if ( fl_stable && animId!=RootData.ANIM_PLAYER_KNOCK_IN.id ) {
					playAnim(RootData.ANIM_PLAYER_KNOCK_IN);
				}
				if ( !fl_stable && animId!=RootData.ANIM_PLAYER_DIE.id ) {
					playAnim(RootData.ANIM_PLAYER_DIE);
				}
			}
		}


		// Gestion de verrou de contrôles
		if ( fl_lockControls ) {
			if ( fl_stable && animId==baseStopAnim?.id ) {
				fl_lockControls = false;
			}
		}

		if ( lockTimer>0 ) {
			lockTimer-=Timer.tmod;
			if ( lockTimer<=0 ) {
				fl_lockControls = false;
			}
			else {
				fl_lockControls = true;
			}
		}

		// Bouclier
		if ( fl_shield ) {
			shieldTimer-=Timer.tmod;
			if ( shieldTimer<=0 ) {
				unshield();
			}
		}


		// MàJ
		super.update() ;
		updateCoords() ;

		// RaZ des compteurs de glandage
		if ( dx!=0 || dy!=0 ) {
			edgeTimer = 0;
			waitTimer = 0;
		}

		if ( !fl_kill ) {
			// Animation de saut
			if ( !fl_stable && dy>=0 && animId!=RootData.ANIM_PLAYER_JUMP_DOWN.id && !fl_lockControls ) {
				playAnim(RootData.ANIM_PLAYER_JUMP_DOWN);
			}
			if ( animId == RootData.ANIM_PLAYER_JUMP_DOWN.id && fl_stable ) {
				playAnim(RootData.ANIM_PLAYER_JUMP_LAND);
			}

			// Anim d'attente
			if ( animId==RootData.ANIM_PLAYER_STOP.id ) {
				if ( waitTimer<=0 ) {
					waitTimer = RootData.WAIT_TIMER;
				}
				waitTimer-=Timer.tmod;
				if ( waitTimer<=0 ) {
					if ( MtStd.random(20)==0 ) {
						playAnim(RootData.ANIM_PLAYER_WAIT1);
					}
					else {
						playAnim(RootData.ANIM_PLAYER_WAIT2);
					}
				}
			}


			// Anim au bord du vide
			if ( fl_stable && dx==0 ) {
				if ( animId==baseStopAnim?.id ) {
					var pt:Dynamic = Entity.rtc( x+dir*RootData.CASE_WIDTH*0.3, y+RootData.CASE_HEIGHT );
					if (  world?.getCase(pt)<=0  &&  world?.getCase( {x:cx+dir,y:cy} )==0  ) {
						if ( edgeTimer<=0 ) {
							edgeTimer = RootData.EDGE_TIMER;
						}
						edgeTimer-=Timer.tmod;
						if ( edgeTimer<=0 ) {
							playAnim(RootData.ANIM_PLAYER_EDGE);
						}
					}
				}
			}
		}

	}

}



// Converti automatiquement depuis hammer/SpecialManager.mt (Motion Twin)
package;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
class SpecialManager
{

	public var game		: mode.GameMode;
	public var player		: entity.Player;

	public var phoneMC		: Dynamic;
	public var clouds		: Array< Dynamic >;

	public var permList	: Array<Int>;
	public var tempList	: Array< {id:Int,end:Float} >;

	public var actives		: Array<Bool>;

	public var recurring	: Array< {timer:Float, baseTimer:Float, fl_repeat:Bool, func:Void->Void} >;


	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new(g:Dynamic,p:Dynamic)  untyped {
		game = g;
		player = p;

		permList = new Array();
		tempList = new Array();
		actives = new Array();

		recurring = new Array();
		clouds = new Array();
	}


	/*------------------------------------------------------------------------
	ACTIVATION D'UN EFFET PERMANENT
	------------------------------------------------------------------------*/
	public function permanent(id:Dynamic)  untyped {
		if ( actives[id]!=true ) {
			actives[id] = true;
			permList?.push(id);
		}
	}


	/*------------------------------------------------------------------------
	ACTIVATION D'UN EFFET TEMPORAIRE
	------------------------------------------------------------------------*/
	public function temporary(id:Dynamic, duration:Dynamic)  untyped {
		// si null, dure jusqu'à la fin du level en cours
		if ( duration==null ) {
			duration = 99999;
		}

		if ( actives[id]!=true ) {
			actives[id] = true;
			tempList?.push( {id:id,end:game.cycle+duration} );
		}
	}


	/*------------------------------------------------------------------------
	ACTIVATION D'UN EFFET PERMANENT GLOBAL (RARE)
	------------------------------------------------------------------------*/
	public function global(id:Dynamic)  untyped {
		{ if (game != null) game.globalActives[id] = true; }
	}



	/*------------------------------------------------------------------------
	ARRÊTE TOUS LES EFFETS TEMPORAIRES
	------------------------------------------------------------------------*/
	public function clearTemp()  untyped {
		while (tempList?.length>0) {
			interrupt( tempList[0]?.id );
			tempList?.splice(0,1);
		}
	}


	/*------------------------------------------------------------------------
	ARRÊTE TOUS LES PERMANENTS
	------------------------------------------------------------------------*/
	public function clearPerm()  untyped {
		while (permList?.length>0) {
			interrupt( permList[0] );
			permList?.splice(0,1);
		}
	}

	/*------------------------------------------------------------------------
	ARRÊTE TOUS LES EFFETS SPÉCIAUX RÉCURRENTS
	------------------------------------------------------------------------*/
	public function clearRec()  untyped {
		recurring = new Array();
	}


	/*------------------------------------------------------------------------
	AJOUTE UN ÉVÈNEMENT RÉCURRENT
	------------------------------------------------------------------------*/
	public function registerRecurring( func:Dynamic, t:Dynamic, fl_repeat:Dynamic )  untyped {
		recurring?.push( {
			timer:t*1.0,
			baseTimer:t,
			func: func,
			fl_repeat: fl_repeat
		} );
	}

	/*------------------------------------------------------------------------
	SPAWN UN ITEM DONNÉ AU DESSUS DE CHAQUE DALLE DU NIVEAU
	------------------------------------------------------------------------*/
	public function levelConversion(id:Dynamic,sid:Dynamic)  untyped {
		var s:Dynamic = game?.world?.scriptEngine?.script?.toString();
		game?.world?.scriptEngine?.safeMode();
//		game.world.scriptEngine.clearScript();
		game?.killPop();
		var n:Dynamic=0;
		{ var y:Dynamic=0; while (y<Data.LEVEL_HEIGHT) {
			{ var x:Dynamic=0; while (x<Data.LEVEL_WIDTH) {
				if ( game?.world?.checkFlag( {x:x,y:y}, Data.IA_TILE_TOP) ) {
					var t:Dynamic=n*2;
					if ( n<4 ) t=1;
					game?.world?.scriptEngine?.insertScoreItem( id, sid, game?.flipCoordCase(x),y, t, null, true, false);
					n++;
				}
			
x++; } }
		
y++; } }
		{ if (game != null) game.perfectItemCpt = n; }
//		game.world.scriptEngine.compile();
	}


	/*------------------------------------------------------------------------
	EFFETS DES ZODIAQUES
	------------------------------------------------------------------------*/
	public function getZodiac(id:Dynamic)  untyped {
		game?.fxMan?.attachBg(Data.BG_CONSTEL,id,Data.SECOND*4);
		var l:Dynamic = game?.getBadClearList();
		{ var i:Dynamic=0; while (i<l?.length) {
			entity.item.ScoreItem.attach(game, l[i]?.x, l[i]?.y-Data.CASE_HEIGHT*2, 169,0);
		
i++; } }
	}

	/*------------------------------------------------------------------------
	EFFETS DES POTIONS DU ZODIAQUE
	------------------------------------------------------------------------*/
	public function getZodiacPotion(id:Dynamic)  untyped {
		var l:Dynamic = game?.getBadClearList();
		{ var i:Dynamic=0; while (i<l?.length) {
			entity.item.ScoreItem.attach(game, l[i]?.x, l[i]?.y-Data.CASE_HEIGHT*2, 169,0);
		
i++; } }
	}


	/*------------------------------------------------------------------------
	DONNE LE BONUS PERFECT
	------------------------------------------------------------------------*/
	public function onPerfect()  untyped {
		interrupt(81);
		interrupt(96);
		interrupt(97);
		interrupt(98);

		var bonus:Dynamic = 50000;
		var mc : Dynamic;
		mc = ((game.depthMan.attach("hammer_fx_perfect",Data.DP_INTERF)):Dynamic);
		{ if (mc != null) mc._x = Data.GAME_WIDTH*0.5; }
		{ if (mc != null) mc._y = Data.GAME_HEIGHT*0.5; }
		{ if (mc != null) mc.label = Lang.get(11); }
		if ( actives[95] ) { // effet sac à thunes
			{ if (mc != null) mc.bonus = ""+bonus*2; }
		}
		else {
			{ if (mc != null) mc.bonus = ""+bonus; }
		}
		var pl:Dynamic = game?.getPlayerList();
		{ var i:Dynamic=0; while (i<pl?.length) {
			pl[i]?.getScoreHidden(Math.floor(bonus/pl?.length));
		
i++; } }
	}

	/*------------------------------------------------------------------------
	EVENT: RAMASSE UN DIAMANT DE CONVERSION
	------------------------------------------------------------------------*/
	public function onPickPerfectItem()  untyped {
		{ if (game != null) game.perfectItemCpt--; }
		if ( game?.perfectItemCpt<=0 ) {
			onPerfect();
		}
	}


	/*------------------------------------------------------------------------
	TÉLÉPORTATION VERS UN NIVEAU BONUS
	------------------------------------------------------------------------*/
//	function gotoSpecialLevel( did, lid ) {
//		game.destroyList(Data.BAD);
//		var link	= new levels.PortalLink();
//		link.from_did	= did;
//		link.from_lid	= lid;
//		link.from_pid	= 0;
//		link.to_did		= game.currentDim;
//		link.to_lid		= game.world.currentId;
//		link.to_pid		= -1;
//		Data.LINKS.push(link);
//		game.switchDimensionById( did, lid, -1 );
//	}


	/*------------------------------------------------------------------------
	EXÉCUTE L'EFFET D'UN EXTEND
	------------------------------------------------------------------------*/
	public function executeExtend(fl_perfect:Dynamic)  untyped {
		game?.registerMapEvent( Data.EVENT_EXTEND, null );
		game?.manager?.logAction("$ext");
		var a:Dynamic = game?.fxMan?.attachFx(Data.GAME_WIDTH/2,Data.GAME_HEIGHT/2,"extendSequence");
		{ if (a != null) a.lifeTimer = 9999; }
		game?.destroyList(Data.BAD);
		game?.destroyList(Data.BAD_BOMB);
		game?.destroyList(Data.SHOOT);

		{ if (player != null) player.lives++; }
		game?.gi?.setLives(player?.pid, player?.lives);
		if ( fl_perfect ) {
			var mc : Dynamic;
			mc = ((game.depthMan.attach("hammer_fx_perfect",Data.DP_INTERF)):Dynamic);
			{ if (mc != null) mc._x = Data.GAME_WIDTH*0.5; }
			{ if (mc != null) mc._y = Data.GAME_HEIGHT*0.2; }
			{ if (mc != null) mc.label = Lang.get(11); }
			if ( actives[95] ) { // effet sac à thunes
				{ if (mc != null) mc.bonus = "300000"; }
			}
			else {
				{ if (mc != null) mc.bonus = "150000"; }
			}
			player?.getScoreHidden(150000);
		}
	}


	/*------------------------------------------------------------------------
	LANCE UN WARPZONE "+N" LEVEL
	------------------------------------------------------------------------*/
	public function warpZone(w:Dynamic)  untyped {
		var arrival:Dynamic = game?.world?.currentId+w;
		game?.manager?.logAction("$WZ>"+arrival);
		var i:Dynamic = game?.world?.currentId+1;
		while (i<=arrival) {
			if ( game?.isBossLevel(i) ) {
				arrival = i;
			}
			if ( game?.world?.isEmptyLevel(i,game) ) {
				arrival = i-1;
			}
			i++;
		}

		// téléportation impossible
		if ( arrival==game?.world?.currentId ) {
			game?.fxMan?.attachAlert( Lang.get(34) );
			return;
		}

		game?.world?.view?.detach();
		game?.forcedGoto( arrival );
	}


	/*------------------------------------------------------------------------
	EXÉCUTE UN ITEM SPÉCIAL
	------------------------------------------------------------------------*/
	public function execute(item:entity.item.SpecialItem)  untyped {
		var id:Dynamic = item?.id;
		var subId:Dynamic = item?.subId;
		var auto:Dynamic = 0;

		{ var __sw:Dynamic = id;
if (__sw == (auto++)) {
				if (actives[27]) {
					player?.getScore(item,25);
				}
				player?.getScoreHidden(5);
				player?.getExtend(subId);
			

			// *** 1. shield or
			}
else if (__sw == (auto++)) {
				player.shield(Data.SECOND*10);
			

			// *** 2. shield argent
			}
else if (__sw == (auto++)) {
				player.shield(Data.SECOND*60);
			

			// *** 3. ballon de plage
			}
else if (__sw == (auto++)) {
				entity.supa.Ball.attach(game);
			

			// *** 4. lampe or: multi bombes (2)
			}
else if (__sw == (auto++)) {
				if ( !actives[5] ) {
					{ if (player != null) player.maxBombs = player?.initialMaxBombs+1; }
					permanent(id);
				}
			

			// *** 5. lampe noire: multi bombes (5)
			}
else if (__sw == (auto++)) {
				player.maxBombs = player?.initialMaxBombs+4;
				permanent(id);
			

			// *** 6. yin yang: freeze all
			}
else if (__sw == (auto++)) {
				var l:Dynamic = game?.getBadClearList();
				{ var i:Dynamic=0; while (i<l?.length) {
					l[i]?.freeze(Data.FREEZE_DURATION*2);
				
i++; } }
			

			// *** 7. chaussure: speed up player
			}
else if (__sw == (auto++)) {
				player.speedFactor = 1.5;
				permanent(id);
			

			// *** 8. étoile: supa bubble
			}
else if (__sw == (auto++)) {
				entity.supa.Bubble.attach(game);
				entity.supa.Bubble.attach(game);
			

			// *** 9. oeil sauron: supa poids
			}
else if (__sw == (auto++)) {
				entity.supa.Tons.attach(game);
			

			// *** 10. téléphone: effet nokia
			}
else if (__sw == (auto++)) {
//				phoneMC.removeMovieClip();
//				phoneMC = downcast( game.depthMan.attach("hammer_fx_phone", Data.DP_TOP) );
//				phoneMC._x -= game.xOffset;
//				phoneMC.screen.blendMode = BlendMode.HARDLIGHT;
//				phoneMC.lines._visible = GameManager.CONFIG.fl_detail;
//				temporary(id, null);
			

			// *** 11. Parapluie rouge: next level
			}
else if (__sw == (auto++)) {
				warpZone(1);
			

			// *** 12. Parapluie bleu: next level x 2
			}
else if (__sw == (auto++)) {
				warpZone(2);
			

			// *** 13. Casque de moto: kicke les bombes plus loin
			}
else if (__sw == (auto++)) {
				permanent(id);
			

			// *** 14. champignon bleu
			}
else if (__sw == (auto++)) {
				permanent(id);
				interrupt(15);
				interrupt(16);
				interrupt(17);
			

			// *** 15. champignon rouge
			}
else if (__sw == (auto++)) {
				permanent(id);
				interrupt(14);
				interrupt(16);
				interrupt(17);
			

			// *** 16. champignon vert
			}
else if (__sw == (auto++)) {
				permanent(id);
				interrupt(14);
				interrupt(15);
				interrupt(17);
			

			// *** 17. champignon or
			}
else if (__sw == (auto++)) {
				permanent(id);
				interrupt(14);
				interrupt(15);
				interrupt(16);
			

			// *** 18. pissenlit: chute lente
			}
else if (__sw == (auto++)) {
				permanent(id);
				{ if (player != null) player.fallFactor = 0.55; }
			

			// *** 19. tournesol
			}
else if (__sw == (auto++)) {
				entity.supa.Smoke.attach(game);
				var l:Dynamic = game?.getBadClearList();
				game?.fxMan?.attachBg(Data.BG_ORANGE,null,Data.SECOND*3);
				{ var i:Dynamic=0; while (i<l?.length) {
					l[i]?.forceKill(null);
				
i++; } }
			

			// *** 20. coffre trésor
			}
else if (__sw == (auto++)) {
				{ var i:Dynamic=0; while (i<5) {
					var s:Dynamic = entity.item.ScoreItem.attach(game,item?.x,item?.y,0,MtStd.random(4));
					s?.moveFrom(item,8);
				
i++; } }
			

			// *** 21. enceinte
			}
else if (__sw == (auto++)) {
				var bad : entity.Bad = ((game.getOne(Data.BAD_CLEAR)):Dynamic);
				if (bad!=null) {
					game?.fxMan?.attachFx( bad?.x, bad?.y-Data.CASE_HEIGHT, "hammer_fx_pop" );
					bad?.forceKill(null);
					game?.fxMan?.attachBg(Data.BG_SINGER,null,Data.SECOND*3);
				}
			

			// *** 22. chaussure pourrie
			}
else if (__sw == (auto++)) {
				interrupt(7);
				player?.curse(Data.CURSE_SLOW);
				{ if (player != null) player.speedFactor = 0.6; }
				temporary(id,Data.SECOND*40);
			

			// *** 23. boule de cristal
			}
else if (__sw == (auto++)) {
				var l:Dynamic = game?.getBadClearList();
				{ var i:Dynamic=0; while (i<l?.length) {
					var b:Dynamic = l[i];
					var s:Dynamic = entity.shoot.PlayerPearl.attach(game, player?.x, player?.y-Data.CASE_WIDTH);
					s?.moveToTarget( l[i], s?.shootSpeed );
					{ if (s != null) s.fl_borderBounce = true; }
					s?.setLifeTimer( Data.SECOND*3 + MtStd.random(400)/10 );
					{ if (s != null) s._yOffset = 0; }
					s?.endUpdate();
				
i++; } }
			

			// *** 24. cristal de neige
			}
else if (__sw == (auto++)) {
				entity.supa.IceMeteor.attach(game);
			

			// *** 25. flamme de glace: rideau de fireballs
			}
else if (__sw == (auto++)) {
				var s:Dynamic;
				{ var i:Dynamic=0; while (i<4) {
					s = entity.shoot.PlayerFireBall.attach(game, Data.GAME_WIDTH*0.125+Data.GAME_WIDTH*0.25*i, 10);
					s?.moveDown( s?.shootSpeed );
				
i++; } }
				{ var i:Dynamic=0; while (i<4) {
					s = entity.shoot.PlayerFireBall.attach(game, Data.GAME_WIDTH*0.25+Data.GAME_WIDTH*0.25*i, Data.GAME_HEIGHT-10);
					s?.moveUp( s?.shootSpeed );
				
i++; } }
			

			// *** 26. ampoule
			}
else if (__sw == (auto++)) {
				permanent(id);
				game?.updateDarkness();
			

			// *** 27. nenuphar: points pour les extends
			}
else if (__sw == (auto++)) {
				permanent(id);
			

			// *** 28. coupe en argent
			}
else if (__sw == (auto++)) {
				game.fxMan.attachBg(Data.BG_STAR,null,Data.SECOND*9);
				var l:Dynamic = game?.getBadClearList();
				{ var i:Dynamic=0; while (i<l?.length) {
					l[i]?.knock(Data.SECOND*10);
				
i++; } }
			

			// *** 29. bague or: tir fireball
			}
else if (__sw == (auto++)) {
				player.changeWeapon(Data.WEAPON_S_FIRE);
				temporary(id, Data.WEAPON_DURATION);
			

			// *** 30. lunettes bleues
			}
else if (__sw == (auto++)) {
				game.flipX(true);
				temporary(id,Data.SECOND*30);
			

			// *** 31. lunettes rouges
			}
else if (__sw == (auto++)) {
				game.flipY(true);
				temporary(id,Data.SECOND*30);
			

			// *** 32. as pique: transforme tous les bads en cristaux
			}
else if (__sw == (auto++)) {
				var l:Dynamic = game?.getBadClearList();
				{ var i:Dynamic=0; while (i<l?.length) {
					l[i]?.destroy();
					entity.item.ScoreItem.attach(game,l[i]?.x,l[i]?.y-Data.CASE_HEIGHT,0,0);
				
i++; } }
			

			// *** 33. as trefle
			}
else if (__sw == (auto++)) {
				var l:Dynamic = game?.getBadClearList();
				{ var i:Dynamic=0; while (i<l?.length) {
					l[i]?.destroy();
					entity.item.ScoreItem.attach(game,l[i]?.x,l[i]?.y-Data.CASE_HEIGHT,0,2);
				
i++; } }
			

			// *** 34. as carreau
			}
else if (__sw == (auto++)) {
				var l:Dynamic = game?.getBadClearList();
				{ var i:Dynamic=0; while (i<l?.length) {
					l[i]?.destroy();
					entity.item.ScoreItem.attach(game,l[i]?.x,l[i]?.y-Data.CASE_HEIGHT,0,5);
				
i++; } }
			

			// *** 35. as coeur
			}
else if (__sw == (auto++)) {
				var l:Dynamic = game?.getBadClearList();
				{ var i:Dynamic=0; while (i<l?.length) {
					l[i]?.destroy();
					entity.item.ScoreItem.attach(game,l[i]?.x-Data.CASE_WIDTH,l[i]?.y-Data.CASE_HEIGHT,0,6);
					entity.item.ScoreItem.attach(game,l[i]?.x+Data.CASE_WIDTH,l[i]?.y-Data.CASE_HEIGHT,0,6);
				
i++; } }
			

			// *** 36. Igor supplémentaire
			}
else if (__sw == (auto++)) {
				player.lives++;
				game?.gi?.setLives(player?.pid, player?.lives);
				game?.fxMan?.attachShine( item?.x, item?.y-Data.CASE_HEIGHT*0.5 );
			

			// *** 37. collier cristal: tir de perles
			}
else if (__sw == (auto++)) {
				player.changeWeapon(Data.WEAPON_S_ICE);
				temporary(id, Data.WEAPON_DURATION);
			

			// *** 38. totem
			}
else if (__sw == (auto++)) {
				var s:Dynamic = entity.supa.Arrow.attach(game);
				s?.setLifeTimer(Data.SUPA_DURATION);
			

			// *** 39. stone head: Igor  fait trembler le décor en tombant
			}
else if (__sw == (auto++)) {
				player.fallFactor = 1.6;
				temporary(id,null);
			

			// *** 40-51. signes du zodiac
			}
else if (__sw == (auto++)) {  getZodiac(id-40) ;  // sagittaire
			}
else if (__sw == (auto++)) {  getZodiac(id-40) ;  // capricorne
			}
else if (__sw == (auto++)) {  getZodiac(id-40) ;  // lion
			}
else if (__sw == (auto++)) {  getZodiac(id-40) ;  // taureau
			}
else if (__sw == (auto++)) {  getZodiac(id-40) ;  // balance
			}
else if (__sw == (auto++)) {  getZodiac(id-40) ;  // belier
			}
else if (__sw == (auto++)) {  getZodiac(id-40) ;  // scorpion
			}
else if (__sw == (auto++)) {  getZodiac(id-40) ;  // cancer
			}
else if (__sw == (auto++)) {  getZodiac(id-40) ;  // verseau
			}
else if (__sw == (auto++)) {  getZodiac(id-40) ;  // gemeau
			}
else if (__sw == (auto++)) {  getZodiac(id-40) ;  // poisson
			}
else if (__sw == (auto++)) {  getZodiac(id-40) ;  // vierge

			// *** 52-63. potions du zodiac
			}
else if (__sw == (auto++)) {  getZodiacPotion(id-40) ;  // sagittaire
			}
else if (__sw == (auto++)) {  getZodiacPotion(id-40) ;  // capricorne
			}
else if (__sw == (auto++)) {  getZodiacPotion(id-40) ;  // lion
			}
else if (__sw == (auto++)) {  getZodiacPotion(id-40) ;  // taureau
			}
else if (__sw == (auto++)) {  getZodiacPotion(id-40) ;  // balance
			}
else if (__sw == (auto++)) {  getZodiacPotion(id-40) ;  // belier
			}
else if (__sw == (auto++)) {  getZodiacPotion(id-40) ;  // scorpion
			}
else if (__sw == (auto++)) {  getZodiacPotion(id-40) ;  // cancer
			}
else if (__sw == (auto++)) {  getZodiacPotion(id-40) ;  // verseau
			}
else if (__sw == (auto++)) {  getZodiacPotion(id-40) ;  // gemeau
			}
else if (__sw == (auto++)) {  getZodiacPotion(id-40) ;  // poisson
			}
else if (__sw == (auto++)) {  getZodiacPotion(id-40) ;  // vierge

			// *** 64. arc en ciel: spawn d'extends
			}
else if (__sw == (auto++)) {
				{ var i:Dynamic=0; while (i<5) {
					var pt:Dynamic = {
						x	: MtStd.random(Data.LEVEL_WIDTH),
						y	: MtStd.random(Data.LEVEL_HEIGHT),
					}
					pt = game?.world?.getGround(pt?.x,pt?.y);
					var s:Dynamic = entity.item.SpecialItem.attach( game, pt?.x*Data.CASE_WIDTH,pt?.y*Data.CASE_HEIGHT, 0, MtStd.random(7) );
				
i++; } }
			

			// *** 65. bouée canard: points pour chaque bad
			}
else if (__sw == (auto++)) {
				var l:Dynamic = game?.getBadList();
				{ var i:Dynamic=0; while (i<l?.length) {
					if ( (l[i]?.types&Data.BAD_CLEAR)>0 ) {
						player?.getScore( l[i], 2500 );
					}
					else {
						player?.getScore( l[i], 600 );
					}

				
i++; } }
			

			// *** 66. cactus: saut donnant des points
			}
else if (__sw == (auto++)) {
				permanent(id);
			

			// *** 67. bague emeraude: tir fleches
			}
else if (__sw == (auto++)) {
				player.changeWeapon(Data.WEAPON_S_ARROW);
				temporary(id, Data.WEAPON_DURATION);
			

			// *** 68. bougie
			}
else if (__sw == (auto++)) {
				permanent(id);
				game?.updateDarkness();
			

			// *** 69. tortue: ralentissement bads
			}
else if (__sw == (auto++)) {
				global(id);
				temporary(id,Data.SECOND*30);
				var l:Dynamic = game?.getBadClearList();
				{ var i:Dynamic=0; while (i<l?.length) {
					l[i]?.updateSpeed();
					{ if (l[i] != null) l[i].animFactor*=0.6; }
				
i++; } }
			

			// *** 70. trefle: kick de bombe donnant des points
			}
else if (__sw == (auto++)) {
				permanent(id);
			

			// *** 71. tete dragon: double fireball horizontale
			}
else if (__sw == (auto++)) {
				var s:Dynamic;
				s = entity.shoot.PlayerFireBall.attach(game, item?.x, item?.y);
				s?.moveLeft( s?.shootSpeed );
				s = entity.shoot.PlayerFireBall.attach(game, item?.x, item?.y);
				s?.moveRight( s?.shootSpeed );
			

			// *** 72. chapeau magicien: remplace les bads par des cristaux (valeur incrémentale)
			}
else if (__sw == (auto++)) {
				game.destroyList(Data.ITEM);
				game?.destroyList(Data.BAD_BOMB);

				var l:Dynamic = game?.getList(Data.BAD_CLEAR);
				var n:Dynamic = 1;
				{ var i:Dynamic=0; while (i<l?.length) {
					var b : entity.Bad = ((l[i]):Dynamic);
					entity.item.ScoreItem.attach(game, b?.x,b?.y, 0, n);
					b?.destroy();
					n++;
				
i++; } }
			

			// *** 73. feuille d'arbre: points gagnés en marchant
			}
else if (__sw == (auto++)) {
				permanent(id);
			

			// *** 74. fantome orange: spawn bonbons
			}
else if (__sw == (auto++)) {
				{ var i:Dynamic=0; while (i<7) {
					var it:Dynamic = entity.item.ScoreItem.attach(
						game,MtStd.random(Data.GAME_WIDTH), Data.GAME_HEIGHT,
						3, null
					);
					it?.moveToAng(-20-MtStd.random(160),MtStd.random(15)+10);
				
i++; } }
			

			// *** 75. fantome bleu
			}
else if (__sw == (auto++)) {
				{ var i:Dynamic=0; while (i<7) {
					var it:Dynamic = entity.item.ScoreItem.attach(
						game,MtStd.random(Data.GAME_WIDTH), Data.GAME_HEIGHT,
						4, null
					);
					it?.moveToAng(-20-MtStd.random(160),MtStd.random(15)+10);
				
i++; } }
			

			// *** 76. fantome vert
			}
else if (__sw == (auto++)) {
				{ var i:Dynamic=0; while (i<7) {
					var it:Dynamic = entity.item.ScoreItem.attach(
						game,MtStd.random(Data.GAME_WIDTH), Data.GAME_HEIGHT,
						5, null
					);
					it?.moveToAng(-20-MtStd.random(160),MtStd.random(15)+10);
				
i++; } }
			

			// *** 77. poisson bleu: cristaux bleus à la fin du level
			}
else if (__sw == (auto++)) {
				var me:Dynamic = game;
				game?.endLevelStack?.push(
				function() {
					{ var i:Dynamic=0; while (i<5) {
						entity.item.ScoreItem.attach(me, MtStd.random(Data.GAME_WIDTH),-30-MtStd.random(50), 0,0);
					
i++; } }
				}
				);
			

			// *** 78. poisson rouge
			}
else if (__sw == (auto++)) {
				var me:Dynamic = game;
				game?.endLevelStack?.push(
				function() {
					{ var i:Dynamic=0; while (i<5) {
						entity.item.ScoreItem.attach(me, MtStd.random(Data.GAME_WIDTH),-30-MtStd.random(50), 0,2);
					
i++; } }
				}
				);
			

			// *** 79. poisson jaune
			}
else if (__sw == (auto++)) {
				var me:Dynamic = game;
				game?.endLevelStack?.push(
				function() {
					{ var i:Dynamic=0; while (i<5) {
						entity.item.ScoreItem.attach(me, MtStd.random(Data.GAME_WIDTH),-30-MtStd.random(50), 0,3);
					
i++; } }
				}
				);
			

			// *** 80. escargot: ralentissement bads
			}
else if (__sw == (auto++)) {
				global(id);
				temporary(id,Data.SECOND*30);
				var l:Dynamic = game?.getBadClearList();
				{ var i:Dynamic=0; while (i<l?.length) {
					l[i]?.updateSpeed();
					{ if (l[i] != null) l[i].animFactor*=0.3; }
				
i++; } }
			

			// *** 81. perle bleue
			}
else if (__sw == (auto++)) {
				game.destroyList(Data.BAD);
				game?.destroyList(Data.ITEM);
				game?.destroyList(Data.BAD_BOMB);
				levelConversion(Data.CONVERT_DIAMANT,0);
				temporary(id, Data.SECOND*19);
			

			// *** 82. pyramide dorée: strike
			}
else if (__sw == (auto++)) {
				onStrike();
			

			// *** 83. pyramide noire: suite de strikes
			}
else if (__sw == (auto++)) {
				temporary(id,null);
				registerRecurring( (this).onStrike, Data.SECOND, true );
				onStrike();
				game?.fxMan?.attachBg(Data.BG_PYRAMID,null,9999);
			

			// *** 84. talisman pluie de feu
			}
else if (__sw == (auto++)) {
				var c : Dynamic;
				c = (( game.depthMan.attach("hammer_fx_clouds", Data.DP_SPRITE_BACK_LAYER) ):Dynamic);
				{ if (c != null) c.speed	= 0.5; }
				{ if (c != null) c._y		+= 9; }
				clouds?.push(c);
				var f:Dynamic = new mtflash.filters.BlurFilter();
				{ if (f != null) f.blurX		= 4; }
				{ if (f != null) f.blurY		= f?.blurX; }
				{ if (c != null) c.filters = [f]; }
				c = (( game.depthMan.attach("hammer_fx_clouds", Data.DP_SPRITE_TOP_LAYER) ):Dynamic);
				{ if (c != null) c.speed	= 1; }
				clouds?.push(c);
				temporary(id,null);
				registerRecurring( (this).onFireRain, Data.SECOND*0.8, true );
				onFireRain();
				game?.fxMan?.attachBg(Data.BG_STORM,null,9999);
			

			// *** 85. marteau
			}
else if (__sw == (auto++)) {
				var s:Dynamic = entity.shoot.Hammer.attach(game,player?.x,player?.y);
				s?.setOwner(player);
				temporary(id,null);
			

			// *** 86. bonbon fantome: mode ghostbuster, chaque bad donne 666pts
			}
else if (__sw == (auto++)) {
				var glow:Dynamic = new mtflash.filters.GlowFilter();
				{ if (glow != null) glow.color		= 0x8cc0ff; }
				{ if (glow != null) glow.alpha		= 0.5; }
				{ if (glow != null) glow.strength	= 100; }
				{ if (glow != null) glow.blurX		= 2; }
				{ if (glow != null) glow.blurY		= 2; }
				{ if (player != null) player.filters = [glow]; }
				temporary(id,Data.SECOND*60);
//				global(id);
				game?.fxMan?.attachBg(Data.BG_GHOSTS,null,Data.SECOND*57);
				var l:Dynamic = game?.getBadList();
				{ var i:Dynamic=0; while (i<l?.length) {
					{ if (glow != null) glow.alpha		= 1.0; }
					{ if (glow != null) glow.color		= 0xff5500; }
					{ if (l[i] != null) l[i].filters	= [glow]; }
				
i++; } }
			

			// *** 87. larve bleue: transforme un bad au hasard en larve bleue
			}
else if (__sw == (auto++)) {
				var bad:Dynamic = game?.getOne(Data.BAD_CLEAR);
				if ( bad!=null ) {
					if ( game?.getBadClearList()?.length==1 ) {
						entity.item.ScoreItem.attach(game, bad?.x,bad?.y, Data.DIAMANT,null);
					}
					else {
						entity.item.SpecialItem.attach(game, bad?.x,bad?.y, id,subId);
					}
					game?.fxMan?.attachShine( bad?.x, bad?.y-Data.CASE_HEIGHT*0.5 );
					bad?.destroy();
				}
			

			// *** 88. pokute: curse retrecissement
			}
else if (__sw == (auto++)) {
				player.curse(Data.CURSE_SHRINK);
				game?.fxMan?.attachShine(player?.x, player?.y);
				player?.scale(50);
				temporary(id,Data.SECOND*30);
			

			// *** 89. oeuf mutant: transforme un bad en une tzongre
			}
else if (__sw == (auto++)) {
				var e:Dynamic = game?.getOne(Data.BAD_CLEAR);
				if ( e!=null ) {
					entity.bad.flyer.Tzongre.attach(game,e?.x,e?.y-Data.CASE_HEIGHT);
					e?.destroy();
				}
			

			// *** 90. cornes goldorak: trébuche à la moindre chute
			}
else if (__sw == (auto++)) {
				temporary(id,Data.SECOND*40);
				player?.curse(6);
			

			// *** 91. chapeau luffy: curse anti attaque
			}
else if (__sw == (auto++)) {
				player.curse(Data.CURSE_PEACE);
				game?.fxMan?.attachShine(player?.x, player?.y);
				temporary(id,Data.SECOND*15);
			

			// *** 92. chapeau rose: duplicateur bombes
			}
else if (__sw == (auto++)) {
				permanent(id);
			

			// *** 93. mailbox: spawn de colis
			}
else if (__sw == (auto++)) {
				game.destroyList(Data.BAD);
				game?.destroyList(Data.ITEM);
				game?.destroyList(Data.BAD_BOMB);
				var n:Dynamic=6;
				do {
					var pt:Dynamic = {
						x:MtStd.random(Data.GAME_WIDTH),
						y:MtStd.random(Data.GAME_HEIGHT)
					}
					if ( player?.distance(pt?.x,pt?.y) >= 100 ) {
						var e:Dynamic = entity.item.SpecialItem.attach(game,pt?.x,pt?.y, 101,null);
						e?.setLifeTimer(null);
						n--;
					}
				} while (n>0);
			

			// *** 94. anneau antok: offre un item à points supplémentaire par level
			}
else if (__sw == (auto++)) {
				global(id);
				permanent(id);
			

			// *** 95. sac à thunes: multiplicateur
			}
else if (__sw == (auto++)) {
				player.curse(Data.CURSE_MULTIPLY);
				permanent(id);
			

			// *** 96. perle orange: conversion
			}
else if (__sw == (auto++)) {
				game.destroyList(Data.BAD);
				game?.destroyList(Data.ITEM);
				game?.destroyList(Data.BAD_BOMB);
				levelConversion(Data.CONVERT_DIAMANT,1);
				temporary(id, Data.SECOND*19);
			

			// *** 97. perle verte: conversion
			}
else if (__sw == (auto++)) {
				game.destroyList(Data.BAD);
				game?.destroyList(Data.ITEM);
				game?.destroyList(Data.BAD_BOMB);
				levelConversion(Data.CONVERT_DIAMANT,2);
				temporary(id, Data.SECOND*19);
			

			// *** 98. perle rose: conversion
			}
else if (__sw == (auto++)) {
				game.destroyList(Data.BAD);
				game?.destroyList(Data.ITEM);
				game?.destroyList(Data.BAD_BOMB);
				levelConversion(Data.CONVERT_DIAMANT,3);
				temporary(id, Data.SECOND*19);
			


			// *** 99. Touffe Chourou: scores réguliers jusqu'a la fin du lvl
			}
else if (__sw == (auto++)) {
				registerRecurring( (this).onPoT, Data.SECOND*2, true );
				{ if (player != null) player.fl_chourou = true; }

				temporary(id,null);
			


			// *** 100. poupée guu
			}
else if (__sw == (auto++)) {
				temporary(id,Data.SECOND*30);
				game?.fxMan?.attachBg(Data.BG_GUU,null,Data.SECOND*30);
				var mc:Dynamic = game?.depthMan?.attach("hammer_fx_cloud",Data.DP_PLAYER);
				player?.stick(mc,0,-80);
				player?.setElaStick(0.4);
			


			// *** 101. colis mystérieux
			}
else if (__sw == (auto++)) {
				if ( MtStd.random(2)==0 ) {
					player?.getScore( item, 5000 );
				}
				else {
					var b:Dynamic = entity.bomb.bad.PoireBomb.attach(game,item?.x, item?.y);
					b?.moveUp(10);
				}
			

			// *** 102. carotte !
			}
else if (__sw == (auto++)) {
				game.world.scriptEngine.playById(100);
				{ if (game != null) game.huTimer = 0; }
				player?.getScore(item,4*25000);
//				player.playAnim(Data.ANIM_PLAYER_CARROT);

				{ if (player != null) player.fl_carot = true; }
			

			// *** 103. coeur 1
			}
else if (__sw == (auto++)) {
				player.lives++;
				game?.gi?.setLives(player?.pid, player?.lives);
				game?.fxMan?.attachShine( item?.x, item?.y-Data.CASE_HEIGHT*0.5 );
				game?.randMan?.remove(Data.RAND_ITEMS_ID, id);
			

			// *** 104. coeur 2
			}
else if (__sw == (auto++)) {
				player.lives++;
				game?.gi?.setLives(player?.pid, player?.lives);
				game?.fxMan?.attachShine( item?.x, item?.y-Data.CASE_HEIGHT*0.5 );
				game?.randMan?.remove(Data.RAND_ITEMS_ID, id);
			

			// *** 105. coeur 3
			}
else if (__sw == (auto++)) {
				player.lives++;
				game?.gi?.setLives(player?.pid, player?.lives);
				game?.fxMan?.attachShine( item?.x, item?.y-Data.CASE_HEIGHT*0.5 );
				game?.randMan?.remove(Data.RAND_ITEMS_ID, id);
			

			// *** 106. livre champignons
			}
else if (__sw == (auto++)) {
				{ var i:Dynamic=0; while (i<5) {
					var s:Dynamic = entity.item.ScoreItem.attach(game,item?.x,item?.y,1047+MtStd.random(4),null);
					s?.moveFrom(item,8);
				
i++; } }
			

			// *** 107. livre étoiles
			}
else if (__sw == (auto++)) {
				{ var i:Dynamic=0; while (i<5) {
					var s:Dynamic = entity.item.ScoreItem.attach(game,item?.x,item?.y,0,0); // todo: etoile à pts
					s?.moveFrom(item,8);
				
i++; } }
			

			// *** 108. parapluie vert
			}
else if (__sw == (auto++)) {
				warpZone(3);
			

			// *** 109. flocon 1
			}
else if (__sw == (auto++)) {
				game.fxMan.attachShine( item?.x, item?.y-Data.CASE_HEIGHT*0.5 );
				game?.randMan?.remove(Data.RAND_ITEMS_ID, id);
			

			// *** 110. flocon 2
			}
else if (__sw == (auto++)) {
				game.fxMan.attachShine( item?.x, item?.y-Data.CASE_HEIGHT*0.5 );
			

			// *** 111. flocon 3
			}
else if (__sw == (auto++)) {
				game.fxMan.attachShine( item?.x, item?.y-Data.CASE_HEIGHT*0.5 );
			

			// *** 112. pioupiouz
			}
else if (__sw == (auto++)) {
				player.head = Data.HEAD_PIOU;
				player?.replayAnim();
			

			// *** 113. cape tuberculoz
			}
else if (__sw == (auto++)) {
				player.getScore(item,75000);
				{ if (player != null) player.head = Data.HEAD_TUB; }
				player?.replayAnim();
			

			// *** 114. item mario
			}
else if (__sw == (auto++)) {
				temporary(id, null);
				player?.curse(Data.CURSE_MARIO);
			

			// *** 115. volleyfest
			}
else if (__sw == (auto++)) {
				permanent(id);
			

			// *** 116. joyau ankhel
			}
else if (__sw == (auto++)) {
				player.lives++;
				game?.gi?.setLives(player?.pid, player?.lives);
				player?.getScore(item, 70000);
			

			// *** 117. clé de gordon
			}
else if (__sw == (auto++)) {
				game.giveKey(12);
				player?.getScore(item, 10000);
			

			}
else {
				GameManager.warning("illegal item id="+id);
			
		}
}
	}



	/*------------------------------------------------------------------------
	UN EFFET SE TERMINE
	------------------------------------------------------------------------*/
	public function interrupt(id:Dynamic)  untyped {
		if ( !actives[id] ) {
			return;
		}
		actives[id] = false;
		game?.fxMan?.clearBg();

		{ var __sw:Dynamic = id;
if (__sw == (4) || __sw == (5)) { 
				player.maxBombs = player?.initialMaxBombs;
			

			// *** 7. chaussure
			}
else if (__sw == (7)) {
				player.speedFactor = 1.0;
			

			}
else if (__sw == (10)) {
				phoneMC.removeMovieClip();
			

			// *** 18. pissenlit
			}
else if (__sw == (18)) {
				player.fallFactor = 1.1;
			

			// *** 22. chaussure
			}
else if (__sw == (22)) {
				player.speedFactor = 1.0;
				player?.unstick();
			

			// *** 29. bague or
			}
else if (__sw == (29)) {
				if ( player?.currentWeapon==Data.WEAPON_S_FIRE) {
					player?.changeWeapon(null);
				}
			

			// *** 30. lunettes bleues
			}
else if (__sw == (30)) {
				game.flipX(false);
			

			// *** 31. lunettes rouges
			}
else if (__sw == (31)) {
				game.flipY(false);
			

			// *** 37. collier cristal
			}
else if (__sw == (37)) {
				if ( player?.currentWeapon==Data.WEAPON_S_ICE) {
					player?.changeWeapon(null);
				}
			

			}
else if (__sw == (39)) {
				player.fallFactor = 1.1;
			

			// *** 67. bague emeraude
			}
else if (__sw == (67)) {
				if ( player?.currentWeapon==Data.WEAPON_S_ARROW) {
					player?.changeWeapon(null);
				}
			

			// *** 69. tortue
			}
else if (__sw == (69)) {
				game.globalActives[id]=false;
				var l:Dynamic = game?.getBadClearList();
				{ var i:Dynamic=0; while (i<l?.length) {
					l[i]?.updateSpeed();
					{ if (l[i] != null) l[i].animFactor*=1/0.6; }
				
i++; } }
			

			// *** 80. escargot
			}
else if (__sw == (80)) {
				game.globalActives[id]=false;
				var l:Dynamic = game?.getBadClearList();
				{ var i:Dynamic=0; while (i<l?.length) {
					l[i]?.updateSpeed();
					{ if (l[i] != null) l[i].animFactor*=1/0.3; }
				
i++; } }
			

			// *** 81. perle bleue
			}
else if (__sw == (81)) {
				game.destroyList(Data.PERFECT_ITEM);
//				game.world.scriptEngine.clearScript();
				// source de bug potentielle pour les scripts prévus pour s'exécuter
				// apres la fin du level !
			

			// *** 84. talisman pluie de feu
			}
else if (__sw == (84)) {
				clearRec();
				{ var i:Dynamic=0; while (i<clouds?.length) {
					clouds[i]?.removeMovieClip();
				
i++; } }
				clouds = new Array();
			

			// *** 86. bonbon fantome
			}
else if (__sw == (86)) {
//				game.globalActives[id]=false;
				var l:Dynamic = game?.getBadList();
				{ var i:Dynamic=0; while (i<l?.length) {
					{ if (l[i] != null) l[i].alpha=100; }
					{ if (l[i] != null) l[i].filters = null; }
				
i++; } }
				{ if (player != null) player.filters = null; }
			

			// *** 88. pokute
			}
else if (__sw == (88)) {
				player.unstick();
				player?.scale(100);
			


			// *** 90. Malédiction de goldorak
			}
else if (__sw == (90)) {
				player.unstick();
			

			// *** 91. chapeau luffy
			}
else if (__sw == (91)) {
				player.unstick();
			


			// *** 94. anneau antok
			}
else if (__sw == (94)) {
				game.globalActives[id]=false;
			


			// *** 95. sac à thunes
			}
else if (__sw == (95)) {
				player.unstick();
			

			// *** 96/97/98. perles (voir commentaire sur 81)
			}
else if (__sw == (96) || __sw == (97) || __sw == (98)) {  
				game.destroyList(Data.PERFECT_ITEM);
//				game.world.scriptEngine.clearScript();
			

			// *** 99: Touffe Chourou
			}
else if (__sw == (99)) {
				player.fl_chourou = false;
				player?.replayAnim();
				clearRec();
			


			// *** 100. poupée guu
			}
else if (__sw == (100)) {
				game.fxMan.attachFx( player?.sticker?._x, player?.sticker?._y, "hammer_fx_pop" );
				player?.unstick();
				player?.scale(100);
			

			// *** 114. mode mario
			}
else if (__sw == (114)) {
				player.unstick();
			
		}
}
	}


	/*------------------------------------------------------------------------
	EVENT: STRIKE!
	------------------------------------------------------------------------*/
	public function onStrike()  untyped {
		var blist:Dynamic = game?.getList(Data.BAD_CLEAR);

		if ( blist?.length==0 || blist==null ) {
			return;
		}

		var bad : entity.Bad;
		var n:Dynamic = 0;
		do {
			bad = ((blist[n]):Dynamic);
			n++;
		} while (bad?.fl_kill==true);

		if ( bad?.fl_kill==false ) {
			var s:Dynamic = game?.depthMan?.attach("hammer_fx_strike", Data.FX);
			{ if (s != null) s._x = Data.DOC_WIDTH/2; }
			{ if (s != null) s._y = bad?._y-Data.CASE_HEIGHT*0.5; }
			var dir:Dynamic = MtStd.random(2)*2-1;
			{ if (s != null) s._xscale *= dir; }
			{ if (s != null) s._yscale = MtStd.random(50)+50; }
			game?.fxMan?.attachShine(bad?.x, bad?.y);
			bad?.forceKill( dir*(MtStd.random(10)+15) );
		}
	}


	/*------------------------------------------------------------------------
	EVENT: PLUIE DE FEU
	------------------------------------------------------------------------*/
	public function onFireRain()  untyped {
		var x:Dynamic = MtStd.random(Math.round(Data.GAME_WIDTH))+50;
		var s:Dynamic = entity.shoot.FireRain.attach(game,x,-MtStd.random(50));
		s?.moveToAng(95+MtStd.random(30),s?.shootSpeed);
	}


	/*------------------------------------------------------------------------
	EVENT: POINTS OVER TIME
	------------------------------------------------------------------------*/
	public function onPoT()  untyped {
		player?.getScore(player, 250);
	}


	/*------------------------------------------------------------------------
	MAIN
	------------------------------------------------------------------------*/
	public function main()  untyped {

		// Gestion des évènements spéciaux récurrents du niveau
		{ var n:Dynamic=0; while (n<recurring?.length) {
			var e:Dynamic = recurring[n];
			{ if (e != null) e.timer-=Timer.tmod; }
			if ( e?.timer<=0 ) {
				e?.func();
				// Répétition
				if ( e?.fl_repeat ) {
					{ if (e != null) e.timer = e?.baseTimer+e?.timer; }
				}
				else {
					recurring?.splice(n,1);
					n--;
				}
			}
		
n++; } }


		// Ecran de portable
		if ( phoneMC?._name!=null ) {
			var d:Dynamic = new js.lib.Date();
			var str:Dynamic = ""+d?.getHours();
			if ( str?.length<2 ) str = "0"+str;
			str = str+":";
			if ( d?.getMinutes()<10 ) {
				str = str+"0"+d?.getMinutes();
			}
			else {
				str = str+d?.getMinutes();
			}
			{ if (phoneMC?.screen?.field != null) phoneMC.screen.field.text = str; }
		}


		// Gestion de durée de vie des temporaires
		{ var i:Dynamic=0; while (i<tempList?.length) {
			if ( game?.cycle >= tempList[i]?.end ) {
				interrupt( tempList[i]?.id );
				tempList?.splice(i,1);
				i--;
			}
		
i++; } }


	}
}

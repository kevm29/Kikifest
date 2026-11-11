// Converti automatiquement depuis hammer/Data.mt (Motion Twin)
package;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
class Data
{
	public static var manager = null;

	public static var DOC_WIDTH:Int=420;
	public static var DOC_HEIGHT:Int=520;

	public static var GAME_WIDTH:Int=400;
	public static var GAME_HEIGHT:Int=500;

	public static var LEVEL_WIDTH:Int=20;
	public static var LEVEL_HEIGHT:Int=25;

	public static var CASE_WIDTH:Int=20;
	public static var CASE_HEIGHT:Int=20;

	public static var SECOND:Int = 32; // dur�e d'une sec en cycles de jeu

	public static var auto_inc:Int = 0;

	// *** DEPTHS
	public static var DP_SPECIAL_BG = auto_inc++;
	public static var DP_BACK_LAYER = auto_inc++;
	public static var DP_SPRITE_BACK_LAYER = auto_inc++;
	public static var DP_FIELD_LAYER = auto_inc++;
	public static var DP_SPEAR = auto_inc++;
	public static var DP_PLAYER = auto_inc++;
	public static var DP_ITEMS = auto_inc++;
	public static var DP_SHOTS = auto_inc++;
	public static var DP_BADS = auto_inc++;
	public static var DP_BOMBS = auto_inc++;
	public static var DP_FX = auto_inc++;
	public static var DP_SUPA = auto_inc++;
	public static var DP_TOP_LAYER = auto_inc++;
	public static var DP_SPRITE_TOP_LAYER = auto_inc++;
	public static var DP_BORDERS = auto_inc++;
	public static var DP_SCROLLER = auto_inc++;
	public static var DP_INTERF = auto_inc++;
	public static var DP_TOP = auto_inc++;
	public static var DP_SOUNDS = auto_inc++;


	// *** SOUNDS
	public static var CHAN_MUSIC:Int	= 0;
	public static var CHAN_BOMB:Int	= 1;
	public static var CHAN_PLAYER:Int	= 2;
	public static var CHAN_BAD:Int		= 3;
	public static var CHAN_ITEM:Int	= 4;
	public static var CHAN_FIELD:Int	= 5;
	public static var CHAN_INTERF:Int	= 6;
	public static var TRACKS = [
		"music_ingame",
		"music_boss",
	];

	// *** TYPES
	public static var type_bit:Int = 0;
	public static var ENTITY		= 1<<(type_bit++);
	public static var PHYSICS		= 1<<(type_bit++);
	public static var ITEM			= 1<<(type_bit++);
	public static var SPECIAL_ITEM	= 1<<(type_bit++);
	public static var PLAYER		= 1<<(type_bit++);
	public static var PLAYER_BOMB	= 1<<(type_bit++);
	public static var BAD			= 1<<(type_bit++);
	public static var SHOOT		= 1<<(type_bit++);
	public static var BOMB			= 1<<(type_bit++);
	public static var FX			= 1<<(type_bit++);
	public static var SUPA			= 1<<(type_bit++);
	public static var CATCHER		= 1<<(type_bit++);
	public static var BALL			= 1<<(type_bit++);
	public static var HU_BAD		= 1<<(type_bit++);
	public static var BOSS			= 1<<(type_bit++);
	public static var BAD_BOMB		= 1<<(type_bit++);
	public static var BAD_CLEAR	= 1<<(type_bit++);
	public static var SOCCERBALL	= 1<<(type_bit++);
	public static var PLAYER_SHOOT	= 1<<(type_bit++);
	public static var PERFECT_ITEM	= 1<<(type_bit++);
	public static var SPEAR		= 1<<(type_bit++);

	// *** LEVELS
	public static var GROUND:Int		= 1;
	public static var WALL:Int			= 2;
	public static var OUT_WALL:Int		= 3;
	public static var HORIZONTAL:Int	= 1;
	public static var VERTICAL:Int		= 2;
	public static var SCROLL_SPEED			= 0.04;//0.05 ; // incr�ment cosinus
	public static var FADE_SPEED:Int			= 8;
	public static var FIELD_TELEPORT:Int		= -6; // id dans la map du level
	public static var FIELD_PORTAL:Int			= -7;
	public static var FIELD_GOAL_1:Int			= -8;
	public static var FIELD_GOAL_2:Int			= -9;
	public static var FIELD_BUMPER:Int			= -10;
	public static var FIELD_PEACE:Int			= -11;
	public static var HU_STEPS				= [35*SECOND, 25*SECOND] ; // seuils timers des hurry ups
	public static var LEVEL_READ_LENGTH:Int	= 1;
	public static var MIN_DARKNESS_LEVEL:Int	= 16;

	// *** STATS
	public static var stat_inc:Int = 0;
	public static var STAT_MAX_COMBO	= stat_inc++;
	public static var STAT_SUPAITEM	= stat_inc++;
	public static var STAT_KICK		= stat_inc++; // inutilis� � partir d'ici...
	public static var STAT_BOMB		= stat_inc++;
	public static var STAT_SHOT		= stat_inc++;
	public static var STAT_JUMP		= stat_inc++;
	public static var STAT_ICEHIT		= stat_inc++;
	public static var STAT_KNOCK		= stat_inc++;
	public static var STAT_DEATH		= stat_inc++;

	// *** EXTENDS
	public static var EXTEND_TIMER = 10*SECOND;
	public static var EXT_MIN_COMBO:Int = 3;
	public static var EXT_MAX_BOMBS:Int = 3;
	public static var EXT_MAX_KICKS:Int = 0;
	public static var EXT_MAX_JUMPS:Int = 10;

	// *** ANIMATIONS
	public static var BLINK_DURATION:Float = 2.5;
	public static var BLINK_DURATION_FAST:Int = 1;
	public static var ANIM_PLAYER_STOP		= {id:0,loop:true};
	public static var ANIM_PLAYER_WALK		= {id:1,loop:true};
	public static var ANIM_PLAYER_JUMP_UP	= {id:2,loop:false};
	public static var ANIM_PLAYER_JUMP_DOWN= {id:3,loop:false};
	public static var ANIM_PLAYER_JUMP_LAND= {id:4,loop:false};
	public static var ANIM_PLAYER_DIE		= {id:5,loop:true};
	public static var ANIM_PLAYER_KICK		= {id:6,loop:false};
	public static var ANIM_PLAYER_ATTACK	= {id:7,loop:false};
	public static var ANIM_PLAYER_EDGE		= {id:8,loop:true};
	public static var ANIM_PLAYER_WAIT1	= {id:9,loop:false};
	public static var ANIM_PLAYER_WAIT2	= {id:10,loop:false};
	public static var ANIM_PLAYER_KNOCK_IN	= {id:12,loop:false};
	public static var ANIM_PLAYER_KNOCK_OUT= {id:13,loop:false};
	public static var ANIM_PLAYER_RESURRECT= {id:14,loop:false};
	public static var ANIM_PLAYER_CARROT	= {id:15,loop:true};
	public static var ANIM_PLAYER_RUN		= {id:16,loop:true};
	public static var ANIM_PLAYER_SOCCER	= {id:17,loop:true};
	public static var ANIM_PLAYER_AIRKICK	= {id:18,loop:false};
	public static var ANIM_PLAYER_STOP_V	= {id:19,loop:true};
	public static var ANIM_PLAYER_WALK_V	= {id:20,loop:true};
	public static var ANIM_PLAYER_STOP_L	= {id:21,loop:true};
	public static var ANIM_PLAYER_WALK_L	= {id:22,loop:true};

	public static var ANIM_BAD_WALK		= {id:0,loop:true};
	public static var ANIM_BAD_ANGER		= {id:1,loop:true};
	public static var ANIM_BAD_FREEZE		= {id:2,loop:false};
	public static var ANIM_BAD_KNOCK		= {id:3,loop:true};
	public static var ANIM_BAD_DIE			= {id:4,loop:true};
	public static var ANIM_BAD_SHOOT_START	= {id:5,loop:false};
	public static var ANIM_BAD_SHOOT_END	= {id:6,loop:false};
	public static var ANIM_BAD_THINK		= {id:7,loop:false};
	public static var ANIM_BAD_JUMP		= {id:8,loop:true};
	public static var ANIM_BAD_SHOOT_LOOP	= {id:9,loop:true};

	public static var ANIM_BAT_WAIT		= {id:0,loop:true};
	public static var ANIM_BAT_MOVE		= {id:1,loop:true};
	public static var ANIM_BAT_SWITCH		= {id:2,loop:false};
	public static var ANIM_BAT_DIVE		= {id:3,loop:false};
	public static var ANIM_BAT_INTRO		= {id:4,loop:false};
	public static var ANIM_BAT_KNOCK		= {id:5,loop:true};
	public static var ANIM_BAT_FINAL_DIVE	= {id:6,loop:true};
	public static var ANIM_BAT_ANGER		= {id:7,loop:true};

	public static var ANIM_BOSS_WAIT			= {id:0,loop:true};
	public static var ANIM_BOSS_SWITCH			= {id:1,loop:false};
	public static var ANIM_BOSS_JUMP_UP		= {id:2,loop:false};
	public static var ANIM_BOSS_JUMP_DOWN		= {id:3,loop:false};
	public static var ANIM_BOSS_JUMP_LAND		= {id:4,loop:false};
	public static var ANIM_BOSS_TORNADO_START	= {id:5,loop:false};
	public static var ANIM_BOSS_TORNADO_END	= {id:6,loop:false};
	public static var ANIM_BOSS_BAT_FORM		= {id:7,loop:false};
	public static var ANIM_BOSS_BURN_START		= {id:8,loop:false};
	public static var ANIM_BOSS_DEATH			= {id:9,loop:false};
	public static var ANIM_BOSS_DASH_START		= {id:10,loop:false};
	public static var ANIM_BOSS_DASH			= {id:11,loop:false};
	public static var ANIM_BOSS_BOMB			= {id:12,loop:false};
	public static var ANIM_BOSS_HIT			= {id:13,loop:false};
	public static var ANIM_BOSS_DASH_BUILD		= {id:14,loop:true};
	public static var ANIM_BOSS_BURN_LOOP		= {id:15,loop:true};
	public static var ANIM_BOSS_TORNADO_LOOP	= {id:16,loop:true};
	public static var ANIM_BOSS_DASH_LOOP		= {id:17,loop:true};


	public static var ANIM_BOMB_DROP		= {id:0,loop:false};
	public static var ANIM_BOMB_LOOP		= {id:1,loop:true};
	public static var ANIM_BOMB_EXPLODE	= {id:2,loop:false};

	public static var ANIM_WBOMB_STOP		= {id:0,loop:true};
	public static var ANIM_WBOMB_WALK		= {id:1,loop:true};

	public static var ANIM_SHOOT = {id:0,loop:false};
	public static var ANIM_SHOOT_LOOP = {id:0,loop:true};

	// *** IA
	public static var MAX_ITERATION:Int = 30;
	public static var flag_bit:Int = 0;
	public static var GRID_NAMES = [
		"$IA_TILE_TOP",		// 0
		"$IA_ALLOW_FALL",	// 1
		"$IA_BORDER",		// 2
		"$IA_SMALLSPOT",	// 3
		"$IA_FALL_SPOT",	// 4
		"$IA_JUMP_UP",		// 5
		"$IA_JUMP_DOWN",	// 6
		"$IA_JUMP_LEFT",	// 7
		"$IA_JUMP_RIGHT",	// 8
		"$IA_TILE",			// 9
		"$IA_CLIMB_LEFT",	// 10
		"$IA_CLIMB_RIGHT",	// 11

		"$FL_TELEPORTER",	// 12
	];
	public static var IA_TILE_TOP		= 1<<(flag_bit++);
	public static var IA_ALLOW_FALL	= 1<<(flag_bit++);
	public static var IA_BORDER		= 1<<(flag_bit++);
	public static var IA_SMALL_SPOT	= 1<<(flag_bit++);
	public static var IA_FALL_SPOT		= 1<<(flag_bit++);
	public static var IA_JUMP_UP		= 1<<(flag_bit++);
	public static var IA_JUMP_DOWN		= 1<<(flag_bit++);
	public static var IA_JUMP_LEFT		= 1<<(flag_bit++);
	public static var IA_JUMP_RIGHT	= 1<<(flag_bit++);
	public static var IA_TILE			= 1<<(flag_bit++);
	public static var IA_CLIMB_LEFT	= 1<<(flag_bit++);
	public static var IA_CLIMB_RIGHT	= 1<<(flag_bit++);

//	static var IA_CORNER_UP		= 1<<(flag_bit++);
//	static var IA_CORNER_DOWN	= 1<<(flag_bit++);
//	static var IA_CORNER_LEFT	= 1<<(flag_bit++);
//	static var IA_CORNER_RIGHT	= 1<<(flag_bit++);

	public static var FL_TELEPORTER = 1<<(flag_bit++);

	public static var IA_HJUMP:Int = 2; // distance de saut horizontal
	public static var IA_VJUMP:Int = 2; // distance de saut vertical
	public static var IA_CLIMB:Int = 4; // distance d'escalade max
	public static var IA_CLOSE_DISTANCE:Int = 110;

	public static var ACTION_MOVE = auto_inc++;
	public static var ACTION_WALK = auto_inc++;
	public static var ACTION_SHOOT = auto_inc++;
	public static var ACTION_FALLBACK = auto_inc++;


	// *** INTERFACE
	public static var EVENT_EXIT_RIGHT:Int		= 1;
	public static var EVENT_BACK_RIGHT:Int		= 2;
	public static var EVENT_EXIT_LEFT:Int		= 3;
	public static var EVENT_BACK_LEFT:Int		= 4;
	public static var EVENT_DEATH:Int			= 5;
	public static var EVENT_EXTEND:Int			= 6;
	public static var EVENT_TIME:Int			= 7;

	// *** PHYSICS
	public static var BORDER_MARGIN = CASE_WIDTH/2;
	public static var FRICTION_X:Float = 0.93;
	public static var FRICTION_Y:Float = 0.86;
	public static var FRICTION_GROUND:Float = 0.70;
	public static var FRICTION_SLIDE:Float = 0.97;
	public static var GRAVITY:Float = 1.0 ; // ajout� au dy en mont�e
	public static var FALL_FACTOR_FROZEN:Float = 2.3;
	public static var FALL_FACTOR_KNOCK:Float = 1.5;
	public static var FALL_FACTOR_DEAD:Float = 1.75;
	public static var FALL_SPEED:Float = 0.9 ; // ajout� au dy en descente
	public static var STEP_MAX = CASE_WIDTH;
	public static var DEATH_LINE = GAME_HEIGHT+50;

	// *** FX
	public static var MAX_FX:Int					= 16;
	public static var DUST_FALL_HEIGHT			= CASE_HEIGHT * 4;
	public static var PARTICLE_ICE:Int				= 1;
	public static var PARTICLE_CLASSIC_BOMB:Int	= 2;
	public static var PARTICLE_STONE:Int			= 3;
	public static var PARTICLE_SPARK:Int			= 4;
	public static var PARTICLE_DUST:Int			= 5;
	public static var PARTICLE_ORANGE:Int			= 6;
	public static var PARTICLE_METAL:Int			= 7;
	public static var PARTICLE_TUBERCULOZ:Int		= 8;
	public static var PARTICLE_RAIN:Int			= 9;
	public static var PARTICLE_LITCHI:Int			= 10;
	public static var PARTICLE_PORTAL			= PARTICLE_SPARK;
	public static var PARTICLE_BUBBLE:Int			= 11;
	public static var PARTICLE_ICE_BAD:Int			= 12;
	public static var PARTICLE_BLOB:Int			= 13;
	public static var PARTICLE_FRAMB:Int			= 14;
	public static var PARTICLE_FRAMB_SMALL:Int		= 14;

	public static var BG_STAR:Int			= 0;
	public static var BG_FLASH:Int			= 1;
	public static var BG_ORANGE:Int		= 2;
	public static var BG_FIREBALL:Int		= 3;
	public static var BG_HYPNO:Int			= 4;
	public static var BG_CONSTEL:Int		= 5;
	public static var BG_JAP:Int			= 6;
	public static var BG_GHOSTS:Int		= 7;
	public static var BG_FIRE:Int			= 8;
	public static var BG_PYRAMID:Int		= 9;
	public static var BG_SINGER:Int		= 10;
	public static var BG_STORM:Int			= 11;
	public static var BG_GUU:Int			= 12;
	public static var BG_SOCCER:Int		= 13;


	// *** PLAYER
	public static var PLAYER_SPEED:Float			= 4.3;
	public static var PLAYER_JUMP:Float			= 18.7 ; // 19.5
	public static var PLAYER_HKICK_X:Float		= 3.5;
	public static var PLAYER_HKICK_Y:Float		= 7.4;
	public static var PLAYER_VKICK:Int			= 18;
	public static var PLAYER_AIR_JUMP:Int		= 7;
	public static var WBOMB_SPEED			= PLAYER_SPEED*1.5;

	public static var KICK_DISTANCE		= CASE_WIDTH;
	public static var AIR_KICK_DISTANCE	= CASE_WIDTH*1.5;

	public static var SHIELD_DURATION		= SECOND*5;
	public static var WEAPON_DURATION		= SECOND*30 ; // en cycles
	public static var SUPA_DURATION		= SECOND*30;
	public static var EXTRA_LIFE_STEPS		= [100000,500000,1000000,2000000,3000000,4000000];
	public static var TELEPORTER_DISTANCE	= CASE_WIDTH*4;

	public static var BASE_COLORS			= [0xffffff, 0xf4e093, 0x5555ff, 0xfbb64f ];
	public static var DARK_COLORS			= [0x70658d, 0xd54000, 0x0, 0x0 ];

	public static var CURSE_PEACE:Int		= 1;
	public static var CURSE_SHRINK:Int		= 2;
	public static var CURSE_SLOW:Int		= 3;
	public static var CURSE_TAUNT:Int		= 4;
	public static var CURSE_MULTIPLY:Int	= 5;
	public static var CURSE_FALL:Int		= 6;
	public static var CURSE_MARIO:Int		= 7;
	public static var CURSE_TRAITOR:Int	= 8;
	public static var CURSE_GOAL:Int		= 9;

	public static var EDGE_TIMER		= SECOND*0.2;
	public static var WAIT_TIMER		= SECOND*8;

	public static var WEAPON_B_CLASSIC:Int	= 1;
	public static var WEAPON_B_BLACK:Int	= 2;
	public static var WEAPON_B_BLUE:Int	= 3;
	public static var WEAPON_B_GREEN:Int	= 4;
	public static var WEAPON_B_RED:Int		= 5;
	public static var WEAPON_B_REPEL:Int	= 9;

	public static var WEAPON_NONE:Int		= -1;

	public static var WEAPON_S_ARROW:Int	= 6;
	public static var WEAPON_S_FIRE:Int	= 7;
	public static var WEAPON_S_ICE:Int		= 8;


	public static var HEAD_NORMAL:Int		= 1;
	public static var HEAD_AFRO:Int		= 2;
	public static var HEAD_CERBERE:Int		= 3;
	public static var HEAD_PIOU:Int		= 4;
	public static var HEAD_MARIO		= 5;
	public static var HEAD_TUB:Int			= 6;
	public static var HEAD_IGORETTE:Int	= 7;
	public static var HEAD_LOSE:Int		= 8;
	public static var HEAD_CROWN:Int		= 9;
	public static var HEAD_SANDY:Int		= 10;
	public static var HEAD_SANDY_LOSE:Int	= 11;
	public static var HEAD_SANDY_CROWN:Int	= 12;



	// *** BADS
	public static var PEACE_COOLDOWN		= SECOND*3;
	public static var AUTO_ANGER			= SECOND*4;
	public static var MAX_ANGER:Int			= 3;
	public static var BALL_TIMEOUT			= 2.3*SECOND;
	public static var BAD_HJUMP_X:Float			= 5.5; // 6.5
	public static var BAD_HJUMP_Y:Float			= 8.5;
	public static var BAD_VJUMP_X_CLIFF:Float	= 2.2; // utilis� pour l'escalade (pied d'un mur)
	public static var BAD_VJUMP_X:Float			= 1.3; // utilis� pour l'escalade (marches dans le vide)
	public static var BAD_VJUMP_Y:Int			= 19;
	public static var BAD_VJUMP_Y_LIST		= [
		11,	// 1 case
		14,	// 2 cases
		19, // 3 cases
	];
	public static var BAD_VDJUMP_Y:Float			= 6.5;
	public static var FREEZE_DURATION		= SECOND * 5;
	public static var KNOCK_DURATION		= SECOND * 3.75;
	public static var PLAYER_KNOCK_DURATION= SECOND * 2.5;
	public static var ICE_HIT_MIN_SPEED:Int	= 4 ; // distance par cycle (dx+dy)
	public static var ICE_KNOCK_MIN_SPEED:Int	= 2 ; // distance par cycle (dx+dy)

	public static var BAD_POMME:Int		= 0;
	public static var BAD_CERISE:Int		= 1;
	public static var BAD_BANANE:Int		= 2;
	public static var BAD_FIREBALL:Int		= 3;
	public static var BAD_ANANAS:Int		= 4;
	public static var BAD_ABRICOT:Int		= 5;
	public static var BAD_ABRICOT2:Int		= 6;
	public static var BAD_POIRE:Int		= 7;
	public static var BAD_BOMBE:Int		= 8;
	public static var BAD_ORANGE:Int		= 9;
	public static var BAD_FRAISE:Int		= 10;
	public static var BAD_CITRON:Int		= 11;
	public static var BAD_BALEINE:Int		= 12;
	public static var BAD_SPEAR:Int		= 13;
	public static var BAD_CRAWLER:Int		= 14;
	public static var BAD_TZONGRE:Int		= 15;
	public static var BAD_SAW:Int			= 16;
	public static var BAD_LITCHI:Int		= 17;
	public static var BAD_KIWI:Int			= 18;
	public static var BAD_LITCHI_WEAK:Int	= 19;
	public static var BAD_FRAMBOISE:Int	= 20;

	public static var LINKAGES = initLinkages();
	public static function initLinkages()  untyped {
		var tab:Dynamic = new Array();
		tab[BAD_POMME]			= "hammer_bad_pomme";
		tab[BAD_CERISE]			= "hammer_bad_cerise";
		tab[BAD_BANANE]			= "hammer_bad_banane";
		tab[BAD_FIREBALL]		= "hammer_bad_fireball";
		tab[BAD_ANANAS]			= "hammer_bad_ananas";
		tab[BAD_ABRICOT]		= "hammer_bad_abricot";
		tab[BAD_ABRICOT2]		= "hammer_bad_abricot";
		tab[BAD_POIRE]			= "hammer_bad_poire";
		tab[BAD_BOMBE]			= "hammer_bad_bombe";
		tab[BAD_ORANGE]			= "hammer_bad_orange";
		tab[BAD_FRAISE]			= "hammer_bad_fraise";
		tab[BAD_CITRON]			= "hammer_bad_citron";
		tab[BAD_BALEINE]		= "hammer_bad_baleine";
		tab[BAD_SPEAR]			= "hammer_bad_spear";
		tab[BAD_CRAWLER]		= "hammer_bad_crawler";
		tab[BAD_TZONGRE]		= "hammer_bad_tzongre";
		tab[BAD_SAW]			= "hammer_bad_saw";
		tab[BAD_LITCHI]			= "hammer_bad_litchi";
		tab[BAD_KIWI]			= "hammer_bad_kiwi";
		tab[BAD_LITCHI_WEAK]	= "hammer_bad_litchi_weak";
		tab[BAD_FRAMBOISE]		= "hammer_bad_framboise";
		return tab;
	}


	// *** BOSS
	public static var BAT_LEVEL:Int = 100;
	public static var TUBERCULOZ_LEVEL:Int = 101;
	public static var BOSS_BAT_MIN_DIST	= CASE_WIDTH*7;
	public static var BOSS_BAT_MIN_X_DIST	= CASE_WIDTH*3;


	// *** ITEMS
	public static var MAX_ITEMS:Int		= 300;
	public static var ITEM_LIFE_TIME	= 8*SECOND;
	public static var DIAMANT:Int			= 8;
	public static var CONVERT_DIAMANT:Int	= 17;
	public static var EXTENDS			= ["C","R","Y","S","T","A","L"];
	public static var SPECIAL_ITEM_TIMER	= 8*SECOND;
	public static var SCORE_ITEM_TIMER		= 12*SECOND;


	// *** ITEM RANDOMIZER
	public static var __NA:Int = 0;
	public static var COMM:Int = 2000;
	public static var UNCO:Int = 1000;
	public static var RARE = 300;
	public static var UNIQ:Int = 100;
	public static var MYTH:Int = 10;
	public static var CANE:Int = 60; // sp�cifique canne de bobble
	public static var LEGEND:Int = 1;
	public static var RARITY = [
		0,			// never randomly spawned
		COMM,		// common
		UNCO,		// unco
		RARE,		// rare
		UNIQ,		// really rare
		MYTH,		// mythic
		LEGEND,		// urban legend
		CANE
	];

	public static var RAND_EXTENDS_ID	= auto_inc++;
	public static var RAND_ITEMS_ID	= auto_inc++;
	public static var RAND_SCORES_ID	= auto_inc++;

	public static var RAND_EXTENDS		= [10,10,6,5,5,10,4];

	public static var SPECIAL_ITEM_FAMILIES	: Array<Array<ItemFamilySet>>;
	public static var SCORE_ITEM_FAMILIES		: Array<Array<ItemFamilySet>>;
	public static var ITEM_VALUES				: Array<Int>;
	public static var FAMILY_CACHE				: Array<Int>;
	public static var LINKS					: Array<levels.PortalLink>;
	public static var LEVEL_TAG_LIST			: Array< {name:String, did:Int, lid:Int} >;



	/*------------------------------------------------------------------------
	INITALISATION
	------------------------------------------------------------------------*/
	public static function init(m:Dynamic)  untyped {
		manager = m ;
		SPECIAL_ITEM_FAMILIES	= xml_readSpecialItems();
		SCORE_ITEM_FAMILIES		= xml_readScoreItems();
		FAMILY_CACHE			= cacheFamilies();
		ITEM_VALUES				= getScoreItemValues();
		LINKS					= xml_readPortalLinks();
	}


	/*------------------------------------------------------------------------
	READS XML_ITEMS, RAW FORMAT
	(transitionnal)
	------------------------------------------------------------------------*/
	public static function initItemsRaw()  untyped {
		var tab:Dynamic = new Array();
		var raw:Dynamic = MtStd.getVar( manager?.root, "xml_items" );
		var node:Dynamic = new MtXml( raw ).firstChild;
		if ( node?.nodeName!="$items".substring(1) ) {
			GameManager.fatal("XML error: invalid node '"+node?.nodeName+"'");
			return null;
		}

		// DEBUG: lecture et stockage "raw" de tous les items dans une seule famille
		var family:Dynamic = node?.firstChild;
		while ( family!=null ) {
			node = family?.firstChild;
			while ( node!=null ) {
				var rarity:Dynamic = Std.int(node?.get("$rarity".substring(1)));
				var id:Dynamic = Std.int(node?.get("$id".substring(1)));
				var rand:Dynamic = Data.__NA;
				{ var __sw:Dynamic = rarity;
if (__sw == (1)) { rand = Data.COMM;
					}
else if (__sw == (2)) { rand = Data.UNCO;
					}
else if (__sw == (3)) { rand = Data.RARE;
					}
else if (__sw == (4)) { rand = Data.UNIQ;
					}
else if (__sw == (5)) { rand = Data.MYTH;
					}
else if (__sw == (6)) { rand = Data.__NA;
					}
else if (__sw == (7)) { rand = Data.CANE;
				}
}
				tab[id] = rand;
				node = node?.nextSibling;
			}
			family = family?.nextSibling;
		}

		return tab;
	}

	/*------------------------------------------------------------------------
	READS XML ITEMS DATA
	------------------------------------------------------------------------*/
	public static function xml_readFamily(xmlName:Dynamic)  untyped { // note: append leading "$" for obfuscator
		var tab:Dynamic = new Array();
		var raw:Dynamic = MtStd.getVar( manager?.root, xmlName );
		var node:Dynamic = new MtXml( raw ).firstChild;
		if ( node?.nodeName!="$items".substring(1) ) {
			GameManager.fatal("XML error ("+xmlName+" @ "+manager?.root?._name+"): invalid node '"+node?.nodeName+"'");
			return null;
		}

		var family:Dynamic = node?.firstChild;
		while ( family!=null ) {
			node = family?.firstChild;
			var fid:Dynamic = Std.int( family?.get("$id".substring(1)) );
			tab[fid] = new Array();
			while ( node!=null ) {
				var id:Dynamic		= Std.int(node?.get("$id".substring(1)));
				var rarity:Dynamic	= Std.int(node?.get("$rarity".substring(1)));
				var value:Dynamic	= Std.int(node?.get("$value".substring(1)));
				if ( value==null ) {
					value=0;
				}
				tab[fid]?.push( {
						id		: id,
						r		: Data.RARITY[rarity],
						v		: value,
						name	: Lang.getItemName(id)
				} );
				node = node?.nextSibling;
			}
			family = family?.nextSibling;
		}

		return tab;
	}

	public static function xml_readSpecialItems()  untyped {
		return xml_readFamily("xml_specialItems");
	}

	public static function xml_readScoreItems()  untyped {
		return xml_readFamily("xml_scoreItems");
	}


	/*------------------------------------------------------------------------
	BUILD A RAND ITEM TABLE CONTAINING SPECIFIED FAMILIES
	------------------------------------------------------------------------*/
	public static function getRandFromFamilies(familySet:Array<Array<ItemFamilySet>>, familiesId:Array<Int>)  untyped {
		var tab:Dynamic = new Array();
		{ var i:Dynamic=0; while (i<familiesId?.length) {
			var family:Dynamic = familySet[familiesId[i]];
			var n:Dynamic=0;
			while ( n<family?.length ) {
				tab[family[n]?.id] = family[n]?.r;
				n++;
			}
		
i++; } }
		return tab;
	}


	/*------------------------------------------------------------------------
	EXTRACTS SCORE VALUES FROM FAMILIES
	------------------------------------------------------------------------*/
	public static function getScoreItemValues()  untyped {
		var tab:Dynamic = new Array();
		{ var i:Dynamic=0; while (Data.SCORE_ITEM_FAMILIES != null && i<Data.SCORE_ITEM_FAMILIES.length) {
			var family:Dynamic = Data.SCORE_ITEM_FAMILIES[i];
			var n:Dynamic=0;
			while ( n<family?.length ) {
				tab[family[n]?.id] = family[n]?.v;
				n++;
			}
		
i++; } }
		return tab;
	}



	/*------------------------------------------------------------------------
	G�N�RE LA TABLE DE CORRESPONDANCE ITEM -> FAMILLE
	------------------------------------------------------------------------*/
	public static function cacheFamilies()  untyped {
		var tab:Dynamic = new Array();

		{ var fid:Dynamic=0; while (SPECIAL_ITEM_FAMILIES != null && fid<SPECIAL_ITEM_FAMILIES.length) {
			var f:Dynamic= SPECIAL_ITEM_FAMILIES[fid];
			{ var i:Dynamic=0; while (i<f?.length) {
				tab[f[i]?.id] = fid;
			
i++; } }
		
fid++; } }

		{ var fid:Dynamic=0; while (SCORE_ITEM_FAMILIES != null && fid<SCORE_ITEM_FAMILIES.length) {
			var f:Dynamic= SCORE_ITEM_FAMILIES[fid];
			{ var i:Dynamic=0; while (i<f?.length) {
				tab[f[i]?.id] = fid;
			
i++; } }
		
fid++; } }
		return tab;
	}



	/*------------------------------------------------------------------------
	CONVERSION DID+LID EN NOM DE TAG
	------------------------------------------------------------------------*/
	public static function getTagFromLevel(did:Dynamic, lid:Dynamic)  untyped {
		var name:Dynamic = null;
		{ var i:Dynamic=0; while (LEVEL_TAG_LIST != null && i<LEVEL_TAG_LIST.length) {
			var tag:Dynamic = LEVEL_TAG_LIST[i];
			if ( tag?.did==did && tag?.lid==lid ) {
				name = tag?.name;
			}
		
i++; } }
		return name;
	}


	/*------------------------------------------------------------------------
	CONVERSION NOM DE TAG EN DID+LID
	------------------------------------------------------------------------*/
	public static function getLevelFromTag(code:String) : {did:Int,lid:Int}  untyped {
		code = code?.toLowerCase();
		var linfo:Dynamic	= null;
		var name:Dynamic	= code?.split("+")[0];
		var inc:Dynamic		= MtStd.parseInt( code?.split("+")[1], 10 );
		if ( MtStd.isNaN(inc) ) {
			inc = 0;
		}
		{ var i:Dynamic=0; while (LEVEL_TAG_LIST != null && i<LEVEL_TAG_LIST.length) {
			var tag:Dynamic = LEVEL_TAG_LIST[i];
			if ( tag?.name == name ) {
				linfo = {did:tag.did, lid:tag.lid+inc};
			}
		
i++; } }
		return linfo;
	}



	/*------------------------------------------------------------------------
	LECTURE DU XML DES PORTALS
	------------------------------------------------------------------------*/
	public static function xml_readPortalLinks()  untyped {
		var list:Dynamic = new Array();
		var raw:Dynamic = MtStd.getVar( manager?.root, "xml_portalLinks" );
		var doc:Dynamic = new MtXml(null);
		{ if (doc != null) doc.ignoreWhite = true; }
		doc?.parseXML( raw );
		var node:Dynamic = doc?.firstChild;
		if ( node?.nodeName!="$links".substring(1) ) {
			GameManager.fatal("XML error (xml_portals @ "+manager?.root?._name+"): invalid node '"+node?.nodeName+"'");
			return null;
		}


		// Lecture des tags de d�but de XML
		node = node?.firstChild;
		if ( node?.nodeName!="$tags".substring(1) ) {
			GameManager.fatal("XML error (xml_portals @ "+manager?.root?._name+"): invalid node '"+node?.nodeName+"'");
		}

		var tag:Dynamic = node?.firstChild;
		LEVEL_TAG_LIST = new Array();
		while ( tag!=null ) {
			LEVEL_TAG_LIST.push(
				{
					name	: tag.get("$name".substring(1)).toLowerCase(),
					did		: MtStd.parseInt(tag?.get("$did".substring(1)),10),
					lid		: MtStd.parseInt(tag?.get("$lid".substring(1)),10),
				}
			);
			tag = tag?.nextSibling;
		}
		node = node?.nextSibling;
		if ( node?.nodeName!="$ways".substring(1) ) {
			GameManager.fatal("xml_readPortalLinks: unknown node "+node?.nodeName);
			return null;
		}
		node = node?.firstChild;


		// Lecture des links
		while ( node!=null ) {

			var att:Dynamic;

			att = node?.get("$from".substring(1));
			att = Tools.replace( att, "(", "," );
			att = Tools.replace( att, ")", "" );
			att = Tools.replace( att, " ", "" );
			var from:Dynamic	= att?.split(",");

			att = node?.get("$to".substring(1));
			att = Tools.replace( att, "(", "," );
			att = Tools.replace( att, ")", "" );
			att = Tools.replace( att, " ", "" );
			var to:Dynamic		= att?.split(",");


			var link:Dynamic	= new levels.PortalLink();
			var linfo:Dynamic = getLevelFromTag( from[0] );
			{ if (link != null) link.from_did	= linfo?.did; }
			{ if (link != null) link.from_lid	= linfo?.lid; }
			{ if (link != null) link.from_pid	= MtStd.parseInt(from[1], 10); }

			linfo = getLevelFromTag( to[0] );
			{ if (link != null) link.to_did		= linfo?.did; }
			{ if (link != null) link.to_lid		= linfo?.lid; }
			{ if (link != null) link.to_pid		= MtStd.parseInt(to[1], 10); }

			link?.cleanUp();
			list?.push(link);

			// 2-way portal
			if ( node?.nodeName=="$twoway".substring(1) ) {
				var backLink:Dynamic = new levels.PortalLink();
				{ if (backLink != null) backLink.from_did	= link?.to_did; }
				{ if (backLink != null) backLink.from_lid	= link?.to_lid; }
				{ if (backLink != null) backLink.from_pid	= link?.to_pid; }
				{ if (backLink != null) backLink.to_did		= link?.from_did; }
				{ if (backLink != null) backLink.to_lid		= link?.from_lid; }
				{ if (backLink != null) backLink.to_pid		= link?.from_pid; }
				list?.push(backLink);
			}


			node = node?.nextSibling;
		}


		return list;
	}



	// *** MODE OPTIONS
	public static var OPT_MIRROR			= "$mirror".substring(1);
	public static var OPT_MIRROR_MULTI		= "$mirrormulti".substring(1);
	public static var OPT_NIGHTMARE_MULTI	= "$nightmaremulti".substring(1);
	public static var OPT_NIGHTMARE		= "$nightmare".substring(1);
	public static var OPT_LIFE_SHARING		= "$lifesharing".substring(1);
	public static var OPT_SOCCER_BOMBS		= "$soccerbomb".substring(1);
	public static var OPT_KICK_CONTROL		= "$kickcontrol".substring(1);
	public static var OPT_BOMB_CONTROL		= "$bombcontrol".substring(1);
	public static var OPT_NINJA			= "$ninja".substring(1);
	public static var OPT_BOMB_EXPERT		= "$bombexpert".substring(1);
	public static var OPT_BOOST			= "$boost".substring(1);

	public static var OPT_SET_TA_0			= "$set_ta_0".substring(1);
	public static var OPT_SET_TA_1			= "$set_ta_1".substring(1);
	public static var OPT_SET_TA_2			= "$set_ta_2".substring(1);

	public static var OPT_SET_MTA_0		= "$set_mta_0".substring(1);
	public static var OPT_SET_MTA_1		= "$set_mta_1".substring(1);
	public static var OPT_SET_MTA_2		= "$set_mta_2".substring(1);

	public static var OPT_SET_SOC_0		= "$set_soc_0".substring(1);
	public static var OPT_SET_SOC_1		= "$set_soc_1".substring(1);
	public static var OPT_SET_SOC_2		= "$set_soc_2".substring(1);
	public static var OPT_SET_SOC_3		= "$set_soc_3".substring(1);




	// *** EDITOR
	public static var FIELDS = [null, "BASE ", "noir ", "bleu ", "vert ", "rouge ", "warp ", "portal ", "goal 1", "goal 2", "bumper ", "peace " ];
	public static var MAX_TILES:Int = 53;
	public static var MAX_BG:Int = 30;
	public static var MAX_BADS:Int = 20;
	public static var MAX_FIELDS:Int = 11;
	public static var TOOL_TILE = auto_inc++;
	public static var TOOL_BAD = auto_inc++;
	public static var TOOL_FIELD = auto_inc++;
	public static var TOOL_START = auto_inc++;
	public static var TOOL_SPECIAL = auto_inc++;
	public static var TOOL_SCORE = auto_inc++;



	/*------------------------------------------------------------------------
	RENVOIE UNE COPIE
	------------------------------------------------------------------------*/
	public static function duplicate(o:Dynamic) : Dynamic  untyped {
		var codec:Dynamic = new PersistCodec();
		var s:Dynamic = codec?.encode(o);
		return codec?.decode(s);
	}


	/*------------------------------------------------------------------------
	VALEUR DES CRISTAUX
	------------------------------------------------------------------------*/
	public static function getCrystalValue(id:Dynamic):Int  untyped {
		return Math.round( Math.min(50000, (5*100)*Math.round(Math.pow(id+1,2))) );
	}

	public static function getCrystalTime(id:Dynamic):Int  untyped {
		var values:Dynamic = [1,3,5,7,9,10];
		return values[ Std.int(Math.min(id, values?.length-1)) ];
	}


	/*------------------------------------------------------------------------
	SERIALISATION, Format:  fileName;elem:elem:elem # fileName;elem:(...)
	------------------------------------------------------------------------*/
	public static function serializeHash(h:Hash<Array<String>>):String  untyped {
		var str:Dynamic = "";
		h?.iter(
			function(k,e:Array<String>) {
				if (str?.length>0)
				str+="#";
				str += k + ";" + e?.join(":");
			}
		);
		return str;
	}



	/*------------------------------------------------------------------------
	D�SERIALISATION
	------------------------------------------------------------------------*/
	public static function unserializeHash(str:String): Hash<Array<String>>  untyped {
		var h:Dynamic = new Hash();

		if ( str==null ) {
			return h;
		}

		var pairs:Dynamic = str?.split("#");
		{ var i:Dynamic=0; while (i<pairs?.length) {
			var pair : Array<String> = pairs[i]?.split(";");
			var k:Dynamic = pair[0];
			var e:Dynamic = pair[1];
			if (e?.length!=null) {
				h?.set(k, (cast (e.split(":"))));
			}
		
i++; } }

		return h;
	}


	/*------------------------------------------------------------------------
	ENL�VE LES LEADING / END SPACES
	------------------------------------------------------------------------*/
	public static function cleanLeading(s:String)  untyped {
		while (s?.substr(0,1)==" ") {
			s = s?.substr(1,s?.length);
		}
		while (s?.substr(s?.length-1,1)==" ") {
			s = s?.substr(0,s?.length-1);
		}
		return s;
	}


	/*------------------------------------------------------------------------
	NETTOYAGE LEADING + SAUTS DE LIGNE
	------------------------------------------------------------------------*/
	public static function cleanString(s:String)  untyped {
		s = cleanLeading(s);
		s = Tools.replace( s, String.fromCharCode(13), " ");
		return s;
	}


	/*------------------------------------------------------------------------
	AJOUT DE LEADING ZEROS
	------------------------------------------------------------------------*/
	public static function leadingZeros(n:Dynamic,zeros:Dynamic)  untyped {
		var s:Dynamic = ""+n;
		while (s?.length<zeros) {
			s = "0"+s;
		}
		return s;
	}


	/*------------------------------------------------------------------------
	REMPLACE UN CARACT�RE DELIMITER PAR UN TAG AVEC CLOSURE
	------------------------------------------------------------------------*/
	public static function replaceTag(str:String, char:Dynamic, start:Dynamic, end:Dynamic)  untyped {
		var arr:Dynamic = str?.split(char);
		if ( arr?.length % 2 == 0 ) {
			GameManager.warning("invalid string (splitter "+char+"): "+str);
			return str;
		}

		var final_:Dynamic = "";
		{ var i:Dynamic=0; while (i<arr?.length) {
			if ( (i%2)!=0 ) {
				final_ += start + arr[i] + end;
			}
			else {
				final_ += arr[i];
			}
		
i++; } }
		return final_;
	}



	/*------------------------------------------------------------------------
	CHRONOM�TRE DE DEBUG
	------------------------------------------------------------------------*/

	public static var WATCH:Int	= 0;

	public static function stime()  untyped {
		WATCH = MtStd.getTimer();
	}

	public static function time(n:String)  untyped {
		var t:Dynamic = MtStd.getTimer()-WATCH;
		Log.trace(n+" : "+t);
	}


	/*------------------------------------------------------------------------
	GROUPEMENT PAR 3 CHIFFRES
	------------------------------------------------------------------------*/
	public static function formatNumber(n:Dynamic)  untyped {
		var txt:Dynamic = n+"";
		// Groupement des chiffres
		if ( txt?.indexOf("-",0)<0 ) {
			{ var i:Dynamic=txt?.length-3; while (i>0) {
				txt = txt?.substr(0,i)+"."+txt?.substr(i,txt?.length);
			
i-=3; } }
		}
		return txt;
	}

	public static function formatNumberStr(txt:String)  untyped {
		return formatNumber( MtStd.parseInt(txt,10) );
	}


	/*------------------------------------------------------------------------
	RENVOIE LE LINK CORRESPONDANT � UN PORTAL DONN�
	------------------------------------------------------------------------*/
	public static function getLink(did:Dynamic, lid:Dynamic, pid:Dynamic)  untyped {
		var link:Dynamic = null;
		var i:Dynamic=0;
		while ( i<Data.LINKS.length && link==null ) {
			var l:Dynamic = Data.LINKS[i];
			if ( l?.from_did==did && l?.from_lid==lid && l?.from_pid==pid ) {
				link = l;
			}
			i++;
		}
		return link;
	}

}


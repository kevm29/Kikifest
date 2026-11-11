// Converti automatiquement depuis hammer/entity/supa/SupaItem.mt (Motion Twin)
package entity.supa;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
import Data as RootData;
class SupaItem extends entity.Supa
{

	public var supaId : Int;

	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new()  untyped {
		super();
		radius = 50;
	}


	/*------------------------------------------------------------------------
	INIT
	------------------------------------------------------------------------*/
	override public function initSupa(g:Dynamic,x:Dynamic,y:Dynamic)  untyped {
		super.initSupa(g,x,y);
		scale(200);
		moveDown(5);
		this.gotoAndStop(Std.string(supaId+1));
	}


	/*------------------------------------------------------------------------
	ATTACH
	------------------------------------------------------------------------*/
	public static function attach(g:mode.GameMode, id:Dynamic)  untyped {
		var linkage:Dynamic = "hammer_supa_item";
		var mc : entity.supa.SupaItem = (( g?.depthMan?.attach(linkage,RootData.DP_SUPA) ):Dynamic);
		{ if (mc != null) mc.supaId = id; }
		mc?.initSupa(g, RootData.GAME_WIDTH/2,-50 );
		return mc;
	}


	/*------------------------------------------------------------------------
	RAMASSAGE
	------------------------------------------------------------------------*/
	public function pick(pl:Dynamic)  untyped {
		game?.fxMan?.inGameParticles(RootData.PARTICLE_ICE,x,y,15);
		game?.fxMan?.attachExplodeZone(x,y,50);
		var score:Dynamic = RootData.getCrystalValue(supaId)*5;
		game?.manager?.logAction("$SU"+supaId);
		pl?.getScore(this,score);
		game?.soundMan?.playSound("sound_item_supa", RootData.CHAN_ITEM);

		// Fait pleurer l'autre joueur ^^
		var l:Dynamic = game?.getPlayerList();
		{ var i:Dynamic=0; while (i<l?.length) {
			if ( l[i]?.uniqId!=pl?.uniqId ) {
				l[i]?.setBaseAnims(RootData.ANIM_PLAYER_WALK, RootData.ANIM_PLAYER_STOP_L);
			}
		
i++; } }

		destroy();
	}


	/*------------------------------------------------------------------------
	EVENT: SORTIE PAR LE BAS (LOUPÉ !)
	------------------------------------------------------------------------*/
	override public function onDeathLine()  untyped {
		var pl:Dynamic = game?.getPlayerList();
		{ var i:Dynamic=0; while (i<pl?.length) {
			pl[i]?.setBaseAnims(RootData.ANIM_PLAYER_WALK, RootData.ANIM_PLAYER_STOP_L);
		
i++; } }
		destroy();
	}


	/*------------------------------------------------------------------------
	INFIXE
	------------------------------------------------------------------------*/
	override public function prefix()  untyped {
		super.prefix();

		var l:Dynamic = game?.getClose( RootData.PLAYER, x,y+RootData.CASE_HEIGHT*1.5, radius, false );
		var fl_break:Dynamic = false;
		{ var i:Dynamic=0; while (i<l?.length && !fl_break) {
			var e : entity.Player = ((l[i]):Dynamic);
			if ( !e?.fl_kill ) {
				pick(e);
				fl_break=true;
			}
		
i++; } }

		if ( y>=RootData.GAME_HEIGHT+50 ) {
			onDeathLine();
		}
	}


}

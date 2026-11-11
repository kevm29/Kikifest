// Converti automatiquement depuis hammer/entity/supa/Tons.mt (Motion Twin)
package entity.supa;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
import Data as RootData;
class Tons extends entity.Supa
{

	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new()  untyped {
		super();
		fl_gravity = true;
	}


	/*------------------------------------------------------------------------
	ATTACH
	------------------------------------------------------------------------*/
	public static function attach(g:mode.GameMode)  untyped {
		var linkage:Dynamic = "hammer_supa_tons";
		var mc : entity.supa.Tons = (( g.depthMan.attach(linkage,RootData.DP_SUPA) ):Dynamic);
		mc?.initSupa(g, RootData.GAME_WIDTH,0 );
		return mc;
	}


	/*------------------------------------------------------------------------
	INITIALISATION
	------------------------------------------------------------------------*/
	override public function initSupa(g:Dynamic,x:Dynamic,y:Dynamic)  untyped {
		super.initSupa(g,x,y);
		speed = 0;
		radius = 40;
		moveTo(MtStd.random(RootData.GAME_WIDTH),-40);
		fallFactor = 0.3;
	}


	/*------------------------------------------------------------------------
	INFIXE
	------------------------------------------------------------------------*/
	override public function prefix()  untyped {
		super.prefix();

		var l:Dynamic;

		// Bads
		l = game?.getClose( RootData.BAD, x,y, radius, false );
		{ var i:Dynamic=0; while (i<l?.length) {
			var e : entity.Bad = ((l[i]):Dynamic);
			if ( !e?.fl_kill ) {
				e?.killHit( (MtStd.random(2)*2-1)*MtStd.random(5) );
				{ if (e != null) e.dy=-25; }
			}
		
i++; } }

		// Player
		l = game?.getClose( RootData.PLAYER, x,y, radius, false );
		{ var i:Dynamic=0; while (i<l?.length) {
			var e : entity.Player = ((l[i]):Dynamic);
			if ( !e?.fl_kill ) {
				e?.killHit( (MtStd.random(2)*2-1)*MtStd.random(5) );
				{ if (e != null) e.dy=-25; }
			}
		
i++; } }
	}


	/*------------------------------------------------------------------------
	POSTFIXE
	------------------------------------------------------------------------*/
	override public function postfix()  untyped {
		super.postfix();
		if ( y>=RootData.GAME_HEIGHT*2 ) {
			moveTo(MtStd.random(RootData.GAME_WIDTH),-40);
			dy = 0;
		}
	}

}

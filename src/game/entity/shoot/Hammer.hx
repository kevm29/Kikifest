// Converti automatiquement depuis hammer/entity/shoot/Hammer.mt (Motion Twin)
package entity.shoot;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
import Data as RootData;
class Hammer extends entity.Shoot
{
	public var player	: entity.Player;

	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new()  untyped {
		super() ;
		shootSpeed = 0 ;
	}


	/*------------------------------------------------------------------------
	INITIALISATION
	------------------------------------------------------------------------*/
	override public function init(g:Dynamic)  untyped {
		super.init(g) ;
		playAnim(RootData.ANIM_SHOOT_LOOP) ;
	}


	/*------------------------------------------------------------------------
	ATTACH
	------------------------------------------------------------------------*/
	public static function attach( g:mode.GameMode, x:Dynamic,y:Dynamic )  untyped {
		var linkage:Dynamic = "hammer_shoot_hammer" ;
		var s : entity.shoot.Hammer = (( g?.depthMan?.attach(linkage,RootData.DP_SPEAR) ):Dynamic) ;
		s?.initShoot(g, x, y-10) ;
		return s ;
	}


	/*------------------------------------------------------------------------
	DESTRUCTION
	------------------------------------------------------------------------*/
	override public function destroy()  untyped {
		player?.specialMan?.interrupt(85);
		game?.fxMan?.attachFx(x,y-RootData.CASE_HEIGHT/2, "hammer_fx_pop") ;
		super.destroy() ;
	}


	/*------------------------------------------------------------------------
	DÉFINI LE PORTEUR
	------------------------------------------------------------------------*/
	public function setOwner(p:Dynamic)  untyped {
		player = p;
	}


	/*------------------------------------------------------------------------
	MISE À JOUR GRAPHIQUE
	------------------------------------------------------------------------*/
	override public function endUpdate()  untyped {
		super.endUpdate();
		if ( player?.dir>0 && _xscale<0 ) {
			_xscale = Math.abs(_xscale);
		}
		if ( player?.dir<0 && _xscale>0 ) {
			_xscale = -Math.abs(_xscale);
		}
	}


	/*------------------------------------------------------------------------
	MAIN
	------------------------------------------------------------------------*/
	override public function update()  untyped {
		var hx:Dynamic = player?.x + player?.dir*RootData.CASE_WIDTH*0.7;
		hx = Math.min(RootData.GAME_WIDTH-1,hx);
		hx = Math.max(1,hx);
		var hy:Dynamic = player?.y-RootData.CASE_HEIGHT*0.7;
		hx = Math.max( 1, Math.min(RootData.GAME_WIDTH-1, hx) );
		hy = Math.max( 20, Math.min(RootData.GAME_HEIGHT-1, hy) );
		moveTo(
			hx,
			hy
		);
		super.update();

		// Contact
		var l:Dynamic = game?.getClose(RootData.BAD, x,y, RootData.CASE_WIDTH*2, false);
		{ var i:Dynamic=0; while (i<l?.length) {
			((l[i]):Dynamic)?.killHit(player?.dir*9);
		
i++; } }

		if ( player?.fl_kill || game?.fl_clear || !player?.specialMan?.actives[85] ) {
			destroy();
		}
	}

}

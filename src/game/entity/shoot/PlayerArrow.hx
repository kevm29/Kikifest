// Converti automatiquement depuis hammer/entity/shoot/PlayerArrow.mt (Motion Twin)
package entity.shoot;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
import Data as RootData;
class PlayerArrow extends entity.Shoot
{
	public var fl_livedOneTurn	: Bool;

	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new()  untyped {
		super();
		shootSpeed	= 4;
		coolDown	= RootData.SECOND*2;
		_yOffset	= -15;
		fl_hitWall	= true;
		fl_teleport	= true;
		fl_livedOneTurn	= false;
	}


	/*------------------------------------------------------------------------
	INITIALISATION
	------------------------------------------------------------------------*/
	override public function init(g:Dynamic)  untyped {
		super.init(g);
		register(RootData.PLAYER_SHOOT) ;
		playAnim(RootData.ANIM_SHOOT_LOOP);
	}


	/*------------------------------------------------------------------------
	ATTACH
	------------------------------------------------------------------------*/
	public static function attach( g:mode.GameMode, x:Dynamic,y:Dynamic )  untyped {
		var linkage:Dynamic = "hammer_shoot_arrow";
		var s : entity.shoot.PlayerArrow = (( g?.depthMan?.attach(linkage,RootData.DP_SHOTS) ):Dynamic);
		s?.initShoot(g, x, y);
		return s;
	}


	/*------------------------------------------------------------------------
	EVENT: TOUCHE UN MUR
	------------------------------------------------------------------------*/
	override public function onHitWall()  untyped {
		if ( fl_livedOneTurn ) {
			var fx:Dynamic = game?.fxMan?.attachFx(x,y+_yOffset, "hammer_fx_arrowPouf");
			if ( dx<0 ) {
				{ if (fx?.mc != null) fx.mc._xscale = -fx?.mc?._xscale; }
			}
		}
		else {
			game?.fxMan?.attachFx(x,y-RootData.CASE_HEIGHT*0.5, "hammer_fx_pop");
		}
		destroy();
	}


	/*------------------------------------------------------------------------
	EVENT: HIT
	------------------------------------------------------------------------*/
	override public function hit(e:Entity)  untyped {
		if ( (e?.types & RootData.BAD) > 0 ) {
			var et : entity.Bad = ((e):Dynamic);
			et?.setCombo(uniqId);
			et?.killHit(dx);
			game?.fxMan?.attachFx(x,y-RootData.CASE_HEIGHT*0.5, "hammer_fx_pop");
			destroy();
		}
	}


	/*------------------------------------------------------------------------
	MAIN
	------------------------------------------------------------------------*/
	override public function update()  untyped {
		super.update();
		fl_livedOneTurn	= true;
	}

}


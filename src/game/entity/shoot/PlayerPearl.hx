// Converti automatiquement depuis hammer/entity/shoot/PlayerPearl.mt (Motion Twin)
package entity.shoot;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
import Data as RootData;
class PlayerPearl extends entity.Shoot
{

	public var shotList			: Array<Int>;
	public var fl_bounceBorders	: Bool;

	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new()  untyped {
		super();
		shootSpeed	= 8.5;
		coolDown	= RootData.SECOND*2;
		shotList	= new Array();
		_yOffset	= -16;
		fl_bounceBorders	= false;
	}


	override public function init(g:Dynamic)  untyped {
		super.init(g);
		register(RootData.PLAYER_SHOOT) ;
	}


	/*------------------------------------------------------------------------
	ATTACH
	------------------------------------------------------------------------*/
	public static function attach( g:mode.GameMode, x:Dynamic,y:Dynamic )  untyped {
		var linkage:Dynamic = "hammer_shoot_player_pearl";
		var s : entity.shoot.PlayerPearl = (( g.depthMan.attach(linkage,RootData.DP_SHOTS) ):Dynamic);
		s?.initShoot(g, x, y);
		return s;
	}


	/*------------------------------------------------------------------------
	VÉRIFIE SI UN UNIQID DE BAD EST DÉJÀ DANS LA LISTE DES BADS TOUCHÉS
	------------------------------------------------------------------------*/
	public function hasBeenShot(id:Dynamic)  untyped {
		{ var i:Dynamic=0; while (i<shotList?.length) {
			if ( shotList[i]==id ) {
				return true;
			}
		
i++; } }
		return false;
	}


	/*------------------------------------------------------------------------
	ANIM AU CONTACT D'UN BORD LATÉRAL
	------------------------------------------------------------------------*/
	public function hitWallAnim()  untyped {
		game?.fxMan?.inGameParticles(RootData.PARTICLE_ICE, x,y,2);
		game?.fxMan?.inGameParticles(RootData.PARTICLE_STONE, x,y,3);
		if ( dx<0 ) {
			game?.fxMan?.attachFx(x+RootData.CASE_WIDTH*0.5,y+_yOffset,"hammer_fx_icePouf");
		}
		else {
			game?.fxMan?.attachFx(x-RootData.CASE_WIDTH*0.5,y+_yOffset,"hammer_fx_icePouf");
		}
	}


	/*------------------------------------------------------------------------
	EVENT: REBOND BORDS LATÉRAUX
	------------------------------------------------------------------------*/
	override public function onSideBorderBounce()  untyped {
		super.onSideBorderBounce();
		hitWallAnim();
	}


	/*------------------------------------------------------------------------
	EVENT: FIN DE VIE
	------------------------------------------------------------------------*/
	override public function onLifeTimer()  untyped {
		game?.fxMan?.attachFx(x,y,"hammer_fx_pop");
		super.onLifeTimer();
	}


	/*------------------------------------------------------------------------
	UPDATE GRAPHIQUE
	------------------------------------------------------------------------*/
	override public function endUpdate()  untyped {
		if ( dy!=0 ) {
			rotation = Math.atan2( dy, dx ) * 180/Math.PI;
		}

		super.endUpdate();
	}


	override public function destroy()  untyped {
		if ( !fl_bounceBorders ) {
			hitWallAnim();
		}
		super.destroy();
	}


	/*------------------------------------------------------------------------
	EVENT: HIT
	------------------------------------------------------------------------*/
	override public function hit(e:Entity)  untyped {
		if ( (e?.types & RootData.BAD) > 0 ) {
			var et : entity.Bad = ((e):Dynamic);
			if ( !hasBeenShot(et?.uniqId) ) {
				et?.setCombo(uniqId);
				et?.freeze(RootData.FREEZE_DURATION);
				{ if (et != null) et.dx = dx*2; }
				{ if (et != null) et.dy -= 3; }
				shotList?.push(et?.uniqId);
			}
		}
	}


}


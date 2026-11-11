// Converti automatiquement depuis hammer/entity/shoot/PlayerFireBall.mt (Motion Twin)
package entity.shoot;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
import Data as RootData;
class PlayerFireBall extends entity.Shoot
{

	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new()  untyped {
		super();
		shootSpeed = 8;
		coolDown = RootData.SECOND*2;
	}


	/*------------------------------------------------------------------------
	INITIALISATION
	------------------------------------------------------------------------*/
	override public function init(g:Dynamic)  untyped {
		super.init(g);
		register(RootData.PLAYER_SHOOT) ;
	}


	/*------------------------------------------------------------------------
	ATTACH
	------------------------------------------------------------------------*/
	public static function attach( g:mode.GameMode, x:Dynamic,y:Dynamic )  untyped {
		var linkage:Dynamic = "hammer_shoot_player_fireball";
		var s : entity.shoot.PlayerFireBall = (( g.depthMan.attach(linkage,RootData.DP_SHOTS) ):Dynamic);
		s?.initShoot(g, x, y);
		return s;
	}


	/*------------------------------------------------------------------------
	EVENT: HIT
	------------------------------------------------------------------------*/
	override public function hit(e:Entity)  untyped {
		if ( (e?.types & RootData.BAD_CLEAR) > 0 ) {
			var et : entity.Bad = ((e):Dynamic);
			et?.setCombo(uniqId);
			et?.burn();
		}
	}


	/*------------------------------------------------------------------------
	DESTRUCTION
	------------------------------------------------------------------------*/
	override public function destroy()  untyped {
		game?.fxMan?.inGameParticles(RootData.PARTICLE_SPARK, x,y,3);
		game?.fxMan?.inGameParticles(RootData.PARTICLE_STONE, x,y,4);
		super.destroy();
	}


	/*------------------------------------------------------------------------
	MAIN
	------------------------------------------------------------------------*/
	override public function update()  untyped {
		super.update();

		// Trainées
		if ( MtStd.random(3)==0 ) {
			game?.fxMan?.inGameParticles(RootData.PARTICLE_SPARK, x,y,MtStd.random(3));
		}
	}

}


// Converti automatiquement depuis hammer/entity/bad/walker/Litchi.mt (Motion Twin)
package entity.bad.walker;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
import Data as RootData;
class Litchi extends entity.bad.Jumper {

	public var child	: entity.bad.walker.LitchiWeak;

	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new()  untyped {
		super() ;
		speed*=0.8;
		setJumpH(100) ;
		setJumpUp(10);
		setJumpDown(6);
		setClimb(25,3);
		setFall(25);
	}


	/*------------------------------------------------------------------------
	ATTACHEMENT
	------------------------------------------------------------------------*/
	public static function attach(g:mode.GameMode,x:Dynamic,y:Dynamic)  untyped {
		var linkage:Dynamic = RootData.LINKAGES[RootData.BAD_LITCHI];
		var mc : entity.bad.walker.Litchi = (( g.depthMan.attach(linkage,RootData.DP_BADS) ):Dynamic) ;
		mc?.initBad(g,x,y) ;
		return mc ;
	}


	/*------------------------------------------------------------------------
	OVERRIDE DES CONDITIONS DE MORT
	------------------------------------------------------------------------*/
	override public function freeze(d:Dynamic)  untyped {
		weaken();
	}
	override public function killHit(dx:Dynamic)  untyped {
		if ( !fl_knock ) {
			knock(RootData.KNOCK_DURATION);
//			if ( dx<0 ) {
//				moveToAng(-135, 8);
//			}
//			else {
//				moveToAng(-45, 8);
//			}
		}
	}


	/*------------------------------------------------------------------------
	HACK: PERMET UNE MORT INSTANTANÉE
	------------------------------------------------------------------------*/
	override public function forceKill(dx:Dynamic)  untyped {
		super.killHit(dx);
	}


	/*------------------------------------------------------------------------
	PERTE D'ARMURE
	------------------------------------------------------------------------*/
	public function weaken()  untyped {
		if ( child?._name != null ) {
			return;
		}
		child = entity.bad.walker.LitchiWeak.attach(game,x,y-RootData.CASE_HEIGHT);
		child?.angerMore();
		child?.updateSpeed();
		child?.halt();
		{ if (child != null) child.dir = dir; }
		{ if (child != null) child.fl_ninFoe = fl_ninFoe; }
		{ if (child != null) child.fl_ninFriend = fl_ninFriend; }
		game?.fxMan?.inGameParticles(
			RootData.PARTICLE_LITCHI,
			x + MtStd.random(20)*(MtStd.random(2)*2-1),
			y-MtStd.random(20),
			MtStd.random(3)+5
		);
		child?.playAnim(RootData.ANIM_BAD_SHOOT_START);
	}


	/*------------------------------------------------------------------------
	MAIN
	------------------------------------------------------------------------*/
	override public function update()  untyped {
		super.update();
		if ( !fl_kill && fl_knock && child==null && dy<=-RootData.BAD_VJUMP_Y*0.6 ) {
			dy = -RootData.BAD_VJUMP_Y*0.6;
		}
	}


	/*------------------------------------------------------------------------
	HACK POUR UTILISER LE DX/DY APRES SHOCKWAVE DU LITCHI GELÉ
	------------------------------------------------------------------------*/
	override public function endUpdate()  untyped {
		if ( child!=null ) {
//			child.dx = dx*0.5;
			{ if (child != null) child.dy = -7; } // -13
			destroy();
		}
		else {
			super.endUpdate();
		}
	}

}


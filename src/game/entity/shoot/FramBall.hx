// Converti automatiquement depuis hammer/entity/shoot/FramBall.mt (Motion Twin)
package entity.shoot;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
import Data as RootData;
class FramBall extends entity.Shoot
{
	public var turnSpeed			: Float;
	public var owner		: entity.bad.walker.Framboise;
	public var ang					: Float;
	public var fl_arrived			: Bool;
	public var white				: Float;

	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new()  untyped {
		super() ;
		shootSpeed = 5+MtStd.random(3) ;
		turnSpeed = 0.03 + MtStd.random(10)/100 + shootSpeed*0.02;
		_yOffset = -2 ;
		setLifeTimer(RootData.SECOND*4);
		fl_checkBounds = false;
		fl_blink = false;
		fl_arrived = false;
		fl_anim = false;
		this.gotoAndStop("1");
		ang = MtStd.random(314);
		white = 0;
	}


	public function setOwner(b:Dynamic)  untyped {
		owner = b;
		var tang:Dynamic = Math.atan2(owner?.ty-y,owner?.tx-x);
		ang = -tang + (MtStd.random(168)/100) * (MtStd.random(2)*2-1);
		if ( owner?.anger>0 ) {
			shootSpeed*=(1 + owner?.anger*0.5);
		}
	}


	/*------------------------------------------------------------------------
	ATTACH
	------------------------------------------------------------------------*/
	public static function attach( g:mode.GameMode, x:Dynamic,y:Dynamic )  untyped {
		var linkage:Dynamic = "hammer_shoot_framBall2" ;
		var s : entity.shoot.FramBall = (( g.depthMan.attach(linkage,RootData.DP_SHOTS) ):Dynamic) ;
		s?.initShoot(g, x, y) ;
		return s ;
	}


	/*------------------------------------------------------------------------
	EVENT: HIT
	------------------------------------------------------------------------*/
	override public function hit(e:Entity)  untyped {
		if ( (e?.types & RootData.PLAYER) > 0 ) {
			var et : entity.Player = ((e):Dynamic) ;
			et?.killHit(dx) ;
		}
	}


	public function adjustAngRad(a:Dynamic)  untyped {
		if ( a<-Math.PI ) return a+Math.PI*2;
		if ( a>Math.PI ) return a-Math.PI*2;
		return a;
	}


	override public function onLifeTimer()  untyped {
		onArrived();
		super.onLifeTimer();
	}


	public function onArrived()  untyped {
		if ( fl_arrived ) {
			return;
		}
		fl_arrived = true;
		owner?.onArrived(this);
	}


	/*------------------------------------------------------------------------
	GRAPHICAL UPDATE
	------------------------------------------------------------------------*/
	override public function endUpdate()  untyped {
		super.endUpdate();
//		if ( white>0 ) {
//			setColorHex(Math.round(100*white), 0xffffff);
//	    	var f = new flash.filters.GlowFilter();
//			f.color = 0xffffff;
//	    	f.strength	= white*3;
//	    	f.blurX		= 8;
//	    	f.blurY		= f.blurX;
//	    	this.filters = [f];
//		}
	}

	override public function infix()  untyped {
		super.infix();
		// slow down if close
		var d:Dynamic = distance(owner?.tx,owner?.ty);
		if ( d<40 ) {
			turnSpeed*=1.1;
		}
		if ( d<20 ) {
			shootSpeed*=0.9;
			if ( shootSpeed<=5.8 || owner?.anger>0 ) {
				onArrived();
			}
			white+=0.1*Timer.tmod;
			white = Math.min(1,white);
		}
		turnSpeed = Math.min(1,turnSpeed);
		shootSpeed = Math.max(2,shootSpeed);
	}

	/*------------------------------------------------------------------------
	MAIN
	------------------------------------------------------------------------*/
	override public function update()  untyped {

		// targetting
		var tang:Dynamic = Math.atan2(owner?.ty-y,owner?.tx-x);
		if ( adjustAngRad(tang-ang)>0 ) {
			ang+=turnSpeed*Timer.tmod;
		}
		if ( adjustAngRad(tang-ang)<0 ) {
			ang-=turnSpeed*Timer.tmod;
		}

		dx = Math.cos(ang)*shootSpeed * Timer.tmod;
		dy = Math.sin(ang)*shootSpeed * Timer.tmod;
		super.update();
	}
}

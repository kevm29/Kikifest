// Converti automatiquement depuis hammer/entity/bad/walker/Framboise.mt (Motion Twin)
package entity.bad.walker;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
import Data as RootData;
class Framboise extends entity.bad.Shooter {
	public static var FRAGS:Int = 6;
	public static var MAX_TRIES:Int = 1000;
	public var tx			: Float;
	public var ty			: Float;
	public var fl_phased	: Bool;
	public var arrived		: Int;
	public var white		: Float;


	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new()  untyped {
		super() ;

		setJumpUp(3) ;
		setJumpDown(6) ;
		setJumpH(100) ;
		setClimb(100,3);
		setFall(20) ;
		setShoot(0.7) ;

		initShooter(20, 12) ;

		white = 0;
		fl_phased = false;
	}


	/*------------------------------------------------------------------------
	INITIALISATION
	------------------------------------------------------------------------*/
	override public function init(g:Dynamic)  untyped {
		super.init(g) ;
	}


	/*------------------------------------------------------------------------
	ATTACHEMENT
	------------------------------------------------------------------------*/
	public static function attach(g:mode.GameMode,x:Dynamic,y:Dynamic)  untyped {
		var linkage:Dynamic = RootData.LINKAGES[RootData.BAD_FRAMBOISE];
		var mc : entity.bad.walker.Framboise = (( g?.depthMan?.attach(linkage,RootData.DP_BADS) ):Dynamic) ;
		mc?.initBad(g,x,y) ;
		return mc ;
	}


	/*------------------------------------------------------------------------
	APPROXIMATIVE COORDS
	------------------------------------------------------------------------*/
	public function aroundX(base:Dynamic)  untyped {
		return base + MtStd.random(RootData.CASE_WIDTH) * (MtStd.random(2)*2-1);
	}

	public function aroundY(base:Dynamic)  untyped {
		return base - MtStd.random(RootData.CASE_HEIGHT);
	}


	override public function isReady()  untyped {
		return super.isReady() && !fl_phased;
	}


	/*------------------------------------------------------------------------
	BAD'S EVENTS
	------------------------------------------------------------------------*/
	override public function freeze(d:Dynamic)  untyped {
		phaseIn();
		super.freeze(d);
	}

	override public function knock(d:Dynamic)  untyped {
		phaseIn();
		super.knock(d);
	}

	override public function killHit(dx:Dynamic)  untyped {
		phaseIn();
		super.killHit(dx);
	}

	override public function destroy()  untyped {
		clearFrags();
		super.destroy();
	}

	override public function onHitGround(h:Dynamic)  untyped {
		super.onHitGround(h);
		if ( h>=RootData.CASE_HEIGHT*2 ) {
			game?.fxMan?.inGameParticles( RootData.PARTICLE_FRAMB_SMALL, x,y, MtStd.random(4)+2 );
		}
	}


	/*------------------------------------------------------------------------
	A FRAGMENT HAS ARRIVED
	------------------------------------------------------------------------*/
	public function onArrived(fb:Dynamic)  untyped {
		show();
		moveTo( tx, ty );
		fb?.destroy();
		if ( fb?._currentframe>=5 ) {
			if ( fb?._currentframe==5 ) {
				{ if (((this.sub):Dynamic)?.o1 != null) ((this.sub):Dynamic).o1._visible = true; }
			}
			else {
				{ if (((this.sub):Dynamic)?.o2 != null) ((this.sub):Dynamic).o2._visible = true; }
			}
		}
		else {
			this.sub?.nextFrame();
		}

		arrived++;
		if ( arrived>=FRAGS ) {
			phaseIn();
		}
	}


	/*------------------------------------------------------------------------
	DELETE ALL FRAGS
	------------------------------------------------------------------------*/
	public function clearFrags()  untyped {
		var sl:Dynamic = game?.getList(RootData.SHOOT);
		{ var i:Dynamic=0; while (i<sl?.length) {
			var s:Dynamic=sl[i];
			if ( ((s):Dynamic)?.owner==this ) {
				s?.destroy();
			}
		
i++; } }
	}


	/*------------------------------------------------------------------------
	PHASING
	------------------------------------------------------------------------*/
	public function phaseOut()  untyped {
		game?.fxMan?.inGameParticles( RootData.PARTICLE_FRAMB_SMALL, x,y, MtStd.random(3)+2 );
		game?.fxMan?.attachExplosion(x,y,40);
		fl_phased = true;
		dx = 0;
		dy = 0;
		disableShooter();
		disableAnimator();
		this.gotoAndStop("15");
		this.sub?.stop();
		{ if (((this.sub):Dynamic)?.o1 != null) ((this.sub):Dynamic).o1._visible = false; }
		{ if (((this.sub):Dynamic)?.o2 != null) ((this.sub):Dynamic).o2._visible = false; }
		hide();
	}

	override public function walk()  untyped {
		if ( !fl_phased ) super.walk();
	}

	public function phaseIn()  untyped {
		clearFrags();
		fl_phased = false;
		enableAnimator();
		enableShooter();
		var a:Dynamic = game?.fxMan?.attachExplosion(x,y,40);
//		a.mc.blendMode = BlendMode.NORMAL;
//		white = 1;
	}


	/*------------------------------------------------------------------------
	EVENT: TIR
	------------------------------------------------------------------------*/
	override public function onShoot()  untyped {
		var tries:Dynamic = 0;
		var ctx:Dynamic;
		var cty:Dynamic;
		var d:Dynamic;
		var fl_inv:Dynamic;
		do {
			fl_inv = false;
			ctx = MtStd.random(RootData.LEVEL_WIDTH);
			cty = MtStd.random(RootData.LEVEL_HEIGHT);
			tries++;
			d = distanceCase(ctx,cty);
			if ( d<=7 ) fl_inv = true;
			if ( !game?.world?.checkFlag( {x:ctx,y:cty}, RootData.IA_TILE_TOP) ) fl_inv = true;
			if ( game?.world?.checkFlag( {x:ctx,y:cty}, RootData.IA_SMALL_SPOT) ) fl_inv = true;
			if ( game?.getListAt(RootData.SPEAR,ctx,cty)?.length>0 ) fl_inv = true;
		} while ( tries<MAX_TRIES && fl_inv );
		if ( tries>=MAX_TRIES ) {
			return;
		}
		tx = Entity.x_ctr(ctx);
		ty = Entity.y_ctr(cty);
		arrived = 0;
		phaseOut();

		var s:Dynamic;
		{ var i:Dynamic=0; while (i<FRAGS) {
			s = entity.shoot.FramBall.attach(game, aroundX(x),aroundY(y)) ;
			s?.setOwner(this);
			s?.gotoAndStop(""+(i+1));
		
i++; } }
	}

	/*------------------------------------------------------------------------
	GRAPHICAL UPDATE
	------------------------------------------------------------------------*/
	override public function endUpdate()  untyped {
		super.endUpdate();
		if ( white>0 ) {
			setColorHex(Math.round(100*white), 0xffffff);
	    	var f:Dynamic = new mtflash.filters.GlowFilter();
			{ if (f != null) f.color = 0xffffff; }
	    	{ if (f != null) f.strength	= white*2; }
	    	{ if (f != null) f.blurX		= 4; }
	    	{ if (f != null) f.blurY		= f?.blurX; }
	    	this.filters = [f];
	    	white-=Timer.tmod*0.1;
	    	if ( white<=0 ) {
	    		this.filters = [];
	    	}
		}
	}


	/*------------------------------------------------------------------------
	MAIN
	------------------------------------------------------------------------*/
	override public function update()  untyped {
		if ( !_visible ) {
			moveTo(100,-200);
			if ( !isHealthy() ) {
				show();
				moveTo( tx, ty );
				phaseIn();
			}
		} else {
			var bl:Dynamic = game?.getClose(RootData.PLAYER_BOMB, x,y, 90, false);
			if ( isReady() && bl?.length>=1 ) {
				startShoot();
			}
		}

		super.update();
	}

}


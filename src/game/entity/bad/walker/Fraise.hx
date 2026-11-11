// Converti automatiquement depuis hammer/entity/bad/walker/Fraise.mt (Motion Twin)
package entity.bad.walker;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
import Data as RootData;
class Fraise extends entity.bad.Shooter
{

	public var fl_ball		: Bool;
	public var ballTarget	: Entity;
	public var catchCD		: Float; // cooldown apres récup de la balle


	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new()  untyped {
		super();

		catchCD		= 0;
		animFactor	= 1.0;
		setShoot(4);

		initShooter(0,10);
	}


	/*------------------------------------------------------------------------
	INITIALISATION
	------------------------------------------------------------------------*/
	override public function init(g:Dynamic)  untyped {
		super.init(g);
		fl_ball = false;

		// Attribution de la première balle
		assignBall();
		var l:Dynamic = game?.getList(RootData.CATCHER);
		{ var i:Dynamic=0; while (i<l?.length) {
			var b : entity.bad.walker.Fraise = ((l[i]):Dynamic);
			if ( b?.fl_ball ) {
				fl_ball = false;
			}
		
i++; } }


		if ( game?.getList(RootData.BALL)?.length > 0 ) {
			fl_ball = false;
		}

		register(RootData.CATCHER);
	}


	/*------------------------------------------------------------------------
	ATTACHEMENT
	------------------------------------------------------------------------*/
	public static function attach(g:mode.GameMode,x:Dynamic,y:Dynamic)  untyped {
		var linkage:Dynamic = RootData.LINKAGES[RootData.BAD_FRAISE];
		var mc : entity.bad.walker.Fraise = (( g?.depthMan?.attach(linkage,RootData.DP_BADS) ):Dynamic);
		mc?.initBad(g,x,y);
		return mc;
	}


	/*------------------------------------------------------------------------
	RÉCEPTION D'UNE BALLE
	------------------------------------------------------------------------*/
	public function catchBall(b:entity.shoot.Ball)  untyped {
		if ( !isHealthy() ) {
			return;
		}
		next = null;
		walk();
		assignBall();
		b?.destroy();
		ballTarget = null;
	}


	/*------------------------------------------------------------------------
	ASSIGNE LA BALLE À CE BAD
	------------------------------------------------------------------------*/
	public function assignBall()  untyped {
		fl_ball = true;
		catchCD = RootData.SECOND*1.5;
	}


	/*------------------------------------------------------------------------
	EVENT: TIR
	------------------------------------------------------------------------*/
	override public function onShoot()  untyped {
		super.onShoot();

		// Lanceur
		this.fl_ball = false;

		// Le receveur est un bad
		if ( (ballTarget?.types&RootData.BAD)>0 ) {
			var bad : entity.bad.Walker = ((ballTarget):Dynamic);
			bad?.setNext(null,null, RootData.BALL_TIMEOUT+5, RootData.ACTION_WALK);
			bad?.halt();
			bad?.playAnim(RootData.ANIM_BAD_THINK);
		}

		// Balle
		var s:Dynamic = entity.shoot.Ball.attach(game,x,y);
		s?.moveToTarget( ballTarget, s?.shootSpeed );
		{ if (s != null) s.targetCatcher = ballTarget; }

	}


	/*------------------------------------------------------------------------
	EVENT: FIN D'ANIM
	------------------------------------------------------------------------*/
	override public function onEndAnim(id:Dynamic)  untyped {
		super.onEndAnim(id);
		ballTarget = null;
	}


	/*------------------------------------------------------------------------
	PRÉPARATION DU TIR (skippé)
	------------------------------------------------------------------------*/
	override public function startShoot()  untyped {
		if ( !fl_ball || catchCD>0 ) {
			return;
		}


		// Cherche un receveur
		var l:Dynamic = game?.getListCopy(RootData.CATCHER);
		var bad : entity.bad.Walker;
		do {
			var i:Dynamic = MtStd.random(l?.length);
			bad = ((l[i]):Dynamic);
			l?.splice(i,1);
		} while ( bad!=null && ( bad==this || !bad?.isReady() ) );


		if ( bad!=null ) {
			ballTarget = (cast (bad));
		}
		else {
			if ( game?.getList(RootData.CATCHER)?.length==1 ) {
				// Vise le joueur
				ballTarget = game?.getOne(RootData.PLAYER);
				if ( ballTarget==null ) {
					return;
				}
			}
			else {
				return;
			}
		}

		super.startShoot();
	}

	/*------------------------------------------------------------------------
	DESTRUCTION
	------------------------------------------------------------------------*/
	override public function destroy()  untyped {
		if ( fl_ball ) {
			// Ré-attribution de la balle
			var bad : entity.bad.walker.Fraise = ((game?.getAnotherOne(RootData.CATCHER, this)):Dynamic);
			if ( bad!=null ) {
				bad?.assignBall();
			}
		}
		super.destroy();
	}


	/*------------------------------------------------------------------------
	MAIN
	------------------------------------------------------------------------*/
	override public function endUpdate()  untyped {
		super.endUpdate();

		// Balle en main
		if ( fl_ball ) {
			{ if (((sub):Dynamic)?.balle != null) ((sub):Dynamic).balle._visible = true; }
		}
		else {
			{ if (((sub):Dynamic)?.balle != null) ((sub):Dynamic).balle._visible = false; }
		}

		// Se tourne dans la direction du tir
		if ( dx==0 && ballTarget?.fl_destroy==false ) {
			if ( ballTarget?.x > x ) {
				_xscale = Math.abs(_xscale);
			}
			if ( ballTarget?.x < x ) {
				_xscale = -Math.abs(_xscale);
			}
		}
	}


	/*------------------------------------------------------------------------
	MAIN
	------------------------------------------------------------------------*/
	override public function update()  untyped {
		super.update();

		if ( catchCD > 0 ) {
			catchCD -= Timer.tmod;
			if ( catchCD <= 0 ) {
				catchCD = 0;
			}
		}

		// Patch: perte de balle
		if ( game?.countList(RootData.BALL)==0 ) {
			var fl_lost:Dynamic = true;
			var bl:Dynamic = game?.getList(RootData.BAD_CLEAR);
			{ var i:Dynamic=0; while (i<bl?.length) {
				if ( ((bl[i]):Dynamic)?.fl_ball ) {
					fl_lost = false;
				}
			
i++; } }
			if ( fl_lost ) {
				assignBall();
			}
		}
	}


}


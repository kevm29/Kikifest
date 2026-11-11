// Converti automatiquement depuis hammer/entity/Animator.mt (Motion Twin)
package entity;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
import Data as RootData;
class Animator extends entity.Trigger
{

	public var sub				: MovieClip;
	public var animId			: Int;

	public var frame			: Float;
	public var animFactor		: Float;
	public var blinkTimer		: Float;

	public var blinkColor		: Int;
	public var blinkColorAlpha	: Int;
	public var blinkAlpha		: Int;


	public var fl_anim			: Bool;
	public var fl_loop			: Bool;
	public var fl_blink		: Bool;
	public var fl_alphaBlink	: Bool;
	public var fl_stickyAnim	: Bool;

	public var fadeStep		: Float;

	public var fl_blinking	: Bool;
	public var fl_blinked	: Bool;


	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new()  untyped {
		super();
		frame = 0;
		fadeStep = 0;
		animFactor = 1.0;
		fl_loop			= false;
		fl_blinking		= false;
		fl_blinked		= true;
		fl_stickyAnim	= false;

		fl_alphaBlink	= true;
		fl_blink		= true;
		blinkTimer		= 0;
		blinkColor		= 0xffffff;
		blinkAlpha		= 20;
		blinkColorAlpha	= 30;
		enableAnimator();
	}


	/*------------------------------------------------------------------------
	INITIALISATION
	------------------------------------------------------------------------*/
	override public function init(g:mode.GameMode)  untyped {
		super.init(g);
		this.gotoAndStop("1");
		sub?.stop();
	}


	/*------------------------------------------------------------------------
	ACTIVE/DÉSACTIVE L'ANIMATOR
	------------------------------------------------------------------------*/
	public function enableAnimator()  untyped {
		fl_anim = true;
		this.stop();
	}
	public function disableAnimator()  untyped {
		fl_anim = false;
		this.play();
	}


	/*------------------------------------------------------------------------
	ACTIVE/DÉSACTIVE LE CLIGNOTEMENT
	------------------------------------------------------------------------*/
	public function blink(duration:Dynamic)  untyped {
		if ( !fl_blink ) {
			return;
		}
		fl_blinking = true;
		blinkTimer = duration;
	}
	public function stopBlink()  untyped {
		fl_blinking = false;
		if ( fl_alphaBlink ) {
			alpha = 100;
		}
		else {
			resetColor();
		}
	}

	/*------------------------------------------------------------------------
	LANCE UN CLIGNOTEMENT BASÉ SUR LA DURÉE DE VIE
	------------------------------------------------------------------------*/
	public function blinkLife()  untyped {
		if ( lifeTimer/totalLife<=0.1 ) {
			blink(RootData.BLINK_DURATION_FAST);
		}
		else if ( lifeTimer/totalLife<=0.3 ) {
			blink(RootData.BLINK_DURATION);
		}
	}


	/*------------------------------------------------------------------------
	REDÉFINI LE PATH VERS L'ANIMATION
	------------------------------------------------------------------------*/
	public function setSub(mc:Dynamic)  untyped {
		sub = mc;
	}


	/*------------------------------------------------------------------------
	EVENT: FIN D'ANIM
	------------------------------------------------------------------------*/
	public function onEndAnim(id:Dynamic)  untyped {
		unstickAnim();
		// Do nothing
	}

	public function stickAnim()  untyped {
		fl_stickyAnim = true;
	}

	public function unstickAnim()  untyped {
		fl_stickyAnim = false;
	}


	/*------------------------------------------------------------------------
	MET L'ENTITÉ DANS UNE PHASE D'ANIM DONNÉE (1 À N)
	------------------------------------------------------------------------*/
	public function playAnim( animObject:Dynamic )  untyped {
		if ( fl_stickyAnim || fl_kill || !fl_anim ) {
			return;
		}
		if ( animId == animObject?.id && fl_loop == animObject?.loop ) {
			return;
		}

		animId = animObject?.id;
		this.gotoAndStop(""+(animId+1));
		sub?.gotoAndStop("1");
		fl_loop = animObject?.loop;
		frame = 0;
	}

	/*------------------------------------------------------------------------
	FORCE LA VALEUR DU FLAG DE LOOP
	------------------------------------------------------------------------*/
	public function forceLoop(flag:Dynamic)  untyped {
		fl_loop = flag;
	}


	/*------------------------------------------------------------------------
	RELANCE L'ANIMATION EN COURS
	------------------------------------------------------------------------*/
	public function replayAnim()  untyped {
		var id:Dynamic = animId;
		var fid:Dynamic = ( (id==1)?2:1 );
		playAnim( {id:fid,	loop:fl_loop} );
		playAnim( {id:id, 	loop:fl_loop} );
	}

//	/*------------------------------------------------------------------------
//	LANCE UN FADE AU BLANC
//	------------------------------------------------------------------------*/
//	function fade(duration) {
//		fadeStep = duration * Timer.fps / 100;
//		// 20   1
//		//      2
//	}


	/*------------------------------------------------------------------------
	MAIN
	------------------------------------------------------------------------*/
	override public function update()  untyped {
		super.update();

		// Clignotement
		if ( fl_blink ) {
			if ( !fl_blinking && lifeTimer>0 ) {
				blinkLife();
			}
			if ( fl_blinking ) {
				blinkTimer-=Timer.tmod;
				if ( blinkTimer<=0 ) {
					if ( fl_blinked ) {
						if ( fl_alphaBlink ) {
							alpha = 100;
						}
						else {
							resetColor();
						}
						fl_blinked = false;
					}
					else {
						if ( fl_alphaBlink ) {
							alpha = blinkAlpha;
						}
						else {
							setColorHex(blinkColorAlpha,blinkColor);
						}
						fl_blinked = true;
					}
					blinkLife();
				}
			}
		}


		if ( !fl_anim ) return;


		// Lecture du subMovie
		if ( frame>=0 ) {
			var fl_break:Dynamic=false;
			frame += animFactor*Timer.tmod;
			while (!fl_break && frame>=1) {
				if (sub?._currentframe==sub?._totalframes ) {
					if ( fl_loop ) {
						sub?.gotoAndStop("1");
					}
					else {
						frame = -1;
						onEndAnim(animId);
						fl_break=true;
					}
				}
				if (!fl_break) {
					sub?.nextFrame();
					frame--;
				}
			}
		}
	}

}

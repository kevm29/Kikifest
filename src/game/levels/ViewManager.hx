// Converti automatiquement depuis hammer/levels/ViewManager.mt (Motion Twin)
package levels;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
import Data as RootData;
import mtflash.display.BitmapData;

class ViewManager extends levels.SetManager
{

	public var view			: levels.View;
	public var fake			: MovieClip;
	public var fl_hideTiles	: Bool;
	public var fl_hideBorders	: Bool;
	public var fl_shadow 		: Bool;
	public var scroller		: MovieClip;
	public var scrollDir		: Int;

	public var fl_restoring	: Bool;
	public var fl_scrolling	: Bool;
	public var fl_hscrolling	: Bool;
	public var fl_fading		: Bool;
	public var fl_fadeNextTransition	: Bool;
	public var darknessFactor	: Float;

	public var prevSnap		: BitmapData;

	public var depthMan		: DepthManager;

	// Scrolling
	public var scrollCpt : Float ;



	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new(m:Dynamic,setName:Dynamic)  untyped {
		super(m,setName);
		fl_scrolling	= false;
		fl_hscrolling	= false;
		fl_hideTiles	= false;
		fl_hideBorders	= false;
		fl_shadow		= true;

		fl_restoring	= false;
		fl_fading		= false;

		darknessFactor	= 0;
	}

	/*------------------------------------------------------------------------
	DESTRUCTEUR
	------------------------------------------------------------------------*/
	override public function destroy()  untyped {
		super.destroy();
		view?.destroy();
		fake?.removeMovieClip();
	}

	/*------------------------------------------------------------------------
	LINK UN DEPTH-MANAGER EXTERNE
	------------------------------------------------------------------------*/
	public function setDepthMan(d:DepthManager)  untyped {
		depthMan = d;
	}



	/*------------------------------------------------------------------------
	GESTION DE LA VUE FAKE
	------------------------------------------------------------------------*/
	public function cloneView(v:Dynamic)  untyped {
		var snap:Dynamic = v?.getSnapShot(0,0);
		createFake(snap);
	}

	public function createFake(snap:Dynamic)  untyped {
		fake?.removeMovieClip();
		fake = depthMan?.empty(RootData.DP_SCROLLER);
		{ if (fake != null) fake.blendMode = BlendMode.LAYER; }
		var mc:Dynamic = MtStd.createEmptyMC(fake,0);
		{ if (mc != null) mc._x = -10; }
		mc?.attachBitmap(snap,0);
		{ if (fake != null) fake._alpha = Math.max(0, 100-darknessFactor); }
	}




	// *** EVENTS *****

	/*------------------------------------------------------------------------
	EVENT: GENERIC TRANSITION CALLBACK
	------------------------------------------------------------------------*/
	public function onTransitionDone()  untyped {
		view?.moveTo(0,0);
		fake?.removeMovieClip();
		if ( fl_mirror ) {
			flipPortals();
		}
	}

	/*------------------------------------------------------------------------
	EVENT: SCROLLING TERMINÉ
	------------------------------------------------------------------------*/
	public function onScrollDone()  untyped {
		fl_scrolling = false;
		onViewReady();
	}


	/*------------------------------------------------------------------------
	EVENT: SCROLLING HORIZONTAL TERMINÉ
	------------------------------------------------------------------------*/
	public function onHScrollDone()  untyped {
		fl_hscrolling = false;
	}


	/*------------------------------------------------------------------------
	EVENT: FADE TERMINÉ
	------------------------------------------------------------------------*/
	public function onFadeDone()  untyped {
		fl_fading = false;
	}


	/*------------------------------------------------------------------------
	EVENT: VUE PRÊTE À ÊTRE JOUER
	------------------------------------------------------------------------*/
	public function onViewReady()  untyped {
		// do nothing
	}


	/*------------------------------------------------------------------------
	EVENT: DÉCODAGE TERMINÉ
	------------------------------------------------------------------------*/
	override public function onDataReady()  untyped {
		super.onDataReady();


		if ( !view?.fl_attach ) {
			view?.destroy();
			view = createView(currentId);
			if ( fl_restoring ) {
				view?.moveTo(RootData.GAME_WIDTH,0);
				onRestoreReady();
			}
			else {
				view?.moveTo(0,0);
				onViewReady();
			}
		}
		else {
			cloneView(view);

			teleporterList = new Array();

			view?.destroy();
			view = createView(currentId);
			view?.moveTo(0,RootData.GAME_HEIGHT);
			scrollCpt = 0;

			fl_scrolling = true;
		}
	}


	/*------------------------------------------------------------------------
	EVENT: RESTORE TERMINÉ
	------------------------------------------------------------------------*/
	override public function onRestoreReady()  untyped {
		super.onRestoreReady();
		fl_restoring = false;
		if ( fl_fadeNextTransition ) {
			fl_fadeNextTransition = false;
			fl_fading = true;
			view?.moveTo(0,0);
		}
		else {
			fl_hscrolling = true;
			scrollCpt = 0;
		}

		// hack: scrolldir is set in GameMechanics
	}


	/*------------------------------------------------------------------------
	ATTACH: VUE
	------------------------------------------------------------------------*/
	public function createView(id:Dynamic)  untyped {
		var v:Dynamic = new levels.View(this, depthMan);
		{ if (v != null) v.fl_hideTiles = fl_hideTiles; }
		{ if (v != null) v.fl_hideBorders = fl_hideBorders; }
		v?.detach();
		if ( !fl_shadow ) {
			v?.removeShadows();
		}
		v?.display(id);
		return v;
	}


	/*------------------------------------------------------------------------
	GESTION MISE EN ATTENTE
	------------------------------------------------------------------------*/
	override public function suspend()  untyped {
		super.suspend();
		view?.detach();
		fake?.removeMovieClip();
	}

	override public function restore(lid:Dynamic)  untyped {
		super.restore(lid);
		fl_restoring = true;
		goto(lid);
	}


	/*------------------------------------------------------------------------
	RÉACTIVATION AVEC ANIM DE TRANSITION DEPUIS UN SNAPSHOT
	------------------------------------------------------------------------*/
	public function restoreFrom(snap:Dynamic,lid:Dynamic)  untyped {
		prevSnap = snap;
		createFake(prevSnap);
		view?.moveTo(RootData.GAME_WIDTH,0);
		restore(lid);
	}


	/*------------------------------------------------------------------------
	RENVOIE UN SNAP SHOT DE LA VUE EN COURS
	------------------------------------------------------------------------*/
	public function getSnapShot() : BitmapData  untyped {
		return view?.getSnapShot(0,0);
	}



	/*------------------------------------------------------------------------
	BOUCLE PRINCIPALE (SCROLLING)
	------------------------------------------------------------------------*/
	override public function update()  untyped {
		super.update();

		if ( fl_scrolling ) {
			scrollCpt += RootData.SCROLL_SPEED * Timer.tmod ;
			view?.moveTo(0, RootData.GAME_HEIGHT+Math.sin(scrollCpt)*(0-RootData.GAME_HEIGHT) ) ;
//			fake.moveTo(0, -Math.sin(scrollCpt)*(Data.GAME_HEIGHT) ) ;
			{ if (fake != null) fake._x = 0; }
			{ if (fake != null) fake._y = -Math.sin(scrollCpt)*(RootData.GAME_HEIGHT); }

			if ( scrollCpt>=Math.PI/2 ) {
				onTransitionDone();
				onScrollDone() ;
			}
		}

		if ( fl_hscrolling ) {
			scrollCpt += scrollDir * RootData.SCROLL_SPEED * Timer.tmod ;
			if ( scrollDir>0 ) {
				view?.moveTo( 20+RootData.GAME_WIDTH+Math.sin(scrollCpt)*(0-RootData.GAME_WIDTH-20), 0 ) ;
			}
			else {
				view?.moveTo( -RootData.GAME_WIDTH-20-Math.sin(scrollCpt)*(RootData.GAME_WIDTH+20), 0 ) ;
			}
			{ if (fake != null) fake._x = -Math.sin(scrollCpt)*(RootData.GAME_WIDTH+20); }
			{ if (fake != null) fake._y = 0; }

			if ( scrollCpt>=Math.PI/2 || scrollCpt<=-Math.PI/2 ) {
				onTransitionDone();
				onHScrollDone() ;
			}
		}

		if ( fl_fading ) {
			{ if (fake != null) fake._alpha -= Timer.tmod*RootData.FADE_SPEED; }

			var f:Dynamic = new mtflash.filters.BlurFilter();
			{ if (f != null) f.blurX			= 100-fake?._alpha; }
			{ if (f != null) f.blurY			= f?.blurX*0.3; }
			{ if (fake != null) fake.filters	= [f]; }

			if ( fake?._alpha<=0 ) {
				onTransitionDone();
				onFadeDone();
			}
		}

	}

}



// Converti automatiquement depuis hammer/entity/Shoot.mt (Motion Twin)
package entity;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
import Data as RootData;
class Shoot extends entity.Physics
{
	public var shootSpeed		: Float ;
	public var shootY			: Float ;
	public var coolDown 		: Float ;
	public var fl_borderBounce	: Bool ;
	public var fl_checkBounds	: Bool;

	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new()  untyped {
		super() ;
		// Physics
		fl_hitWall		= false ;
		fl_hitBorder	= false ;
		fl_hitGround	= false ;
		fl_gravity		= false ;
		fl_friction		= false ;
		fl_borderBounce	= false ;
		fl_checkBounds	= true;
		fl_bump			= false;
		coolDown = 50 ;
	}

	/*------------------------------------------------------------------------
	INITIALISATION
	------------------------------------------------------------------------*/
	override public function init(g:Dynamic)  untyped {
		super.init(g) ;
		register(RootData.SHOOT) ;
		setSub(this) ;
		playAnim(RootData.ANIM_SHOOT) ;
	}

	/*------------------------------------------------------------------------
	INITIALISATION
	------------------------------------------------------------------------*/
	public function initShoot(g:mode.GameMode, x:Dynamic,y:Dynamic)  untyped {
		init(g) ;
		moveTo(x,y) ;
		endUpdate() ;
	}


	/*------------------------------------------------------------------------
	MISE À JOUR GRAPHIQUE
	------------------------------------------------------------------------*/
	override public function endUpdate()  untyped {
		// Flip horizontal
		if ( dy==0 ) {
			if ( dx<0 ) {
				_xscale = -Math.abs(_xscale) ;
			}
			else {
				_xscale = Math.abs(_xscale) ;
			}
		}

		super.endUpdate();
	}



	/*------------------------------------------------------------------------
	EVENT: REBOND AUX BORDS
	------------------------------------------------------------------------*/
	public function onSideBorderBounce()  untyped {
		// do nothing
	}

	public function onHorizontalBorderBounce()  untyped {
		// do nothing
	}


	/*------------------------------------------------------------------------
	MAIN
	------------------------------------------------------------------------*/
	override public function update()  untyped {
		super.update() ;

		// Hors-jeu
		if ( fl_checkBounds ) {
			if ( fl_borderBounce ) {
				// Rebonds aux bords du jeu
				if ( x<0 ) {
					onSideBorderBounce();
					dx = Math.abs(dx) ;
				}
				if ( x>=RootData.GAME_WIDTH ) {
					onSideBorderBounce();
					dx = -Math.abs(dx) ;
				}

				if ( y<0 ) {
					onHorizontalBorderBounce();
					dy = Math.abs(dy) ;
				}
				if ( y>=RootData.GAME_HEIGHT ) {
					onHorizontalBorderBounce();
					dy = -Math.abs(dy) ;
				}
			}
			else {
				// Destruction
				if ( !world?.inBound(cx,cy) ) {
					destroy() ;
				}
			}
		}

	}

}


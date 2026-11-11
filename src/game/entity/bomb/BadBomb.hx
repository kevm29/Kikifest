// Converti automatiquement depuis hammer/entity/bomb/BadBomb.mt (Motion Twin)
package entity.bomb;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
import Data as RootData;
class BadBomb extends entity.Bomb
{
	public var owner : entity.Bad;

	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new()  untyped {
		super();
		fl_airKick = true;
	}


	/*------------------------------------------------------------------------
	INITIALISATION
	------------------------------------------------------------------------*/
	override public function init(g:Dynamic)  untyped {
		super.init(g);
		register(RootData.BAD_BOMB);
	}

	/*------------------------------------------------------------------------
	INITIALISATION BOMBE
	------------------------------------------------------------------------*/
	override public function initBomb(g:Dynamic,x:Dynamic,y:Dynamic)  untyped {
		super.initBomb(g,x,y);
		if ( game?.fl_bombExpert ) {
			radius*=1.4;
		}
	}


	/*------------------------------------------------------------------------
	DÉFINI LE BAD PARENT DE LA BOMBE
	------------------------------------------------------------------------*/
	public function setOwner(b:Dynamic)  untyped {
		owner = b;
	}


	/*------------------------------------------------------------------------
	GÈLE LA BOMBE ET LA REND DANGEUREUSE POUR LE BAD
	------------------------------------------------------------------------*/
	public function getFrozen(uid:Dynamic) : entity.Bomb  untyped {
		return null; // do nothing
	}


	/*------------------------------------------------------------------------
	EVENT: EXPLOSION
	------------------------------------------------------------------------*/
	override public function onExplode()  untyped {
		super.onExplode();
		if ( game?.getDynamicVar("$BAD_BOMB_TRIGGER")!=null ) {
			game?.onExplode(x,y,radius);
		}
	}

	/*------------------------------------------------------------------------
	EVENT: KICK (BOMBES FACILES À REPOUSSER)
	------------------------------------------------------------------------*/
	override public function onKick(p:Dynamic)  untyped {
		super.onKick(p);
		dx*=3;
	}
}


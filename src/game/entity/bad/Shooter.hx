// Converti automatiquement depuis hammer/entity/bad/Shooter.mt (Motion Twin)
package entity.bad;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
import Data as RootData;
class Shooter extends entity.bad.Jumper
{

	public var fl_shooter		: Bool;

	public var shootCD			: Float;
	public var shootDuration	: Float;
	public var shootPreparation: Float;
	public var chanceShoot		: Int;

	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new()  untyped {
		super();
		shootCD	= RootData.PEACE_COOLDOWN;
		disableShooter();
		setShoot(null);
	}


	/*------------------------------------------------------------------------
	INITIALISATION
	------------------------------------------------------------------------*/
	override public function init(g:Dynamic)  untyped {
		super.init(g);
	}


	/*------------------------------------------------------------------------
	INITIALISATION PARAMÈTRES DE TIR
	------------------------------------------------------------------------*/
	public function initShooter( prepa:Dynamic, duration:Dynamic )  untyped {
		shootPreparation = prepa;
		shootDuration = duration;
	}


	/*------------------------------------------------------------------------
	ACTIVE/DÉSACTIVE LE COMPORTEMENT SHOOTER
	------------------------------------------------------------------------*/
	public function enableShooter()  untyped {
		fl_shooter = true;
	}
	public function disableShooter()  untyped {
		fl_shooter = false;
	}


	public function setShoot(chance:Dynamic)  untyped {
		if ( chance==null ) {
			fl_shooter = false;
		}
		else {
			fl_shooter = true;
			chanceShoot = chance*10;
		}
	}

	/*------------------------------------------------------------------------
	EVENT: FIN D'ATTENTE POUR UNE ACTION
	------------------------------------------------------------------------*/
	override public function onNext()  untyped {
		super.onNext();
		if ( next?.action == RootData.ACTION_SHOOT ) {
			setNext(null,null,shootDuration, RootData.ACTION_WALK);
			halt();
			playAnim( RootData.ANIM_BAD_SHOOT_END );
			onShoot();
		}
	}


	/*------------------------------------------------------------------------
	PRÉPARATION AU TIR
	------------------------------------------------------------------------*/
	public function startShoot()  untyped {
		setNext(dx,dy,shootPreparation,RootData.ACTION_SHOOT);
		halt();
		playAnim( RootData.ANIM_BAD_SHOOT_START );
	}


	/*------------------------------------------------------------------------
	EVENT: ANIMATION LUE
	------------------------------------------------------------------------*/
	override public function onEndAnim(id:Dynamic)  untyped {
		super.onEndAnim(id);
		if ( id==RootData.ANIM_BAD_SHOOT_START.id ) {
			playAnim( RootData.ANIM_BAD_SHOOT_LOOP );
		}
	}


	/*------------------------------------------------------------------------
	EVENT: TIR LANCÉ
	------------------------------------------------------------------------*/
	public function onShoot()  untyped {
		// do nothing
	}


	/*------------------------------------------------------------------------
	MAIN
	------------------------------------------------------------------------*/
	override public function update()  untyped {
		if ( shootCD>0 ) {
			shootCD-=Timer.tmod;
		}
		if ( fl_shooter && shootCD<=0 ) {
			if ( isReady() && MtStd.random(1000)<chanceShoot ) {
				startShoot();
			}
		}
		super.update();
	}

}


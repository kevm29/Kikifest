// Converti automatiquement depuis hammer/entity/bomb/PlayerBomb.mt (Motion Twin)
package entity.bomb;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
import Data as RootData;
class PlayerBomb extends entity.Bomb
{
	public static var UPGRADE_FACTOR:Float	= 1.5;
	public static var MAX_UPGRADES:Int		= 1;

	public var owner			: entity.Player;
	public var upgrades		: Int;
	public var fl_unstable		: Bool;

	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new()  untyped {
		super();
		fl_airKick	= true;
		fl_unstable	= false;
		upgrades	= 0;
	}


	/*------------------------------------------------------------------------
	INITIALISATION
	------------------------------------------------------------------------*/
	override public function init(g:Dynamic)  untyped {
		super.init(g);
		register(RootData.PLAYER_BOMB);
	}


	/*------------------------------------------------------------------------
	DÉFINI LE PLAYER PARENT DE LA BOMBE
	------------------------------------------------------------------------*/
	public function setOwner(p:Dynamic)  untyped {
		owner = p;
	}


	/*------------------------------------------------------------------------
	TOUCHE UNE ENTITÉ
	------------------------------------------------------------------------*/
	override public function hit(e:Entity)  untyped {
		super.hit(e) ;
		if ( fl_unstable ) {
			if ( (e?.types&RootData.BAD)>0 ) {
				onExplode() ;
			}
		}
	}


	/*------------------------------------------------------------------------
	EVENT: TOUCHE LE SOL
	------------------------------------------------------------------------*/
	override public function onHitGround(h:Dynamic)  untyped {
		super.onHitGround(h) ;
		if ( fl_unstable && fl_bounce ) {
			onExplode() ;
		}
	}

	/*------------------------------------------------------------------------
	EVENT: BOMBE KICKÉE
	------------------------------------------------------------------------*/
	override public function onKick(p:Dynamic)  untyped {
		if ( upgrades<MAX_UPGRADES ) {
			if ( p?.pid!=owner?.pid ) {
				upgradeBomb(p);
			}
		}

		super.onKick(p);
		if ( !fl_stable ) {
			fl_airKick = false;
		}
	}


	/*------------------------------------------------------------------------
	AUGMENTE LA PUISSANCE D'UNE BOMBE
	------------------------------------------------------------------------*/
	public function upgradeBomb(p:Dynamic)  untyped {
		game?.fxMan?.attachFx(x,y,"hammer_fx_pop");
		radius*=UPGRADE_FACTOR;
		power*=UPGRADE_FACTOR;
		setLifeTimer(duration*0.7);
		dx*=1.5;
		fl_blink = true;
		fl_alphaBlink = false;
		blinkColor = 0xff0000;
		scale( scaleFactor*UPGRADE_FACTOR*100 );
		owner = p;
		upgrades++;
	}


	/*------------------------------------------------------------------------
	EVENT: DESTRUCTION
	------------------------------------------------------------------------*/
	override public function onLifeTimer()  untyped {
		var p : entity.Player = ((parent):Dynamic);
//		if ( p!=null && world.currentId<100 ) { // patch anti score infini
//			p.getScore( null,10 );
//		}
		super.onLifeTimer();
	}


	/*------------------------------------------------------------------------
	EVENT: EXPLOSION
	------------------------------------------------------------------------*/
	override public function onExplode()  untyped {
		super.onExplode();

		if ( upgrades>0 ) {
			game?.fxMan?.attachExplosion(x,y,radius);
		}

		if ( game?.fl_bombExpert ) {
			var pl:Dynamic = game?.getPlayerList();
			{ var i:Dynamic=0; while (i<pl?.length) {
				var p:Dynamic = pl[i];
				var dist:Dynamic = distance( p?.x, p?.y );
				if ( dist<=radius ) {
					var ratio:Dynamic = (radius-dist)/radius;
					p?.knock( RootData.SECOND + 2*RootData.SECOND*ratio );
					var ang:Dynamic = Math.atan2( p?.y-y, p?.x-x );
					{ if (p != null) p.dx = Math.cos(ang)*power*0.7*ratio; }
					{ if (p != null) p.dy = Math.sin(ang)*power*0.7*ratio; }
				}
			
i++; } }
		}

		game?.onExplode(x,y,radius);

		if ( owner!=null ) {

			if ( owner?.specialMan?.actives[14] ) { // champi bleu
				entity.item.ScoreItem.attach(game, x,y, 47,0);
			}
			if ( owner?.specialMan?.actives[15] ) { // champi rouge
				entity.item.ScoreItem.attach(game, x,y, 48,0);
			}
			if ( owner?.specialMan?.actives[16] ) { // champi vert
				entity.item.ScoreItem.attach(game, x,y, 49,0);
			}
			if ( owner?.specialMan?.actives[17] ) { // champi or
				entity.item.ScoreItem.attach(game, x,y, 50,0);
			}

		}
	}


	override public function update()  untyped {
		super.update();
		if ( !fl_blinking && upgrades>0 ) {
			blink(RootData.BLINK_DURATION_FAST);
		}
	}

}


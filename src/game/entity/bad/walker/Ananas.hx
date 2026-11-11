// Converti automatiquement depuis hammer/entity/bad/walker/Ananas.mt (Motion Twin)
package entity.bad.walker;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
import Data as RootData;
class Ananas extends entity.bad.Jumper {

	public static var CHANCE_DASH:Int	= 6;

	public var fl_attack	: Bool ;

	public var dashRadius	: Float ;
	public var dashPower	: Float ;

	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new()  untyped {
		super() ;
		setJumpH(100) ;
		speed			*= 0.8 ;
		dashRadius 		= 100 ;
		dashPower		= 30 ;
		fl_attack		= false ;
		slideFriction	= 0.9;
		shockResistance	= 2.0;
	}


	/*------------------------------------------------------------------------
	INITIALISATION
	------------------------------------------------------------------------*/
	override public function init(g:Dynamic)  untyped {
		super.init(g) ;
		if ( game?.fl_bombExpert ) {
			dashRadius*=2;
		}
	}


	/*------------------------------------------------------------------------
	ATTACHEMENT
	------------------------------------------------------------------------*/
	public static function attach(g:mode.GameMode,x:Dynamic,y:Dynamic)  untyped {
		var linkage:Dynamic = RootData.LINKAGES[RootData.BAD_ANANAS];
		var mc : entity.bad.walker.Ananas = (( g?.depthMan?.attach(linkage,RootData.DP_BADS) ):Dynamic) ;
		mc?.initBad(g,x,y) ;
		return mc ;
	}


	/*------------------------------------------------------------------------
	GELÉ
	------------------------------------------------------------------------*/
	override public function freeze(d:Dynamic)  untyped {
		super.freeze(d);
		fallFactor *= 1.5;
		fl_attack = false;
		unstick();
	}

	/*------------------------------------------------------------------------
	ASSOMÉ
	------------------------------------------------------------------------*/
	override public function knock(d:Dynamic)  untyped {
		super.knock(d);
		fallFactor *= 1.5;
		fl_attack = false;
		unstick();
	}


	/*------------------------------------------------------------------------
	MORT
	------------------------------------------------------------------------*/
	override public function killHit(dx:Dynamic)  untyped {
		super.killHit(dx);
		fl_attack = false;
	}


	/*------------------------------------------------------------------------
	RENVOIE TRUE SI LE BAD EST PRÊT POUR UNE ACTION
	------------------------------------------------------------------------*/
	override public function isReady()  untyped {
		return !fl_attack && super.isReady() ;
	}


	/*------------------------------------------------------------------------
	REPOUSSE UN TYPE D'ENTITÉ
	------------------------------------------------------------------------*/
	public function repel(type:Dynamic, powerFactor:Dynamic)  untyped {
		var l:Dynamic = game?.getClose(type,x,y,dashRadius,false) ;
		{ var i:Dynamic=0; while (i<l?.length) {
			var e : entity.Physics = ((l[i]):Dynamic) ;
			shockWave( e, dashRadius, dashPower*powerFactor) ;
			{ if (e != null) e.dy -= 8 ; }
			if ( e?.isType(RootData.PLAYER) ) {
				((e):Dynamic)?.knock(RootData.SECOND*1.5);
			}
		
i++; } }
	}


	/*------------------------------------------------------------------------
	REPOUSSE UN TYPE D'ENTITÉ
	------------------------------------------------------------------------*/
	public function vaporize(type:Dynamic)  untyped {
		var l:Dynamic = game?.getClose(type,x,y,dashRadius,false) ;
		{ var i:Dynamic=0; while (i<l?.length) {
			var e:Dynamic = l[i];
			game?.fxMan?.attachFx( e?.x, e?.y-RootData.CASE_HEIGHT, "hammer_fx_pop" );
			e?.destroy();
		
i++; } }
	}


	/*------------------------------------------------------------------------
	LANCE L'ATTAQUE
	------------------------------------------------------------------------*/
	public function startAttack()  untyped {
		var fl_allOut:Dynamic = true;
		var pl:Dynamic = game?.getPlayerList();
		{ var i:Dynamic=0; while (i<pl?.length) {
			if ( !pl[i]?.fl_knock ) {
				fl_allOut = false;
			}
		
i++; } }
		if ( fl_allOut ) {
			return;
		}
		halt();
		playAnim(RootData.ANIM_BAD_THINK);
		forceLoop(true);
		setNext(0,-10,RootData.SECOND*0.9,RootData.ACTION_MOVE);
		fl_attack = true;
		var mc:Dynamic = game?.depthMan?.attach("curse", RootData.DP_FX) ;
		mc?.gotoAndStop(""+RootData.CURSE_TAUNT) ;
		stick(mc,0,-RootData.CASE_HEIGHT*2.5);
	}


	/*------------------------------------------------------------------------
	EFFETS DE L'ATTAQUE
	------------------------------------------------------------------------*/
	public function attack()  untyped {
		var fx:Dynamic = game?.fxMan?.attachExplodeZone(x,y,dashRadius) ;
		{ if (fx?.mc != null) fx.mc._alpha = 20; }
		game?.shake(RootData.SECOND*0.5, 5) ;

		var l:Dynamic = game?.getPlayerList();
		{ var i:Dynamic=0; while (i<l?.length) {
			var p:Dynamic = l[i];
			if ( p?.fl_stable ) {
				if ( p?.fl_shield ) {
					{ if (p != null) p.dy = -8; }
				}
				else {
					p?.knock( RootData.PLAYER_KNOCK_DURATION );
				}
			}
		
i++; } }

		repel(RootData.BOMB, 1) ;
		repel(RootData.PLAYER, 2) ;
		vaporize(RootData.PLAYER_SHOOT) ;

		fl_attack = false ;
		unstick();
	}


	/*------------------------------------------------------------------------
	EVENT: ATTERRISSAGE
	------------------------------------------------------------------------*/
	override public function onHitGround(h:Dynamic)  untyped {
		super.onHitGround(h) ;

		if ( fl_attack && isHealthy() ) {
			attack();
			playAnim(RootData.ANIM_BAD_SHOOT_END);
			halt();
		}
		else {
			game?.shake(RootData.SECOND*0.2, 2) ;
		}
	}


	/*------------------------------------------------------------------------
	EVENT: TOUCHE UN MUR
	------------------------------------------------------------------------*/
	override public function onHitWall()  untyped {
		if ( !isHealthy() ) {
			game?.shake(5,3) ;
		}
		super.onHitWall() ;
	}


	/*------------------------------------------------------------------------
	EVENT: FIN D'ANIM D'ATTAQUE
	------------------------------------------------------------------------*/
	override public function onEndAnim(id:Dynamic)  untyped {
		super.onEndAnim(id);
		if ( id==RootData.ANIM_BAD_SHOOT_END.id ) {
			walk();
		}
	}


	/*------------------------------------------------------------------------
	PRÉFIXE DE STEPPING
	------------------------------------------------------------------------*/
	override public function prefix()  untyped {
		if ( isReady()  ) {
			if ( fl_playerClose && MtStd.random(1000)<=CHANCE_DASH*2 ) {
				startAttack();
			}
			if ( !fl_playerClose && MtStd.random(1000)<=CHANCE_DASH ) {
				startAttack();
			}
		}
		super.prefix() ;
	}

}


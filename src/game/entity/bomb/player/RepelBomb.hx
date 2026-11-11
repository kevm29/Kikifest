// Converti automatiquement depuis hammer/entity/bomb/player/RepelBomb.mt (Motion Twin)
package entity.bomb.player;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
import Data as RootData;
class RepelBomb extends entity.bomb.PlayerBomb
{

	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new()  untyped {
		super();
		duration	= 38;
		power		= 20;
		radius		= RootData.CASE_WIDTH*3;
	}


	/*------------------------------------------------------------------------
	ATTACH
	------------------------------------------------------------------------*/
	public static function attach(g:mode.GameMode,x:Dynamic,y:Dynamic)  untyped {
		var linkage:Dynamic = "hammer_bomb_repel";
		var mc : entity.bomb.player.RepelBomb = (( g?.depthMan?.attach(linkage,RootData.DP_BOMBS) ):Dynamic);
		mc?.initBomb(g, x,y);
		return mc;
	}


	/*------------------------------------------------------------------------
	DUPLICATION
	------------------------------------------------------------------------*/
	override public function duplicate()  untyped {
		return attach(game, x,y);
	}


	override public function onKick(p:Dynamic)  untyped {
		super.onKick(p);
		dx*=2.5;
	}


	/*------------------------------------------------------------------------
	EVENT: EXPLOSION
	------------------------------------------------------------------------*/
	override public function onExplode()  untyped {
		super.onExplode();

		// fx
		game?.fxMan?.inGameParticles(RootData.PARTICLE_ICE, x,y, MtStd.random(2)+2);
		game?.fxMan?.attachExplodeZone(x,y,radius);


		// Players
		var pl:Dynamic = game?.getPlayerList();
		{ var i:Dynamic=0; while (i<pl?.length) {
			var p:Dynamic = pl[i];
			var dist:Dynamic = distance( p?.x, p?.y );
			if ( dist<=radius ) {
				var ratio:Dynamic = (radius-dist)/radius;
				p?.knock( RootData.SECOND + RootData.SECOND*ratio );
				var ang:Dynamic = Math.atan2( p?.y-y, p?.x-x );
				{ if (p != null) p.dx = Math.cos(ang)*power*ratio; }
				{ if (p != null) p.dy = Math.sin(ang)*power*ratio; }
			}
		
i++; } }


		// Ballon
		var l:Dynamic = game?.getList(RootData.SOCCERBALL);
		{ var i:Dynamic=0; while (i<l?.length) {
			var ball : entity.bomb.player.SoccerBall = ((l[i]):Dynamic);
			var dist:Dynamic = distance( ball?.x, ball?.y );
			if ( dist<=radius ) {
				{ if (ball != null) ball.lastPlayer = owner; }
				var ratio:Dynamic = (radius-dist)/radius;
				var ang:Dynamic = Math.atan2( ball?.y-y, ball?.x-x );
				{ if (ball != null) ball.dx = Math.cos(ang)*power*ratio*1.5; }
				{ if (ball != null) ball.dy = Math.sin(ang)*power*ratio*1.5; }
				if ( ball?.dy<4 && ball?.dy>-8 ) {
					{ if (ball != null) ball.dy = -8; }
				}
				ball?.burn();
				if ( ball?.fl_stable ) {
					{ if (ball != null) ball.dx *= 2; }
				}
				else {
					{ if (ball != null) ball.dx *= 1.5; }
				}
			}
		
i++; } }

	}
}


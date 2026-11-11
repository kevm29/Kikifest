// Converti automatiquement depuis hammer/entity/PlayerController.mt (Motion Twin)
package entity;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
import Data as RootData;
class PlayerController
{

	public var player			: entity.Player;
	public var game			: mode.GameMode;

	public var lastKeys		: Array<Int>;
	public var keyLocks		: Array<Bool>;

	public var jump 			: Int;
	public var down			: Int;
	public var left			: Int;
	public var right			: Int;
	public var attack			: Int;
	public var alt_attack		: Int;

	public var walkTimer		: Float;
	public var fl_upKick		: Bool;
	public var fl_powerControl	: Bool;
	public var waterJump		: Int;

	public var alts			: Array<Int>;


	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new(p:entity.Player)  untyped {
		lastKeys		= new Array();
		keyLocks		= new Array();
		alts			= new Array();
		player			= p;
		game			= player?.game;
		fl_upKick		= GameManager.CONFIG.hasFamily(101);
		fl_powerControl	= false;
		setKeys(
			Key.UP,
			Key.DOWN,
			Key.LEFT,
			Key.RIGHT,
			Key.SPACE
		);

		setAlt(attack, Key.CONTROL);
		walkTimer		= 0;
		waterJump		= 0;
	}


	/*------------------------------------------------------------------------
	DÉFINI LES CONTRÔLES CLAVIER
	------------------------------------------------------------------------*/
	public function setKeys(j:Dynamic,d:Dynamic,l:Dynamic,r:Dynamic,a:Dynamic)  untyped {
		jump = j;
		down = d;
		left = l;
		right = r;
		attack = a;
	}


	/*------------------------------------------------------------------------
	DÉFINI UNE TOUCHE ALTERNATIVE
	------------------------------------------------------------------------*/
	public function setAlt(id:Dynamic, idAlt:Dynamic)  untyped {
		alts[id] = idAlt;
	}


	/*------------------------------------------------------------------------
	TESTE SI UNE TOUCHE VERROUILLABLE EST ENFONCÉE
	------------------------------------------------------------------------*/
	public function keyIsDown(id:Dynamic)  untyped {
		var fl:Dynamic =
			( Key.isDown(id) && !keyLocks[id] ) ||
			( Key.isDown(alts[id]) && !keyLocks[alts[id]] );
		if ( fl ) {
			lockKey(id);
		}
		return fl;
	}

	public function lockKey(id:Dynamic)  untyped {
		keyLocks[id] = true;
		keyLocks[alts[id]] = true;
		lastKeys?.push(id);
		lastKeys?.push(alts[id]);
	}


	/*------------------------------------------------------------------------
	SAISIE DES CONTRÔLES CLAVIER
	------------------------------------------------------------------------*/
	public function getControls()  untyped {

		// Dernières touches enfoncées
		{ var i:Dynamic=0; while (i<lastKeys?.length) {if ( !Key.isDown(lastKeys[i]) ) {
			keyLocks[lastKeys[i]] = false;
			lastKeys?.splice(i,1);
			i--;
		}
i++; } }

		if ( player?.fl_stable ) {
			waterJump = 3;
		}

		// *** Gauche
		if ( Key.isDown(left) ) {
			if ( game?.fl_ice || game?.fl_aqua ) {
				var frict:Dynamic;
				if ( !player?.fl_stable && game?.fl_ice ) {
					frict = 0.35;
				}
				else {
					frict = 0.1;
				}
				{ if (player != null) player.dx -= frict* RootData.PLAYER_SPEED * player?.speedFactor; }
				{ if (player != null) player.dx = Math.max(player?.dx, -RootData.PLAYER_SPEED * player?.speedFactor); }
			}
			else {
				{ if (player != null) player.dx=-RootData.PLAYER_SPEED * player?.speedFactor; }
			}
			{ if (player != null) player.dir = -1; }
			if ( player?.fl_stable ) {
				player?.playAnim(player?.baseWalkAnim);
			}
		}

		// *** Droite
		if ( Key.isDown(right) ) {
			if ( game?.fl_ice || game?.fl_aqua ) {
				var frict:Dynamic;
				if ( !player?.fl_stable && game?.fl_ice ) {
					frict = 0.35;
				}
				else {
					frict = 0.1;
				}
				{ if (player != null) player.dx += frict* RootData.PLAYER_SPEED * player?.speedFactor; }
				{ if (player != null) player.dx = Math.min(player?.dx, RootData.PLAYER_SPEED * player?.speedFactor); }
			}
			else {
				{ if (player != null) player.dx = RootData.PLAYER_SPEED * player?.speedFactor; }
			}
			{ if (player != null) player.dir = 1; }
			if ( player?.fl_stable ) {
				player?.playAnim(player?.baseWalkAnim);
			}
		}

		if ( player?.specialMan?.actives[73] ) { // effet feuille arbre
			if ( player?.fl_stable && player?.dx!=0 ) {
				walkTimer-=Timer.tmod;
				if ( walkTimer<=0 ) {
					walkTimer = RootData.SECOND;
					player?.getScore(player, 10);
				}
			}
		}


		// *** Freinage horizontal
		if ( !Key.isDown(left) && !Key.isDown(right) ) {
			if ( !game?.fl_ice ) {
				{ if (player != null) player.dx*=game?.gFriction*0.8; }
			}
			if ( player?.animId == player?.baseWalkAnim?.id || player?.animId == RootData.ANIM_PLAYER_RUN.id ) { // || player.animId == Data.ANIM_PLAYER_EDGE.id ) {
//				if ( game.fl_ice && Math.abs(player.dx)>=0.2 ) {
//					player.playAnim( Data.ANIM_PLAYER_EDGE );
//				}
//				else {
					player?.playAnim( player?.baseStopAnim );
//				}
			}
		}

		// *** WaterJump
		if ( game?.fl_aqua && waterJump>0 ) {
			if ( !player?.fl_stable && keyIsDown(jump) ) {
				player?.airJump();
				waterJump--;
			}
		}

		// *** Saut
		if ( player?.fl_stable && Key.isDown(jump) ) {
			if ( player?.specialMan?.actives[88] ) { // effet pokute shrink
				{ if (player != null) player.dy = -RootData.PLAYER_JUMP*0.5; }
			}
			else {
				{ if (player != null) player.dy = -RootData.PLAYER_JUMP; }
			}

			game?.soundMan?.playSound("sound_jump", RootData.CHAN_PLAYER);
			player?.playAnim(RootData.ANIM_PLAYER_JUMP_UP);
			var fx:Dynamic = game?.fxMan?.attachFx(player?.x,player?.y,"hammer_fx_jump");
			{ if (fx?.mc != null) fx.mc._alpha = 50; }
			if ( player?.specialMan?.actives[66] ) { // effet cactus
				player?.getScore(player, 10);
			}
			game?.statsMan?.inc(RootData.STAT_JUMP,1);
			lockKey(jump);
		}

		// *** Attaque
//		if ( player.fl_stable && keyIsDown(attack) && player.coolDown==0 ) {
		if ( keyIsDown(attack) && player?.coolDown==0 ) {
			var dist:Dynamic = RootData.KICK_DISTANCE;
			if ( !player?.fl_stable ) {
				dist = RootData.AIR_KICK_DISTANCE;
			}
			if ( player?.specialMan?.actives[115] ) {
				dist*=1.2;
			}
			var bombList : Array<entity.Bomb> = (cast (
				game.getClose( RootData.BOMB, player.x,player.y, dist, false )
			));
			if ( bombList?.length==0 ) {
				// Pose de bombe
				if ( player?.currentWeapon>0 && player?.countBombs() < player?.maxBombs ) {
					var e:Dynamic = player?.attack();
					if ( game?.fl_bombControl && e?.isType(RootData.BOMB) ) {
						var b : entity.bomb.PlayerBomb = ((e):Dynamic);
						var wb:Dynamic = entity.WalkingBomb.attach(game,b);
					}

					if (e!=null) {
						e?.setParent( (cast (player)) );
					}
					if ( player?.fl_stable ) {
						player?.playAnim(RootData.ANIM_PLAYER_ATTACK);
					}
				}
			}
			else {
				// Kick de bombe
				if ( fl_powerControl && player?.fl_stable ) {
					var power:Dynamic = Math.min(1.2, 0.5 + Math.abs(player?.dx)/4);
					player?.kickBomb(bombList, power);
				}
				else {
					player?.kickBomb(bombList, 1.0);
				}
			}
		}
		else {
			// *** Up kick
			if ( keyIsDown(down) && fl_upKick ) {
				var dist:Dynamic = RootData.KICK_DISTANCE;
				if ( !player?.fl_stable ) {
					dist = RootData.AIR_KICK_DISTANCE;
				}
				if ( player?.specialMan?.actives[115] ) {
					dist*=1.2;
				}
				var bombList : Array<entity.Bomb> = (cast (
					game.getClose( RootData.BOMB, player.x,player.y, dist, false )
				));
				if ( bombList?.length>0 ) {
					player?.upKickBomb(bombList);
				}
			}
		}



	}


	/*------------------------------------------------------------------------
	MAIN
	------------------------------------------------------------------------*/
	public function update()  untyped {
		getControls();
	}

}


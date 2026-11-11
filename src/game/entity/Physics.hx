// Converti automatiquement depuis hammer/entity/Physics.mt (Motion Twin)
package entity;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
import Data as RootData;
import levels.TeleporterData;

class Physics extends entity.Animator
{

	public var dx	: Float;
	public var dy	: Float;

	public var fallStart		: Float; // use for fall height

	public var gravityFactor	: Float;
	public var fallFactor		: Float;
	public var slideFriction	: Float; // default world value if "null"
	public var shockResistance	: Float; // resistance to shockwaves

	public var fl_stable		: Bool;
	public var fl_physics		: Bool;
	public var fl_friction		: Bool;
	public var fl_gravity		: Bool;
	public var fl_strictGravity: Bool;
	public var fl_hitGround	: Bool;
	public var fl_hitCeil		: Bool;
	public var fl_hitWall		: Bool;
	public var fl_hitBorder	: Bool;
	public var fl_slide		: Bool;
	public var fl_teleport		: Bool;
	public var fl_portal		: Bool;
	public var fl_wind			: Bool;
	public var fl_moveable		: Bool;
	public var fl_bump			: Bool;

	public var fl_stopStepping		: Bool;
	public var fl_skipNextGravity	: Bool;
	public var fl_skipNextGround	: Bool;

	public var lastTeleporter	: TeleporterData;


	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new()  untyped {
		super();

		dx = 0;
		dy = 0;
		gravityFactor = 1.0;
		fallFactor = 1.0;
		shockResistance = 1.0;

		fl_stable = false;

		fl_physics		= true;
		fl_friction		= true;
		fl_gravity		= true;
		fl_strictGravity= true;
		fl_hitGround	= true;
		fl_hitCeil		= false;
		fl_hitWall		= true;
		fl_hitBorder	= true;
		fl_slide		= true;
		fl_teleport		= false;
		fl_portal		= false;
		fl_wind			= false;
		fl_moveable		= true;
		fl_bump			= false;

		fl_stopStepping = false;
		fl_skipNextGravity = true;
		fl_skipNextGround = false;
	}


	/*------------------------------------------------------------------------
	INIT
	------------------------------------------------------------------------*/
	override public function init(g:mode.GameMode)  untyped {
		super.init(g);
		this.register(RootData.PHYSICS);
	}


	/*------------------------------------------------------------------------
	ACTIVATION/DÉSACTIVATION DU MOTEUR PHYSIQUE
	------------------------------------------------------------------------*/
	public function enablePhysics()  untyped {
		fl_physics = true;
	}

	public function disablePhysics()  untyped {
		fl_physics = false;
	}


	/*------------------------------------------------------------------------
	EFFET D'ONDE DE CHOC AUTOUR DE L'ENTITÉ
	------------------------------------------------------------------------*/
	public function shockWave(e:entity.Physics, radius:Dynamic, power:Dynamic)  untyped {
		if ( !e?.fl_moveable ) {
			return;
		}
		power /= e?.shockResistance; // le poids réduit la puissance
		var dist:Dynamic = e?.distance(x,y); // Math.sqrt( Math.pow(e.x-x,2) + Math.pow(e.y-y,2) );
		var ratio:Dynamic = 1-dist/radius;
		var ang:Dynamic = Math.atan2(e?.y-y,e?.x-x);
		{ if (e != null) e.dx = Math.cos(ang) * ratio * power; }
		if ( e?.fl_stable ) {
			{ if (e != null) e.dy = -5; }
		}
		else {
			if ( ((e):Dynamic)?.fl_intercept ) { // amélioration du freeze des volants
				{ if (e != null) e.dy = 0; }
				{ if (e != null) e.dx *=2; }
			}
			else {
				{ if (e != null) e.dy += Math.sin(ang) * ratio * power; }
			}
			{ if (e != null) e.dy = Math.max(e?.dy, -10); }
		}
		{ if (e != null) e.fl_stable = false; }
	}


	/*------------------------------------------------------------------------
	MORT AVEC ANIMATION DE SAUT
	------------------------------------------------------------------------*/
	public function killHit(dx:Dynamic)  untyped {
		if ( fl_kill ) {
			return;
		}

		this.dx = dx;
		this.dy = -10;
		fl_hitGround = false;
		fl_hitWall = false;
		fl_kill = true;
		fallFactor = RootData.FALL_FACTOR_DEAD;
		onKill();
	}


	/*------------------------------------------------------------------------
	RÉSURRECTION
	------------------------------------------------------------------------*/
	public function resurrect()  untyped {
		fl_hitGround = true;
		fl_hitWall = true;
		fl_kill = false;
		fallFactor = 1.0;
		fl_stopStepping = true;
	}


	// *** MACROS DE DÉPLACEMENT

	/*------------------------------------------------------------------------
	CALCULE LES DX,DY SELON UN ANGLE (EN DEGRÉ) ET UNE VITESSE
	------------------------------------------------------------------------*/
	public function moveToAng(angDeg:Dynamic, speed:Dynamic)  untyped {
		var rad:Dynamic = Math.PI*angDeg / 180;
		dx = Math.cos(rad)*speed;
		dy = Math.sin(rad)*speed;
	}

	/*------------------------------------------------------------------------
	CALCULE LES DX,DY SELON UNE AUTRE ENTITÉ CIBLE
	------------------------------------------------------------------------*/
	public function moveToTarget(e:Entity, speed:Dynamic)  untyped {
		var rad:Dynamic = Math.atan2(e?.y-y,e?.x-x);
		dx = Math.cos(rad)*speed;
		dy = Math.sin(rad)*speed;
	}

	/*------------------------------------------------------------------------
	CALCULE DX / DY SELON UNE COORDONNÉE
	------------------------------------------------------------------------*/
	public function moveToPoint(x:Dynamic,y:Dynamic, speed:Dynamic)  untyped {
		var rad:Dynamic = Math.atan2(y-this.y,x-this.x);
		dx = Math.cos(rad)*speed;
		dy = Math.sin(rad)*speed;
	}


	/*------------------------------------------------------------------------
	DÉPLACEMENT DANS UNE DIRECTION AU CHOIX
	------------------------------------------------------------------------*/
	public function moveUp(speed:Dynamic)  untyped {
		moveToAng( -90, speed );
	}
	public function moveDown(speed:Dynamic)  untyped {
		moveToAng( 90, speed );
	}
	public function moveLeft(speed:Dynamic)  untyped {
		moveToAng( 180, speed );
	}
	public function moveRight(speed:Dynamic)  untyped {
		moveToAng( 0, speed );
	}


	/*------------------------------------------------------------------------
	DÉPLACEMENT EN PARTANT D'UNE ENTITÉ
	------------------------------------------------------------------------*/
	public function moveFrom(e:Entity, speed:Dynamic)  untyped {
		x = e?.x;
		y = e?.y;
		var ang:Dynamic = -MtStd.random(Math.round(100*Math.PI))/100;
		x = e?.x+Math.cos(ang)*RootData.CASE_WIDTH*2;
		y = e?.y+Math.sin(ang)*RootData.CASE_HEIGHT*2;
		moveToTarget(e,speed);
		dx=-dx;
		dy=-dy;
	}


	/*------------------------------------------------------------------------
	POSE L'ENTITÉ AU SOL LE PLUS PROCHE (AVEC CYCLE DE NIVEAU HAUT/BAS)
	------------------------------------------------------------------------*/
	public function moveToGround()  untyped {
		if ( fl_stable ) {
			return;
		}
		var pt:Dynamic = world?.getGround(cx,cy);
		moveToCase(pt?.x,pt?.y);
	}


	// *** STEPPING


	/*------------------------------------------------------------------------
	EXÉCUTE LES COLLISIONS ENTRE ENTITÉS
	------------------------------------------------------------------------*/
	public function checkHits()  untyped {
		var l:Dynamic = getByType(RootData.ENTITY);
		{ var i:Dynamic=0; while (i<l?.length) {
			if ( !l[i]?.fl_kill && !fl_kill && this.hitBound(l[i]) && l[i]?.uniqId!=this.uniqId ) {
				this.hit( l[i] );
				l[i]?.hit( this );
			}
		
i++; } }
	}

	/*------------------------------------------------------------------------
	PRÉFIXE DU STEPPING
	------------------------------------------------------------------------*/
	public function prefix()  untyped {
		// do nothing
	}


	/*------------------------------------------------------------------------
	INFIXE DU STEPPING (CHANGEMENT DE CASE)
	------------------------------------------------------------------------*/
	public function infix()  untyped {
		checkHits();

		var cid:Dynamic = world?.getCase( {x:cx,y:cy} );

		// Téléportation
		if ( fl_teleport && !fl_kill ) {
			if ( cid == RootData.FIELD_TELEPORT ) {
				var start:Dynamic = world?.getTeleporter(this, cx,cy);
				if ( start!=null ) {
					var target:Dynamic = world?.getNextTeleporter(start);
					game?.fxMan?.attachFx(x,y-RootData.CASE_HEIGHT,"hammer_fx_pop");
					if ( target?.td?.dir==RootData.HORIZONTAL ) {
						if ( target?.fl_rand ) {
							moveTo( target?.td?.centerX-RootData.CASE_WIDTH*0.5, target?.td?.centerY );
						}
						else {
							moveTo( target?.td?.centerX+Entity.x_ctr(cx)-start?.centerX, target?.td?.centerY );
						}
					}
					else {
						if ( target?.fl_rand ) {
							moveTo( target?.td?.centerX, target?.td?.centerY );
						}
						else {
							moveTo( target?.td?.centerX, target?.td?.centerY+Entity.y_ctr(cy)-start?.centerY );
						}
					}
					game?.fxMan?.attachFx(x,y-RootData.CASE_HEIGHT,"hammer_fx_shine");
					game?.soundMan?.playSound("sound_teleport",RootData.CHAN_FIELD);
					fl_stopStepping = true;
					lastTeleporter = target?.td;
					onTeleport();
				}
			}
			else {
				lastTeleporter = null;
			}
		}


		if ( fl_portal && !fl_kill ) {
			if ( cid==RootData.FIELD_PORTAL ) {
				if ( game?.fl_clear ) {
					var px:Dynamic = cx;
					var py:Dynamic = cy;
					// Cherche le portal correspondant
					while ( world?.getCase( {x:px-1,y:py} ) == RootData.FIELD_PORTAL ) {
						px--;
					}
					while ( world?.getCase( {x:px,y:py-1} ) == RootData.FIELD_PORTAL ) {
						py--;
					}

					var pid:Dynamic = null;
					{ var i:Dynamic=0; while (i<world?.portalList?.length) {
						if ( world?.portalList[i]?.cx==px && world?.portalList[i]?.cy==py ) {
							pid = i;
						}
					
i++; } }

					onPortal(pid);
				}
				else {
					onPortalRefusal();
				}
			}
		}


		// Bumpers
		if ( fl_bump && !fl_kill && cid==RootData.FIELD_BUMPER ) {
			var fdir:Dynamic = RootData.VERTICAL;
			if ( world?.getCase( {x:cx-1,y:cy} )==cid || world?.getCase( {x:cx+1,y:cy} )==cid ) {
				fdir = RootData.HORIZONTAL;
			}

			// Projection verticale
			if ( fdir==RootData.HORIZONTAL && Math.abs(dy)<20 ) {
				dx = 0;
				dy *= 5;
			}
			// Projection horizontale
			if ( fdir==RootData.VERTICAL && Math.abs(dx)<20 ) {
				dx *= 7;
				dy = 0;
			}
			onBump();
		}

	}


	/*------------------------------------------------------------------------
	POSTFIXE
	------------------------------------------------------------------------*/
	public function postfix()  untyped {
		// Do nothing
	}



	/*------------------------------------------------------------------------
	RECALAGE Y
	------------------------------------------------------------------------*/
	public function recal()  untyped {
		y = Entity.y_ctr( Entity.y_rtc(y) );
		updateCoords();
		while ( world?.getCase( {x:cx,y:cy} )==RootData.GROUND ) {
			y-=RootData.CASE_HEIGHT;
			updateCoords();
		}
	}


	/*------------------------------------------------------------------------
	CALCUL DE STEPS
	------------------------------------------------------------------------*/
	public function calcSteps(dxStep:Dynamic,dyStep:Dynamic)  untyped {
		var dxTotal:Dynamic = dxStep*Timer.tmod;
		var dyTotal:Dynamic = dyStep*Timer.tmod;
		var total:Dynamic = Math.ceil(Math.abs(dxTotal)/RootData.STEP_MAX);
		total = Math.max(total, Math.ceil(Math.abs(dyTotal)/RootData.STEP_MAX) );

		return {
			total: total,
			dx: dxTotal/total,
			dy: dyTotal/total
		};
	}


	/*------------------------------------------------------------------------
	AUTORISE L'APPLICATION DU PATCH COLLISION AU SOL (ESCALIERS)
	------------------------------------------------------------------------*/
	public function needsPatch()  untyped {
		return false;
	}


	// *** EVENTS

	/*------------------------------------------------------------------------
	EVENT: MORT
	------------------------------------------------------------------------*/
	public function onKill()  untyped {
		// do nothing
	}

	/*------------------------------------------------------------------------
	EVENT: TOMBE SOUS LA LIGNE DU BAS
	------------------------------------------------------------------------*/
	public function onDeathLine()  untyped {
		// do nothing
	}

	/*------------------------------------------------------------------------
	EVENT: BLOQUE CONTRE UN MUR
	------------------------------------------------------------------------*/
	public function onHitWall()  untyped {
		dx = 0;
	}

	/*------------------------------------------------------------------------
	EVENT: ATTERISSAGE
	------------------------------------------------------------------------*/
	public function onHitGround(height:Dynamic)  untyped {
		fl_stable = true;
		dy = 0;
		recal();
	}

	/*------------------------------------------------------------------------
	EVENT: TOUCHE LE PLAFOND
	------------------------------------------------------------------------*/
	public function onHitCeil()  untyped {
		dy=0;
	}


	/*------------------------------------------------------------------------
	EVENT: TÉLÉPORTATION
	------------------------------------------------------------------------*/
	public function onTeleport()  untyped {
		// do nothing
	}


	/*------------------------------------------------------------------------
	EVENT: TÉLÉPORTATION PORTAL
	------------------------------------------------------------------------*/
	public function onPortal(pid:Dynamic)  untyped {
		// do nothing
	}


	/*------------------------------------------------------------------------
	EVENT: PORTAIL FERMÉ
	------------------------------------------------------------------------*/
	public function onPortalRefusal()  untyped {
		// do nothing
	}


	/*------------------------------------------------------------------------
	EVENT: BUMPER
	------------------------------------------------------------------------*/
	public function onBump()  untyped {
		// do nothing
	}


	// *** UPDATES

	/*------------------------------------------------------------------------
	MISE À JOUR GRAPHIQUE
	------------------------------------------------------------------------*/
	override public function endUpdate()  untyped {
		if ( fl_hitBorder ) { // patch contre les sorties d'écran latérales
			if ( x<RootData.BORDER_MARGIN ) x=RootData.BORDER_MARGIN;
			if ( x>=RootData.GAME_WIDTH-RootData.BORDER_MARGIN ) x=RootData.GAME_WIDTH-RootData.BORDER_MARGIN-1;
		}

		if ( game?.fl_aqua ) {
			if ( !isType(RootData.FX) && (dx!=0 || dy!=0) ) {
				if ( MtStd.random(100)<=10 ) {
					game?.fxMan?.inGameParticles(
						RootData.PARTICLE_BUBBLE,
						x+MtStd.random(RootData.CASE_WIDTH) * (MtStd.random(2)*2-1),
						y-MtStd.random(RootData.CASE_HEIGHT),
						1
					);
				}
			}
		}
		super.endUpdate();
	}


	/*------------------------------------------------------------------------
	MAIN
	------------------------------------------------------------------------*/
	override public function update()  untyped {
		super.update();

		if ( !fl_physics ) {
			return;
		}

		updateCoords();


		// Vent
		if ( fl_wind ) {
			if ( fl_stable && game?.fl_wind ) {
				dx += game?.windSpeed*Timer.tmod;
			}
		}


		// Chute
		if ( fl_stable ) {
			if ( dy!=0 || world?.getCase( {x:fcx,y:fcy} )!=RootData.GROUND ) {
				fl_stable = false;
			}
		}


		if (dx!=0 || dy!=0 || !fl_stable) {
			var step:Dynamic;

			// Gravité
			if ( !fl_skipNextGravity && !fl_stable && fl_gravity ) {

				// facteur de correction pour les tmods extrèmes
				var patchFactor:Dynamic = 1.0;
				if ( Timer.tmod>=2 ) {
					patchFactor = 1.1;
				}

				if ( dy<0 ) {
					dy += gravityFactor * RootData.GRAVITY * Timer.tmod * patchFactor;
				}
				else {
					if ( fallStart==null ) {
						fallStart = y;
					}
					if ( game?.fl_aqua && !fl_strictGravity ) {
						dy += 0.3 * fallFactor * RootData.FALL_SPEED * Timer.tmod * patchFactor;
					}
					else {
						dy += fallFactor * RootData.FALL_SPEED * Timer.tmod * patchFactor;
					}

				}
			}
			fl_skipNextGravity = false;


			prefix();

			var stepInfos:Dynamic = calcSteps(dx,dy);
			step=0;

			// Début du stepping
			while ( !fl_stopStepping && step < stepInfos?.total ) {
				var ocx:Dynamic = cx;
				var ocy:Dynamic = cy;
				var ofcx:Dynamic = fcx;
				var ofcy:Dynamic = fcy;
				var ox:Dynamic = x;
				var oy:Dynamic = y;
				oldX = x;
				oldY = y;

				x += stepInfos?.dx;
				y += stepInfos?.dy;
				updateCoords();

				// Patch pénétration dans les murs
				if ( fl_hitWall ) {
					var fl_hasHitWall:Dynamic = false;
					if ( dx>0 && world?.getCase( {x:Entity.x_rtc(ox+RootData.CASE_WIDTH*0.5),y:Entity.y_rtc(oy)} )>0) {
						fl_hasHitWall = true;
					}
					if ( dx<0 && world?.getCase( {x:Entity.x_rtc(ox-RootData.CASE_WIDTH*0.5),y:Entity.y_rtc(oy)} )>0) {
						fl_hasHitWall = true;
					}
					if ( fl_hasHitWall ) {
						x=ox;
						{ if (stepInfos != null) stepInfos.dx = 0; }
						updateCoords();
						onHitWall();
					}
				}

				// Collision horizontale
				if ( (fl_hitBorder && (x<RootData.BORDER_MARGIN || x>=RootData.GAME_WIDTH-RootData.BORDER_MARGIN)) ||
					(fl_hitWall && world?.getCase( {x:cx,y:Entity.y_rtc(oy)} )>0) ) {
					x = ox;
					{ if (stepInfos != null) stepInfos.dx = 0; }
					updateCoords();
					onHitWall();
				}


				// Patch traversée de murs par le haut
				if ( fl_hitWall && stepInfos?.dy>0 && !fl_kill ) {
					if ( world?.getCase(Entity.rtc(ox,oy+Math.floor(RootData.CASE_HEIGHT/2)))!=RootData.WALL && world?.getCase( {x:fcx,y:fcy} )==RootData.WALL ) {
						x = ox;
						{ if (stepInfos != null) stepInfos.dx = 0; }
						updateCoords();
						onHitWall();
					}
				}

				// Atterrissage
				if ( fl_hitGround && stepInfos?.dy>=0 ) {
					if ( world?.getCase(Entity.rtc(ox,oy+Math.floor(RootData.CASE_HEIGHT/2)))!=RootData.GROUND && world?.getCase( {x:fcx,y:fcy} )==RootData.GROUND ) {
						if ( world?.checkFlag( {x:fcx,y:fcy}, RootData.IA_TILE) ) {
							if ( fl_skipNextGround ) {
								fl_skipNextGround = false;
							}
							else {
								{ if (stepInfos != null) stepInfos.dy = 0; }
								onHitGround( y-fallStart );
								fallStart = null;
								updateCoords();
							}
						}
					}
				}

				// Plafond
				if ( fl_hitCeil && stepInfos?.dy<=0 ) {
					if ( world?.getCase(Entity.rtc(ox,oy-Math.floor(RootData.CASE_HEIGHT/2)))<=0 && world?.getCase(Entity.rtc(x,y-Math.floor(RootData.CASE_HEIGHT/2)))>0 ) {
						{ if (stepInfos != null) stepInfos.dy = 0; }
						onHitCeil();
						updateCoords();
					}
				}

				// Changement de case
				if ( ocx!=cx || ocy!=cy ) {
					var fl_patch:Dynamic = false;

					// Patch d'entrée dans un sol avec air jump
					if ( fl_hitGround && ocy<cy) {
						if ( needsPatch() ) {
							if ( world?.getCase({x:ocx,y:ocy})<=0 && dy>0 && world?.getCase({x:cx,y:cy})>0 && cy<RootData.LEVEL_HEIGHT ) {
								x = Entity.x_ctr(ocx);
								y = Entity.y_ctr(ocy);
								{ if (stepInfos != null) stepInfos.dy=0; }
								updateCoords();
								onHitGround(y-fallStart);
								fl_patch = true;
							}
						}
					}

					// Patch entrée dans un sol (coins en diagonal)
					if ( fl_hitGround && dy>=0 && ocx!=cx && ocy!=cy ) {
						if ( world?.getCase({x:ocx,y:ocy})<=0 && world?.getCase({x:cx,y:cy})==RootData.GROUND ) {
							x = Entity.x_ctr(ocx);
							y = Entity.y_ctr(ocy);
							{ if (stepInfos != null) stepInfos.dx=0; }
							updateCoords();
							onHitWall();
							fl_patch = true;
						}
					}
					if ( !fl_patch ) {
						tRem(ocx,ocy);
						infix() ; // appel infixe
						updateCoords();
						tAdd(cx,cy);
					}
				}

				step++;
			}
			// Fin du stepping


		}

		fl_stopStepping = false;
		postfix();

		// Frictions
		if ( fl_friction ) {
			if ( (game?.fl_ice || fl_slide) && fl_stable ) {
				if ( slideFriction==null ) {
					dx *= game?.sFriction;
				}
				else {
					dx *= Math.pow(slideFriction, Timer.tmod);
				}
			}
			else {
				dx *= game?.xFriction;
				dy *= game?.yFriction;
			}
		}
		if (Math.abs(dx)<=0.2) {
			dx = 0;
		}
		if (Math.abs(dy)<=0.2) {
			dy = 0;
		}


		// Mort
		if ( y>=RootData.DEATH_LINE ) {
			onDeathLine();
		}
	}

}


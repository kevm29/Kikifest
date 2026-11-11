// Converti automatiquement depuis hammer/levels/GameMechanics.mt (Motion Twin)
package levels;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
import Data as RootData;
import levels.TeleporterData;

class GameMechanics extends levels.ViewManager
{
	public var game			: mode.GameMode;

	public var fl_parsing		: Bool;
	public var flcurrentIA		: Bool;
	public var fl_compile		: Bool;
	public var fl_lock			: Bool;
	public var fl_visited		: Array<Bool>;
	public var fl_mainWorld	: Bool;

	public var flagMap			: Array<Array<Int>>; // flags IA
	public var fallMap			: Array<Array<Int>>; // hauteur de chute par case
	public var triggers		: Array<Array< Array<Entity> >> ;

	public var scriptEngine	: levels.ScriptEngine;


	public var _iteration : {cx:Int,cy:Int} ;


	/*------------------------------------------------------------------------
	CONSTRUCTEUR
	------------------------------------------------------------------------*/
	public function new(m:Dynamic,s:Dynamic)  untyped {
		super(m,s);

		fl_parsing		= false;
		fl_lock			= true;
		fl_visited		= new Array();
		fl_mainWorld	= true;

		resetIA();

		triggers = new Array() ;

		{ var i:Dynamic=0; while (i<RootData.LEVEL_WIDTH) {
			triggers[i] = new Array() ;
			{ var j:Dynamic=0; while (j<RootData.LEVEL_HEIGHT) {
				triggers[i][j] = new Array() ;
			
j++; } }
		
i++; } }
	}

	override public function destroy()  untyped {
		super.destroy();
		scriptEngine?.destroy();
	}


	/*------------------------------------------------------------------------
	DÉFINI LE GAME INTERNE
	------------------------------------------------------------------------*/
	public function setGame(g:Dynamic)  untyped {
		game = g;
	}


	/*------------------------------------------------------------------------
	GESTION VERROU DE SCRIPT
	------------------------------------------------------------------------*/
	public function lock()  untyped {
		fl_lock = true;
	}
	public function unlock()  untyped {
		fl_lock = false;
	}


	/*------------------------------------------------------------------------
	CHANGE LE NIVEAU COURANT
	------------------------------------------------------------------------*/
	override public function goto(id:Dynamic)  untyped {
		setVisited();
		resetIA();
//		scriptEngine.clearScript();
		super.goto(id);
	}


	/*------------------------------------------------------------------------
	RENVOIE TRUE SI LES DONNÉES SONT PRETES
	------------------------------------------------------------------------*/
	override public function isDataReady()  untyped {
		return super.isDataReady() && flcurrentIA;
	}


	/*------------------------------------------------------------------------
	ATTACHEMENT D'UNE VUE
	------------------------------------------------------------------------*/
	override public function createView(id:Dynamic)  untyped {
		scriptEngine?.onLevelAttach();
		return super.createView(id);
	}


	/*------------------------------------------------------------------------
	MISE EN ATTENTE
	------------------------------------------------------------------------*/
	override public function suspend()  untyped {
		super.suspend();
		lock();
		var s:Dynamic = RootData.cleanString( scriptEngine?.script?.toString() );
		if ( s != null ) {
			{ if (current != null) current.__S_script = s; }
		}
		setVisited();
	}

	override public function restore(lid:Dynamic)  untyped {
		super.restore(lid);
	}


	/*------------------------------------------------------------------------
	FLAG LE LEVEL COURANT COMME DÉJÀ PARCOURU
	------------------------------------------------------------------------*/
	public function setVisited()  untyped {
		fl_visited[currentId]=true;
	}


	/*------------------------------------------------------------------------
	RENVOIE TRUE SI LE NIVEAU A DÉJÀ ÉTÉ PARCOURU
	------------------------------------------------------------------------*/
	public function isVisited()  untyped {
		return fl_visited[currentId]==true;
	}


	// *** IA *****


	/*------------------------------------------------------------------------
	RELANCE LE PROCESSUS DE PARSING IA
	------------------------------------------------------------------------*/
	public function resetIA()  untyped {
		flcurrentIA = false;
		_iteration = {cx:0, cy:0};
		flagMap = new Array();
		fallMap = new Array();

		{ var i:Dynamic=0; while (i<RootData.LEVEL_WIDTH) {
			flagMap[i] = new Array() ;
			fallMap[i] = new Array() ;
			{ var j:Dynamic=0; while (j<RootData.LEVEL_HEIGHT) {
				flagMap[i][j] = 0 ;
				fallMap[i][j] = -1 ;
			
j++; } }
		
i++; } }
	}

	/*------------------------------------------------------------------------
	RETOURNE UNE CASE DE LA MAP IA
	------------------------------------------------------------------------*/
	public function checkFlag(pt:Dynamic, flag:Dynamic):Bool  untyped {
		var x:Int=pt?.x ;
		var y:Int=pt?.y ;
		if (x>=0 && x<RootData.LEVEL_WIDTH && y>=0 && y<RootData.LEVEL_HEIGHT) {
			return (MtStd.ix(flagMap[x], y) & flag)>0 ; // dans la zone de jeu
		}
		else {
			return false ; // hors écran
		}
	}


	/*------------------------------------------------------------------------
	FORCE UN FLAG DANS UNE CASE
	------------------------------------------------------------------------*/
	public function forceFlag(pt:Dynamic, flag:Dynamic, value:Bool)  untyped {
		if ( value ) {
			flagMap[pt?.x][pt?.y] |= flag;
		}
		else {
			flagMap[pt?.x][pt?.y] &= ~flag;
		}
	}


	/*------------------------------------------------------------------------
	PARCOURE DE LA MAP DÉCALÉ SUR PLUSIEURS FRAMES
	------------------------------------------------------------------------*/
	public function parseCurrentIA( it: {cx:Int,cy:Int} )  untyped {
		var n:Dynamic=0 ;
		var total:Dynamic = RootData.LEVEL_WIDTH*RootData.LEVEL_HEIGHT ;
		var cx:Dynamic = it?.cx ;
		var cy:Dynamic = it?.cy ;

		while (n<RootData.MAX_ITERATION && cy<RootData.LEVEL_HEIGHT) {
			var flags:Dynamic = 0 ;

			// Dalle normale
			if ( getCase( {x:cx,y:cy+1} )==RootData.GROUND ) {
				flags |= RootData.IA_TILE_TOP ;
				// Zone de saut vers le haut
				if ( getCase( {x:cx,y:cy-RootData.IA_VJUMP} )==RootData.GROUND && getCase( {x:cx,y:cy-RootData.IA_VJUMP-1} )<=0 ) {
					flags |= RootData.IA_JUMP_UP ;
				}
			}

			if ( getCase( {x:cx,y:cy} )==RootData.GROUND && getCase( {x:cx,y:cy-1} )<=0 ) {
				flags |= RootData.IA_TILE ;
			}

			// Point de chute autorisé (fallHeight==-1 si dans le vide)
			var fallHeight:Dynamic = _checkSecureFall(cx,cy) ;
			fallMap[cx][cy] = fallHeight;
			if ( fallHeight>=0 ) {
				flags |= RootData.IA_ALLOW_FALL ;
			}

			// Point de saut vertical, vers le bas (on est sous une dalle)
			if ( getCase( {x:cx,y:cy} )==0 && getCase( {x:cx,y:cy+1} )==RootData.GROUND ) {
				fallHeight = _checkSecureFall(cx,cy+2) ;
				if ( fallHeight>=0 ) {
					flags |= RootData.IA_JUMP_DOWN ;
				}
			}

			// Bord de dalle
			if ( getCase( {x:cx,y:cy+1} )==RootData.GROUND &&
			( getCase( {x:cx-1,y:cy+1} )<=0 || getCase( {x:cx+1,y:cy+1} )<=0 ) ) {
				flags |= RootData.IA_BORDER ;
			}

			// Case en bord de dalle d'où les bads peuvent se laisser tomber
			if ( getCase( {x:cx,y:cy+1} )<=0 &&
			( getCase( {x:cx-1,y:cy+1} )==RootData.GROUND || getCase( {x:cx+1,y:cy+1} )==RootData.GROUND ) ) {
				flags |= RootData.IA_FALL_SPOT ;
			}

			// Petite dalle merdique
			if ( (flags & RootData.IA_BORDER)>0 ) {
				if ( getCase( {x:cx-1,y:cy+1} )!=RootData.GROUND && getCase( {x:cx+1,y:cy+1} )!=RootData.GROUND ) {
					flags |= RootData.IA_SMALL_SPOT ;
				}
			}

			// Au pied d'un mur
			if ( (flags & RootData.IA_TILE_TOP)>0 ) {

				// Calcule la distance au plafond
				var maxHeight:Dynamic=1;
				var d:Dynamic=1;
				while (d<=5) {
					if ( getCase( {x:cx,y:cy-d} )<=0 ) {
						maxHeight++;
					}
					else {
						d=999;
					}
					d++;
				}

				if ( maxHeight>0 ) {
					// Gauche
					if ( getCase( {x:cx-1,y:cy} )>0 ) {
						var h:Dynamic = getWallHeight(cx-1,cy, RootData.IA_CLIMB);
						if ( h!=null && h<maxHeight && cy-h>=0 ) {
							flags |= RootData.IA_CLIMB_LEFT;
						}
					}
					// Droite
					if ( getCase( {x:cx+1,y:cy} )>0 ) {
						var h:Dynamic = getWallHeight(cx+1,cy, RootData.IA_CLIMB);
						if ( h!=null && h<maxHeight && cy-h>=0 ) {
							flags |= RootData.IA_CLIMB_RIGHT;
						}
					}
				}
			}


			// Escaclier dans le vide
			if ( (flags & RootData.IA_FALL_SPOT)>0 ) {

				// Calcule la distance au plafond
				var maxHeight:Dynamic=1;
				var d:Dynamic=1;
				while (d<=5) {
					if ( getCase( {x:cx,y:cy-d} )<=0 ) {
						maxHeight++;
					}
					else {
						maxHeight+=2;
						d=999;
					}
					d++;
				}


				if ( maxHeight>0 ) {
					// Gauche
					if ( getCase( {x:cx+1,y:cy+1} )==RootData.GROUND ) {
						var h:Dynamic = getStepHeight(cx,cy, RootData.IA_CLIMB);
						if ( h!=null && h<maxHeight ) {
							if (  checkFlag( {x:cx,y:cy-h}, RootData.IA_BORDER ) && checkFlag( {x:cx+1,y:cy-h}, RootData.IA_FALL_SPOT )  ) {
								flags |= RootData.IA_CLIMB_LEFT;
							}
						}
					}
					// Droite
					if ( getCase( {x:cx-1,y:cy+1} )==RootData.GROUND ) {
						var h:Dynamic = getStepHeight(cx,cy, RootData.IA_CLIMB);
						if ( h!=null && h<maxHeight ) {
							if (  checkFlag( {x:cx,y:cy-h}, RootData.IA_BORDER ) && checkFlag( {x:cx-1,y:cy-h}, RootData.IA_FALL_SPOT )  ) {
								flags |= RootData.IA_CLIMB_RIGHT;
							}
						}
					}
				}
			}


			// Sous-catégories de bords de dalle
			if ( (flags & RootData.IA_FALL_SPOT)>0 ) {
				// Saut à gauche
				if ( getCase( {x:cx+1,y:cy+1} )==RootData.GROUND && getCase( {x:cx-RootData.IA_HJUMP,y:cy+1} )==RootData.GROUND ) {
					if ( getCase( {x:cx-1,y:cy} )<=0 ) {
						flags |= RootData.IA_JUMP_LEFT ;
					}
				}
				// Saut à droite
				if ( getCase( {x:cx-1,y:cy+1} )==RootData.GROUND && getCase( {x:cx+RootData.IA_HJUMP,y:cy+1} )==RootData.GROUND ) {
					if ( getCase( {x:cx+1,y:cy} )<=0 ) {
						flags |= RootData.IA_JUMP_RIGHT ;
					}
				}
			}

			flagMap[cx][cy] = flags ;

			// Case suivante
			cx++ ;
			if ( cx>=RootData.LEVEL_WIDTH ) {
				cx=0 ;
				cy++ ;
			}
			n++ ;
		}

		manager?.progress( cy/RootData.LEVEL_HEIGHT ) ;

		if (n!=RootData.MAX_ITERATION) {
			onParseIAComplete() ;
		}

		{ if (it != null) it.cx = cx ; }
		{ if (it != null) it.cy = cy ; }
	}



	/*------------------------------------------------------------------------
	VERIFIE SI UN POINT EST SÛR POUR TOMBER (RENVOIE LA HAUTEUR OU -1 SI VIDE)
	------------------------------------------------------------------------*/
	public function _checkSecureFall(cx:Dynamic,cy:Dynamic)  untyped {
		var secure:Dynamic,i:Dynamic,h:Dynamic ;

		// Optimisations
		if ( MtStd.ix(current?.__S_map[cx], cy)==RootData.GROUND )			return -1 ;
		if ( MtStd.ix(current?.__S_map[cx], cy)==RootData.WALL )				return -1 ;
		if ( (MtStd.ix(flagMap[cx], cy-1) & RootData.IA_ALLOW_FALL)>0 )	return MtStd.ix(fallMap[cx], cy-1)-1;

		secure = false ;
		i = cy+1 ;
		h = 0;
		while ( !secure && i < RootData.LEVEL_HEIGHT && cx >= 0 && cx < RootData.LEVEL_WIDTH ) {
			if ( MtStd.ix(current?.__S_map[cx], i) == RootData.GROUND ) {
				secure = true ;
			}
			else {
				i++ ;
				h++;
			}
		}

		if ( secure ) {
			return h;
		}
		else {
			return -1;
		}
	}


	/*------------------------------------------------------------------------
	RENVOIE LA HAUTEUR D'UN MUR (AVEC UN MAX ÉVENTUEL, -1 SI MAX ATTEINT)
	------------------------------------------------------------------------*/
	public function getWallHeight(cx:Dynamic,cy:Dynamic,max:Dynamic):Int  untyped {
		var h:Dynamic = 0;
		while ( getCase( {x:cx,y:cy-h} )>0 && h<max ) {
			h++;
		}
		if ( h>=max ) {
			h=null;
		}
		return h;
	}


	/*------------------------------------------------------------------------
	RENVOIE LA HAUTEUR D'UNE MARCHE DANS LE VIDE
	------------------------------------------------------------------------*/
	public function getStepHeight(cx:Dynamic,cy:Dynamic,max:Dynamic):Int  untyped {
		var h:Dynamic = 0;
		while (  getCase( {x:cx,y:cy-h} )<=0  &&  h<max  ) {
			h++;
		}
		h++;
		if ( h>=max ) {
			h=null;
		}
		return h;
	}

	// *** EVENTS *****

	/*------------------------------------------------------------------------
	EVENT: DONNÉES LUES, PRÊT POUR LE SCROLLING
	------------------------------------------------------------------------*/
	override public function onDataReady()  untyped {
		super.onDataReady();
		scriptEngine?.compile();
	}

	/*------------------------------------------------------------------------
	EVENT: PARSE MAP IA TERMINÉ
	------------------------------------------------------------------------*/
	public function onParseIAComplete()  untyped {
		fl_parsing = false;
		flcurrentIA = true;
		checkDataReady();
	}


	/*------------------------------------------------------------------------
	EVENT: DECRUNCH TERMINÉ
	------------------------------------------------------------------------*/
	override public function onReadComplete()  untyped {
		super.onReadComplete();
		scriptEngine = new levels.ScriptEngine(game, current);
		fl_parsing = true;
	}

	/*------------------------------------------------------------------------
	EVENT: VUE PRÊTE À ÊTRE JOUÉE
	------------------------------------------------------------------------*/
	override public function onViewReady()  untyped {
		super.onViewReady();
		game?.onLevelReady();
	}

	/*------------------------------------------------------------------------
	EVENT: FIN DE TRANSITION PORTAL
	------------------------------------------------------------------------*/
	override public function onFadeDone()  untyped {
		super.onFadeDone();
		game?.onRestore();
		onViewReady();
	}
	override public function onHScrollDone()  untyped {
		super.onHScrollDone();
		game?.onRestore();
		onViewReady();
	}


	/*------------------------------------------------------------------------
	EVENT: FIN DU SET
	------------------------------------------------------------------------*/
	override public function onEndOfSet()  untyped {
		super.onEndOfSet();
		game?.onEndOfSet();
	}


	/*------------------------------------------------------------------------
	EVENT: RESTORE TERMINÉ
	------------------------------------------------------------------------*/
	override public function onRestoreReady()  untyped {
		super.onRestoreReady();
		scrollDir = game?.fl_rightPortal ? 1 : -1; // hack: game var doesn't exist in ViewManager
	}


	// *** DONNÉES ***

	/*------------------------------------------------------------------------
	FORCE LE CONTENU D'UNE CASE (DYNAMIQUE SEULEMENT!)
	------------------------------------------------------------------------*/
	override public function forceCase(cx:Dynamic,cy:Dynamic,t:Dynamic)  untyped {
		super.forceCase(cx,cy,t);
		if ( inBound(cx,cy) ) {
			if ( t==RootData.GROUND ) {
				forceFlag( {x:cx,y:cy}, RootData.IA_TILE, true );
			}
			else {
				forceFlag( {x:cx,y:cy}, RootData.IA_TILE, false );
			}
		}
	}

	/*------------------------------------------------------------------------
	DÉTECTION DES MURS (ID=2)
	------------------------------------------------------------------------*/
	public function parseWalls(l:Dynamic)  untyped {
		var map:Dynamic = l?.__S_map;
		var n:Dynamic=0;
		{ var cy:Dynamic=0; while (cy<RootData.LEVEL_HEIGHT) {
			{ var cx:Dynamic=0; while (cx<RootData.LEVEL_WIDTH) {
				if ( MtStd.ix(map[cx], cy) > 0 ) {
					if ( MtStd.ix(map[cx], cy-1) > 0 ) {
						map[cx][cy] = RootData.WALL;
						n++;
					}
				}
			
cx++; } }
		
cy++; } }
	}


	/*------------------------------------------------------------------------
	LECTURE + DÉTECTION DES MURS (ID=2)
	------------------------------------------------------------------------*/
	override public function unserialize(id:Dynamic)  untyped {
		var l:Dynamic = super.unserialize(id);
		parseWalls(l);
		return l;
	}



	// *** TÉLÉPORTEURS *****

	/*------------------------------------------------------------------------
	RENVOIE LE TELEPORTER D'UNE CASE DONNÉE
	------------------------------------------------------------------------*/
	public function getTeleporter(e:entity.Physics, cx:Dynamic,cy:Dynamic) : TeleporterData  untyped {
		var out : TeleporterData = null ;
		if ( getCase( {x:cx,y:cy} ) != RootData.FIELD_TELEPORT ) {
			return null ;
		}

		var fl_break:Dynamic=false;


		{ var i:Dynamic=0; while (i<teleporterList?.length && !fl_break) {
			var td:Dynamic = teleporterList[i] ;
			if ( td?.dir==RootData.HORIZONTAL && cx>=td?.cx && cx<td?.cx+td?.length && cy==td?.cy ) {
				out = td;
				fl_break = true;
			}
			if ( !fl_break ) {
				if ( td?.dir==RootData.VERTICAL && cy>=td?.cy && cy<td?.cy+td?.length && cx==td?.cx ) {
					out = td;
					fl_break = true;
				}
			}
		
i++; } }

		if ( out==e?.lastTeleporter ) {
			return null ;
		}

		if ( out == null ) {
			GameManager.fatal("teleporter not found in level "+currentId) ;
		}
		return out ;
	}


	/*------------------------------------------------------------------------
	RENVOIE LE TÉLÉPORTEUR D'ARRIVÉE POUR UN TÉLÉPORTEUR DONNÉ
	------------------------------------------------------------------------*/
	public function getNextTeleporter( start : TeleporterData ) : { fl_rand:Bool, td:TeleporterData }    untyped {
		var out : TeleporterData = null ;
		var fl_break:Dynamic = false;
		var fl_rand:Dynamic = false;

		// Recherche de correspondance face à face
		{ var i:Dynamic=0; while (i<teleporterList?.length && !fl_break) {
			var td:Dynamic = teleporterList[i] ;
			if ( td?.cx!=start?.cx || td?.cy!=start?.cy ) {
				if ( start?.dir == RootData.HORIZONTAL ) {
					if ( start?.dir==td?.dir && start?.cx==td?.cx && start?.length==td?.length ) {
						out = td ;
						fl_break = true;
					}
				}
				if ( !fl_break && start?.dir == RootData.VERTICAL ) {
					if ( start?.dir==td?.dir && start?.cy==td?.cy && start?.length==td?.length ) {
						out = td ;
						fl_break = true;
					}
				}
			}
		
i++; } }

		// Correspondance par dir / length egales
		if ( out==null ) {

			fl_rand = true;
			if ( teleporterList?.length>1 ) {
				var l:Dynamic = new Array() ;
				{ var i:Dynamic=0; while (i<teleporterList?.length) {
					var td:Dynamic = teleporterList[i];
					if (  td?.cx!=start?.cx || td?.cy!=start?.cy  ) {
						if ( td?.dir == start?.dir && td?.length == start?.length ) {
							l?.push(teleporterList[i]) ;
						}
					}
				
i++; } }
				if ( l?.length>0 ) {
					out = l[MtStd.random(l?.length)] ;
					if ( l?.length==1 ) {
						fl_rand = false;
					}
				}
			}
		}

		// Correspondance random
		if ( out==null ) {

			fl_rand = true;
			if ( teleporterList?.length>1 ) {
				var l:Dynamic = new Array() ;
				{ var i:Dynamic=0; while (i<teleporterList?.length) {
					if (  teleporterList[i]?.cx!=start?.cx || teleporterList[i]?.cy!=start?.cy  ) {
						l?.push(teleporterList[i]) ;
					}
				
i++; } }
				out = l[MtStd.random(l?.length)] ;
			}
		}

		// Aucune correspondance
		if ( out==null ) {
			GameManager.fatal("target teleporter not found in level "+currentId) ;
		}
		return { fl_rand:fl_rand, td:out };
	}



	/*------------------------------------------------------------------------
	BOUCLE PRINCIPALE
	------------------------------------------------------------------------*/
	override public function update()  untyped {
		super.update();

		// Analyse (IA) niveau en cours si on a la main et que ca n'est pas déjà fait
		if ( fl_parsing ) {
			parseCurrentIA(_iteration);
		}

		if ( !fl_lock ) {
			scriptEngine?.update();
		}


		// Flottement des fields Portal
		{ var i:Dynamic=0; while (i<portalList?.length) {
			var p:Dynamic = portalList[i];
			{ if (p?.mc != null) p.mc._y = p?.y + 3*Math.sin(p?.cpt); }
			{ if (p != null) p.cpt += Timer.tmod*0.1; }
			if ( MtStd.random(5)==0 ) {
				var a:Dynamic = game?.fxMan?.attachFx(
					p?.x + RootData.CASE_WIDTH*0.5 + MtStd.random(15)*(MtStd.random(2)*2-1),
					p?.y + RootData.CASE_WIDTH*0.5 + MtStd.random(15)*(MtStd.random(2)*2-1),
					"hammer_fx_star"
				);
				{ if (a?.mc != null) a.mc._xscale	= MtStd.random(70)+30; }
				{ if (a?.mc != null) a.mc._yscale	= a?.mc?._xscale; }
			}
		
i++; } }

	}

}


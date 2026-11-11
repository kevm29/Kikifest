package net.rollback;

/**
	Ce que la simulation du jeu doit fournir à la couche rollback.

	`S` est le type d'une sauvegarde de l'état (tableau, Bytes, objet...).
	Le jeu choisit la forme la plus rapide à copier pour lui.

	Règles pour que deux ordinateurs restent identiques :
	- `advance` fait exactement un pas fixe (1/40 s) et ne lit ni le clavier,
	  ni l'horloge, ni `Math.random` : tout vient de `inputs` et de l'état ;
	- tout ce qui influence la suite (y compris la graine du générateur aléatoire
	  et le compteur de frames) est dans la sauvegarde ;
	- `save` renvoie une copie indépendante, et `load` ne garde aucune référence
	  vers l'objet chargé (il peut être rechargé plusieurs fois) ;
	- éviter `Math.sin`, `Math.cos`, `Math.pow`... dont les derniers bits peuvent
	  varier d'un navigateur à l'autre (préférer des tables précalculées).
**/
interface RollbackGame<S> {
	/** Avance d'une frame. `inputs[i]` = touches du joueur i (masque de bits, 16 bits max). **/
	function advance(inputs:Array<Int>):Void;

	/** Copie complète de l'état courant. **/
	function save():S;

	/** Remet l'état tel qu'il était lors de `save`. **/
	function load(state:S):Void;

	/** Empreinte de l'état courant, pour détecter les désynchronisations. **/
	function checksum():Int;
}

package net.transport;

import haxe.io.Bytes;

/**
	Canal de messages vers l'autre joueur, **non fiable et non ordonné**
	(un message peut être perdu, dupliqué ou arriver dans le désordre :
	la couche rollback s'en accommode en renvoyant ce qui n'est pas acquitté).
**/
interface Transport {
	/** Envoie un message (perdu sans erreur si le canal est fermé). **/
	function send(data:Bytes):Void;

	/** Appelé à la réception de chaque message. Affecté par la session. **/
	var onMessage:Bytes->Void;
}

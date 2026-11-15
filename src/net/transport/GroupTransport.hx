package net.transport;

import haxe.io.Bytes;

/**
	Regroupe plusieurs liaisons (une par autre joueur) en un canal de diffusion pour
	`GroupSession` : `send` part sur toutes les liaisons, et les messages de toutes
	arrivent sur `onMessage`.

	Avec `relay = true` (chez l'hôte), chaque message reçu est aussi renvoyé sur les
	autres liaisons : deux invités qui ne se joignent pas directement passent ainsi par
	l'hôte (réseau en étoile). Les doublons éventuels (liaison directe + relais) sont
	sans danger pour la session.
**/
class GroupTransport implements Transport {
	public var onMessage:Bytes->Void;
	public var relay:Bool;

	var links:Array<Transport> = [];

	public function new(relay = false) {
		this.relay = relay;
	}

	public function add(link:Transport):Void {
		links.push(link);
		link.onMessage = data -> {
			if (relay)
				for (other in links)
					if (other != link)
						other.send(data);
			if (onMessage != null)
				onMessage(data);
		};
	}

	public function remove(link:Transport):Void {
		links.remove(link);
		link.onMessage = null;
	}

	public function send(data:Bytes):Void {
		for (l in links)
			l.send(data);
	}
}

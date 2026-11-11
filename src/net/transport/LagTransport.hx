package net.transport;

import haxe.io.Bytes;

/**
	Enveloppe un transport et simule un mauvais réseau sur les messages envoyés :
	latence, gigue (donc désordre), pertes et doublons.
	Les messages sont livrés par `update(now)`, à appeler régulièrement
	avec l'heure en millisecondes. Avec une horloge et une graine fixes,
	le résultat est reproductible (tests).
**/
class LagTransport implements Transport {
	public var onMessage:Bytes->Void;

	public var latencyMs:Float;
	public var jitterMs:Float;
	public var lossRate:Float;
	public var duplicateRate:Float;

	var inner:Transport;
	var queue:Array<{at:Float, data:Bytes}> = [];
	var rng:Int;
	var now:Float = 0;

	public function new(inner:Transport, latencyMs = 0., jitterMs = 0., lossRate = 0., duplicateRate = 0., seed = 1) {
		this.inner = inner;
		this.latencyMs = latencyMs;
		this.jitterMs = jitterMs;
		this.lossRate = lossRate;
		this.duplicateRate = duplicateRate;
		rng = seed == 0 ? 1 : seed;
		inner.onMessage = data -> if (onMessage != null) onMessage(data);
	}

	public function send(data:Bytes):Void {
		if (random() < lossRate)
			return;
		push(data);
		if (random() < duplicateRate)
			push(data);
	}

	function push(data:Bytes) {
		var at = now + latencyMs + (random() * 2 - 1) * jitterMs;
		queue.push({at: at, data: data});
	}

	public function update(now:Float):Void {
		this.now = now;
		var due = [], rest = [];
		for (m in queue)
			(m.at <= now ? due : rest).push(m);
		queue = rest;
		due.sort((a, b) -> a.at < b.at ? -1 : (a.at > b.at ? 1 : 0));
		for (m in due)
			inner.send(m.data);
	}

	function random():Float {
		rng ^= rng << 13;
		rng ^= rng >>> 17;
		rng ^= rng << 5;
		return (rng & 0x7fffffff) / 2147483648.0;
	}
}

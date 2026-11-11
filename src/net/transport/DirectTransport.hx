package net.transport;

import haxe.io.Bytes;

/** Deux extrémités reliées directement en mémoire (tests, démo locale). **/
class DirectTransport implements Transport {
	public var onMessage:Bytes->Void;
	public var peer(default, null):DirectTransport;

	public function new() {}

	public static function pair():Array<DirectTransport> {
		var a = new DirectTransport(), b = new DirectTransport();
		a.peer = b;
		b.peer = a;
		return [a, b];
	}

	public function send(data:Bytes):Void {
		if (peer != null && peer.onMessage != null)
			peer.onMessage(data);
	}
}

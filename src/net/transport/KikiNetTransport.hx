package net.transport;

#if js
import haxe.io.Bytes;

/**
	Adaptateur vers le `Peer` fourni par `web/js/kikinet.js` (salon hôte/invité) :
	`KikiNet.connect()` renvoie un Peer avec `send(data)` (canal non fiable),
	`sendReliable(data)`, `onmessage = (data, reliable) => {}`, `role`, `seed`.
	Seuls les messages binaires non fiables sont transmis à la session ;
	les messages fiables sont confiés à `onReliable`.
**/
class KikiNetTransport implements Transport {
	public var onMessage:Bytes->Void;

	/** Messages du canal fiable (texte ou binaire), pour le salon ou les menus. **/
	public var onReliable:Dynamic->Void;

	public var peer(default, null):Dynamic;

	public function new(peer:Dynamic) {
		this.peer = peer;
		peer.onmessage = function(data:Dynamic, reliable:Bool) {
			if (reliable) {
				if (onReliable != null)
					onReliable(data);
				return;
			}
			if (onMessage == null || !js.Syntax.instanceof(data, js.lib.ArrayBuffer))
				return;
			onMessage(Bytes.ofData(data));
		};
	}

	/** Joueur local : 0 pour l'hôte, 1 pour l'invité. **/
	public var localPlayer(get, never):Int;

	function get_localPlayer()
		return peer.role == "host" ? 0 : 1;

	public function send(data:Bytes):Void {
		var buf:js.lib.ArrayBuffer = data.getData();
		peer.send(buf.byteLength == data.length ? buf : buf.slice(0, data.length));
	}
}
#end

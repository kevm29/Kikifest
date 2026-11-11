package net.rollback;

import haxe.io.Bytes;
import haxe.io.BytesInput;
import haxe.io.BytesOutput;
import net.transport.Transport;

enum TickResult {
	/** Une frame a été simulée (après d'éventuelles frames rejouées). **/
	Advanced;

	/** Trop d'avance sans nouvelles de l'autre joueur : on attend ses touches. **/
	WaitingForRemote;

	/** On est en avance sur l'autre joueur : on saute une frame pour le laisser rattraper. **/
	SlowingDown;
}

typedef SessionOptions = {
	/** 0 ou 1. **/
	var localPlayer:Int;

	/** Horloge en millisecondes (pings, détection de silence). **/
	var now:Void->Float;

	/** Frames de délai sur ses propres touches (défaut 2). Plus de délai = moins de rollbacks. **/
	var ?inputDelay:Int;

	/** Nombre maximal de frames simulées sans les touches de l'autre (défaut 8). **/
	var ?maxPrediction:Int;

	/** Une empreinte est comparée toutes les N frames (défaut 20, soit 2 fois par seconde). **/
	var ?checksumInterval:Int;

	/** Durée d'une frame en ms (défaut 25, soit 40 images/s). **/
	var ?frameMs:Float;
}

typedef SessionStats = {
	var rollbacks:Int;
	var maxRollback:Int;
	var resimulatedFrames:Int;
	var waitingTicks:Int;
	var slowdownTicks:Int;
	var messagesSent:Int;
	var messagesReceived:Int;
	var checksumsCompared:Int;
}

/**
	Session de rollback netcode pour 2 joueurs (dans l'esprit de GGPO).

	Boucle d'utilisation, appelée 40 fois par seconde à pas fixe :
	```
	session.tick(lireClavier());
	afficher(jeu);
	```
	- Les touches locales sont appliquées après `inputDelay` frames et envoyées à l'autre.
	- Les touches de l'autre sont **prédites** (on répète la dernière connue) ;
	  quand les vraies arrivent et diffèrent, l'état est restauré à la première
	  frame fausse et tout est rejoué jusqu'au présent, dans le même `tick`.
	- Toutes les `checksumInterval` frames confirmées, une empreinte de l'état est
	  échangée ; une différence déclenche `onDesync`.
	- Les deux horloges sont gardées alignées : celui qui a de l'avance saute
	  de temps en temps une frame (`SlowingDown`).
**/
class RollbackSession<S> {
	static inline var SIZE = 256; // frames gardées en mémoire (puissance de 2)
	static inline var MASK = SIZE - 1;
	static inline var MSG_INPUT = 1;
	static inline var MSG_CHECKSUM = 2;
	static inline var MSG_PING = 3;
	static inline var MSG_PONG = 4;
	static inline var PING_EVERY_MS = 250.;
	static inline var SYNC_EVERY = 40; // frames entre deux décisions de recalage

	public var localPlayer(default, null):Int;
	public var remotePlayer(default, null):Int;

	/** Prochaine frame à simuler (= nombre de frames simulées). **/
	public var currentFrame(default, null):Int = 0;

	/** Dernière frame dont on connaît les touches de l'autre joueur. **/
	public var remoteConfirmedFrame(default, null):Int = -1;

	/** Vrai pendant qu'on rejoue des frames : le jeu doit alors couper sons et effets ponctuels. **/
	public var resimulating(default, null):Bool = false;

	public var inputDelay(default, set):Int;
	public var maxPrediction(default, null):Int;
	public var checksumInterval(default, null):Int;
	public var frameMs(default, null):Float;

	/** Aller-retour réseau lissé, en ms. **/
	public var rttMs(default, null):Float = 0;

	/** Avance moyenne en frames sur l'autre joueur (positive = on est devant). **/
	public var frameAdvantage(default, null):Float = 0;

	public var desynced(default, null):Bool = false;

	/** (frame, empreinte locale, empreinte distante) **/
	public var onDesync:(Int, Int, Int) -> Void;

	public var stats(default, null):SessionStats = {
		rollbacks: 0,
		maxRollback: 0,
		resimulatedFrames: 0,
		waitingTicks: 0,
		slowdownTicks: 0,
		messagesSent: 0,
		messagesReceived: 0,
		checksumsCompared: 0
	};

	var game:RollbackGame<S>;
	var transport:Transport;
	var now:Void->Float;

	var localInputs:Array<Int> = [for (i in 0...SIZE) 0];
	var remoteInputs:Array<Int> = [for (i in 0...SIZE) 0];
	var usedRemote:Array<Int> = [for (i in 0...SIZE) 0];
	var states:Array<S> = [];
	var stateChecksums:Array<Int> = [for (i in 0...SIZE) 0];
	var frameInputs:Array<Int> = [0, 0];

	var lastLocalFrame = -1; // dernière frame dont la touche locale est fixée
	var lastLocalInput = 0;
	var remoteAckedLocal = -1; // dernière frame locale reçue par l'autre
	var firstMispredict = -1;

	var incoming:Array<Bytes> = [];
	var remoteFrame = 0;
	var heardFromRemote = false;
	var remoteAdvantage:Float = 0;
	var advantageSum:Float = 0;
	var advantageCount = 0;
	var slowdownBudget = 0;
	var ticks = 0;
	var lastPing:Float = -1e9;
	var lastReceive:Float;

	var nextChecksumFrame:Int;
	var localChecks = new Map<Int, Int>();
	var remoteChecks = new Map<Int, Int>();

	public function new(game:RollbackGame<S>, transport:Transport, options:SessionOptions) {
		this.game = game;
		this.transport = transport;
		localPlayer = options.localPlayer;
		remotePlayer = 1 - localPlayer;
		now = options.now;
		maxPrediction = clamp(options.maxPrediction == null ? 8 : options.maxPrediction, 1, 30);
		inputDelay = options.inputDelay == null ? 2 : options.inputDelay;
		checksumInterval = options.checksumInterval == null ? 20 : options.checksumInterval;
		frameMs = options.frameMs == null ? 25 : options.frameMs;
		nextChecksumFrame = checksumInterval;
		lastReceive = now();
		transport.onMessage = data -> incoming.push(data);
	}

	function set_inputDelay(v:Int):Int {
		// Augmenter le délai répète la dernière touche sur les frames intermédiaires ;
		// le diminuer ignore les touches des quelques ticks suivants.
		return inputDelay = clamp(v, 0, 30);
	}

	/**
		À appeler une fois par pas de temps (40 fois par seconde) avec les touches locales.
		Le jeu peut avoir été avancé de plusieurs frames (rollback) ou pas du tout.
	**/
	public function tick(localInput:Int):TickResult {
		ticks++;
		processIncoming();
		rollbackIfNeeded();
		updateTimeSync();

		var result = Advanced;
		if (currentFrame > remoteConfirmedFrame + maxPrediction || lastLocalFrame - remoteAckedLocal >= SIZE - 2) {
			result = WaitingForRemote;
			stats.waitingTicks++;
		} else if (slowdownBudget > 0 && ticks % 3 == 0) {
			slowdownBudget--;
			result = SlowingDown;
			stats.slowdownTicks++;
		} else {
			addLocalInput(localInput);
			advanceFrame();
		}
		sendInputs();
		sendChecksums();
		maybePing();
		return result;
	}

	/** Traite le réseau sans avancer (pause, fin de partie, attente). **/
	public function poll():Void {
		processIncoming();
		rollbackIfNeeded();
		sendInputs();
		sendChecksums();
		maybePing();
	}

	/** Millisecondes écoulées depuis le dernier message de l'autre joueur. **/
	public function silenceMs():Float
		return now() - lastReceive;

	/** Touches connues pour une frame (définitives si `frame <= remoteConfirmedFrame`). **/
	public function inputsAt(frame:Int):Array<Int> {
		var r = [0, 0];
		r[localPlayer] = frame <= lastLocalFrame ? localInputs[frame & MASK] : 0;
		r[remotePlayer] = frame <= remoteConfirmedFrame ? remoteInputs[frame & MASK] : usedRemote[frame & MASK];
		return r;
	}

	// --- Simulation -------------------------------------------------------

	function addLocalInput(input:Int) {
		var target = currentFrame + inputDelay;
		while (lastLocalFrame < target) {
			lastLocalFrame++;
			if (lastLocalFrame == target)
				lastLocalInput = input & 0xffff;
			localInputs[lastLocalFrame & MASK] = lastLocalInput;
		}
	}

	function advanceFrame() {
		var f = currentFrame;
		var i = f & MASK;
		states[i] = game.save();
		if (f % checksumInterval == 0)
			stateChecksums[i] = game.checksum();
		var remote = if (f <= remoteConfirmedFrame) remoteInputs[i] else if (remoteConfirmedFrame >= 0)
			remoteInputs[remoteConfirmedFrame & MASK] else 0;
		usedRemote[i] = remote;
		frameInputs[localPlayer] = f <= lastLocalFrame ? localInputs[i] : lastLocalInput;
		frameInputs[remotePlayer] = remote;
		game.advance(frameInputs);
		currentFrame++;
	}

	function rollbackIfNeeded() {
		if (firstMispredict < 0)
			return;
		var target = currentFrame;
		var from = firstMispredict;
		firstMispredict = -1;
		game.load(states[from & MASK]);
		currentFrame = from;
		resimulating = true;
		while (currentFrame < target)
			advanceFrame();
		resimulating = false;
		var depth = target - from;
		stats.rollbacks++;
		stats.resimulatedFrames += depth;
		if (depth > stats.maxRollback)
			stats.maxRollback = depth;
	}

	// --- Réseau -----------------------------------------------------------

	function processIncoming() {
		if (incoming.length == 0)
			return;
		var list = incoming;
		incoming = [];
		for (data in list) {
			try {
				readMessage(new BytesInput(data));
				stats.messagesReceived++;
				lastReceive = now();
			} catch (e:Dynamic) {
				// message tronqué ou inconnu : ignoré
			}
		}
	}

	function readMessage(inp:BytesInput) {
		switch (inp.readByte()) {
			case MSG_INPUT:
				var start = inp.readInt32();
				var count = inp.readByte();
				var ack = inp.readInt32();
				var senderFrame = inp.readInt32();
				var senderAdvantage = inp.readInt16() / 16;
				if (ack > remoteAckedLocal)
					remoteAckedLocal = ack;
				heardFromRemote = true;
				if (senderFrame >= remoteFrame) {
					remoteFrame = senderFrame;
					remoteAdvantage = senderAdvantage;
				}
				for (k in 0...count) {
					var v = inp.readUInt16();
					var f = start + k;
					if (f != remoteConfirmedFrame + 1)
						continue; // déjà connu, ou trou (il sera renvoyé)
					var i = f & MASK;
					remoteInputs[i] = v;
					remoteConfirmedFrame = f;
					if (f < currentFrame && usedRemote[i] != v && (firstMispredict < 0 || f < firstMispredict))
						firstMispredict = f;
				}
			case MSG_CHECKSUM:
				var f = inp.readInt32();
				var c = inp.readInt32();
				remoteChecks.set(f, c);
				compareChecksum(f);
			case MSG_PING:
				var t = inp.readDouble();
				var out = new BytesOutput();
				out.writeByte(MSG_PONG);
				out.writeDouble(t);
				send(out);
			case MSG_PONG:
				var rtt = now() - inp.readDouble();
				rttMs = rttMs == 0 ? rtt : rttMs * 0.8 + rtt * 0.2;
			case _:
		}
	}

	function sendInputs() {
		var start = remoteAckedLocal + 1;
		var count = lastLocalFrame - start + 1;
		if (count < 0)
			count = 0;
		if (count > 255)
			count = 255;
		var out = new BytesOutput();
		out.writeByte(MSG_INPUT);
		out.writeInt32(start);
		out.writeByte(count);
		out.writeInt32(remoteConfirmedFrame);
		out.writeInt32(currentFrame);
		out.writeInt16(clamp(Math.round(frameAdvantage * 16), -32000, 32000));
		for (k in 0...count)
			out.writeUInt16(localInputs[(start + k) & MASK]);
		send(out);
	}

	function sendChecksums() {
		// L'état au début de la frame f est définitif quand toutes les touches
		// des frames précédentes sont confirmées.
		while (nextChecksumFrame < currentFrame && nextChecksumFrame - 1 <= remoteConfirmedFrame && firstMispredict < 0) {
			var f = nextChecksumFrame;
			nextChecksumFrame += checksumInterval;
			if (f < currentFrame - SIZE)
				continue;
			var c = stateChecksums[f & MASK];
			localChecks.set(f, c);
			var out = new BytesOutput();
			out.writeByte(MSG_CHECKSUM);
			out.writeInt32(f);
			out.writeInt32(c);
			send(out);
			compareChecksum(f);
		}
	}

	function compareChecksum(f:Int) {
		if (!localChecks.exists(f) || !remoteChecks.exists(f))
			return;
		var l = localChecks.get(f), r = remoteChecks.get(f);
		localChecks.remove(f);
		remoteChecks.remove(f);
		stats.checksumsCompared++;
		if (l != r && !desynced) {
			desynced = true;
			if (onDesync != null)
				onDesync(f, l, r);
		}
		// oubli des empreintes trop anciennes (perdues côté distant)
		for (k in localChecks.keys())
			if (k < f - SIZE * 4)
				localChecks.remove(k);
		for (k in remoteChecks.keys())
			if (k < f - SIZE * 4)
				remoteChecks.remove(k);
	}

	function maybePing() {
		var t = now();
		if (t - lastPing < PING_EVERY_MS)
			return;
		lastPing = t;
		var out = new BytesOutput();
		out.writeByte(MSG_PING);
		out.writeDouble(t);
		send(out);
	}

	function send(out:BytesOutput) {
		stats.messagesSent++;
		transport.send(out.getBytes());
	}

	// --- Recalage des horloges ---------------------------------------------

	function updateTimeSync() {
		if (!heardFromRemote)
			return;
		// Frame où l'autre devrait être maintenant, compte tenu du trajet du message.
		var estimatedRemote = remoteFrame + (rttMs / 2) / frameMs;
		advantageSum += currentFrame - estimatedRemote;
		advantageCount++;
		if (advantageCount < SYNC_EVERY)
			return;
		frameAdvantage = advantageSum / advantageCount;
		advantageSum = 0;
		advantageCount = 0;
		// Comme GGPO : chacun mesure son avance, celui qui est devant ralentit
		// de la moitié de l'écart (l'autre fait la même mesure en miroir).
		var wait = Math.round((frameAdvantage - remoteAdvantage) / 2);
		slowdownBudget = wait >= 1 ? (wait > 8 ? 8 : wait) : 0;
	}

	static inline function clamp(v:Int, lo:Int, hi:Int):Int
		return v < lo ? lo : (v > hi ? hi : v);
}

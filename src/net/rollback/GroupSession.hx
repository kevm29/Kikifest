package net.rollback;

import haxe.io.Bytes;
import haxe.io.BytesInput;
import haxe.io.BytesOutput;
import net.rollback.RollbackSession.TickResult;
import net.rollback.RollbackSession.SessionStats;
import net.transport.Transport;

typedef GroupOptions = {
	/** Nombre de joueurs dans la partie (2 à 4). **/
	var players:Int;

	/** Numéro de ce joueur : 0 = hôte, puis 1, 2, 3 dans l'ordre d'arrivée. **/
	var localPlayer:Int;

	var now:Void->Float;
	var ?inputDelay:Int;
	var ?maxPrediction:Int;
	var ?checksumInterval:Int;
	var ?frameMs:Float;
	var ?saveEvery:Int;
}

/**
	Session de rollback pour 2 à 4 joueurs (étude du mode 3-4 joueurs).

	Même principe et même interface de jeu (`RollbackGame`) que `RollbackSession`, généralisé :
	- chacun envoie ses touches à **tous** les autres (un seul message, diffusé) ;
	- les touches de chaque autre joueur sont prédites séparément (répétition de la dernière connue) ;
	- une frame est définitive quand les touches de **tous** les joueurs sont connues ;
	- les horloges se recalent sur le joueur le plus en retard.

	Le transport est un canal de **diffusion** : `send` part vers tous les autres joueurs, et
	`onMessage` reçoit ceux de n'importe qui. Chaque message porte le numéro de son auteur, et il
	est autonome : un joueur relais (l'hôte) peut donc simplement faire suivre ce qu'il reçoit aux
	autres, sans le décoder. Ça permet un réseau en étoile (tout passe par l'hôte) quand deux
	invités n'arrivent pas à se joindre directement. Pertes, doublons et désordre sont tolérés.
**/
class GroupSession<S> {
	static inline var SIZE = 256;
	static inline var MASK = SIZE - 1;
	static inline var MSG_INPUT = 11;
	static inline var MSG_CHECKSUM = 12;
	static inline var MSG_PING = 13;
	static inline var MSG_PONG = 14;
	static inline var PING_EVERY_MS = 250.;
	static inline var SYNC_EVERY = 40;

	public var players(default, null):Int;
	public var localPlayer(default, null):Int;
	public var currentFrame(default, null):Int = 0;

	/** Dernière frame dont on connaît les touches de **tous** les joueurs. **/
	public var confirmedFrame(get, never):Int;

	public var resimulating(default, null):Bool = false;
	public var inputDelay(default, set):Int;
	public var maxPrediction(default, null):Int;
	public var checksumInterval(default, null):Int;
	public var frameMs(default, null):Float;
	public var desynced(default, null):Bool = false;

	/** (frame, joueur distant, empreinte locale, empreinte distante) **/
	public var onDesync:(Int, Int, Int, Int) -> Void;

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
	var lastLocalFrame = -1;
	var lastLocalInput = 0;

	// Par joueur (la case du joueur local ne sert pas)
	var inputs:Array<Array<Int>>; // touches reçues
	var used:Array<Array<Int>>; // touches utilisées (prédites ou reçues)
	var confirmed:Array<Int>; // dernière frame reçue sans trou
	var ackedLocal:Array<Int>; // dernière de nos frames qu'il a reçue
	var remoteFrame:Array<Int>;
	var remoteAdvantage:Array<Float>; // son avance sur nous, qu'il nous annonce
	var advantage:Array<Float>; // notre avance sur lui, mesurée
	var advantageSum:Array<Float>;
	var heard:Array<Bool>;
	var rtt:Array<Float>;
	var lastReceive:Array<Float>;
	var remoteChecks:Array<Map<Int, Int>>;

	var frameInputs:Array<Int>;
	var states:Array<S> = [];
	var stateChecksums:Array<Int> = [for (i in 0...SIZE) 0];
	var savedAt:Array<Int> = [for (i in 0...SIZE) -1];
	var lastSave = -1;
	var saveEvery:Int;
	var firstMispredict = -1;
	var incoming:Array<Bytes> = [];
	var advantageCount = 0;
	var slowdownBudget = 0;
	var ticks = 0;
	var lastPing:Float = -1e9;
	var nextChecksumFrame:Int;
	var localChecks = new Map<Int, Int>();

	public function new(game:RollbackGame<S>, transport:Transport, options:GroupOptions) {
		this.game = game;
		this.transport = transport;
		players = clamp(options.players, 2, 8);
		localPlayer = options.localPlayer;
		if (localPlayer < 0 || localPlayer >= players)
			throw 'joueur $localPlayer hors de 0..${players - 1}';
		now = options.now;
		maxPrediction = clamp(options.maxPrediction == null ? 8 : options.maxPrediction, 1, 30);
		inputDelay = options.inputDelay == null ? 2 : options.inputDelay;
		checksumInterval = options.checksumInterval == null ? 20 : options.checksumInterval;
		frameMs = options.frameMs == null ? 25 : options.frameMs;
		saveEvery = options.saveEvery == null || options.saveEvery < 1 ? 0 : options.saveEvery;
		nextChecksumFrame = checksumInterval;
		var t = now();
		inputs = [for (p in 0...players) [for (i in 0...SIZE) 0]];
		used = [for (p in 0...players) [for (i in 0...SIZE) 0]];
		confirmed = [for (p in 0...players) -1];
		ackedLocal = [for (p in 0...players) -1];
		remoteFrame = [for (p in 0...players) 0];
		remoteAdvantage = [for (p in 0...players) 0.];
		advantage = [for (p in 0...players) 0.];
		advantageSum = [for (p in 0...players) 0.];
		heard = [for (p in 0...players) false];
		rtt = [for (p in 0...players) 0.];
		lastReceive = [for (p in 0...players) t];
		remoteChecks = [for (p in 0...players) new Map<Int, Int>()];
		frameInputs = [for (p in 0...players) 0];
		transport.onMessage = data -> incoming.push(data);
	}

	function set_inputDelay(v:Int):Int
		return inputDelay = clamp(v, 0, 30);

	function get_confirmedFrame():Int {
		var m = 0x7fffffff;
		for (p in 0...players)
			if (p != localPlayer && confirmed[p] < m)
				m = confirmed[p];
		return m;
	}

	function minAcked():Int {
		var m = 0x7fffffff;
		for (p in 0...players)
			if (p != localPlayer && ackedLocal[p] < m)
				m = ackedLocal[p];
		return m;
	}

	/** Aller-retour lissé vers un joueur, en ms. **/
	public function rttTo(p:Int):Float
		return rtt[p];

	/** Le pire aller-retour parmi les autres joueurs. **/
	public function worstRtt():Float {
		var m = 0.;
		for (p in 0...players)
			if (p != localPlayer && rtt[p] > m)
				m = rtt[p];
		return m;
	}

	/** Millisecondes depuis le dernier message d'un joueur. **/
	public function silenceMsOf(p:Int):Float
		return now() - lastReceive[p];

	/** Le plus long silence parmi les autres joueurs. **/
	public function silenceMs():Float {
		var m = 0.;
		for (p in 0...players)
			if (p != localPlayer && silenceMsOf(p) > m)
				m = silenceMsOf(p);
		return m;
	}

	public function tick(localInput:Int):TickResult {
		ticks++;
		processIncoming();
		rollbackIfNeeded();
		updateTimeSync();
		var result = Advanced;
		if (currentFrame > confirmedFrame + maxPrediction || lastLocalFrame - minAcked() >= SIZE - 2) {
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

	public function poll():Void {
		processIncoming();
		rollbackIfNeeded();
		sendInputs();
		sendChecksums();
		maybePing();
	}

	/** Touches connues pour une frame (définitives si `frame <= confirmedFrame`). **/
	public function inputsAt(frame:Int):Array<Int> {
		var i = frame & MASK;
		return [
			for (p in 0...players)
				p == localPlayer ? (frame <= lastLocalFrame ? localInputs[i] : 0) : (frame <= confirmed[p] ? inputs[p][i] : used[p][i])
		];
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
		var allKnown = confirmedFrame;
		if (saveEvery == 0)
			states[i] = game.save();
		else if (f > allKnown && (f == allKnown + 1 || f - lastSave >= saveEvery || lastSave > f)) {
			states[i] = game.save();
			savedAt[i] = f;
			lastSave = f;
		} else
			savedAt[i] = -1;
		if (f % checksumInterval == 0)
			stateChecksums[i] = game.checksum();
		for (p in 0...players) {
			if (p == localPlayer) {
				frameInputs[p] = f <= lastLocalFrame ? localInputs[i] : lastLocalInput;
				continue;
			}
			var c = confirmed[p];
			var v = f <= c ? inputs[p][i] : (c >= 0 ? inputs[p][c & MASK] : 0);
			used[p][i] = v;
			frameInputs[p] = v;
		}
		game.advance(frameInputs);
		currentFrame++;
	}

	function rollbackIfNeeded() {
		if (firstMispredict < 0)
			return;
		var target = currentFrame;
		var from = firstMispredict;
		firstMispredict = -1;
		if (saveEvery > 0) {
			var lim = from - SIZE;
			while (savedAt[from & MASK] != from && from > lim)
				from--;
		}
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
				var inp = new BytesInput(data);
				var type = inp.readByte();
				var sender = inp.readByte();
				if (sender == localPlayer || sender >= players)
					continue;
				readMessage(type, sender, inp);
				stats.messagesReceived++;
				lastReceive[sender] = now();
			} catch (e:Dynamic) {}
		}
	}

	function readMessage(type:Int, sender:Int, inp:BytesInput) {
		switch (type) {
			case MSG_INPUT:
				var start = inp.readInt32();
				var count = inp.readByte();
				var senderFrame = inp.readInt32();
				for (q in 0...players) {
					var seen = inp.readInt32();
					var adv = inp.readInt16() / 16;
					if (q == localPlayer) {
						if (seen > ackedLocal[sender])
							ackedLocal[sender] = seen;
						if (senderFrame >= remoteFrame[sender])
							remoteAdvantage[sender] = adv;
					}
				}
				heard[sender] = true;
				if (senderFrame >= remoteFrame[sender])
					remoteFrame[sender] = senderFrame;
				var mine = inputs[sender], guess = used[sender];
				for (k in 0...count) {
					var v = inp.readUInt16();
					var f = start + k;
					if (f != confirmed[sender] + 1)
						continue;
					var i = f & MASK;
					mine[i] = v;
					confirmed[sender] = f;
					if (f < currentFrame && guess[i] != v && (firstMispredict < 0 || f < firstMispredict))
						firstMispredict = f;
				}
			case MSG_CHECKSUM:
				var f = inp.readInt32();
				remoteChecks[sender].set(f, inp.readInt32());
				compareChecksum(f, sender);
			case MSG_PING:
				var t = inp.readDouble();
				var out = header(MSG_PONG);
				out.writeByte(sender);
				out.writeDouble(t);
				send(out);
			case MSG_PONG:
				var target = inp.readByte();
				var t = inp.readDouble();
				if (target == localPlayer) {
					var r = now() - t;
					rtt[sender] = rtt[sender] == 0 ? r : rtt[sender] * 0.8 + r * 0.2;
				}
			case _:
		}
	}

	function header(type:Int):BytesOutput {
		var out = new BytesOutput();
		out.writeByte(type);
		out.writeByte(localPlayer);
		return out;
	}

	function sendInputs() {
		var start = minAcked() + 1;
		var count = clamp(lastLocalFrame - start + 1, 0, 255);
		var out = header(MSG_INPUT);
		out.writeInt32(start);
		out.writeByte(count);
		out.writeInt32(currentFrame);
		for (q in 0...players) {
			out.writeInt32(q == localPlayer ? lastLocalFrame : confirmed[q]);
			out.writeInt16(clamp(Math.round(advantage[q] * 16), -32000, 32000));
		}
		for (k in 0...count)
			out.writeUInt16(localInputs[(start + k) & MASK]);
		send(out);
	}

	function sendChecksums() {
		while (nextChecksumFrame < currentFrame && nextChecksumFrame - 1 <= confirmedFrame && firstMispredict < 0) {
			var f = nextChecksumFrame;
			nextChecksumFrame += checksumInterval;
			if (f < currentFrame - SIZE)
				continue;
			var c = stateChecksums[f & MASK];
			localChecks.set(f, c);
			var out = header(MSG_CHECKSUM);
			out.writeInt32(f);
			out.writeInt32(c);
			send(out);
			for (p in 0...players)
				if (p != localPlayer)
					compareChecksum(f, p);
		}
		for (k in localChecks.keys())
			if (k < currentFrame - SIZE * 4)
				localChecks.remove(k);
	}

	function compareChecksum(f:Int, p:Int) {
		var theirs = remoteChecks[p];
		if (!localChecks.exists(f) || !theirs.exists(f))
			return;
		var l = localChecks.get(f), r = theirs.get(f);
		theirs.remove(f);
		stats.checksumsCompared++;
		if (l != r && !desynced) {
			desynced = true;
			if (onDesync != null)
				onDesync(f, p, l, r);
		}
		for (k in theirs.keys())
			if (k < f - SIZE * 4)
				theirs.remove(k);
	}

	function maybePing() {
		var t = now();
		if (t - lastPing < PING_EVERY_MS)
			return;
		lastPing = t;
		var out = header(MSG_PING);
		out.writeDouble(t);
		send(out);
	}

	function send(out:BytesOutput) {
		stats.messagesSent++;
		transport.send(out.getBytes());
	}

	// --- Recalage des horloges ---------------------------------------------

	function updateTimeSync() {
		var any = false;
		for (p in 0...players) {
			if (p == localPlayer || !heard[p])
				continue;
			any = true;
			advantageSum[p] += currentFrame - (remoteFrame[p] + (rtt[p] / 2) / frameMs);
		}
		if (!any)
			return;
		advantageCount++;
		if (advantageCount < SYNC_EVERY)
			return;
		// On ralentit pour le joueur le plus en retard par rapport à nous.
		var wait = 0;
		for (p in 0...players) {
			if (p == localPlayer || !heard[p])
				continue;
			advantage[p] = advantageSum[p] / advantageCount;
			advantageSum[p] = 0;
			var w = Math.round((advantage[p] - remoteAdvantage[p]) / 2);
			if (w > wait)
				wait = w;
		}
		advantageCount = 0;
		slowdownBudget = wait > 8 ? 8 : wait;
	}

	static inline function clamp(v:Int, lo:Int, hi:Int):Int
		return v < lo ? lo : (v > hi ? hi : v);
}

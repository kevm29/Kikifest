import net.rollback.RollbackSession;
import net.rollback.SyncTest;
import net.transport.DirectTransport;
import net.transport.LagTransport;
import netdemo.DemoGame;

/**
	Tests déterministes de la couche rollback (sans navigateur) :
	haxe tests.hxml   (compile et lance avec Node)
**/
class NetTest {
	static var failures = 0;
	static var rng = 42;
	static var sparse = false;

	static function main() {
		testSyncTest();
		testSyncTestFindsMissingField();
		for (net in [
			{name: "local parfait", lat: 0., jit: 0., loss: 0., dup: 0.},
			{name: "wifi 30 ms", lat: 30., jit: 5., loss: 0.01, dup: 0.},
			{name: "internet 80 ms", lat: 80., jit: 20., loss: 0.05, dup: 0.01},
			{name: "très mauvais 150 ms", lat: 150., jit: 50., loss: 0.15, dup: 0.03},
		])
			for (delay in [0, 2, 4])
				testMatch(net.name, net.lat, net.jit, net.loss, net.dup, delay, 0);
		testMatch("horloge de l'invité 2 % trop rapide", 50, 10, 0.02, 0, 2, 50);
		sparse = true;
		for (net in [
			{name: "clairsemé, wifi 30 ms", lat: 30., jit: 5., loss: 0.01, dup: 0.},
			{name: "clairsemé, internet 80 ms", lat: 80., jit: 20., loss: 0.05, dup: 0.01},
			{name: "clairsemé, très mauvais 150 ms", lat: 150., jit: 50., loss: 0.15, dup: 0.03},
		])
			for (delay in [0, 2])
				testMatch(net.name, net.lat, net.jit, net.loss, net.dup, delay, 0);
		sparse = false;
		testDesyncDetected();
		testDisconnectAndRecover();
		log(failures == 0 ? "\nTOUS LES TESTS PASSENT" : '\n$failures ÉCHEC(S)');
		#if js
		js.Syntax.code("process.exit({0})", failures == 0 ? 0 : 1);
		#end
	}

	static function testSyncTest() {
		var st = new SyncTest(new DemoGame(7), 7);
		var a = 0, b = 0;
		for (i in 0...3000) {
			a = nextInput(a);
			b = nextInput(b);
			if (!st.tick([a, b]))
				break;
		}
		check(st.firstError < 0, "SyncTest : DemoGame déterministe sur 3000 frames", st.errorMessage);
	}

	static function testSyncTestFindsMissingField() {
		var g = new DemoGame(7);
		g.forgetRngInSave = true;
		var st = new SyncTest(g, 4);
		for (i in 0...500)
			if (!st.tick([nextInput(0), 0]))
				break;
		check(st.firstError >= 0, "SyncTest : détecte un champ oublié dans save()", 'erreur à la frame ${st.firstError}');
	}

	/**
		Deux sessions reliées par un réseau simulé. On vérifie que les deux parties
		finissent identiques entre elles ET identiques à une partie rejouée sans réseau
		avec les touches définitives.
	**/
	static function testMatch(name:String, lat:Float, jit:Float, loss:Float, dup:Float, delay:Int, guestFastEvery:Int) {
		var t = 0.;
		var clock = () -> t;
		var pipes = DirectTransport.pair();
		var lagA = new LagTransport(pipes[0], lat, jit, loss, dup, 11);
		var lagB = new LagTransport(pipes[1], lat, jit, loss, dup, 22);
		var seed = 1234;
		var gameA = new DemoGame(seed), gameB = new DemoGame(seed);
		var a = new RollbackSession(gameA, lagA, {localPlayer: 0, now: clock, inputDelay: delay, saveEvery: sparse ? 4 : 0});
		var b = new RollbackSession(gameB, lagB, {localPlayer: 1, now: clock, inputDelay: delay, saveEvery: sparse ? 4 : 0});
		var desync = false;
		a.onDesync = b.onDesync = (_, _, _) -> desync = true;
		var histA:Array<Array<Int>> = [], histB:Array<Array<Int>> = [];
		var inA = 0, inB = 0, maxGap = 0;

		var steps = 2400; // 60 s de jeu
		for (step in 0...steps) {
			t += 25;
			lagA.update(t);
			lagB.update(t);
			inA = nextInput(inA);
			inB = nextInput(inB);
			a.tick(inA);
			if (step >= 5) // l'invité démarre un peu plus tard
				b.tick(inB);
			if (guestFastEvery > 0 && step % guestFastEvery == 0)
				b.tick(inB);
			record(a, histA);
			record(b, histB);
			if (step > 200)
				maxGap = Std.int(Math.max(maxGap, Math.abs(a.currentFrame - b.currentFrame)));
		}
		// Fin : on amène les deux à la même frame, touches toutes confirmées.
		var target = a.currentFrame > b.currentFrame ? a.currentFrame : b.currentFrame;
		var guard = 0;
		while (guard++ < 5000) {
			t += 25;
			lagA.update(t);
			lagB.update(t);
			for (s in [a, b])
				if (s.currentFrame < target) s.tick(0) else s.poll();
			record(a, histA);
			record(b, histB);
			if (a.currentFrame == target && b.currentFrame == target && a.remoteConfirmedFrame >= target - 1
				&& b.remoteConfirmedFrame >= target - 1)
				break;
		}
		a.poll();
		b.poll();
		record(a, histA);
		record(b, histB);

		var ref = new DemoGame(seed);
		var sameInputs = histA.length == target && histB.length == target;
		for (f in 0...target) {
			if (sameInputs && (histA[f][0] != histB[f][0] || histA[f][1] != histB[f][1]))
				sameInputs = false;
			ref.advance(histA[f]);
		}
		var ok = !desync && sameInputs && gameA.checksum() == gameB.checksum() && gameA.checksum() == ref.checksum();
		var st = a.stats, sb = b.stats;
		var saves = gameA.saves + gameB.saves;
		check(ok, '$name, délai $delay',
			'frames $target, rollbacks ${st.rollbacks}/${sb.rollbacks} (max ${Std.int(Math.max(st.maxRollback, sb.maxRollback))} frames), '
			+ 'attentes ${st.waitingTicks}/${sb.waitingTicks}, ralentis ${st.slowdownTicks}/${sb.slowdownTicks}, '
			+ 'sauvegardes $saves, écart max ${maxGap}, rtt ${Math.round(a.rttMs)} ms, empreintes comparées ${st.checksumsCompared}'
			+ (ok ? "" : ' [desync=$desync entrées=$sameInputs ${gameA.checksum()} ${gameB.checksum()} ${ref.checksum()}]'));
		if (guestFastEvery > 0)
			check(maxGap <= 12, "  le recalage des horloges garde les deux joueurs proches", 'écart max $maxGap frames');
	}

	static function testDesyncDetected() {
		var t = 0.;
		var pipes = DirectTransport.pair();
		var gameA = new DemoGame(5), gameB = new DemoGame(5);
		gameB.corruptAtFrame = 300;
		var a = new RollbackSession(gameA, pipes[0], {localPlayer: 0, now: () -> t});
		var b = new RollbackSession(gameB, pipes[1], {localPlayer: 1, now: () -> t});
		var at = -1;
		a.onDesync = (f, _, _) -> at = f;
		for (i in 0...600) {
			t += 25;
			a.tick(nextInput(0));
			b.tick(nextInput(0));
		}
		check(at > 300 && at <= 320, "désynchro détectée juste après le bug", 'signalée à la frame $at (bug à la frame 300)');
	}

	static function testDisconnectAndRecover() {
		var t = 0.;
		var pipes = DirectTransport.pair();
		var lagA = new LagTransport(pipes[0], 40, 0, 0, 0, 3);
		var lagB = new LagTransport(pipes[1], 40, 0, 0, 0, 4);
		var gameA = new DemoGame(9), gameB = new DemoGame(9);
		var a = new RollbackSession(gameA, lagA, {localPlayer: 0, now: () -> t});
		var b = new RollbackSession(gameB, lagB, {localPlayer: 1, now: () -> t});
		var waited = 0, frameAtCut = 0, maxAhead = 0;
		for (i in 0...1200) {
			t += 25;
			var cut = i >= 400 && i < 480; // 2 s de coupure totale
			lagA.lossRate = lagB.lossRate = cut ? 1 : 0;
			lagA.update(t);
			lagB.update(t);
			if (i == 400)
				frameAtCut = a.remoteConfirmedFrame;
			if (a.tick(nextInput(0)) == WaitingForRemote)
				waited++;
			b.tick(nextInput(0));
			if (cut)
				maxAhead = Std.int(Math.max(maxAhead, a.currentFrame - frameAtCut));
		}
		for (i in 0...100) {
			t += 25;
			lagA.update(t);
			lagB.update(t);
			a.poll();
			b.poll();
		}
		var same = a.currentFrame != b.currentFrame || gameA.checksum() == gameB.checksum();
		check(waited > 50 && maxAhead <= 8 + 4 && !a.desynced && !b.desynced && same, "coupure de 2 s : attente puis reprise synchronisée",
			'$waited ticks d\'attente, ${maxAhead} frames d\'avance max pendant la coupure');
	}

	static function record(s:RollbackSession<Array<Int>>, hist:Array<Array<Int>>) {
		while (hist.length <= s.remoteConfirmedFrame && hist.length < s.currentFrame)
			hist.push(s.inputsAt(hist.length));
	}

	/** Touches aléatoires qui changent environ 1 fois sur 8. **/
	static function nextInput(prev:Int):Int {
		rng ^= rng << 13;
		rng ^= rng >>> 17;
		rng ^= rng << 5;
		if ((rng & 7) != 0)
			return prev;
		return (rng >>> 8) & 31;
	}

	static function check(ok:Bool, label:String, ?detail:String) {
		if (!ok)
			failures++;
		log((ok ? "ok    " : "ÉCHEC ") + label + (detail != null ? "  — " + detail : ""));
	}

	static function log(s:String) {
		#if js
		js.Syntax.code("console.log({0})", s);
		#else
		Sys.println(s);
		#end
	}
}

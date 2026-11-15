import net.rollback.GroupSession;
import net.transport.DirectTransport;
import net.transport.GroupTransport;
import net.transport.LagTransport;
import netdemo.DemoGame;

/**
	Tests du rollback à 3 ou 4 joueurs (étude) :
	haxe tests-groupe.hxml
	Chaque joueur simule toute la partie ; à la fin, toutes les parties doivent être
	identiques entre elles et à une partie rejouée sans réseau.
**/
class GroupTest {
	static var failures = 0;
	static var rng = 42;

	static function main() {
		// latence aller simple (ms) des invités vers l'hôte, et entre invités
		for (n in [2, 3, 4]) {
			testMatch('$n joueurs, maillage, wifi 30 ms', n, false, 30, 30, 5, 0.01, 2, 0);
			testMatch('$n joueurs, maillage, internet 40-80 ms', n, false, 40, 80, 20, 0.05, 2, 0);
		}
		testMatch("4 joueurs, étoile (tout passe par l'hôte), 40 ms vers l'hôte", 4, true, 40, 0, 10, 0.03, 2, 0);
		testMatch("4 joueurs, étoile, 40 ms, délai 3", 4, true, 40, 0, 10, 0.03, 3, 0);
		testMatch("4 joueurs, maillage, très mauvais 150 ms", 4, false, 150, 150, 50, 0.15, 2, 0);
		testMatch("4 joueurs, maillage, clairsemé, internet 40-80 ms", 4, false, 40, 80, 20, 0.05, 2, 4);
		testMatch("4 joueurs, étoile, clairsemé, 40 ms", 4, true, 40, 0, 10, 0.03, 2, 4);
		testDesync();
		log(failures == 0 ? "\nTOUS LES TESTS PASSENT" : '\n$failures ÉCHEC(S)');
		#if js
		js.Syntax.code("process.exit({0})", failures == 0 ? 0 : 1);
		#end
	}

	static function testMatch(name:String, n:Int, star:Bool, latHost:Float, latGuests:Float, jit:Float, loss:Float, delay:Int,
			saveEvery:Int) {
		var t = 0.;
		var clock = () -> t;
		var seed = 1234;
		var lags:Array<LagTransport> = [];
		var groups = [for (p in 0...n) new GroupTransport(star && p == 0)];
		var s = 1;
		for (i in 0...n)
			for (j in i + 1...n) {
				if (star && i != 0)
					continue;
				var lat = i == 0 ? latHost : latGuests;
				var pipes = DirectTransport.pair();
				var a = new LagTransport(pipes[0], lat, jit, loss, loss / 5, s++);
				var b = new LagTransport(pipes[1], lat, jit, loss, loss / 5, s++);
				lags.push(a);
				lags.push(b);
				groups[i].add(a);
				groups[j].add(b);
			}
		var games = [for (p in 0...n) new DemoGame(seed, n)];
		var sessions = [
			for (p in 0...n)
				new GroupSession(games[p], groups[p], {
					players: n,
					localPlayer: p,
					now: clock,
					inputDelay: delay,
					saveEvery: saveEvery
				})
		];
		var desync = false;
		for (x in sessions)
			x.onDesync = (_, _, _, _) -> desync = true;
		var hist = [for (p in 0...n) new Array<Array<Int>>()];
		var keys = [for (p in 0...n) 0];
		var maxGap = 0;
		function update() {
			t += 25;
			for (l in lags)
				l.update(t);
		}
		for (step in 0...2400) {
			update();
			for (p in 0...n) {
				keys[p] = nextInput(keys[p]);
				if (step >= p * 3) // les invités arrivent un peu plus tard
					sessions[p].tick(keys[p]);
				record(sessions[p], hist[p]);
			}
			if (step > 200) {
				var lo = 1 << 30, hi = 0;
				for (x in sessions) {
					if (x.currentFrame < lo) lo = x.currentFrame;
					if (x.currentFrame > hi) hi = x.currentFrame;
				}
				if (hi - lo > maxGap)
					maxGap = hi - lo;
			}
		}
		var target = 0;
		for (x in sessions)
			if (x.currentFrame > target)
				target = x.currentFrame;
		var guard = 0;
		while (guard++ < 5000) {
			update();
			var done = true;
			for (p in 0...n) {
				var x = sessions[p];
				if (x.currentFrame < target) x.tick(0) else x.poll();
				record(x, hist[p]);
				if (x.currentFrame != target || x.confirmedFrame < target - 1)
					done = false;
			}
			if (done)
				break;
		}
		for (p in 0...n) {
			sessions[p].poll();
			record(sessions[p], hist[p]);
		}
		var ref = new DemoGame(seed, n);
		var same = true;
		for (p in 0...n)
			if (hist[p].length != target)
				same = false;
		if (same)
			for (f in 0...target) {
				for (p in 1...n)
					for (q in 0...n)
						if (hist[p][f][q] != hist[0][f][q])
							same = false;
				ref.advance(hist[0][f]);
			}
		var ok = !desync && same;
		for (g in games)
			if (g.checksum() != ref.checksum())
				ok = false;
		var rb = 0, maxRb = 0, waits = 0, resim = 0, saves = 0;
		for (x in sessions) {
			rb += x.stats.rollbacks;
			resim += x.stats.resimulatedFrames;
			waits += x.stats.waitingTicks;
			if (x.stats.maxRollback > maxRb)
				maxRb = x.stats.maxRollback;
		}
		for (g in games)
			saves += g.saves;
		var worst = 0.;
		for (x in sessions)
			if (x.worstRtt() > worst)
				worst = x.worstRtt();
		check(ok, name,
			'frames $target, rollbacks/joueur ${Math.round(rb / n)} (max $maxRb frames, ${Math.round(resim / n)} frames rejouées), '
			+ 'attentes ${waits}, sauvegardes/joueur ${Math.round(saves / n)}, écart max $maxGap, pire ping ${Math.round(worst)} ms'
			+ (ok ? "" : ' [desync=$desync entrées=$same]'));
	}

	/** Le joueur 3 a un bug à la frame 300 : un autre joueur doit le signaler peu après. **/
	static function testDesync() {
		var t = 0.;
		var n = 4;
		var groups = [for (p in 0...n) new GroupTransport()];
		for (i in 0...n)
			for (j in i + 1...n) {
				var pipes = DirectTransport.pair();
				groups[i].add(pipes[0]);
				groups[j].add(pipes[1]);
			}
		var games = [for (p in 0...n) new DemoGame(5, n)];
		games[2].corruptAtFrame = 300;
		var sessions = [for (p in 0...n) new GroupSession(games[p], groups[p], {players: n, localPlayer: p, now: () -> t})];
		var at = -1, who = -1;
		sessions[0].onDesync = (f, p, _, _) -> {
			at = f;
			who = p;
		};
		for (i in 0...600) {
			t += 25;
			for (x in sessions)
				x.tick(nextInput(0));
		}
		check(at > 300 && at <= 320 && who == 2, "4 joueurs : désynchro du joueur 3 détectée", 'frame $at, joueur ${who + 1}');
	}

	static function record(s:GroupSession<Array<Int>>, hist:Array<Array<Int>>) {
		while (hist.length <= s.confirmedFrame && hist.length < s.currentFrame)
			hist.push(s.inputsAt(hist.length));
	}

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

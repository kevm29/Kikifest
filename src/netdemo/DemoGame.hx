package netdemo;

import net.rollback.Checksum;
import net.rollback.RollbackGame;

/**
	Petit jeu déterministe pour tester le rollback : deux personnages qui sautent
	et frappent des balles. Tout est en entiers (virgule fixe, 1 px = 256),
	avec un générateur aléatoire à graine. L'état tient dans un tableau d'entiers.
**/
class DemoGame implements RollbackGame<Array<Int>> {
	public static inline var LEFT = 1;
	public static inline var RIGHT = 2;
	public static inline var JUMP = 4;
	public static inline var DOWN = 8;
	public static inline var ACTION = 16;

	public static inline var WIDTH = 640;
	public static inline var HEIGHT = 360;
	public static inline var PLAYER_SIZE = 24;
	public static inline var BALL_SIZE = 12;
	public static inline var BALLS = 6;

	static inline var FP = 256;
	static inline var GRAVITY = 90;

	// Disposition de l'état
	static inline var FRAME = 0;
	static inline var RNG = 1;
	static inline var PLAYERS = 2;
	static inline var P_STRIDE = 6; // x, y, vx, vy, score, recharge
	static inline var BALLS_AT = PLAYERS + 2 * P_STRIDE;
	static inline var B_STRIDE = 4; // x, y, vx, vy
	static inline var STATE_SIZE = BALLS_AT + BALLS * B_STRIDE;

	public var s:Array<Int>;

	/** Pour les tests : altère l'état à cette frame (simule un bug de désynchro). **/
	public var corruptAtFrame = -1;

	/** Pour les tests : oublie la graine dans save() (bug que SyncTest doit trouver). **/
	public var forgetRngInSave = false;

	public function new(seed:Int) {
		s = [for (i in 0...STATE_SIZE) 0];
		s[RNG] = seed == 0 ? 0x1234567 : seed;
		for (p in 0...2) {
			s[PLAYERS + p * P_STRIDE] = (p == 0 ? 160 : 480) * FP;
			s[PLAYERS + p * P_STRIDE + 1] = (HEIGHT - PLAYER_SIZE) * FP;
		}
		for (b in 0...BALLS) {
			var o = BALLS_AT + b * B_STRIDE;
			s[o] = (40 + random(WIDTH - 80)) * FP;
			s[o + 1] = (20 + random(120)) * FP;
			s[o + 2] = (random(7) - 3) * FP;
			s[o + 3] = 0;
		}
	}

	public var frame(get, never):Int;

	inline function get_frame()
		return s[FRAME];

	public function advance(inputs:Array<Int>):Void {
		var f = s[FRAME];
		for (p in 0...2)
			updatePlayer(p, inputs[p]);
		var wind = 0;
		if (f % 40 == 0)
			wind = random(5) - 2;
		for (b in 0...BALLS)
			updateBall(b, wind);
		if (f == corruptAtFrame)
			s[BALLS_AT] += FP;
		s[FRAME] = f + 1;
	}

	function updatePlayer(p:Int, input:Int) {
		var o = PLAYERS + p * P_STRIDE;
		var floor = (HEIGHT - PLAYER_SIZE) * FP;
		var vx = 0;
		if (input & LEFT != 0)
			vx -= 4 * FP;
		if (input & RIGHT != 0)
			vx += 4 * FP;
		s[o + 2] = vx;
		var onGround = s[o + 1] >= floor;
		if (onGround && input & JUMP != 0)
			s[o + 3] = -14 * FP;
		s[o + 3] += GRAVITY * 2;
		if (input & DOWN != 0)
			s[o + 3] += GRAVITY * 2;
		s[o] = clamp(s[o] + s[o + 2], 0, (WIDTH - PLAYER_SIZE) * FP);
		s[o + 1] += s[o + 3];
		if (s[o + 1] >= floor) {
			s[o + 1] = floor;
			s[o + 3] = 0;
		}
		if (s[o + 5] > 0)
			s[o + 5]--;
		if (input & ACTION != 0 && s[o + 5] == 0) {
			s[o + 5] = 10;
			var cx = s[o] + (PLAYER_SIZE * FP >> 1), cy = s[o + 1] + (PLAYER_SIZE * FP >> 1);
			for (b in 0...BALLS) {
				var q = BALLS_AT + b * B_STRIDE;
				var dx = (s[q] + (BALL_SIZE * FP >> 1) - cx) >> 8, dy = (s[q + 1] + (BALL_SIZE * FP >> 1) - cy) >> 8;
				if (dx * dx + dy * dy < 48 * 48) {
					s[q + 2] = (dx >= 0 ? 1 : -1) * (3 + random(6)) * FP;
					s[q + 3] = -(8 + random(8)) * FP;
					s[o + 4]++;
				}
			}
		}
	}

	function updateBall(b:Int, wind:Int) {
		var q = BALLS_AT + b * B_STRIDE;
		s[q + 2] += wind * 16;
		s[q + 3] += GRAVITY;
		s[q] += s[q + 2];
		s[q + 1] += s[q + 3];
		var maxX = (WIDTH - BALL_SIZE) * FP, maxY = (HEIGHT - BALL_SIZE) * FP;
		if (s[q] < 0) {
			s[q] = -s[q];
			s[q + 2] = -s[q + 2];
		} else if (s[q] > maxX) {
			s[q] = 2 * maxX - s[q];
			s[q + 2] = -s[q + 2];
		}
		if (s[q + 1] > maxY) {
			s[q + 1] = maxY;
			s[q + 3] = -(s[q + 3] * 7 >> 3); // rebond qui amortit
			s[q + 2] = s[q + 2] * 15 >> 4; // frottement
		}
	}

	public function save():Array<Int> {
		var c = s.copy();
		if (forgetRngInSave)
			c[RNG] = 0;
		return c;
	}

	public function load(state:Array<Int>):Void {
		var rng = s[RNG];
		s = state.copy();
		if (forgetRngInSave)
			s[RNG] = rng;
	}

	public function checksum():Int
		return Checksum.ofInts(s);

	public function playerX(p:Int):Int
		return Std.int(s[PLAYERS + p * P_STRIDE] / FP);

	public function playerY(p:Int):Int
		return Std.int(s[PLAYERS + p * P_STRIDE + 1] / FP);

	public function score(p:Int):Int
		return s[PLAYERS + p * P_STRIDE + 4];

	public function ballX(b:Int):Int
		return Std.int(s[BALLS_AT + b * B_STRIDE] / FP);

	public function ballY(b:Int):Int
		return Std.int(s[BALLS_AT + b * B_STRIDE + 1] / FP);

	/** Entier dans [0, n[, xorshift32. **/
	function random(n:Int):Int {
		var x = s[RNG];
		x ^= x << 13;
		x ^= x >>> 17;
		x ^= x << 5;
		s[RNG] = x;
		return (x & 0x7fffffff) % n;
	}

	static inline function clamp(v:Int, lo:Int, hi:Int):Int
		return v < lo ? lo : (v > hi ? hi : v);
}

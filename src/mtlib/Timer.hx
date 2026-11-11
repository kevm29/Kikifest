package mtlib;

/**
	Pas de temps fixe : la simulation avance toujours à 40 images/s, et tmod
	vaut 32/40 (le jeu était réglé pour 32 i/s avec un facteur de correction).
**/
class Timer {
	public static inline var SIM_FPS = 40;
	public static var wantedFPS:Float = 32;
	public static var tmod:Float = 32 / 40;
	public static var deltaT:Float = 1 / 40;
	public static var frameCount:Int = 0;

	public static function update() {
		frameCount++;
		tmod = wantedFPS / SIM_FPS;
		deltaT = 1 / SIM_FPS;
	}

	public static function fps():Float return wantedFPS / tmod;
}

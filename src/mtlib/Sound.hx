package mtlib;

/** Objet Sound de Flash, branché sur SoundBank (Web Audio). */
class Sound {
	var target:Dynamic;
	var linkage:String;
	var volume:Float = 100;
	var pan:Float = 0;
	var playing:Dynamic = null;
	var wanted:Bool = false;

	/** Musique du jeu n° slot (0 thème, 1 boss, 2 « vite ») : le morceau joué est choisi par meta.Jukebox. **/
	public var jukeboxSlot:Int = -1;

	/** Démarrée et pas arrêtée (même si la musique est coupée), avec ses paramètres de départ. **/
	var active:Bool = false;
	var lastLoops:Null<Int> = null;

	/** Position de lecture en ms (non suivie : la musique reprend du début). */
	public var position:Float = 0;

	public var onSoundComplete:Void->Void;
	public var onLoad:Bool->Void;

	public function new(?target:Dynamic) {
		this.target = target;
	}

	public function attachSound(id:String) linkage = id;

	public function loadSound(url:String, stream:Bool) {
		linkage = url;
		if (onLoad != null) onLoad(true);
	}

	public function start(?offset:Float, ?loops:Int) {
		stop();
		active = true;
		lastLoops = loops;
		var n = loops == null ? 1 : loops;
		var file = linkage, rate = 1.0;
		if (jukeboxSlot >= 0) {
			var r = meta.Jukebox.resolve(jukeboxSlot, linkage);
			if (r == null) return; // musique coupée : elle reprendra si on la remet
			file = r.linkage;
			rate = r.rate;
		}
		playing = SoundBank.play(file, volume / 100, n, () -> if (onSoundComplete != null) onSoundComplete(), rate);
		if (playing == null && n > 1 && !SoundBank.muted) {
			// musique pas encore chargée : elle démarrera dès qu'elle le sera
			wanted = true;
			SoundBank.whenReady(file, () -> if (wanted && playing == null) start(offset, loops));
		}
	}

	/** Relance le son s'il était en cours (le choix de musique a changé). **/
	public function restart() {
		if (active) start(0, lastLoops);
	}

	public function stop(?id:String) {
		wanted = false;
		active = false;
		if (playing != null) SoundBank.stop(playing);
		playing = null;
	}

	public function setVolume(v:Float) {
		volume = v;
		if (playing != null) SoundBank.setVolume(playing, v / 100);
	}

	public function getVolume():Float return volume;

	public function setPan(p:Float) pan = p;

	public function getPan():Float return pan;

	public function getBytesLoaded():Int return 1;

	public function getBytesTotal():Int return 1;
}

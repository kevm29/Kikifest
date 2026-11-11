package mtlib;

/** Objet Sound de Flash, branché sur SoundBank (Web Audio). */
class Sound {
	var target:Dynamic;
	var linkage:String;
	var volume:Float = 100;
	var pan:Float = 0;
	var playing:Dynamic = null;
	var wanted:Bool = false;

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
		var n = loops == null ? 1 : loops;
		playing = SoundBank.play(linkage, volume / 100, n, () -> if (onSoundComplete != null) onSoundComplete());
		if (playing == null && n > 1 && !SoundBank.muted) {
			// musique pas encore chargée : elle démarrera dès qu'elle le sera
			wanted = true;
			SoundBank.whenReady(linkage, () -> if (wanted && playing == null) start(offset, loops));
		}
	}

	public function stop(?id:String) {
		wanted = false;
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

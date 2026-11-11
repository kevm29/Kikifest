package mtlib;

import swf.MovieClip;

/**
	Gestionnaire de sons par canaux (même API que le SoundManager de MotionTypes),
	sur Web Audio. Les sons sont coupés pendant les re-simulations du rollback.
**/
class SoundManager {
	var volumes:Map<Int, Float> = new Map();
	var enabled:Map<Int, Bool> = new Map();
	var loops:Map<String, Sound> = new Map();

	public function new(mc:MovieClip, baseDepth:Int) {}

	public function destroy() {
		for (s in loops) s.stop();
		loops = new Map();
	}

	function vol(chan:Int):Float return volumes.exists(chan) ? volumes.get(chan) : 100;

	function isEnabled(chan:Int):Bool return enabled.get(chan) != false;

	public function playSound(name:String, chan:Int) {
		if (!isEnabled(chan) || SoundBank.muted) return;
		var s = new Sound();
		s.attachSound(name);
		s.setVolume(vol(chan));
		s.start(0, 1);
	}

	public function play(name:String) playSound(name, 0);

	public function loop(name:String, chan:Int) {
		var k = chan + ":" + name;
		if (loops.exists(k)) return;
		var s = new Sound();
		s.attachSound(name);
		s.setVolume(vol(chan));
		s.start(0, 99999);
		loops.set(k, s);
	}

	public function stopSound(name:String, chan:Int) {
		var k = chan + ":" + name;
		var s = loops.get(k);
		if (s != null) s.stop();
		loops.remove(k);
	}

	public function fade(from:Int, to:Int, length:Int) {}

	public function main() {}

	public function enable(chan:Int, flag:Bool) enabled.set(chan, flag);

	public function stop(chan:Int) {
		for (k in [for (k in loops.keys()) k])
			if (StringTools.startsWith(k, chan + ":")) {
				loops.get(k).stop();
				loops.remove(k);
			}
	}

	public function isPlaying(name:String, chan:Int):Bool return loops.exists(chan + ":" + name);

	public function setVolume(chan:Int, volume:Float) {
		volumes.set(chan, volume);
		for (k => s in loops)
			if (StringTools.startsWith(k, chan + ":")) s.setVolume(volume);
	}
}

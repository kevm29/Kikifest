package mtlib;

import js.html.audio.AudioContext;
import js.html.audio.AudioBuffer;

/** Sons du jeu en Web Audio. Muet pendant les re-simulations du rollback. */
class SoundBank {
	public static var muted:Bool = false;

	/** Volumes réglés dans les paramètres (0 à 1) : musique d'un côté, bruitages de l'autre. */
	public static var musicVolume(default, set):Float = 1;
	public static var sfxVolume(default, set):Float = 1;

	static var musicBus:js.html.audio.GainNode;
	static var sfxBus:js.html.audio.GainNode;

	static function set_musicVolume(v:Float) {
		musicVolume = v;
		if (musicBus != null) musicBus.gain.value = v;
		return v;
	}

	static function set_sfxVolume(v:Float) {
		sfxVolume = v;
		if (sfxBus != null) sfxBus.gain.value = v;
		return v;
	}

	/** Les musiques sont des fichiers (music.mp3...), les bruitages des sons du SWF. */
	static function bus(c:AudioContext, linkage:String):js.html.audio.GainNode {
		if (musicBus == null) {
			musicBus = c.createGain();
			musicBus.gain.value = musicVolume;
			musicBus.connect(c.destination);
			sfxBus = c.createGain();
			sfxBus.gain.value = sfxVolume;
			sfxBus.connect(c.destination);
		}
		return linkage.indexOf(".mp3") > 0 ? musicBus : sfxBus;
	}
	public static var base:String = "assets/sfx/";

	static var ctx:AudioContext;
	static var buffers:Map<String, AudioBuffer> = new Map();
	static var loading:Map<String, Bool> = new Map();
	static var waiting:Map<String, Array<Void->Void>> = new Map();

	/** Appelle f quand le son est chargé (tout de suite s'il l'est déjà). */
	public static function whenReady(linkage:String, f:Void->Void) {
		if (buffers.exists(linkage)) {
			f();
			return;
		}
		if (!waiting.exists(linkage)) waiting.set(linkage, []);
		waiting.get(linkage).push(f);
		preload(linkage);
	}

	static function context():AudioContext {
		if (ctx == null) {
			try ctx = new AudioContext() catch (e:Dynamic) {}
		}
		return ctx;
	}

	/** Le navigateur n'autorise le son qu'après une action du joueur (touche pressée). */
	public static function unlock() {
		var c = context();
		if (c != null && c.state == SUSPENDED) c.resume();
	}

	static function url(linkage:String):String {
		if (linkage.indexOf(".") > 0) return base + linkage;
		var lib = swf.Library.inst;
		var id = lib.exportId(linkage);
		if (id == null) return null;
		var c:Dynamic = lib.char(id);
		return c != null && c.file != null ? base + c.file : null;
	}

	public static function preload(linkage:String) {
		var c = context();
		if (c == null || buffers.exists(linkage) || loading.exists(linkage)) return;
		var u = url(linkage);
		if (u == null) return;
		loading.set(linkage, true);
		js.Browser.window.fetch(u).then(r -> r.arrayBuffer()).then(b -> c.decodeAudioData(b)).then(buf -> {
			buffers.set(linkage, buf);
			var w = waiting.get(linkage);
			if (w != null) {
				waiting.remove(linkage);
				for (f in w) f();
			}
			return null;
		});
	}

	public static function play(linkage:String, volume:Float, loops:Int, onEnd:Void->Void):Dynamic {
		// pendant un rollback, seuls les bruitages sont coupés : une musique qui démarre doit démarrer
		if ((muted && loops <= 1) || linkage == null) return null;
		var c = context();
		if (c == null) return null;
		var b = buffers.get(linkage);
		if (b == null) {
			preload(linkage);
			return null;
		}
		var src = c.createBufferSource();
		src.buffer = b;
		src.loop = loops > 1;
		var g = c.createGain();
		g.gain.value = safe(volume);
		src.connect(g);
		g.connect(bus(c, linkage));
		src.onended = () -> onEnd();
		src.start();
		return {src: src, gain: g};
	}

	/** Flash ignorait un volume invalide (undefined/NaN) : on garde le volume plein. */
	static inline function safe(v:Float):Float
		return (v == null || Math.isNaN(v) || !Math.isFinite(v)) ? 1.0 : Math.max(0, v);

	public static function stop(h:Dynamic) {
		try h.src.stop() catch (e:Dynamic) {}
	}

	public static function setVolume(h:Dynamic, v:Float) {
		h.gain.gain.value = safe(v);
	}
}

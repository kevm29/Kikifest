package net;

/**
	Photo complète de l'état du jeu, pour le rollback.

	Le code du jeu (converti depuis MotionTypes) garde son état un peu partout : entités, clips,
	tableaux, variables statiques des classes. Plutôt que d'écrire save/load à la main pour des
	centaines de classes, on parcourt tout le graphe d'objets JavaScript accessible depuis les
	racines (gestionnaire, clip racine, statiques de toutes les classes) et on garde une copie
	superficielle de chaque objet. Restaurer réécrit ces copies dans les mêmes objets : les
	références restent valables, et les objets créés après la photo deviennent inaccessibles.

	Ce qui n'est pas de l'état de jeu est laissé tel quel (ressources du SWF, DOM, sons, caches
	de rendu) : voir `skip`.
**/
class Snapshot {
	/** objets[i] et copies[i] : un objet et le contenu qu'il avait au moment de la photo **/
	public var objects:Array<Dynamic>;

	public var copies:Array<Dynamic>;

	function new(o, c) {
		objects = o;
		copies = c;
	}

	static var roots:Array<Dynamic> = null;
	static var skipObjects:Dynamic = null;

	/** Champs jamais parcourus (gardés par référence) : définitions du SWF, mandataires des scripts de frame, sons en cours. **/
	static var SKIP_FIELDS = ["__def", "__scope", "playing", "__cache", "__img", "__canvas", "__ctx"];

	/** Classes dont les statiques ne sont pas de l'état de jeu. **/
	static var SKIP_CLASSES = [
		"swf.Library", "swf.Renderer", "swf.FrameScripts", "mtlib.SoundBank", "net.Snapshot", "Boot", "net.rollback.RollbackSession", "Lang", "Data", "meta.Quests", "meta.Settings"
	];

	/** Racines : objets donnés + statiques de toutes les classes Haxe. **/
	public static function init(extra:Array<Dynamic>) {
		Type.resolveClass("Boot"); // force la génération de $hxClasses
		var classes:Dynamic = js.Syntax.code("$hxClasses");
		roots = extra.copy();
		for (name in Reflect.fields(classes)) {
			if (SKIP_CLASSES.indexOf(name) >= 0 || StringTools.startsWith(name, "js."))
				continue;
			roots.push(Reflect.field(classes, name));
		}
		skipObjects = js.Syntax.code("new Set()");
		if (swf.Library.inst != null)
			skipObjects.add(swf.Library.inst);
	}

	public static function skip(o:Dynamic) {
		if (skipObjects == null)
			skipObjects = js.Syntax.code("new Set()");
		skipObjects.add(o);
	}

	static var opaque:Dynamic = null;

	/** Types gardés par référence sans être parcourus. **/
	static function opaqueTypes():Dynamic {
		if (opaque == null) {
			opaque = js.Syntax.code("new Set()");
			for (n in ["CanvasRenderingContext2D", "ImageBitmap", "AudioBuffer", "AudioContext", "GainNode", "AudioBufferSourceNode", "Promise", "ArrayBuffer", "RegExp", "Image", "HTMLCanvasElement", "HTMLImageElement", "OffscreenCanvas", "Path2D", "CanvasPattern", "CanvasGradient", "DOMMatrix"]) {
				var c = Reflect.field(js.Lib.global, n);
				if (c != null)
					opaque.add(c);
			}
			opaque.add(Xml);
			opaque.add(mtlib.Sound);
		}
		return opaque;
	}

	public static function save():Snapshot {
		var objects:Array<Dynamic> = [];
		var copies:Array<Dynamic> = [];
		js.Syntax.code("{
		const seen = new Set();
		const skip = {0}, skipFields = {1}, OBJ = {2}, CPY = {3};
		const stack = [];
		const opaque = {5};
		const isOpaque = (v) => opaque.has(v.constructor) || (typeof Node !== 'undefined' && v instanceof Node)
			|| ArrayBuffer.isView(v) || v === globalThis;
		for (const r of {4}) stack.push(r);
		while (stack.length > 0) {
			const o = stack.pop();
			if (seen.has(o) || skip.has(o)) continue;
			seen.add(o);
			if (Array.isArray(o)) {
				const c = o.slice();
				OBJ.push(o); CPY.push(c);
				for (let i = 0; i < c.length; i++) {
					const v = c[i];
					if (v !== null && (typeof v === 'object') && !seen.has(v)) stack.push(v);
				}
				continue;
			}
			if (typeof o === 'function') {
				// classe : seules ses statiques nous intéressent
				const c = {};
				for (const k of Object.keys(o)) {
					const v = o[k];
					if (typeof v === 'function') continue;
					c[k] = v;
					if (v !== null && typeof v === 'object' && !seen.has(v)) stack.push(v);
				}
				OBJ.push(o); CPY.push(c);
				continue;
			}
			if (o instanceof Map) {
				const c = new Map(o);
				OBJ.push(o); CPY.push(c);
				for (const [k, v] of c) {
					if (k !== null && typeof k === 'object' && !seen.has(k)) stack.push(k);
					if (v !== null && typeof v === 'object' && !seen.has(v)) stack.push(v);
				}
				continue;
			}
			if (o instanceof Set) {
				const c = new Set(o);
				OBJ.push(o); CPY.push(c);
				for (const v of c) if (v !== null && typeof v === 'object' && !seen.has(v)) stack.push(v);
				continue;
			}
			if (isOpaque(o)) continue;
			// clip retiré de l'affichage : mort pour de bon, inutile de le photographier
			if (o._name === null && o._parent === null && o.__children !== undefined) continue;
			const c = Object.assign(Object.create(null), o);
			OBJ.push(o); CPY.push(c);
			for (const k in c) {
				const v = c[k];
				if (v === null || typeof v !== 'object' || seen.has(v)) continue;
				if (skipFields.indexOf(k) >= 0) continue;
				stack.push(v);
			}
		}
		}", skipObjects, SKIP_FIELDS, objects, copies, roots, opaqueTypes());
		return new Snapshot(objects, copies);
	}

	public function restore() {
		js.Syntax.code("{
		const OBJ = {0}, CPY = {1};
		for (let i = 0; i < OBJ.length; i++) {
			const o = OBJ[i], c = CPY[i];
			if (Array.isArray(o)) {
				// les tableaux à trous (fréquents en ActionScript) doivent garder leurs trous
				o.length = c.length;
				for (let j = 0; j < c.length; j++) {
					if (j in c) { if (o[j] !== c[j] || !(j in o)) o[j] = c[j]; }
					else if (j in o) delete o[j];
				}
			} else if (o instanceof Map) {
				o.clear();
				for (const [k, v] of c) o.set(k, v);
			} else if (o instanceof Set) {
				o.clear();
				for (const v of c) o.add(v);
			} else if (typeof o === 'function') {
				for (const k in c) o[k] = c[k];
			} else {
				// mêmes clés dans le même ordre : simple réécriture ; sinon on reconstruit l'objet
				// pour retrouver l'ordre d'origine (l'ordre d'itération doit rester identique chez les deux joueurs)
				const ko = Object.keys(o), kc = Object.keys(c);
				let same = ko.length === kc.length;
				if (same) for (let j = 0; j < ko.length; j++) if (ko[j] !== kc[j]) { same = false; break; }
				if (same) { for (const k of kc) { const v = c[k]; if (o[k] !== v) o[k] = v; } }
				else { for (const k of ko) delete o[k]; for (const k of kc) o[k] = c[k]; }
			}
		}
		}", objects, copies);
	}
}

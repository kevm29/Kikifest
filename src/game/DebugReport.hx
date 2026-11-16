package;

import js.Browser;

/**
	Rapport de débogage, à demander en pleine partie :
	- F9 (ou le bouton « Rapport de débogage ») télécharge un fichier kikifest-debug-….json
	  à renvoyer tel quel pour qu'on puisse comprendre un ralentissement ;
	- F3 affiche/masque un petit panneau avec les mesures en direct.

	Pour chaque image affichée on garde : durée depuis l'image précédente, nombre de pas de simulation,
	temps de simulation, photos et retours en arrière du rollback (nombre et durée), frames rejouées,
	temps de dessin, images recolorées créées et calques utilisés par le rendu. Les images lentes sont
	gardées à part avec le contexte du jeu (niveau, nombre d'entités, de bombes…).

	Rien de tout ça ne fait partie de l'état du jeu : la classe est exclue des photos du rollback
	(voir net.Snapshot.SKIP_CLASSES).
**/
class DebugReport {
	/** Images gardées en mémoire (environ 60 s à 60 images/s). **/
	static inline var N = 3600;

	/** Une image est « lente » au-delà de ce délai depuis la précédente (ms). **/
	static inline var SLOW_MS = 45.0;

	static var t0 = 0.0;
	static var count = 0;
	static var tAt = new js.lib.Float64Array(N);
	static var dtAt = new js.lib.Float32Array(N);
	static var stepsAt = new js.lib.Uint8Array(N);
	static var simAt = new js.lib.Float32Array(N);
	static var savesAt = new js.lib.Uint8Array(N);
	static var saveMsAt = new js.lib.Float32Array(N);
	static var loadsAt = new js.lib.Uint8Array(N);
	static var loadMsAt = new js.lib.Float32Array(N);
	static var resimAt = new js.lib.Uint16Array(N);
	static var drawAt = new js.lib.Float32Array(N);
	static var tintsAt = new js.lib.Uint16Array(N);
	static var layersAt = new js.lib.Uint16Array(N);

	// image en cours
	static var curT = 0.0;
	static var curDt = 0.0;
	static var curSteps = 0;
	static var curSim = 0.0;
	static var curSaves = 0;
	static var curSaveMs = 0.0;
	static var curLoads = 0;
	static var curLoadMs = 0.0;
	static var curResim = 0;
	static var curDraw = 0.0;

	static var tintsCreated = 0;
	static var layersUsed = 0;

	static var lastResim = 0;
	static var lastT = -1.0;
	static var slow:Array<Dynamic> = [];
	static var events:Array<Dynamic> = [];
	static var lastLevel:String = null;
	static var hiddenCount = 0;
	static var errors:Array<String> = [];
	static var overlay:js.html.Element = null;
	static var lastOverlay = 0.0;
	static var iceInfo:Dynamic = null;
	static var lockSince = -1.0;

	public static function init() {
		t0 = now();
		Browser.document.addEventListener("visibilitychange", (_) -> {
			if (Browser.document.hidden) hiddenCount++;
			event(Browser.document.hidden ? "onglet caché" : "onglet visible");
		});
		Browser.window.addEventListener("error", (e:Dynamic) -> error("JS : " + e.message + " @ " + e.filename + ":" + e.lineno));
		Browser.window.addEventListener("unhandledrejection", (e:Dynamic) -> error("promesse : " + Std.string(e.reason)));
		var cv = Browser.document.getElementById("game");
		if (cv != null) {
			cv.addEventListener("contextlost", (_) -> error("canevas perdu par le navigateur (contextlost)"));
			cv.addEventListener("contextrestored", (_) -> event("canevas rendu (contextrestored)"));
		}
		addButton();
	}

	static inline function now():Float
		return Browser.window.performance.now();

	static function round(v:Float, d = 1):Float {
		var m = Math.pow(10, d);
		return Math.round(v * m) / m;
	}

	// ------------------------------------------------------------ mesures

	/** Début d'une image (appelé par la boucle requestAnimationFrame). **/
	public static function frameStart(t:Float) {
		curT = t;
		curDt = lastT < 0 ? 0 : t - lastT;
		lastT = t;
		curSteps = 0;
		curSim = 0;
		curSaves = 0;
		curSaveMs = 0;
		curLoads = 0;
		curLoadMs = 0;
		curResim = 0;
		curDraw = 0;
		swf.Renderer.statTints = 0;
		swf.Renderer.statLayers = 0;
		swf.Renderer.statLayerPx = 0;
	}

	public static function addStep(ms:Float) {
		curSteps++;
		curSim += ms;
	}

	public static function addSave(ms:Float) {
		curSaves++;
		curSaveMs += ms;
	}

	public static function addLoad(ms:Float) {
		curLoads++;
		curLoadMs += ms;
	}

	public static function addDraw(ms:Float)
		curDraw += ms;

	/** Fin d'une image : enregistrement, et contexte du jeu si elle a été lente. **/
	public static function frameEnd(session:Dynamic, manager:Dynamic) {
		tintsCreated = swf.Renderer.statTints;
		layersUsed = swf.Renderer.statLayers;
		if (session != null && session.stats != null) {
			var r:Int = session.stats.resimulatedFrames;
			curResim = r - lastResim;
			if (curResim < 0)
				curResim = 0;
			lastResim = r;
		}
		var i = count % N;
		tAt[i] = curT;
		dtAt[i] = curDt;
		stepsAt[i] = curSteps > 255 ? 255 : curSteps;
		simAt[i] = curSim;
		savesAt[i] = curSaves > 255 ? 255 : curSaves;
		saveMsAt[i] = curSaveMs;
		loadsAt[i] = curLoads > 255 ? 255 : curLoads;
		loadMsAt[i] = curLoadMs;
		resimAt[i] = curResim;
		drawAt[i] = curDraw;
		tintsAt[i] = tintsCreated;
		layersAt[i] = layersUsed;
		count++;

		try {
			var g:Dynamic = manager != null ? manager.current : null;
			var locked = g != null && g.fl_lock == true;
			if (locked && lockSince < 0) {
				lockSince = curT;
			} else if (!locked && lockSince >= 0) {
				if (curT - lockSince > 4000)
					event("transition terminée après " + round((curT - lockSince) / 1000) + " s");
				lockSince = -1;
			}
		} catch (e:Dynamic) {}
		var lvl = levelName(manager);
		if (lvl != lastLevel) {
			if (lastLevel != null || lvl != null)
				event("niveau " + lvl);
			lastLevel = lvl;
		}
		if (curDt > SLOW_MS && count > 1 && !Browser.document.hidden) {
			slow.push({
				t: round((curT - t0) / 1000, 2),
				ecartMs: round(curDt),
				pas: curSteps,
				simMs: round(curSim),
				photos: curSaves,
				photosMs: round(curSaveMs),
				retours: curLoads,
				retoursMs: round(curLoadMs),
				rejouees: curResim,
				dessinMs: round(curDraw),
				teintes: tintsCreated,
				calques: layersUsed,
				calquesKpx: Math.round(swf.Renderer.statLayerPx / 1000),
				jeu: gameContext(manager),
			});
			if (slow.length > 150)
				slow.shift();
		}
		if (overlay != null && curT - lastOverlay > 250) {
			lastOverlay = curT;
			updateOverlay(session);
		}
	}

	/** Évènement daté (changement de niveau, désynchronisation, erreur, message…). **/
	public static function event(msg:String) {
		events.push({t: round((now() - t0) / 1000, 2), msg: msg});
		if (events.length > 300)
			events.shift();
	}

	public static function error(msg:String) {
		errors.push(msg);
		if (errors.length > 30)
			errors.shift();
		event("erreur : " + msg);
	}

	static function levelName(manager:Dynamic):String {
		try {
			var g:Dynamic = manager != null ? manager.current : null;
			if (g == null)
				return null;
			var w:Dynamic = g.world;
			if (w == null || w.currentId == null)
				return Type.getClassName(Type.getClass(g));
			return (g.currentDim != null && g.currentDim != 0 ? "dim " + g.currentDim + " / " : "") + w.currentId;
		} catch (e:Dynamic) {
			return null;
		}
	}

	static function gameContext(manager:Dynamic):Dynamic {
		try {
			var g:Dynamic = manager != null ? manager.current : null;
			if (g == null)
				return null;
			var ent = 0;
			var lists:Array<Array<Dynamic>> = g.lists;
			if (lists != null && lists.length > 0 && lists[0] != null)
				ent = lists[0].length;
			inline function n(type:Int):Int {
				var l:Array<Dynamic> = g.getList != null ? g.getList(type) : null;
				return l != null ? l.length : 0;
			}
			return {
				niveau: levelName(manager),
				entites: ent,
				bombes: n(Data.BOMB),
				ennemis: n(Data.BAD),
				effets: n(Data.FX),
				tremblement: g.shakeTimer != null && g.shakeTimer > 0,
				transition: g.fl_lock == true,
				transitionDepuisS: lockSince >= 0 ? round((lastT - lockSince) / 1000) : 0,
			};
		} catch (e:Dynamic) {
			return null;
		}
	}

	/** État du décor et des transitions (pour comprendre un écran noir). **/
	static function viewState(manager:Dynamic):Dynamic {
		try {
			var g:Dynamic = manager != null ? manager.current : null;
			var w:Dynamic = g != null ? g.world : null;
			if (w == null)
				return null;
			var v:Dynamic = w.view;
			inline function cv(b:Dynamic):String
				return b == null ? null : (b.canvas != null ? b.canvas.width + "x" + b.canvas.height : "?");
			var mc:Dynamic = g.mc;
			return {
				defilement: w.fl_scrolling,
				defilementHorizontal: w.fl_hscrolling,
				fondu: w.fl_fading,
				restauration: w.fl_restoring,
				scrollCpt: w.scrollCpt,
				fauxDecor: w.fake != null && w.fake._name != null,
				vueAttachee: v != null ? v.fl_attach : null,
				vueXY: v != null && v._back != null ? [v._back._x, v._back._y] : null,
				caches: v != null ? [cv(v.viewCache), cv(v.topCache), cv(v.tileCache)] : null,
				jeuXY: mc != null ? [mc._x, mc._y, mc._visible, mc._alpha] : null,
				dimension: g.currentDim,
				obscurite: w.darknessFactor,
				pause: g.fl_pause,
				finDePartie: g.fl_gameOver,
			};
		} catch (e:Dynamic) {
			return {erreur: Std.string(e)};
		}
	}

	/** Miniature de l'écran au moment du rapport (JPEG en base64, à coller dans un navigateur). **/
	static function thumbnail(renderer:swf.Renderer):String {
		try {
			var c = renderer.canvas;
			var t:js.html.CanvasElement = cast Browser.document.createElement("canvas");
			t.width = 240;
			t.height = Std.int(240 * c.height / Math.max(1, c.width));
			t.getContext2d().drawImage(c, 0, 0, t.width, t.height);
			return t.toDataURL("image/jpeg", 0.7);
		} catch (e:Dynamic) {
			return null;
		}
	}

	// ------------------------------------------------------------ synthèse

	static function percentile(a:Array<Float>, p:Float):Float {
		if (a.length == 0)
			return 0;
		var s = a.copy();
		s.sort((x, y) -> x < y ? -1 : (x > y ? 1 : 0));
		return s[Std.int(Math.min(s.length - 1, Math.floor(p * s.length)))];
	}

	/** Statistiques sur les `secs` dernières secondes. **/
	static function summary(secs:Float):Dynamic {
		var n = count < N ? count : N;
		var tEnd = lastT;
		var dts:Array<Float> = [], sims:Array<Float> = [], draws:Array<Float> = [];
		var steps = 0, saves = 0, loads = 0, resim = 0, tints = 0, saveMs = 0.0, loadMs = 0.0, maxSave = 0.0, maxLoad = 0.0, slowN = 0, frames = 0;
		var span = 0.0;
		for (k in 0...n) {
			var i = (count - 1 - k) % N;
			if (tEnd - tAt[i] > secs * 1000)
				break;
			frames++;
			span = tEnd - tAt[i];
			if (dtAt[i] > 0)
				dts.push(dtAt[i]);
			sims.push(simAt[i]);
			draws.push(drawAt[i]);
			steps += stepsAt[i];
			saves += savesAt[i];
			loads += loadsAt[i];
			resim += resimAt[i];
			tints += tintsAt[i];
			saveMs += saveMsAt[i];
			loadMs += loadMsAt[i];
			if (savesAt[i] > 0 && saveMsAt[i] / savesAt[i] > maxSave)
				maxSave = saveMsAt[i] / savesAt[i];
			if (loadsAt[i] > 0 && loadMsAt[i] / loadsAt[i] > maxLoad)
				maxLoad = loadMsAt[i] / loadsAt[i];
			if (dtAt[i] > SLOW_MS)
				slowN++;
		}
		var sec = span / 1000;
		if (sec <= 0)
			sec = 1;
		var sum = (a:Array<Float>) -> {
			var s = 0.0;
			for (x in a)
				s += x;
			s;
		};
		return {
			secondes: round(sec),
			imagesParSeconde: round(frames / sec),
			pasDeJeuParSeconde: round(steps / sec),
			ecartEntreImagesMs: {median: round(percentile(dts, 0.5)), p95: round(percentile(dts, 0.95)), p99: round(percentile(dts, 0.99)), max: round(percentile(dts, 1))},
			imagesLentes: slowN,
			simulationMs: {moyenne: round(sum(sims) / Math.max(1, sims.length), 2), p99: round(percentile(sims, 0.99)), max: round(percentile(sims, 1))},
			dessinMs: {moyenne: round(sum(draws) / Math.max(1, draws.length), 2), p99: round(percentile(draws, 0.99)), max: round(percentile(draws, 1))},
			photosRollback: {nombre: saves, msMoyen: round(saveMs / Math.max(1, saves), 2), msMax: round(maxSave)},
			retoursEnArriere: {nombre: loads, msMoyen: round(loadMs / Math.max(1, loads), 2), msMax: round(maxLoad)},
			framesRejouees: resim,
			imagesRecoloreesCreees: tints,
		};
	}

	static function connection(session:Dynamic, netCfg:Dynamic):Dynamic {
		if (netCfg == null)
			return {mode: "local (pas de réseau)"};
		var peer:Dynamic = netCfg.peer;
		var links:Array<Dynamic> = netCfg.peers != null ? netCfg.peers : [peer];
		var o:Dynamic = {
			adressePage: Browser.location.protocol + "//" + Browser.location.host,
			parTunnelCloudflare: Browser.location.host.indexOf("trycloudflare.com") >= 0,
			role: peer != null ? peer.role : null,
			joueurs: netCfg.players != null ? netCfg.players : 2,
			joueurLocal: netCfg.index,
			liaisons: [for (l in links) {transport: l.transport, pingReseauMs: round(l.rtt)}],
			ice: iceInfo,
		};
		if (session != null) {
			o.session = {
				pingRollbackMs: round(session.rttMs),
				delaiTouches: session.inputDelay,
				frame: session.currentFrame,
				frameConfirmee: session.remoteConfirmedFrame,
				avanceFrames: round(session.frameAdvantage, 2),
				desynchro: session.desynced,
				silenceMs: Math.round(session.silenceMs()),
				stats: session.stats,
			};
		}
		return o;
	}

	/** Type de liaison WebRTC réellement utilisée (host = réseau local, srflx = direct par internet, relay = serveur relais). **/
	public static function probeIce(netCfg:Dynamic):js.lib.Promise<Dynamic> {
		if (netCfg == null)
			return js.lib.Promise.resolve(null);
		var links:Array<Dynamic> = netCfg.peers != null ? netCfg.peers : [netCfg.peer];
		var jobs:Array<js.lib.Promise<Dynamic>> = [];
		for (l in links) {
			var pc:Dynamic = l.pc;
			if (pc == null || pc.getStats == null) {
				jobs.push(js.lib.Promise.resolve({transport: l.transport}));
				continue;
			}
			jobs.push((pc.getStats() : js.lib.Promise<Dynamic>).then(stats -> {
				var pair:Dynamic = null;
				var byId = new Map<String, Dynamic>();
				stats.forEach((r:Dynamic) -> {
					byId.set(r.id, r);
					if (r.type == "transport" && r.selectedCandidatePairId != null)
						pair = {id: r.selectedCandidatePairId};
				});
				if (pair != null)
					pair = byId.get(pair.id);
				if (pair == null)
					stats.forEach((r:Dynamic) -> if (r.type == "candidate-pair" && (r.selected == true || (r.nominated == true && r.state == "succeeded")))
						pair = r);
				if (pair == null)
					return ({transport: l.transport, paire: "inconnue"} : Dynamic);
				var loc:Dynamic = byId.get(pair.localCandidateId), rem:Dynamic = byId.get(pair.remoteCandidateId);
				return ({
					transport: l.transport,
					local: loc != null ? loc.candidateType + " " + loc.protocol : null,
					distant: rem != null ? rem.candidateType + " " + rem.protocol : null,
					rttIceMs: pair.currentRoundTripTime != null ? round(pair.currentRoundTripTime * 1000) : null,
					octetsEnvoyes: pair.bytesSent,
					octetsRecus: pair.bytesReceived,
				} : Dynamic);
			}, _ -> {transport: l.transport}));
		}
		return js.lib.Promise.all(jobs).then(r -> {
			iceInfo = r;
			return r;
		});
	}

	static function system(renderer:swf.Renderer):Dynamic {
		var nav:Dynamic = Browser.navigator;
		var mem:Dynamic = untyped Browser.window.performance.memory;
		var dts:Array<Float> = [];
		var n = count < N ? count : N;
		for (k in 0...(n < 300 ? n : 300))
			dts.push(dtAt[(count - 1 - k) % N]);
		return {
			navigateur: nav.userAgent,
			coeurs: nav.hardwareConcurrency,
			memoireGo: nav.deviceMemory,
			ecran: Browser.window.screen.width + "x" + Browser.window.screen.height,
			fenetre: Browser.window.innerWidth + "x" + Browser.window.innerHeight,
			zoomPixels: Browser.window.devicePixelRatio,
			canevas: renderer != null ? renderer.canvas.width + "x" + renderer.canvas.height : null,
			canevasPerdu: renderer != null ? (try untyped renderer.ctx.isContextLost() catch (_:Dynamic) null) : null,
			rafraichissementEcranHz: round(1000 / Math.max(1, percentile(dts, 0.5))),
			ongletCache: hiddenCount,
			memoireJsMo: mem != null ? Math.round(mem.usedJSHeapSize / 1048576) : null,
		};
	}

	/** Le rapport complet (objet JSON). **/
	public static function build(session:Dynamic, netCfg:Dynamic, manager:Dynamic, renderer:swf.Renderer, extra:Dynamic):Dynamic {
		return {
			rapport: "Kikifest - rapport de débogage",
			date: Date.now().toString(),
			dureePartieS: round((now() - t0) / 1000),
			niveau: levelName(manager),
			dernieres10s: summary(10),
			dernieres60s: summary(60),
			connexion: connection(session, netCfg),
			systeme: system(renderer),
			jeu: gameContext(manager),
			vue: viewState(manager),
			image: thumbnail(renderer),
			extra: extra,
			imagesLentes: slow.slice(-80),
			evenements: events.slice(-150),
			erreurs: errors,
		};
	}

	// ------------------------------------------------------------ export et affichage

	public static function download(session:Dynamic, netCfg:Dynamic, manager:Dynamic, renderer:swf.Renderer, extra:Dynamic, done:String->Void) {
		var finish = (_:Dynamic) -> {
			var rep = build(session, netCfg, manager, renderer, extra);
			var text = haxe.Json.stringify(rep, null, "  ");
			var d = Date.now();
			var name = "kikifest-debug-" + DateTools.format(d, "%Y%m%d-%H%M%S") + ".json";
			try {
				var blob = new js.html.Blob([text], {type: "application/json"});
				var url = js.html.URL.createObjectURL(blob);
				var a:js.html.AnchorElement = cast Browser.document.createElement("a");
				a.href = url;
				a.download = name;
				Browser.document.body.appendChild(a);
				a.click();
				a.remove();
				Browser.window.setTimeout(() -> js.html.URL.revokeObjectURL(url), 5000);
			} catch (e:Dynamic) {}
			done(name);
			return null;
		};
		probeIce(netCfg).then(finish, finish);
	}

	static function addButton() {
		var st = Browser.document.getElementById("status");
		if (st == null || Browser.document.getElementById("kiki-debug-btn") != null)
			return;
		var b:Dynamic = Browser.document.createElement("button");
		b.id = "kiki-debug-btn";
		b.textContent = "🐞 Rapport de débogage (F9)";
		b.title = "Télécharge un fichier avec les mesures de la partie (images par seconde, rollback, ping…), à envoyer pour comprendre un ralentissement. F3 : mesures en direct.";
		b.setAttribute("style", "position:fixed;right:8px;bottom:8px;z-index:10;font-size:12px;opacity:.6;padding:3px 8px;cursor:pointer");
		b.onmouseenter = () -> b.style.opacity = "1";
		b.onmouseleave = () -> b.style.opacity = ".6";
		// sinon Espace (la bombe) « cliquerait » à nouveau sur le bouton après un clic
		b.onfocus = () -> b.blur();
		b.onclick = () -> onRequest();
		Browser.document.body.appendChild(b);
	}

	/** Branché par Boot : ce qui se passe quand on demande le rapport. **/
	public static var onRequest:Void->Void = () -> {};

	public static function removeButton() {
		var b = Browser.document.getElementById("kiki-debug-btn");
		if (b != null)
			b.remove();
		if (overlay != null) {
			overlay.remove();
			overlay = null;
		}
	}

	public static function toggleOverlay(session:Dynamic) {
		if (overlay != null) {
			overlay.remove();
			overlay = null;
			return;
		}
		overlay = Browser.document.createPreElement();
		overlay.setAttribute("style",
			"position:fixed;left:8px;top:8px;z-index:10;margin:0;padding:6px 8px;background:rgba(0,0,0,.75);color:#9f9;font:12px/1.35 monospace;pointer-events:none;white-space:pre");
		Browser.document.body.appendChild(overlay);
		updateOverlay(session);
	}

	static function updateOverlay(session:Dynamic) {
		if (overlay == null)
			return;
		var s:Dynamic = summary(2);
		var lines = [
			"images/s " + s.imagesParSeconde + "   pas de jeu/s " + s.pasDeJeuParSeconde,
			"écart images  méd " + s.ecartEntreImagesMs.median + "  max " + s.ecartEntreImagesMs.max + " ms",
			"simulation    moy " + s.simulationMs.moyenne + "  max " + s.simulationMs.max + " ms",
			"dessin        moy " + s.dessinMs.moyenne + "  max " + s.dessinMs.max + " ms",
			"photos " + s.photosRollback.nombre + " (" + s.photosRollback.msMoyen + " ms)   retours " + s.retoursEnArriere.nombre + "   rejouées " + s.framesRejouees,
		];
		if (session != null)
			lines.push("ping " + Math.round(session.rttMs) + " ms   délai touches " + session.inputDelay + "   avance " + round(session.frameAdvantage, 1));
		lines.push("images lentes (60 s) " + summary(60).imagesLentes + "   niveau " + lastLevel);
		overlay.textContent = lines.join("\n");
	}
}

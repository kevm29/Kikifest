package viewer;

import js.Browser;
import js.html.CanvasElement;
import swf.Library;
import swf.MovieClip;
import swf.Renderer;

/**
	Visionneuse des symboles de Hammerfest : permet de vérifier que
	l'extraction et le moteur MovieClip affichent correctement les animations.
**/
class Viewer {
	static var root:MovieClip;
	static var current:MovieClip;
	static var renderer:Renderer;
	static var zoom = 2.0;
	static var paused = false;
	static var shown = "";

	static function main() {
		var doc = Browser.document;
		var status = doc.getElementById("status");
		Library.load("assets", lib -> start(lib), e -> status.textContent = "Erreur de chargement : " + e);
	}

	static function start(lib:Library) {
		var doc = Browser.document;
		doc.getElementById("status").textContent = "";
		var canvas:CanvasElement = cast doc.getElementById("stage");
		renderer = new Renderer(canvas);
		renderer.background = "#20263a";
		root = new MovieClip(-1);
		root.isRoot = true;

		var list = doc.getElementById("list");
		var filter:js.html.InputElement = cast doc.getElementById("filter");
		var names = lib.exportNames().filter(n -> {
			var c:Dynamic = lib.char(lib.exportId(n));
			return c != null && c.k == "sprite";
		});
		function fill() {
			list.innerHTML = "";
			var q = filter.value.toLowerCase();
			for (n in names) {
				if (q != "" && n.toLowerCase().indexOf(q) < 0)
					continue;
				var li = doc.createLIElement();
				li.textContent = n;
				li.onclick = () -> show(n);
				list.appendChild(li);
			}
		}
		filter.oninput = fill;
		fill();

		doc.getElementById("play").onclick = () -> {
			paused = !paused;
			doc.getElementById("play").textContent = paused ? "Lecture" : "Pause";
		};
		doc.getElementById("step").onclick = () -> {
			paused = true;
			doc.getElementById("play").textContent = "Lecture";
			MovieClip.tick(root);
		};
		doc.getElementById("zoomIn").onclick = () -> zoom = Math.min(8, zoom * 1.5);
		doc.getElementById("zoomOut").onclick = () -> zoom = Math.max(0.25, zoom / 1.5);

		var hash = StringTools.urlDecode(Browser.location.hash.substr(1));
		show(hash != "" && lib.exportId(hash) != null ? hash : "hammer_player");
		Browser.window.onhashchange = () -> {
			var h = StringTools.urlDecode(Browser.location.hash.substr(1));
			if (h != "" && lib.exportId(h) != null && (current == null || h != shown))
				show(h);
		};

		var step = 1000 / lib.frameRate;
		var last = Browser.window.performance.now();
		var acc = 0.0;
		function loop(t:Float) {
			acc += t - last;
			last = t;
			if (acc > 250)
				acc = 250;
			while (acc >= step) {
				acc -= step;
				if (!paused)
					MovieClip.tick(root);
			}
			draw();
			Browser.window.requestAnimationFrame(loop);
		}
		Browser.window.requestAnimationFrame(loop);
	}

	static function show(name:String) {
		if (current != null)
			current.removeMovieClip();
		current = root.attachMovie(name, "sym", 1);
		shown = name;
		Browser.location.hash = name;
		var labels:Dynamic = Library.inst.char(Library.inst.exportId(name)).labels;
		var box = Browser.document.getElementById("labels");
		box.innerHTML = "";
		if (labels != null)
			for (l in Reflect.fields(labels)) {
				var b = Browser.document.createButtonElement();
				b.textContent = l + " (" + Reflect.field(labels, l) + ")";
				b.onclick = () -> current.gotoAndPlay(l);
				box.appendChild(b);
			}
	}

	static function draw() {
		var canvas = renderer.canvas;
		var dpr = Browser.window.devicePixelRatio;
		var w = Std.int(canvas.clientWidth * dpr);
		var h = Std.int(canvas.clientHeight * dpr);
		if (canvas.width != w || canvas.height != h) {
			canvas.width = w;
			canvas.height = h;
		}
		renderer.scale = zoom * dpr;
		if (current != null) {
			current._x = canvas.clientWidth / 2 / zoom;
			current._y = canvas.clientHeight / 2 / zoom;
		}
		renderer.render(root);
		var info = Browser.document.getElementById("info");
		if (current != null)
			info.textContent = shown + " : image " + current._currentframe + " / " + current._totalframes + " (" + Math.round(zoom * 100) + " %)";
	}
}

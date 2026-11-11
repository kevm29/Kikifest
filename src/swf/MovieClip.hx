package swf;

/**
	Émulation minimale d'un MovieClip AS2 : timeline, liste d'affichage par
	profondeur, enfants nommés accessibles comme des champs (__mc.sub), et les
	méthodes utilisées par le code de Hammerfest.
**/
class MovieClip extends DisplayObject {
	/** Profondeur des objets placés par la timeline (comme Flash : -16384 + profondeur). */
	public static inline var TIMELINE_DEPTH = -16384;

	/** Actions de frame à exécuter en fin de tick. */
	public static var queue:Array<Void->Void> = [];

	/** Scripts de frame non reconnus par l'extracteur, portés à la main : "charId:frame". */
	public static var frameScripts:Map<String, MovieClip->Void> = new Map();

	/** Appelé pour les sons déclenchés par la timeline. */
	public static var onTimelineSound:Int->Void = null;

	public var __children:Array<DisplayObject> = [];
	public var _currentframe(default, null):Int = 0;
	public var _totalframes(default, null):Int = 1;
	public var __playing:Bool = true;
	public var onEnterFrame:Void->Void = null;

	var __def:Dynamic;
	var __placeKeys:Map<Int, String> = new Map();
	var __justCreated:Bool = true;

	/** Classes associées aux symboles (Std.registerClass / Object.registerClass). */
	static var registry:Map<String, Class<MovieClip>> = new Map();

	static var pending:Dynamic = null;
	static var classByChar:Map<Int, Class<MovieClip>> = new Map();

	public static function registerClass(linkage:String, cls:Dynamic) {
		registry.set(linkage, cls);
		var id = Library.inst.exportId(linkage);
		if (id != null)
			classByChar.set(id, cls);
	}

	// propriétés et événements AS2 utilisés par le jeu
	public var onRelease:Dynamic = null;
	public var onPress:Dynamic = null;
	public var onRollOver:Dynamic = null;
	public var onRollOut:Dynamic = null;
	public var onReleaseOutside:Dynamic = null;
	public var useHandCursor:Bool = true;
	public var enabled:Bool = true;
	public var cacheAsBitmap:Bool = false;
	public var _lockroot:Bool = false;
	public var _xmouse:Float = 0;
	public var _ymouse:Float = 0;
	public var _quality:String = "HIGH";
	public var _droptarget:String = "";

	public function new(?__charId:Int) {
		var p:Dynamic = null;
		if (__charId == null) {
			p = pending;
			pending = null;
			__charId = p != null ? p.id : -1;
		}
		super(__charId);
		if (__charId >= 0) {
			__def = Library.inst.char(__charId);
			_totalframes = __def != null && __def.frames != null ? __def.frames.length : 1;
			if (_totalframes < 1)
				_totalframes = 1;
		} else
			_currentframe = 1;
		if (p != null) {
			// Comme Flash : le clip est nommé, placé, initialisé (objet init) et sa frame 1
			// construite AVANT le corps du constructeur de la classe associée.
			_name = p.name;
			if (p.parent != null)
				(p.parent : MovieClip).__addChildAt(this, p.depth);
			if (p.init != null)
				for (f in Reflect.fields(p.init))
					Reflect.setProperty(this, f, Reflect.field(p.init, f));
			if (p.timeline != true)
				__init();
		}
	}

	/** Crée une instance (avec sa classe associée si elle existe). */
	static function instantiate(id:Int, name:String, parent:MovieClip, depth:Int, init:Dynamic, timeline:Bool = false):MovieClip {
		var cls = classByChar.get(id);
		pending = {id: id, name: name, parent: parent, depth: depth, init: init, timeline: timeline};
		var mc:MovieClip = cls != null ? Type.createInstance(cls, []) : new MovieClip();
		pending = null;
		return mc;
	}

	// --- création ---------------------------------------------------------

	public static function create(__charId:Int):DisplayObject {
		var c:Dynamic = Library.inst.char(__charId);
		if (c == null)
			return new DisplayObject(__charId);
		return switch (c.k) {
			case "sprite": new MovieClip(__charId);
			case "etext": new TextField(__charId);
			default: new DisplayObject(__charId);
		}
	}

	/** Premier affichage : frame 1 et ses actions. */
	public function __init() {
		if (__def == null || _currentframe > 0)
			return;
		__enterFrame(1);
	}

	// --- liste d'affichage ------------------------------------------------

	public function __addChildAt(o:DisplayObject, __depth:Int) {
		var old = __getChildAtDepth(__depth);
		if (old != null)
			__removeChild(old);
		o.__depth = __depth;
		o._parent = this;
		var i = 0;
		while (i < __children.length && __children[i].__depth < __depth)
			i++;
		__children.insert(i, o);
		if (o._name != null && o._name != "")
			Reflect.setField(this, o._name, o);
		return o;
	}

	public function __removeChild(o:DisplayObject) {
		__children.remove(o);
		if (o._name != null && o._name != "" && Reflect.field(this, o._name) == o)
			Reflect.deleteField(this, o._name);
		o._parent = null;
	}

	public function __getChildAtDepth(__depth:Int):Null<DisplayObject> {
		for (c in __children)
			if (c.__depth == __depth)
				return c;
		return null;
	}

	public function attachMovie(linkage:String, name:String, __depth:Int, ?init:Dynamic):MovieClip {
		var id = Library.inst.exportId(linkage);
		if (id == null)
			return null;
		return instantiate(id, name, this, __depth, init);
	}

	public function createEmptyMovieClip(name:String, __depth:Int):MovieClip {
		return instantiate(-1, name, this, __depth, null);
	}

	public function duplicateMovieClip(name:String, depth:Int, ?init:Dynamic):MovieClip {
		if (_parent == null)
			return null;
		var mc = instantiate(__charId, name, _parent, depth, init);
		mc.__setMatrix([__ma(), __mb(), __mc(), __md(), __mtx(), __mty()]);
		mc.__cx = __cx;
		return mc;
	}

	public function createTextField(name:String, depth:Int, x:Float, y:Float, w:Float, h:Float):TextField {
		var t = new TextField(-1);
		t._name = name;
		t.__w = w;
		t.__h = h;
		t._x = x;
		t._y = y;
		__addChildAt(t, depth);
		return t;
	}

	public function attachBitmap(bmp:Dynamic, depth:Int, ?snap:String, ?smooth:Bool) {
		var b = new BitmapObject(bmp);
		__addChildAt(b, depth);
	}

	public function setMask(m:Dynamic) {}

	public function getInstanceAtDepth(d:Int):DisplayObject return __getChildAtDepth(d);

	/** Boîte englobante dans l'espace de `target` (ou local). */
	public function hitTest(a:Dynamic, ?b:Float, ?shape:Bool):Bool {
		if (Std.isOfType(a, DisplayObject)) {
			var r1 = getBounds(null);
			var r2 = (a : DisplayObject).getBounds(null);
			if (r1 == null || r2 == null)
				return false;
			return r1.xMin < r2.xMax && r1.xMax > r2.xMin && r1.yMin < r2.yMax && r1.yMax > r2.yMin;
		}
		var r = getBounds(null);
		var x:Float = a;
		return r != null && x >= r.xMin && x <= r.xMax && b >= r.yMin && b <= r.yMax;
	}

	public function getDepth() return __depth;

	public function getNextHighestDepth():Int {
		var d = 0;
		for (c in __children)
			if (c.__depth >= d)
				d = c.__depth + 1;
		return d;
	}

	public function swapDepths(target:Dynamic) {
		if (_parent == null)
			return;
		var p = _parent;
		var newDepth:Int = Std.isOfType(target, DisplayObject) ? (cast target : DisplayObject).__depth : Std.int(target);
		var other = p.__getChildAtDepth(newDepth);
		var myDepth = __depth;
		p.__children.remove(this);
		if (other != null) {
			p.__children.remove(other);
			other.__depth = myDepth;
			p.__insertSorted(other);
		}
		__depth = newDepth;
		p.__insertSorted(this);
	}

	function __insertSorted(o:DisplayObject) {
		var i = 0;
		while (i < __children.length && __children[i].__depth < o.__depth)
			i++;
		__children.insert(i, o);
	}

	// --- timeline ---------------------------------------------------------

	public function play() __playing = true;

	public function stop() __playing = false;

	public function gotoAndStop(f:Dynamic) {
		__playing = false;
		__gotoFrame(f);
	}

	public function gotoAndPlay(f:Dynamic) {
		__playing = true;
		__gotoFrame(f);
	}

	public function nextFrame() {
		__playing = false;
		if (_currentframe < _totalframes)
			__gotoFrame(_currentframe + 1);
	}

	public function prevFrame() {
		__playing = false;
		if (_currentframe > 1)
			__gotoFrame(_currentframe - 1);
	}

	function __resolveFrame(f:Dynamic):Int {
		if (Std.isOfType(f, String)) {
			var s:String = f;
			var n = Std.parseInt(s);
			if (n != null && Std.string(n) == s)
				return n;
			if (__def != null && __def.labels != null) {
				var l = Reflect.field(__def.labels, s);
				if (l != null)
					return l;
			}
			return -1;
		}
		return Std.int(f);
	}

	public function __gotoFrame(f:Dynamic) {
		if (__def == null || __def.frames == null)
			return;
		var n = __resolveFrame(f);
		if (n < 1)
			return;
		if (n > _totalframes)
			n = _totalframes;
		if (n == _currentframe)
			return;
		__enterFrame(n);
	}

	/** État de la liste d'affichage à une frame donnée (mis en cache dans la définition). */
	function __stateAt(n:Int):Map<Int, Dynamic> {
		var cache:Array<Map<Int, Dynamic>> = __def.__states;
		if (cache == null) {
			cache = [];
			__def.__states = cache;
		}
		if (cache[n] != null)
			return cache[n];
		var frames:Array<Array<Dynamic>> = __def.frames;
		var start = n - 1;
		while (start > 0 && cache[start] == null)
			start--;
		var st:Map<Int, Dynamic> = new Map();
		if (start > 0)
			for (k => v in cache[start])
				st.set(k, v);
		for (i in start + 1...n + 1) {
			var ops = frames[i - 1];
			if (ops != null)
				for (op in ops) {
					var d:Int = op.d;
					if (op.rm != null) {
						st.remove(d);
						continue;
					}
					var prev:Dynamic = st.get(d);
					var e:Dynamic = {};
					if (prev != null && op.n == null) {
						for (f in Reflect.fields(prev))
							Reflect.setField(e, f, Reflect.field(prev, f));
					} else {
						e.key = i + ":" + op.c;
					}
					for (f in Reflect.fields(op))
						if (f != "d" && f != "n")
							Reflect.setField(e, f, Reflect.field(op, f));
					if (op.c != null && prev != null && prev.c != op.c)
						e.key = i + ":" + op.c;
					st.set(d, e);
				}
			cache[i] = st;
			if (i < n) {
				var copy:Map<Int, Dynamic> = new Map();
				for (k => v in st)
					copy.set(k, v);
				st = copy;
			}
		}
		return st;
	}

	function __enterFrame(n:Int) {
		var st = __stateAt(n);
		// retire les objets de timeline absents ou remplacés
		for (c in __children.copy()) {
			if (!c.__fromTimeline)
				continue;
			var d = c.__depth - TIMELINE_DEPTH;
			var e:Dynamic = st.get(d);
			if (e == null || e.key != __placeKeys.get(d)) {
				__removeChild(c);
				__placeKeys.remove(d);
			}
		}
		// crée ou met à jour
		for (d => e in st) {
			var c = __getChildAtDepth(d + TIMELINE_DEPTH);
			if (c == null) {
				var ch:Dynamic = Library.inst.char(e.c);
				if (ch != null && ch.k == "sprite") {
					c = instantiate(e.c, e.name != null ? e.name : "instance" + d, this, d + TIMELINE_DEPTH, null, true);
				} else {
					c = create(e.c);
					if (e.name != null)
						c._name = e.name;
					__addChildAt(c, d + TIMELINE_DEPTH);
				}
				c.__fromTimeline = true;
				__placeKeys.set(d, e.key);
				__applyPlacement(c, e, true);
				if (Std.isOfType(c, MovieClip))
					(cast c : MovieClip).__init();
			} else {
				__applyPlacement(c, e, false);
			}
		}
		_currentframe = n;
		var acts:Array<Dynamic> = __def.actions != null ? Reflect.field(__def.actions, Std.string(n)) : null;
		if (acts != null)
			queue.push(() -> __runActions(n, acts));
		if (__def.sounds != null && onTimelineSound != null) {
			var s:Array<Int> = Reflect.field(__def.sounds, Std.string(n));
			if (s != null)
				for (id in s)
					onTimelineSound(id);
		}
	}

	function __applyPlacement(c:DisplayObject, e:Dynamic, fresh:Bool) {
		if (!c.__scripted || fresh) {
			if (e.m != null)
				c.__setMatrix(e.m);
			c.__cx = e.cx;
		}
		c.__ratio = e.r != null ? e.r : 0;
		c.__clipDepth = e.clip != null ? e.clip + TIMELINE_DEPTH : 0;
		c.__blend = e.blend;
		c.__filters = e.filters;
	}

	function __runActions(frame:Int, acts:Array<Dynamic>) {
		if (_parent == null && !__isRoot)
			return; // retiré entre temps
		for (a in acts) {
			var op:Array<Dynamic> = a;
			switch (op[0]) {
				case "stop":
					stop();
				case "play":
					play();
				case "next":
					nextFrame();
				case "prev":
					prevFrame();
				case "goto":
					if (op[2])
						gotoAndPlay(op[1])
					else
						gotoAndStop(op[1]);
				case "todo":
					var h = frameScripts.get(__charId + ":" + frame);
					if (h != null)
						h(this);
			}
		}
	}

	public var __isRoot:Bool = false;

	override public function __localBounds():Null<Rect> {
		var r:Null<Rect> = null;
		for (c in __children) {
			if (!c._visible || c.__clipDepth != 0)
				continue;
			var b = c.__boundsInParent();
			if (b == null)
				continue;
			r = r == null ? b : Rect.union(r, b);
		}
		return r;
	}

	override public function __advance(q:Array<Void->Void>) {
		if (__justCreated) {
			__justCreated = false;
		} else if (__playing && __def != null && _totalframes > 1) {
			__enterFrame(_currentframe >= _totalframes ? 1 : _currentframe + 1);
		}
		if (onEnterFrame != null)
			queue.push(onEnterFrame);
		for (c in __children.copy())
			if (c._parent == this)
				c.__advance(q);
	}

	/** Un tick complet : avance toutes les timelines puis exécute les actions. */
	public static function tick(root:MovieClip) {
		root.__advance(queue);
		var guard = 0;
		while (queue.length > 0 && guard++ < 10000) {
			var f = queue.shift();
			f();
		}
	}
}

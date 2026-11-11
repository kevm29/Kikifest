package swf;

/**
	Émulation minimale d'un MovieClip AS2 : timeline, liste d'affichage par
	profondeur, enfants nommés accessibles comme des champs (mc.sub), et les
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

	public var children:Array<DisplayObject> = [];
	public var _currentframe(default, null):Int = 0;
	public var _totalframes(default, null):Int = 1;
	public var playing:Bool = true;
	public var onEnterFrame:Void->Void = null;

	var def:Dynamic;
	var placeKeys:Map<Int, String> = new Map();
	var justCreated:Bool = true;

	public function new(charId:Int) {
		super(charId);
		if (charId >= 0) {
			def = Library.inst.char(charId);
			_totalframes = def != null && def.frames != null ? def.frames.length : 1;
			if (_totalframes < 1)
				_totalframes = 1;
		}
	}

	// --- création ---------------------------------------------------------

	public static function create(charId:Int):DisplayObject {
		var c:Dynamic = Library.inst.char(charId);
		if (c == null)
			return new DisplayObject(charId);
		return switch (c.k) {
			case "sprite": new MovieClip(charId);
			case "etext": new TextField(charId);
			default: new DisplayObject(charId);
		}
	}

	/** Premier affichage : frame 1 et ses actions. */
	public function init() {
		if (def == null || _currentframe > 0)
			return;
		enterFrame(1);
	}

	// --- liste d'affichage ------------------------------------------------

	public function addChildAt(o:DisplayObject, depth:Int) {
		var old = getChildAtDepth(depth);
		if (old != null)
			removeChild(old);
		o.depth = depth;
		o._parent = this;
		var i = 0;
		while (i < children.length && children[i].depth < depth)
			i++;
		children.insert(i, o);
		if (o._name != null && o._name != "")
			Reflect.setField(this, o._name, o);
		return o;
	}

	public function removeChild(o:DisplayObject) {
		children.remove(o);
		if (o._name != null && o._name != "" && Reflect.field(this, o._name) == o)
			Reflect.deleteField(this, o._name);
		o._parent = null;
	}

	public function getChildAtDepth(depth:Int):Null<DisplayObject> {
		for (c in children)
			if (c.depth == depth)
				return c;
		return null;
	}

	public function attachMovie(linkage:String, name:String, depth:Int, ?init:Dynamic):MovieClip {
		var id = Library.inst.exportId(linkage);
		if (id == null)
			return null;
		var mc = new MovieClip(id);
		mc._name = name;
		if (init != null)
			for (f in Reflect.fields(init))
				Reflect.setProperty(mc, f, Reflect.field(init, f));
		addChildAt(mc, depth);
		mc.init();
		return mc;
	}

	public function createEmptyMovieClip(name:String, depth:Int):MovieClip {
		var mc = new MovieClip(-1);
		mc._name = name;
		mc._currentframe = 1;
		addChildAt(mc, depth);
		return mc;
	}

	public function getDepth() return depth;

	public function getNextHighestDepth():Int {
		var d = 0;
		for (c in children)
			if (c.depth >= d)
				d = c.depth + 1;
		return d;
	}

	public function swapDepths(target:Dynamic) {
		if (_parent == null)
			return;
		var p = _parent;
		var newDepth:Int = Std.isOfType(target, DisplayObject) ? (cast target : DisplayObject).depth : Std.int(target);
		var other = p.getChildAtDepth(newDepth);
		var myDepth = depth;
		p.children.remove(this);
		if (other != null) {
			p.children.remove(other);
			other.depth = myDepth;
			p.insertSorted(other);
		}
		depth = newDepth;
		p.insertSorted(this);
	}

	function insertSorted(o:DisplayObject) {
		var i = 0;
		while (i < children.length && children[i].depth < o.depth)
			i++;
		children.insert(i, o);
	}

	// --- timeline ---------------------------------------------------------

	public function play() playing = true;

	public function stop() playing = false;

	public function gotoAndStop(f:Dynamic) {
		playing = false;
		gotoFrame(f);
	}

	public function gotoAndPlay(f:Dynamic) {
		playing = true;
		gotoFrame(f);
	}

	public function nextFrame() {
		playing = false;
		if (_currentframe < _totalframes)
			gotoFrame(_currentframe + 1);
	}

	public function prevFrame() {
		playing = false;
		if (_currentframe > 1)
			gotoFrame(_currentframe - 1);
	}

	function resolveFrame(f:Dynamic):Int {
		if (Std.isOfType(f, String)) {
			var s:String = f;
			var n = Std.parseInt(s);
			if (n != null && Std.string(n) == s)
				return n;
			if (def != null && def.labels != null) {
				var l = Reflect.field(def.labels, s);
				if (l != null)
					return l;
			}
			return -1;
		}
		return Std.int(f);
	}

	public function gotoFrame(f:Dynamic) {
		if (def == null || def.frames == null)
			return;
		var n = resolveFrame(f);
		if (n < 1)
			return;
		if (n > _totalframes)
			n = _totalframes;
		if (n == _currentframe)
			return;
		enterFrame(n);
	}

	/** État de la liste d'affichage à une frame donnée (mis en cache dans la définition). */
	function stateAt(n:Int):Map<Int, Dynamic> {
		var cache:Array<Map<Int, Dynamic>> = def.__states;
		if (cache == null) {
			cache = [];
			def.__states = cache;
		}
		if (cache[n] != null)
			return cache[n];
		var frames:Array<Array<Dynamic>> = def.frames;
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

	function enterFrame(n:Int) {
		var st = stateAt(n);
		// retire les objets de timeline absents ou remplacés
		for (c in children.copy()) {
			if (!c.fromTimeline)
				continue;
			var d = c.depth - TIMELINE_DEPTH;
			var e:Dynamic = st.get(d);
			if (e == null || e.key != placeKeys.get(d)) {
				removeChild(c);
				placeKeys.remove(d);
			}
		}
		// crée ou met à jour
		for (d => e in st) {
			var c = getChildAtDepth(d + TIMELINE_DEPTH);
			if (c == null) {
				c = create(e.c);
				c.fromTimeline = true;
				if (e.name != null)
					c._name = e.name;
				addChildAt(c, d + TIMELINE_DEPTH);
				placeKeys.set(d, e.key);
				applyPlacement(c, e, true);
				if (Std.isOfType(c, MovieClip))
					(cast c : MovieClip).init();
			} else {
				applyPlacement(c, e, false);
			}
		}
		_currentframe = n;
		var acts:Array<Dynamic> = def.actions != null ? Reflect.field(def.actions, Std.string(n)) : null;
		if (acts != null)
			queue.push(() -> runActions(n, acts));
		if (def.sounds != null && onTimelineSound != null) {
			var s:Array<Int> = Reflect.field(def.sounds, Std.string(n));
			if (s != null)
				for (id in s)
					onTimelineSound(id);
		}
	}

	function applyPlacement(c:DisplayObject, e:Dynamic, fresh:Bool) {
		if (!c.scripted || fresh) {
			if (e.m != null)
				c.setMatrix(e.m);
			c.cx = e.cx;
		}
		c.ratio = e.r != null ? e.r : 0;
		c.clipDepth = e.clip != null ? e.clip + TIMELINE_DEPTH : 0;
		c.blend = e.blend;
		c.filters = e.filters;
	}

	function runActions(frame:Int, acts:Array<Dynamic>) {
		if (_parent == null && !isRoot)
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
					var h = frameScripts.get(charId + ":" + frame);
					if (h != null)
						h(this);
			}
		}
	}

	public var isRoot:Bool = false;

	override public function advance(q:Array<Void->Void>) {
		if (justCreated) {
			justCreated = false;
		} else if (playing && def != null && _totalframes > 1) {
			enterFrame(_currentframe >= _totalframes ? 1 : _currentframe + 1);
		}
		if (onEnterFrame != null)
			queue.push(onEnterFrame);
		for (c in children.copy())
			if (c._parent == this)
				c.advance(q);
	}

	/** Un tick complet : avance toutes les timelines puis exécute les actions. */
	public static function tick(root:MovieClip) {
		root.advance(queue);
		var guard = 0;
		while (queue.length > 0 && guard++ < 10000) {
			var f = queue.shift();
			f();
		}
	}
}

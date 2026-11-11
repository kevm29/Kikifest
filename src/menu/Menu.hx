package menu;

import js.Browser;
import js.html.CanvasElement;
import js.html.Element;
import meta.Quests;
import meta.Save;
import swf.Library;
import swf.MovieClip;
import swf.Renderer;

typedef ModeInfo = {
	id:String,
	name:String,
	desc:String,
	icon:Int,
	?unlock:String,
	options:Array<String>
};

/**
	Menu de Kikifest, inspiré du site d'origine : modes de jeu, frigo (objets trouvés) et quêtes.
	La collection est lue dans la sauvegarde locale (voir meta.Save).
**/
class Menu {
	static var doc = Browser.document;
	static var quests:Quests;
	static var save:Save;
	static var state:QuestState;
	static var root:MovieClip;
	static var uniq = 1;

	static var itemNames = new Map<Int, String>();
	static var familyNames = new Map<Int, String>();
	static var questTexts = new Map<Int, {title:String, desc:String}>();

	static var MODES:Array<ModeInfo> = [
		{
			id: "solo",
			name: "Aventure",
			desc: "Jouez la vraie Aventure ! Libérez les fruits ! (avec les Dimensions parallèles)",
			icon: 1000,
			options: ["mirror", "nightmare", "ninja", "bombexpert"]
		},
		{
			id: "tutorial",
			name: "Apprentissage",
			desc: "Découvrez le jeu pas à pas, avec des vies illimitées. Ce mode est gratuit et illimité !",
			icon: 1,
			options: []
		},
		{
			id: "multicoop",
			name: "Aventure à deux",
			desc: "Igor et Sandy repartent ensemble dans la grande aventure, sur le même clavier.\nIgor : flèches + Entrée · Sandy : R D F G + A",
			icon: 1027,
			options: ["mirrormulti", "nightmaremulti", "lifesharing"]
		},
		{
			id: "timeattack",
			name: "Time Attack",
			desc: "Traversez les niveaux le plus vite possible !",
			icon: 1236,
			unlock: "timeattack",
			options: []
		},
		{
			id: "soccer",
			name: "Soccerfest",
			desc: "Un match de football à deux, à coups de bombes.\nIgor : flèches + Entrée · Sandy : R D F G + A",
			icon: 1043,
			options: ["kickcontrol", "soccerbomb"]
		},
	];

	static var OPTION_NAMES = [
		"mirror" => "Miroir (niveaux inversés)",
		"nightmare" => "Cauchemar (ennemis plus rapides)",
		"ninja" => "Ninjutsu (ne pas tuer les fruits amis)",
		"bombexpert" => "Explosifs instables",
		"mirrormulti" => "Miroir",
		"nightmaremulti" => "Cauchemar",
		"lifesharing" => "Partage des vies",
		"kickcontrol" => "Contrôle du ballon",
		"soccerbomb" => "Bombes au Soccerfest",
	];

	/** options toujours actives une fois gagnées (pas de case à cocher) */
	static var PASSIVE = ["boost", "set_ta_0", "set_ta_1", "set_ta_2", "set_mta_0", "set_mta_1", "set_mta_2"];

	static function main() {
		var files = ["quests", "specialItems", "scoreItems", "lang/fr"];
		var texts = new Map<String, String>();
		var jobs = [
			for (f in files)
				Browser.window.fetch("assets/data/" + f + ".xml").then(r -> r.text()).then(t -> {
					texts.set(f, t);
					return null;
				})
		];
		js.lib.Promise.all(jobs).then(_ -> {
			quests = new Quests(texts.get("quests"), [texts.get("specialItems"), texts.get("scoreItems")]);
			readLang(texts.get("lang/fr"));
			Library.load("assets", lib -> start(), e -> setStatus("Erreur : " + e));
			return null;
		});
	}

	static function setStatus(s:String) {
		var el = doc.getElementById("status");
		if (el != null)
			el.textContent = s;
	}

	static function find(x:Xml, name:String):Null<Xml> {
		for (e in x.elements()) {
			if (e.nodeName == name)
				return e;
			var r = find(e, name);
			if (r != null)
				return r;
		}
		return null;
	}

	static function readLang(src:String) {
		if (StringTools.startsWith(src, "\u{FEFF}"))
			src = src.substr(1);
		var x = Xml.parse(src).firstElement();
		for (e in find(x, "items").elementsNamed("item"))
			itemNames.set(Std.parseInt(e.get("id")), e.get("name"));
		for (e in find(x, "families").elementsNamed("family"))
			familyNames.set(Std.parseInt(e.get("id")), e.get("name"));
		for (e in find(x, "quests").elementsNamed("quest")) {
			var desc = new StringBuf();
			for (c in e)
				if (c.nodeType == Xml.PCData || c.nodeType == Xml.CData)
					desc.add(c.nodeValue);
			questTexts.set(Std.parseInt(e.get("id")), {title: e.get("title"), desc: ~/\s+/g.replace(StringTools.trim(desc.toString()), " ")});
		}
	}

	static function start() {
		setStatus("");
		root = new MovieClip(-1);
		root.__isRoot = true;
		save = Save.load();
		state = quests.compute(save.items);

		var nameInput:js.html.InputElement = cast doc.getElementById("player");
		nameInput.value = getPref("name", "Igor");
		nameInput.onchange = () -> setPref("name", nameInput.value);
		doc.getElementById("count").textContent = Std.string(save.totalItems());

		// icônes des cubes de glace (graphismes du jeu)
		for (cube in doc.querySelectorAll(".cube[data-item]")) {
			var el:Element = cast cube;
			el.querySelector(".ico").appendChild(itemIcon(Std.parseInt(el.dataset.item), 54));
		}
		for (cube in doc.querySelectorAll(".cube")) {
			var el:Element = cast cube;
			el.onclick = () -> show(el.dataset.view);
		}
		Browser.window.onhashchange = () -> show(Browser.location.hash.substr(1));
		show(Browser.location.hash.substr(1));
	}

	static function getPref(k:String, def:String):String {
		try {
			var v = Browser.window.localStorage.getItem("kikifest." + k);
			return v != null ? v : def;
		} catch (e:Dynamic) {
			return def;
		}
	}

	static function setPref(k:String, v:String) {
		try {
			Browser.window.localStorage.setItem("kikifest." + k, v);
		} catch (e:Dynamic) {}
	}

	static function show(view:String) {
		if (view != "frigo" && view != "quetes")
			view = "jouer";
		if (Browser.location.hash.substr(1) != view && !(view == "jouer" && Browser.location.hash == ""))
			Browser.location.hash = view;
		for (c in doc.querySelectorAll(".cube")) {
			var el:Element = cast c;
			el.classList.toggle("on", el.dataset.view == view);
		}
		var main = doc.getElementById("main");
		main.innerHTML = "";
		switch (view) {
			case "frigo":
				showFridge(main);
			case "quetes":
				showQuests(main);
			default:
				showModes(main);
		}
	}

	// ---------------------------------------------------------------- icônes

	static var iconCache = new Map<String, String>();

	/** Dessine un objet du jeu (clip hammer_item_special / hammer_item_score) dans une image. */
	static function itemIcon(id:Int, size:Int, ?dark:Bool):Element {
		var key = id + ":" + size;
		var url = iconCache.get(key);
		if (url == null) {
			var dpr = Browser.window.devicePixelRatio;
			var px = Std.int(size * dpr);
			var c:CanvasElement = doc.createCanvasElement();
			c.width = c.height = px;
			var mc = root.attachMovie(id >= 1000 ? "hammer_item_score" : "hammer_item_special", "ic" + uniq, uniq++);
			if (mc != null) {
				mc.gotoAndStop(Std.string(id >= 1000 ? id - 1000 + 1 : id + 1));
				var b:Dynamic = mc.getBounds(mc);
				var w:Float = b.xMax - b.xMin, h:Float = b.yMax - b.yMin;
				if (w > 0 && h > 0) {
					var s = Math.min(px * 0.9 / Math.max(w, h), 2.5 * dpr);
					mc._xscale = mc._yscale = s * 100;
					Renderer.drawInto(c, mc, (px - w * s) / 2 - b.xMin * s, (px - h * s) / 2 - b.yMin * s);
				}
				mc.removeMovieClip();
			}
			url = c.toDataURL();
			iconCache.set(key, url);
		}
		var img = doc.createImageElement();
		img.src = url;
		img.width = img.height = size;
		img.className = "item" + (dark ? " dark" : "");
		img.title = itemNames.exists(id) ? itemNames.get(id) : "Objet " + id;
		return img;
	}

	static function el(tag:String, ?cls:String, ?text:String):Element {
		var e = doc.createElement(tag);
		if (cls != null)
			e.className = cls;
		if (text != null)
			e.textContent = text;
		return e;
	}

	// ---------------------------------------------------------------- modes de jeu

	static function isUnlocked(m:ModeInfo)
		return m.unlock == null || state.modes.indexOf(m.unlock) >= 0;

	static function showModes(main:Element) {
		var list = el("div", "panel modes");
		list.appendChild(el("h2", null, "Modes de jeu"));
		var detail = el("div", "panel detail");
		var current = getPref("mode", "solo");
		function select(m:ModeInfo) {
			setPref("mode", m.id);
			for (a in list.querySelectorAll("a"))
				(cast a : Element).classList.toggle("sel", (cast a : Element).dataset.mode == m.id);
			detail.innerHTML = "";
			detail.appendChild(el("h2", null, m.name));
			for (line in m.desc.split("\n"))
				detail.appendChild(el("p", null, line));
			var opts = m.options.filter(o -> state.options.indexOf(o) >= 0);
			var boxes = [];
			if (opts.length > 0) {
				var box = el("div", "options");
				box.appendChild(el("h3", null, "Options débloquées"));
				for (o in opts) {
					var lab = el("label");
					var cb:js.html.InputElement = cast doc.createInputElement();
					cb.type = "checkbox";
					cb.checked = getPref("opt." + o, "0") == "1";
					cb.onchange = () -> setPref("opt." + o, cb.checked ? "1" : "0");
					boxes.push({o: o, cb: cb});
					lab.appendChild(cb);
					lab.appendChild(doc.createTextNode(" " + (OPTION_NAMES.exists(o) ? OPTION_NAMES.get(o) : o)));
					box.appendChild(lab);
				}
				detail.appendChild(box);
			}
			var go = el("a", "button", "Commencer");
			go.onclick = () -> {
				var o = [for (b in boxes) if (b.cb.checked) b.o];
				for (p in PASSIVE)
					if (state.options.indexOf(p) >= 0)
						o.push(p);
				Browser.location.href = "index.html?mode=" + m.id + (o.length > 0 ? "&options=" + o.join(",") : "");
			};
			detail.appendChild(go);
			var bonus = startBonus();
			if (bonus.length > 0 && m.id != "tutorial" && m.id != "soccer")
				detail.appendChild(el("p", "bonus", "Vos quêtes vous donnent : " + bonus.join(", ") + "."));
		}
		for (m in MODES) {
			var row = el("div", "mode");
			var a = el(isUnlocked(m) ? "a" : "span", isUnlocked(m) ? null : "locked", isUnlocked(m) ? m.name : "Non débloqué");
			a.dataset.mode = m.id;
			row.appendChild(a);
			row.appendChild(isUnlocked(m) ? itemIcon(m.icon, 28) : el("span", "qmark", "?"));
			if (isUnlocked(m))
				a.onclick = () -> select(m);
			list.appendChild(row);
		}
		main.appendChild(list);
		main.appendChild(detail);
		var m = MODES.filter(x -> x.id == current && isUnlocked(x))[0];
		select(m != null ? m : MODES[0]);
	}

	/** Bonus permanents de départ, lus comme le fait Player.hx (familles 100 à 108). */
	static function startBonus():Array<String> {
		var f = state.families;
		var lives = 0;
		for (id in [102, 103, 104, 105, 108])
			if (f.indexOf(id) >= 0)
				lives++;
		var r = [];
		if (lives > 0)
			r.push(lives + (lives > 1 ? " vies supplémentaires" : " vie supplémentaire"));
		if (f.indexOf(100) >= 0)
			r.push("2 bombes à la fois");
		if (f.indexOf(101) >= 0)
			r.push("le coup de pied vers le haut");
		if (f.indexOf(106) >= 0 || f.indexOf(107) >= 0)
			r.push("de la lumière dans le noir");
		return r;
	}

	// ---------------------------------------------------------------- frigo

	static function showFridge(main:Element) {
		var p = el("div", "panel wide");
		p.appendChild(el("h2", null, "Mon frigo"));
		var found = 0, total = 0;
		for (f in quests.familyOrder)
			for (i in quests.familyItems.get(f)) {
				total++;
				if (Quests.count(save.items, i) > 0)
					found++;
			}
		p.appendChild(el("p", "intro", 'Vous avez trouvé $found objets différents sur $total, en ${save.games} partie${save.games > 1 ? "s" : ""}.'
			+ (save.best > 0 ? ' Meilleur score : ${save.best}.' : "")));
		for (f in quests.familyOrder) {
			var items = quests.familyItems.get(f);
			var n = items.filter(i -> Quests.count(save.items, i) > 0).length;
			var active = state.families.indexOf(f) >= 0;
			if (n == 0 && !active)
				continue; // famille pas encore découverte
			var sec = el("section", "family");
			var h = el("h3", null, familyNames.exists(f) ? familyNames.get(f) : "Famille " + f);
			h.appendChild(el("span", "count", ' $n / ${items.length}'));
			sec.appendChild(h);
			var grid = el("div", "grid");
			for (i in items) {
				var c = Quests.count(save.items, i);
				var cell = el("div", "cell" + (c > 0 ? "" : " unknown"));
				if (c > 0) {
					cell.appendChild(itemIcon(i, 40));
					cell.appendChild(el("span", "qty", "×" + c));
				} else
					cell.appendChild(el("span", "qmark", "?"));
				grid.appendChild(cell);
			}
			sec.appendChild(grid);
			p.appendChild(sec);
		}
		main.appendChild(p);
	}

	// ---------------------------------------------------------------- quêtes

	static function showQuests(main:Element) {
		var p = el("div", "panel wide");
		p.appendChild(el("h2", null, "Mes quêtes"));
		var all = getPref("spoil", "0") == "1";
		var done = 0, started = 0, hidden = 0;
		var listDone = el("div"), listOpen = el("div");
		for (q in quests.list) {
			var complete = state.done.indexOf(q.id) >= 0;
			var has = q.require.filter(r -> Quests.count(save.items, r.item) > 0).length > 0;
			if (complete)
				done++;
			else if (has)
				started++;
			else
				hidden++;
			if (!complete && !has && !all)
				continue;
			var t = questTexts.get(q.id);
			var card = el("section", "quest" + (complete ? " done" : ""));
			card.appendChild(el("h3", null, (complete ? "✔ " : "") + (t != null ? t.title : "Quête " + q.id)));
			var req = el("div", "reqs");
			for (r in q.require) {
				var c = Quests.count(save.items, r.item);
				var cell = el("span", "req" + (c >= r.qty ? " ok" : ""));
				cell.appendChild(itemIcon(r.item, 36, c == 0));
				cell.appendChild(el("span", "qty", '${Std.int(Math.min(c, r.qty))}/${r.qty}'));
				req.appendChild(cell);
			}
			card.appendChild(req);
			if (t != null && (complete || all))
				card.appendChild(el("p", "reward", t.desc));
			(complete ? listDone : listOpen).appendChild(card);
		}
		p.appendChild(el("p", "intro",
			'$done quête${done > 1 ? "s" : ""} terminée${done > 1 ? "s" : ""}, $started en cours, $hidden encore secrète${hidden > 1 ? "s" : ""}.'
			+ " Les objets ramassés s'additionnent d'une partie à l'autre."));
		var toggle:js.html.InputElement = cast doc.createInputElement();
		toggle.type = "checkbox";
		toggle.checked = all;
		toggle.onchange = () -> {
			setPref("spoil", toggle.checked ? "1" : "0");
			show("quetes");
		};
		var lab = el("label", "spoil");
		lab.appendChild(toggle);
		lab.appendChild(doc.createTextNode(" Montrer aussi les quêtes secrètes et leurs récompenses"));
		p.appendChild(lab);
		if (listOpen.childElementCount > 0) {
			p.appendChild(el("h2", "sub", "En cours"));
			p.appendChild(listOpen);
		}
		if (listDone.childElementCount > 0) {
			p.appendChild(el("h2", "sub", "Terminées"));
			p.appendChild(listDone);
		}
		main.appendChild(p);
	}
}

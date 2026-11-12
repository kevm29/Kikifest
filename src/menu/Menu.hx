package menu;

import js.Browser;
import js.html.CanvasElement;
import js.html.Element;
import meta.Quests;
import meta.Save;
import meta.Save.GameRecord;
import meta.Quests.Quest;
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
	static var oldHeroes:Array<{d:String, msg:String, name:String}> = [];
	/** classements par étage du site d'origine (assets/data/classement-anciens.json) */
	static var oldRanking:Dynamic = null;

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
			desc: "Igor et Sandy repartent ensemble dans la grande aventure, sur le même clavier.\n{keys}\nPour jouer à deux chacun chez soi, passez par l'onglet Multijoueur.",
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
			desc: "Un match de football à deux, à coups de bombes, sur le même clavier.\n{keys}",
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
		jobs.push(Browser.window.fetch("assets/data/pantheon-anciens.json").then(r -> r.json()).then(j -> {
			oldHeroes = j.heroes;
			return null;
		}));
		jobs.push(Browser.window.fetch("assets/data/classement-anciens.json").then(r -> r.json()).then(j -> {
			oldRanking = j.floors;
			return null;
		}));
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

		// un seul pseudo : le vôtre (celui de l'autre joueur arrive par le réseau)
		var input:js.html.InputElement = cast doc.getElementById("name");
		input.value = getPref("name", "");
		input.oninput = () -> setPref("name", StringTools.trim(input.value));
		doc.getElementById("pyr").innerHTML = pyramidSvg(-1, 56);
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
		Online.init();
		Browser.window.onhashchange = () -> show(Browser.location.hash.substr(1));
		// lien d'invitation reçu de l'hôte (?code=XXXXX) : onglet Multijoueur
		var code = new js.html.URLSearchParams(Browser.location.search).get("code");
		show(code != null ? "multi" : Browser.location.hash.substr(1));
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
		if (["frigo", "quetes", "classement", "pantheon", "multi", "parametres"].indexOf(view) < 0)
			view = "jouer";
		if (Browser.location.hash.substr(1) != view && !(view == "jouer" && Browser.location.hash == ""))
			Browser.location.hash = view;
		for (c in doc.querySelectorAll(".cube")) {
			var el:Element = cast c;
			el.classList.toggle("on", el.dataset.view == view || (view == "pantheon" && el.dataset.view == "classement"));
		}
		var main = doc.getElementById("main");
		main.innerHTML = "";
		switch (view) {
			case "frigo":
				showFridge(main);
			case "quetes":
				showQuests(main);
			case "classement":
				showRanking(main);
			case "pantheon":
				showPantheon(main);
			case "multi":
				Online.showMulti(main, hostGame, soloUrl());
			case "parametres":
				Online.showSettings(main, v -> (cast doc.getElementById("name") : js.html.InputElement).value = v);
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
			var keys = "Igor : " + Online.keysText(false) + " · Sandy : " + Online.keysText(true);
			for (line in m.desc.split("\n"))
				detail.appendChild(el("p", null, StringTools.replace(line, "{keys}", keys)));
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
				if (m.id == "soccer")
					o.push("set_soc_0"); // terrain du Soccerfest
				Browser.location.href = "jeu.html?mode=" + m.id + (o.length > 0 ? "&options=" + o.join(",") : "");
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

	/** Options cochées dans un mode, plus les options passives gagnées. **/
	static function chosenOptions(m:ModeInfo):Array<String> {
		var o = [for (x in m.options) if (state.options.indexOf(x) >= 0 && getPref("opt." + x, "0") == "1") x];
		for (p in PASSIVE)
			if (state.options.indexOf(p) >= 0)
				o.push(p);
		return o;
	}

	/** Partie en ligne créée par l'hôte : Aventure à deux, avec ses options et ses familles d'objets (bonus de quêtes). **/
	static function hostGame():Dynamic {
		var m = MODES.filter(x -> x.id == "multicoop")[0];
		return {mode: "multicoop", options: chosenOptions(m).join(","), families: state.families.join(",")};
	}

	static function soloUrl():String {
		var o = chosenOptions(MODES[0]);
		return "jeu.html?mode=solo" + (o.length > 0 ? "&options=" + o.join(",") : "");
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

	static function pageTitle(main:Element, light:String, bold:String) {
		var h = el("h1", "ptitle", light + " ");
		h.appendChild(el("b", null, bold));
		main.appendChild(h);
	}

	/** Page « quêtes » du site d'origine : deux tableaux, en cours et complétées. */
	static function showQuests(main:Element) {
		var page = el("div", "page");
		pageTitle(page, "", "quêtes");
		var all = getPref("spoil", "0") == "1";
		var open = [], done = [], hidden = 0;
		for (q in quests.list) {
			var complete = state.done.indexOf(q.id) >= 0;
			var started = q.require.filter(r -> Quests.count(save.items, r.item) > 0).length > 0;
			if (complete)
				done.push(q);
			else if (started || all)
				open.push(q);
			if (!complete && !started)
				hidden++;
		}

		function table(head:String, list:Array<Quest>, empty:String, complete:Bool) {
			var t = el("table", "qtable");
			var tr = el("tr");
			tr.appendChild(el("th", null, head));
			tr.appendChild(el("th", "st", "Statut"));
			t.appendChild(tr);
			if (list.length == 0) {
				var r = el("tr");
				var td = el("td", "empty", empty);
				td.setAttribute("colspan", "2");
				r.appendChild(td);
				t.appendChild(r);
			}
			for (q in list) {
				var txt = questTexts.get(q.id);
				var r = el("tr");
				var td = el("td");
				td.appendChild(el("div", "qname", txt != null ? txt.title : "Quête " + q.id));
				var req = el("div", "reqs");
				var have = 0, need = 0;
				for (rq in q.require) {
					var c = Quests.count(save.items, rq.item);
					have += Std.int(Math.min(c, rq.qty));
					need += rq.qty;
					var cell = el("span", "req" + (c >= rq.qty ? " ok" : ""));
					cell.appendChild(itemIcon(rq.item, 32, c == 0));
					cell.appendChild(el("span", "qty", '${Std.int(Math.min(c, rq.qty))}/${rq.qty}'));
					req.appendChild(cell);
				}
				td.appendChild(req);
				if (txt != null && (complete || all))
					td.appendChild(el("div", "reward", txt.desc));
				r.appendChild(td);
				r.appendChild(el("td", "st", complete ? "Complétée !" : Math.floor(have * 100 / need) + " %"));
				t.appendChild(r);
			}
			page.appendChild(t);
		}
		table("Quêtes en cours", open, "Vous n'avez pas encore initié de quêtes !", false);
		table("Quêtes complétées", done, "Aucune quête complétée ! N'abandonnez pas vos recherches !", true);

		var toggle:js.html.InputElement = cast doc.createInputElement();
		toggle.type = "checkbox";
		toggle.checked = all;
		toggle.onchange = () -> {
			setPref("spoil", toggle.checked ? "1" : "0");
			show("quetes");
		};
		var lab = el("label", "spoil");
		lab.appendChild(toggle);
		lab.appendChild(doc.createTextNode(' Montrer aussi les $hidden quêtes encore secrètes et leurs récompenses'));
		page.appendChild(lab);
		main.appendChild(page);
	}

	// ---------------------------------------------------------------- pyramide et Panthéon

	static var FLOOR_COLORS = ["#f2c230", "#c9a3ec", "#a777d6", "#c64fa0", "#e2445f"];

	/** La pyramide du site : la pointe dorée (Panthéon) puis les étages 1 à 4. `hl` = étage mis en valeur. */
	static function pyramidSvg(hl:Int, size:Int):String {
		var svg = '<svg viewBox="0 0 200 170" width="$size" height="${Std.int(size * 0.85)}" aria-hidden="true">';
		var ys = [0, 34, 68, 102, 136, 166];
		for (f in 0...5) {
			var y0 = ys[f], y1 = ys[f + 1];
			var x0 = 100 - y0 * 0.6, x1 = 100 - y1 * 0.6;
			var col = FLOOR_COLORS[f];
			var op = hl < 0 || hl == f ? 1 : 0.45;
			svg += '<polygon points="$x0,$y0 ${200 - x0},$y0 ${200 - x1},$y1 $x1,$y1" fill="$col" opacity="$op" stroke="#fff" stroke-opacity=".5" stroke-width="${hl == f ? 3 : 1}"/>';
		}
		svg += '<rect x="0" y="164" width="200" height="6" rx="2" fill="#f08a2c"/>';
		return svg + "</svg>";
	}

	static function lastHero():{d:String, msg:String, name:String} {
		var mine = save.heroes.filter(h -> h.msg != null);
		if (mine.length > 0) {
			var h = mine[mine.length - 1];
			return {d: h.d, msg: h.msg, name: h.name};
		}
		return oldHeroes.length > 0 ? oldHeroes[0] : null;
	}

	static function quote(h:{d:String, msg:String, name:String}):Element {
		var q = el("div", "quote");
		q.appendChild(el("p", null, h.msg));
		q.appendChild(el("div", "sig", h.d + (h.name != null ? "  " + h.name : "")));
		return q;
	}

	/** Pour un héros qui vient d'entrer au Panthéon : écrire sa phrase. */
	static function heroForm(page:Element) {
		for (h in save.heroes) {
			if (h.msg != null)
				continue;
			var box = el("div", "heroform");
			box.appendChild(el("h3", null, 'Bravo ${h.name} ! Avec ${fmt(h.score)} points, vous entrez au Panthéon.'));
			box.appendChild(el("p", null, "Laissez quelques paroles pleines de sagesse pour l'éternité :"));
			var ta:js.html.TextAreaElement = cast doc.createElement("textarea");
			ta.maxLength = 600;
			box.appendChild(ta);
			var b = el("a", "button", "Graver dans la pierre");
			b.onclick = () -> {
				var m = StringTools.trim(ta.value);
				h.msg = m == "" ? "----" : m;
				save.store();
				show(Browser.location.hash.substr(1));
			};
			box.appendChild(b);
			page.appendChild(box);
			return;
		}
	}

	static function fmt(n:Int):String {
		var s = Std.string(n), r = "";
		while (s.length > 3) {
			r = "." + s.substr(s.length - 3) + r;
			s = s.substr(0, s.length - 3);
		}
		return s + r;
	}

	static function showRanking(main:Element) {
		var page = el("div", "page");
		var top = el("div", "pyramid");
		top.innerHTML = pyramidSvg(Save.floorOf(save.best), 240);
		page.appendChild(top);
		heroForm(page);
		var h = lastHero();
		if (h != null) {
			page.appendChild(el("p", "said", (save.heroes.filter(x -> x.msg != null).length > 0 ? "Le dernier héros de Kikifest" : "Le dernier héros d'Hammerfest") + ", a dit :"));
			page.appendChild(quote(h));
		}
		var link = el("p", "center");
		var a = el("a", null, "[ Voir le panthéon ]");
		a.setAttribute("href", "#pantheon");
		link.appendChild(a);
		page.appendChild(link);

		// meilleure partie de chaque joueur, rangée par étage (comme les classements hebdomadaires du site)
		var best = new Map<String, GameRecord>();
		for (r in save.history) {
			var b = best.get(r.name);
			if (b == null || r.score > b.score || (r.score == b.score && r.level > b.level))
				best.set(r.name, r);
		}
		var rows = [for (r in best) r];
		rows.sort((x, y) -> y.score - x.score);
		for (f in [4, 3, 2, 1]) {
			// anciens joueurs de cet étage (captures du site) + vos meilleures parties, rangés au score
			var olds:Array<{pos:Int, name:String, level:Int, score:Int}> = oldRanking != null ? Reflect.field(oldRanking, Std.string(f)) : null;
			var list:Array<{pos:Int, name:String, level:Int, score:Int, mine:Bool}> = [];
			if (olds != null)
				for (o in olds)
					list.push({pos: o.pos, name: o.name, level: o.level, score: o.score, mine: false});
			for (r in rows)
				if (Save.floorOf(r.score) == f)
					list.push({pos: 0, name: r.name, level: r.level, score: r.score, mine: true});
			list.sort((x, y) -> y.score != x.score ? y.score - x.score : (x.mine ? -1 : 1));

			page.appendChild(el("h2", "floor", 'Classement de l\'étage $f :'));
			var t = el("table", "rank");
			var tr = el("tr");
			for (c in ["Position", "Joueur", "Niveau atteint", "Score"])
				tr.appendChild(el("th", null, c));
			t.appendChild(tr);
			var shift = 0, last = 0;
			for (x in list) {
				var pos = x.mine ? last + 1 : x.pos + shift;
				if (x.mine)
					shift++;
				if (pos > last + 1) { // trou dans les captures d'origine
					var gap = el("tr");
					var td = el("td", "gap", "…");
					td.setAttribute("colspan", "4");
					gap.appendChild(td);
					t.appendChild(gap);
				}
				last = pos;
				var r = el("tr", x.mine ? "mine" : null);
				r.appendChild(el("td", "num", Std.string(pos)));
				r.appendChild(el("td", "who", x.name));
				r.appendChild(el("td", "num", Std.string(x.level)));
				r.appendChild(el("td", "num", fmt(x.score)));
				t.appendChild(r);
			}
			page.appendChild(t);
			var next = el("p", "next", "Score à atteindre pour la prochaine montée : ");
			next.appendChild(el("b", null, fmt(Save.FLOORS[4 - f]) + " points"));
			page.appendChild(next);
		}

		// dernières parties
		if (save.history.length > 0) {
			page.appendChild(el("h2", "floor", "Vos dernières parties :"));
			var t = el("table", "rank");
			var tr = el("tr");
			for (c in ["Date", "Joueur", "Mode", "Niveau atteint", "Score"])
				tr.appendChild(el("th", null, c));
			t.appendChild(tr);
			var h = save.history.copy();
			h.reverse();
			for (g in h.slice(0, 20)) {
				var r = el("tr");
				r.appendChild(el("td", null, g.d));
				r.appendChild(el("td", "who", g.name));
				r.appendChild(el("td", null, g.mode == "multicoop" ? "À deux" : "Aventure"));
				r.appendChild(el("td", "num", Std.string(g.level)));
				r.appendChild(el("td", "num", fmt(g.score)));
				t.appendChild(r);
			}
			page.appendChild(t);
		}
		main.appendChild(page);
	}

	static function showPantheon(main:Element) {
		var page = el("div", "page");
		var top = el("div", "pyramid");
		top.innerHTML = pyramidSvg(0, 200);
		page.appendChild(top);
		pageTitle(page, "le", "panthéon");
		page.appendChild(el("p", null, "Les plus courageux et plus talentueux joueurs ont leur place pour l'éternité au Panthéon ! Vous aussi devenez une légende de Kikifest ! Il faut pour cela dépasser "
			+ fmt(Save.FLOORS[3]) + " points en une partie d'Aventure."));
		heroForm(page);
		var h = lastHero();
		if (h != null) {
			page.appendChild(el("p", "said", "Le nouveau héros" + (h.name != null ? " " + h.name : "") + ", les mains gelées d'avoir trop joué, a dit :"));
			page.appendChild(quote(h));
		}

		function hall(title:String, list:Array<{d:String, msg:String, name:String}>) {
			page.appendChild(el("h2", "hall", title));
			var t = el("table", "rank heroes");
			var tr = el("tr");
			for (c in ["Date", "Joueur", "Paroles pleines de sagesse"])
				tr.appendChild(el("th", null, c));
			t.appendChild(tr);
			for (x in list) {
				var r = el("tr");
				r.appendChild(el("td", "date", x.d));
				r.appendChild(el("td", x.name != null ? "who" : "who anon", x.name != null ? x.name : "un héros"));
				r.appendChild(el("td", "words", x.msg));
				t.appendChild(r);
			}
			page.appendChild(t);
		}
		var mine = [for (x in save.heroes) if (x.msg != null) {d: x.d, msg: x.msg, name: x.name}];
		mine.reverse();
		if (mine.length > 0)
			hall("Le hall des Héros de Kikifest", mine);
		hall("Le hall des Héros de Hammerfest", oldHeroes);
		main.appendChild(page);
	}
}

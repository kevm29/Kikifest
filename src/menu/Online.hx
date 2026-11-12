package menu;

import js.Browser;
import js.html.Element;
import meta.Settings;

/**
	Onglets « Multijoueur » (créer ou rejoindre une partie hébergée, avec KikiNet)
	et « Paramètres » (volumes, pseudo, touches) du menu.
**/
class Online {
	static var doc = Browser.document;

	static function el(tag:String, ?cls:String, ?text:String):Element {
		var e = doc.createElement(tag);
		if (cls != null)
			e.className = cls;
		if (text != null)
			e.textContent = text;
		return e;
	}

	static function button(text:String, f:Void->Void, ?cls:String):Element {
		var b = el("a", cls != null ? cls : "button", text);
		b.onclick = f;
		return b;
	}

	// ---------------------------------------------------------------- multijoueur

	/** Peer en cours (une seule partie à la fois) **/
	static var busy = false;

	/**
		@param start  options de la partie de l'hôte : { mode, options, families }
		@param soloUrl  adresse de l'Aventure en solo (sans Sandy)
	**/
	public static function showMulti(main:Element, hostGame:Void->Dynamic, soloUrl:String) {
		var p = el("div", "panel wide");
		p.appendChild(el("h2", null, "Jouer à deux en ligne"));
		main.appendChild(p);
		var kiki:Dynamic = untyped js.Browser.window.KikiNet;
		if (kiki == null || Browser.location.protocol == "file:") {
			p.appendChild(el("p", null, "Le jeu à deux en ligne passe par le serveur de l'hôte : lancez Heberger-Windows.bat (ou Heberger-Mac.command), puis ouvrez http://localhost:8080/."));
			return;
		}
		var body = el("div");
		p.appendChild(body);

		var urlCode = new js.html.URLSearchParams(Browser.location.search).get("code");
		if (urlCode != null && !busy) {
			join(body, urlCode);
			return;
		}

		body.appendChild(el("p", null, "L'un de vous deux héberge la partie (il a lancé le serveur sur son ordinateur) et envoie le lien à l'autre. "
			+ "Chacun joue sur son propre clavier, avec les touches choisies dans les Paramètres."));
		body.appendChild(el("p", null, "L'hôte joue Igor, l'invité joue Sandy. La partie démarre avec les bonus de quêtes de l'hôte ; "
			+ "les objets ramassés s'ajoutent au frigo de chacun."));

		var box = el("div", "options");
		box.appendChild(el("h3", null, "Créer une partie"));
		box.appendChild(button("Créer une partie et inviter quelqu'un", () -> host(body, hostGame, soloUrl)));
		body.appendChild(box);

		var box2 = el("div", "options");
		box2.appendChild(el("h3", null, "Rejoindre une partie"));
		var row = el("div", "row");
		var input:js.html.InputElement = cast doc.createInputElement();
		input.placeholder = "Code";
		input.maxLength = 5;
		input.className = "code";
		input.onkeydown = (e:js.html.KeyboardEvent) -> if (e.key == "Enter") join(body, input.value);
		row.appendChild(input);
		row.appendChild(button("Rejoindre", () -> join(body, input.value), "button small"));
		box2.appendChild(row);
		body.appendChild(box2);

		var solo = el("p", "note");
		solo.appendChild(doc.createTextNode("Personne avec qui jouer ? "));
		var a:js.html.AnchorElement = cast el("a", null, "Jouer seul l'Aventure (sans Sandy)");
		a.href = soloUrl;
		solo.appendChild(a);
		body.appendChild(solo);
	}

	static function statusLine(parent:Element):Element {
		var s = el("p", "netstatus");
		parent.appendChild(s);
		return s;
	}

	static function fail(body:Element, e:Dynamic) {
		busy = false;
		body.innerHTML = "";
		body.appendChild(el("p", "warn", "Oups : " + (e != null && e.message != null ? e.message : Std.string(e))));
		body.appendChild(button("Recommencer", () -> Browser.location.href = "index.html#multi"));
	}

	static function host(body:Element, hostGame:Void->Dynamic, soloUrl:String) {
		if (busy)
			return;
		busy = true;
		body.innerHTML = "";
		body.appendChild(el("p", null, "Partie créée ! Envoyez ce lien à l'autre joueur :"));
		var links = el("div", "links");
		body.appendChild(links);
		var code = el("p", "bigcode", "…");
		var st = statusLine(body);
		var note = el("p", "note");
		body.appendChild(note);
		var solo = el("p", "note");
		var a:js.html.AnchorElement = cast el("a", null, "Personne ne vient ? Jouer seul (sans Sandy)");
		a.href = soloUrl;
		solo.appendChild(a);
		body.appendChild(solo);

		var kiki:Dynamic = untyped js.Browser.window.KikiNet;
		var pr:js.lib.Promise<Dynamic> = kiki.host({
			onCode: (c:String) -> {
				code.textContent = "Code : " + c;
				showLinks(links, note, c);
			},
			onStatus: (s:String) -> st.textContent = s
		});
		links.parentElement.insertBefore(code, links.nextSibling);
		pr.then(peer -> {
			st.textContent = "L'autre joueur est là ! Lancement…";
			peer.onclose = (r:Dynamic) -> fail(body, "L'autre joueur est parti.");
			peer.onmessage = (data:Dynamic, reliable:Bool) -> {
				if (!reliable || !Std.isOfType(data, String))
					return;
				var m:Dynamic = try haxe.Json.parse(data) catch (e:Dynamic) null;
				if (m == null || m.t != "hello")
					return;
				var g:Dynamic = hostGame();
				var guestName:String = m.name != null && StringTools.trim(m.name) != "" ? m.name : "Sandy";
				var cfg = {
					t: "start",
					mode: g.mode,
					options: g.options,
					families: g.families,
					seed: Std.int(peer.seed) & 0x7fffffff,
					names: [Settings.name(), guestName.substr(0, 20)]
				};
				peer.sendReliable(haxe.Json.stringify(cfg));
				launch(peer, cfg);
			};
			return null;
		}, e -> {
			fail(body, e);
			return null;
		});
	}

	static function copyable(label:String, url:String):Element {
		var wrap = el("div", "copy");
		wrap.appendChild(el("div", "label", label));
		var row = el("div", "row");
		var link = el("div", "link", url);
		row.appendChild(link);
		var btn = el("a", "button small", "Copier");
		btn.onclick = () -> {
			var nav:Dynamic = Browser.navigator;
			try {
				nav.clipboard.writeText(url);
			} catch (e:Dynamic) {
				var r = doc.createRange();
				r.selectNodeContents(link);
				Browser.window.getSelection().removeAllRanges();
				Browser.window.getSelection().addRange(r);
				doc.execCommand("copy");
			}
			btn.textContent = "Copié !";
			Browser.window.setTimeout(() -> btn.textContent = "Copier", 1500);
		};
		row.appendChild(btn);
		wrap.appendChild(row);
		return wrap;
	}

	/** Liens d'invitation : par internet (tunnel ou adresse publique) et sur le même réseau (adresses locales). **/
	static function showLinks(links:Element, note:Element, code:String) {
		Browser.window.fetch("api/info").then(r -> r.json()).then((info:Dynamic) -> {
			// le serveur prépare la connexion par internet (pare-feu, box, vérification, tunnel) pendant quelques secondes
			if (info != null && info.ready != true) {
				if (links.childNodes.length == 0)
					links.appendChild(el("p", "note", "Préparation du lien par internet…"));
				Browser.window.setTimeout(() -> showLinks(links, note, code), 1500);
				return null;
			}
			links.innerHTML = "";
			var host = Browser.location.hostname;
			var local = host == "localhost" || host == "127.0.0.1" || host == "[::1]";
			var port = Browser.location.port != "" ? ":" + Browser.location.port : "";
			var lan:Array<String> = info != null && info.lan != null ? info.lan : [];
			if (!local)
				links.appendChild(copyable("Lien à envoyer", Browser.location.protocol + "//" + Browser.location.host + "/?code=" + code));
			else if (info != null) {
				if (info.tunnelUrl != null)
					links.appendChild(copyable("Lien à envoyer (par internet)", info.tunnelUrl + "/?code=" + code));
				else if (info.publicIp != null)
					links.appendChild(copyable("Lien à envoyer (par internet)", "http://" + info.publicIp + port + "/?code=" + code));
				for (ip in lan)
					links.appendChild(copyable("Lien si l'autre joueur est chez vous (même Wi-Fi)", "http://" + ip + port + "/?code=" + code));
			}
			if (info != null && local) {
				note.className = "note";
				if (info.tunnelUrl != null)
					note.textContent = "Le lien par internet passe par un tunnel gratuit : rien à régler sur votre box. Il change à chaque lancement du serveur.";
				else if (info.reachable == true)
					note.textContent = 'Vérifié : votre ordinateur est bien joignable par internet (port ${info.port}).';
				else {
					note.textContent = 'Attention : le port ${info.port} ne semble pas joignable depuis internet, le lien par internet risque de ne pas marcher. '
						+ 'Relancez le serveur avec « --tunnel », ou voir docs/HEBERGER.md. Sur le même Wi-Fi, ça marche sans rien faire.';
					note.className = "note warn";
				}
			}
			return null;
		}).catchError(_ -> {
			links.innerHTML = "";
			links.appendChild(copyable("Code de la partie", code));
		});
	}

	static function join(body:Element, code:String) {
		code = ~/[^A-Z0-9]/g.replace(code.toUpperCase(), "");
		if (code.length != 5 || busy)
			return;
		busy = true;
		Browser.window.history.replaceState(null, "", "?code=" + code + "#multi");
		body.innerHTML = "";
		body.appendChild(el("p", null, "Connexion à la partie " + code + "…"));
		var st = statusLine(body);
		var kiki:Dynamic = untyped js.Browser.window.KikiNet;
		var pr:js.lib.Promise<Dynamic> = kiki.join(code, {onStatus: (s:String) -> st.textContent = s});
		pr.then(peer -> {
			st.textContent = "Connecté ! En attente du lancement par l'hôte…";
			peer.onclose = (r:Dynamic) -> fail(body, "L'hôte a fermé la partie.");
			peer.onmessage = (data:Dynamic, reliable:Bool) -> {
				if (!reliable || !Std.isOfType(data, String))
					return;
				var m:Dynamic = try haxe.Json.parse(data) catch (e:Dynamic) null;
				if (m != null && m.t == "start")
					launch(peer, m);
			};
			peer.sendReliable(haxe.Json.stringify({t: "hello", name: guestName()}));
			return null;
		}, e -> {
			fail(body, e);
			return null;
		});
	}

	/** Pseudo de l'invité : celui des paramètres, ou Sandy s'il n'en a pas choisi. **/
	static function guestName():String {
		var v:String = null;
		try
			v = Browser.window.localStorage.getItem("kikifest.name")
		catch (e:Dynamic) {}
		return v != null && StringTools.trim(v) != "" ? StringTools.trim(v) : "Sandy";
	}

	/** Remplace le menu par le jeu, dans la même page (la connexion doit rester ouverte). **/
	static function launch(peer:Dynamic, cfg:Dynamic) {
		peer.onclose = null;
		peer.onmessage = null;
		untyped js.Browser.window.KIKI_NET = {
			peer: peer,
			mode: cfg.mode,
			options: cfg.options,
			families: cfg.families,
			seed: cfg.seed,
			names: cfg.names
		};
		doc.title = "Kikifest à deux";
		doc.body.className = "playing";
		doc.body.innerHTML = '<canvas id="game"></canvas><div id="status">Chargement…</div>'
			+ '<div class="help">' + StringTools.htmlEscape(cfg.names[0]) + ' (Igor) et ' + StringTools.htmlEscape(cfg.names[1])
			+ ' (Sandy) · chacun avec ses touches · P : pause</div>';
		var s = doc.createScriptElement();
		s.src = "js/game.js";
		doc.body.appendChild(s);
	}

	// ---------------------------------------------------------------- paramètres

	static var capture:js.html.KeyboardEvent->Void = null;

	public static function showSettings(main:Element, onName:String->Void) {
		var d = Settings.load();
		var p = el("div", "panel wide settings");
		p.appendChild(el("h2", null, "Paramètres"));

		var box = el("div", "options");
		box.appendChild(el("h3", null, "Pseudo"));
		var name:js.html.InputElement = cast doc.createInputElement();
		name.maxLength = 20;
		var cur:String = null;
		try
			cur = Browser.window.localStorage.getItem("kikifest.name")
		catch (e:Dynamic) {}
		name.value = cur != null ? cur : "";
		name.placeholder = "Igor";
		name.oninput = () -> {
			Settings.setName(name.value);
			onName(name.value);
		};
		box.appendChild(name);
		box.appendChild(el("p", "note", "Affiché à l'autre joueur en ligne, et au classement."));
		p.appendChild(box);

		var vol = el("div", "options");
		vol.appendChild(el("h3", null, "Son"));
		for (k in [{id: "music", name: "Musique"}, {id: "sfx", name: "Bruitages"}]) {
			var lab = el("label", "slider");
			lab.appendChild(el("span", "lbl", k.name));
			var r:js.html.InputElement = cast doc.createInputElement();
			r.type = "range";
			r.min = "0";
			r.max = "100";
			r.value = Std.string(Reflect.field(d, k.id));
			var val = el("span", "val", r.value + " %");
			r.oninput = () -> {
				Reflect.setField(d, k.id, Std.parseInt(r.value));
				val.textContent = r.value + " %";
				Settings.store(d);
			};
			lab.appendChild(r);
			lab.appendChild(val);
			vol.appendChild(lab);
		}
		p.appendChild(vol);

		var keys = el("div", "options");
		keys.appendChild(el("h3", null, "Touches"));
		keys.appendChild(el("p", "note", "Cliquez sur une touche puis appuyez sur la nouvelle. "
			+ "En ligne, chacun joue avec ses propres touches, celles de la colonne « Vous ». "
			+ "La 2e colonne sert au 2e joueur sur le même clavier (Aventure à deux en local)."));
		var t = el("table", "keys");
		var head = el("tr");
		for (h in ["", "Vous (Igor, ou seul)", "2e joueur (même clavier)"])
			head.appendChild(el("th", null, h));
		t.appendChild(head);
		var buttons:Array<{b:Element, set:String, id:String}> = [];
		function refresh() {
			for (x in buttons)
				x.b.textContent = Settings.label(d, Reflect.field(Reflect.field(d, x.set), x.id));
		}
		for (a in Settings.ACTIONS) {
			var tr = el("tr");
			tr.appendChild(el("td", "act", a.name));
			for (set in ["keys", "keys2"]) {
				var td = el("td");
				var b = el("a", "key");
				b.onclick = () -> {
					refresh();
					b.textContent = "Appuyez…";
					b.classList.add("wait");
					capture = (e:js.html.KeyboardEvent) -> {
						capture = null;
						b.classList.remove("wait");
						if (e.code != "Escape" && e.code != "") {
							Reflect.setField(Reflect.field(d, set), a.id, e.code);
							var lbl = e.key != null && e.key.length == 1 && e.key != " " ? e.key.toUpperCase() : null;
							if (lbl != null)
								Reflect.setField(d.labels, e.code, lbl);
							Settings.store(d);
						}
						refresh();
					};
				};
				buttons.push({b: b, set: set, id: a.id});
				td.appendChild(b);
				tr.appendChild(td);
			}
			t.appendChild(tr);
		}
		keys.appendChild(t);
		keys.appendChild(el("p", "note", "Échap : quitter la partie (en solo ou sur le même clavier)."));
		keys.appendChild(button("Touches par défaut", () -> {
			d.keys = Settings.defaultKeys();
			d.keys2 = Settings.defaultKeys2();
			Settings.store(d);
			refresh();
		}, "button small"));
		p.appendChild(keys);
		refresh();
		main.appendChild(p);
	}

	public static function init() {
		Browser.window.addEventListener("keydown", (e:js.html.KeyboardEvent) -> {
			if (capture != null) {
				e.preventDefault();
				capture(e);
			}
		}, true);
	}

	/** Touches d'un joueur, pour les textes d'aide (« Flèches + Espace »). **/
	public static function keysText(second:Bool):String {
		var d = Settings.load();
		var k = second ? d.keys2 : d.keys;
		var dirs = [k.left, k.up, k.right, k.down];
		var arrows = dirs.join(",") == "ArrowLeft,ArrowUp,ArrowRight,ArrowDown";
		return (arrows ? "flèches" : [for (c in [k.up, k.left, k.down, k.right]) Settings.label(d, c)].join(" ")) + " + " + Settings.label(d, k.bomb);
	}
}

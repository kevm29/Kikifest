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

	/**
		État de la partie en ligne, gardé quand on change d'onglet : le salon vit dans `box`,
		un élément créé une fois et raccroché à chaque affichage de l'onglet Multijoueur.
	**/
	static var box:Element = null;

	/** Liaisons ouvertes : chez l'hôte, une par invité ; chez un invité, celle vers l'hôte. **/
	static var peers:Array<Dynamic> = [];

	static var peer(get, never):Dynamic;

	static function get_peer():Dynamic
		return peers.length > 0 ? peers[0] : null;

	static var isHost = false;
	static var hostGame:Void->Dynamic;
	static var myReady = false;

	/** Mon numéro dans le salon : 0 pour l'hôte, sinon la place donnée par le serveur. **/
	static var myId = 0;

	/** Joueurs du salon, dans l'ordre (l'hôte d'abord) ; tenu par l'hôte, recopié chez les invités. **/
	static var players:Array<{id:Int, name:String, ready:Bool}> = [];

	/** Joueurs de la partie en cours (leurs numéros), dans l'ordre des personnages. **/
	static var inGameIds:Array<Int> = [];

	static var round = 0;
	static var inGame = false;
	static var savedBody:Array<js.html.Node> = null;
	static var savedTitle:String;
	static var resultLine:Element = null;

	static inline var MAX_PLAYERS = 4;
	static var CHARACTERS = ["Igor", "Sandy", "Igor vert", "Igor bleu"];

	public static function showMulti(main:Element, hostGameF:Void->Dynamic, soloUrl:String) {
		hostGame = hostGameF;
		var p = el("div", "panel wide");
		p.appendChild(el("h2", null, "Jouer en ligne (2 à 4)"));
		main.appendChild(p);
		var kiki:Dynamic = untyped js.Browser.window.KikiNet;
		if (kiki == null || Browser.location.protocol == "file:") {
			p.appendChild(el("p", null, "Le jeu à deux en ligne passe par le serveur de l'hôte : lancez Heberger-Windows.bat (ou Heberger-Mac.command), puis ouvrez http://localhost:8080/."));
			return;
		}
		if (box != null) {
			// une partie est en cours de création ou un joueur est déjà là : on la remontre telle quelle
			p.appendChild(box);
			return;
		}
		var body = el("div");
		p.appendChild(body);

		var urlCode = new js.html.URLSearchParams(Browser.location.search).get("code");
		if (urlCode != null) {
			join(p, urlCode);
			body.remove();
			return;
		}

		body.appendChild(el("p", null, "1. Celui qui a lancé le serveur clique sur « Créer une partie » et envoie le lien aux autres (jusqu'à 3)."));
		body.appendChild(el("p", null, "2. Les autres ouvrent le lien : vous vous retrouvez dans le salon, où chacun choisit son pseudo."));
		body.appendChild(el("p", null, "3. Chacun clique sur « Je suis prêt » : la partie démarre chez tout le monde, avec autant de personnages que de joueurs (Igor, Sandy, Igor vert, Igor bleu), chacun sur son clavier avec ses touches (onglet Paramètres)."));

		var b1 = el("div", "options");
		b1.appendChild(el("h3", null, "Créer une partie"));
		b1.appendChild(button("Créer une partie et inviter quelqu'un", () -> {
			body.remove();
			host(p);
		}));
		body.appendChild(b1);

		var b2 = el("div", "options");
		b2.appendChild(el("h3", null, "Rejoindre une partie"));
		var row = el("div", "row");
		var input:js.html.InputElement = cast doc.createInputElement();
		input.placeholder = "Code";
		input.maxLength = 5;
		input.className = "code";
		var go = () -> {
			if (~/^[A-Za-z0-9]{5}$/.match(StringTools.trim(input.value))) {
				body.remove();
				join(p, input.value);
			}
		};
		input.onkeydown = (e:js.html.KeyboardEvent) -> if (e.key == "Enter") go();
		row.appendChild(input);
		row.appendChild(button("Rejoindre", go, "button small"));
		b2.appendChild(row);
		body.appendChild(b2);

		var solo = el("p", "note");
		solo.appendChild(doc.createTextNode("Personne avec qui jouer ? "));
		var a:js.html.AnchorElement = cast el("a", null, "Jouer seul l'Aventure (sans Sandy)");
		a.href = soloUrl;
		solo.appendChild(a);
		body.appendChild(solo);
	}

	static function newBox(parent:Element):Element {
		box = el("div");
		parent.appendChild(box);
		return box;
	}

	static function fail(e:Dynamic) {
		var msg = e != null && e.message != null ? e.message : Std.string(e);
		for (q in peers)
			try q.close() catch (_:Dynamic) {}
		peers = [];
		if (hostRoom != null)
			try hostRoom.close() catch (_:Dynamic) {}
		hostRoom = null;
		if (box == null)
			return;
		box.innerHTML = "";
		box.appendChild(el("p", "warn", "Oups : " + msg));
		box.appendChild(button("Revenir au début", () -> Browser.location.href = "index.html#multi"));
	}

	static function host(parent:Element) {
		var b = newBox(parent);
		var title = el("p", null, "Partie créée ! Envoyez ce lien à l'autre joueur (Discord, SMS…) :");
		b.appendChild(title);
		var links = el("div", "links");
		b.appendChild(links);
		var code = el("p", "bigcode", "…");
		b.appendChild(code);
		var st = el("p", "netstatus");
		b.appendChild(st);
		var note = el("p", "note");
		b.appendChild(note);
		b.appendChild(el("p", "note", "Vous pouvez changer d'onglet en attendant (paramètres, frigo…) : la partie reste ouverte."));

		var kiki:Dynamic = untyped js.Browser.window.KikiNet;
		isHost = true;
		myId = 0;
		players = [{id: 0, name: myName(), ready: false}];
		var pr:js.lib.Promise<Dynamic> = kiki.host({
			onCode: (c:String) -> {
				code.textContent = "Code : " + c;
				showLinks(links, note, c);
			},
			onStatus: (s:String) -> st.textContent = s,
			onPeer: (p:Dynamic) -> addGuest(p),
			onClosed: () -> if (peers.length == 0) fail("Le serveur s'est arrêté.")
		});
		pr.then(r -> {
			hostRoom = r;
			return null;
		}, e -> {
			fail(e);
			return null;
		});
	}

	static var hostRoom:Dynamic = null;

	/** Hôte : un invité vient de se connecter. **/
	static function addGuest(p:Dynamic) {
		var first = peers.length == 0;
		peers.push(p);
		var id:Int = p.slot != null ? Std.int(p.slot) : peers.length;
		players.push({id: id, name: "Joueur " + (players.length + 1), ready: false});
		p.onclose = (r:Dynamic) -> guestLeft(p, id);
		listen(p);
		if (first)
			buildLobby();
		broadcastLobby();
		refresh();
	}

	/** Hôte : un invité est parti (fermeture de sa page, réseau coupé). **/
	static function guestLeft(p:Dynamic, id:Int) {
		peers.remove(p);
		var name = nameOf(id);
		players = players.filter(x -> x.id != id);
		if (inGame && inGameIds.indexOf(id) >= 0) {
			// à plus de deux, la partie ne peut pas continuer sans lui : tout le monde revient au salon
			if (inGameIds.length > 2) {
				sendAll({t: "left", name: name});
				stopGameAndReturn(name + " a quitté la partie.");
			}
		} else if (resultLine != null)
			resultLine.textContent = name + " est parti.";
		broadcastLobby();
		refresh();
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

	static function join(parent:Element, code:String) {
		code = ~/[^A-Z0-9]/g.replace(code.toUpperCase(), "");
		var b = newBox(parent);
		Browser.window.history.replaceState(null, "", "index.html?code=" + code + "#multi");
		b.appendChild(el("p", null, "Connexion à la partie " + code + "…"));
		var st = el("p", "netstatus");
		b.appendChild(st);
		var kiki:Dynamic = untyped js.Browser.window.KikiNet;
		isHost = false;
		var pr:js.lib.Promise<Dynamic> = kiki.join(code, {onStatus: (s:String) -> st.textContent = s});
		pr.then(p -> {
			peers = [p];
			myId = -1; // donné par l'hôte dans son premier message
			players = [];
			p.onclose = (r:Dynamic) -> {
				if (inGame)
					stopGameAndReturn(null);
				fail("L'hôte s'est déconnecté" + (r != null ? " (" + r + ")" : "") + ".");
			};
			listen(p);
			buildLobby();
			send(p, {t: "hello", name: myName()});
			return null;
		}, e -> {
			fail(e);
			return null;
		});
	}

	static function myName():String {
		var v:String = null;
		try
			v = Browser.window.localStorage.getItem("kikifest.name")
		catch (e:Dynamic) {}
		if (v != null && StringTools.trim(v) != "")
			return StringTools.trim(v).substr(0, 20);
		return isHost ? "Igor" : "Sandy";
	}

	static function cleanName(n:Dynamic, def:String):String {
		var s = StringTools.trim(Std.string(n));
		return s == "" || n == null ? def : s.substr(0, 20);
	}

	static function nameOf(id:Int):String {
		for (x in players)
			if (x.id == id)
				return x.name;
		return "Un joueur";
	}

	static function send(p:Dynamic, m:Dynamic) {
		if (p != null)
			try p.sendReliable(haxe.Json.stringify(m)) catch (e:Dynamic) {}
	}

	/** Hôte : à tous les invités ; invité : à l'hôte. **/
	static function sendAll(m:Dynamic) {
		for (q in peers)
			send(q, m);
	}

	/** Messages fiables du salon, reçus d'une liaison. **/
	static function listen(p:Dynamic) {
		p.onmessage = (data:Dynamic, reliable:Bool) -> onReliable(p, data);
	}

	static function onReliable(p:Dynamic, data:Dynamic) {
		if (!Std.isOfType(data, String))
			return;
		var m:Dynamic = try haxe.Json.parse(data) catch (e:Dynamic) null;
		if (m != null)
			onLobbyMessage(p, m);
	}

	static function guestId(p:Dynamic):Int
		return p.slot != null ? Std.int(p.slot) : 1;

	/** Hôte : envoie à chaque invité l'état du salon (avec son propre numéro). **/
	static function broadcastLobby() {
		if (!isHost)
			return;
		for (q in peers)
			send(q, {
				t: "lobby",
				you: guestId(q),
				players: players,
				inGame: inGame ? inGameIds : null
			});
	}

	static var refresh:Void->Void = () -> {};

	/** Salon d'attente : liste des joueurs, pseudo, « Je suis prêt ». **/
	static function buildLobby() {
		box.innerHTML = "";
		box.appendChild(el("p", "ok", "Vous êtes connectés !"));
		resultLine = el("p", "result");
		box.appendChild(resultLine);
		var t = el("table", "lobby");
		box.appendChild(t);

		var input:js.html.InputElement = cast doc.createInputElement();
		input.maxLength = 20;
		input.value = myName();
		input.placeholder = "Votre pseudo";
		input.oninput = () -> {
			Settings.setName(input.value);
			var head:js.html.InputElement = cast doc.getElementById("name");
			if (head != null)
				head.value = input.value;
			setMine(x -> x.name = myName());
			if (isHost)
				broadcastLobby();
			else
				sendAll({t: "name", name: myName()});
			refresh();
		};
		input.onchange = () -> if (onNameChanged != null) onNameChanged();

		var readyBtn = button("Je suis prêt !", () -> {
			resultLine.textContent = "";
			myReady = !myReady;
			setMine(x -> x.ready = myReady);
			if (isHost) {
				broadcastLobby();
				maybeStart();
			} else
				sendAll({t: "ready", ready: myReady});
			refresh();
		});
		box.appendChild(readyBtn);
		var hint = el("p", "note");
		box.appendChild(hint);
		var ping = el("p", "note");
		box.appendChild(ping);
		var p0 = peer;

		refresh = () -> {
			// le champ du pseudo est gardé d'un affichage à l'autre (sinon il perdrait le focus)
			if (input.parentNode != null)
				input.parentNode.removeChild(input);
			t.innerHTML = "";
			var k = 0;
			for (x in players) {
				var tr = el("tr");
				var mine = x.id == myId;
				var role = k < MAX_PLAYERS ? CHARACTERS[k] : "?";
				tr.appendChild(el("td", "who", role + (x.id == 0 ? " (hôte)" : "")));
				var td = el("td", mine ? null : "other");
				if (mine) {
					td.appendChild(input);
					td.appendChild(el("span", "note", " ← vous"));
				} else
					td.textContent = x.name;
				tr.appendChild(td);
				var waiting = inGame && inGameIds.indexOf(x.id) < 0;
				tr.appendChild(el("td", "state", waiting ? "attend la prochaine partie" : (x.ready ? "✔ prêt" : "pas encore prêt")));
				t.appendChild(tr);
				k++;
			}
			readyBtn.textContent = myReady ? "Finalement, pas encore" : "Je suis prêt !";
			hint.textContent = "Vos touches : " + keysText(false) + " · P : pause. La partie démarre quand tout le monde est prêt"
				+ (isHost ? " (vous pouvez encore inviter " + (MAX_PLAYERS - players.length) + " joueur" + (MAX_PLAYERS - players.length > 1 ? "s" : "") + " avec le même lien)." : ".");
			if (players.length >= MAX_PLAYERS && isHost)
				hint.textContent = "Vos touches : " + keysText(false) + " · P : pause. La partie est complète (4 joueurs) : elle démarre quand tout le monde est prêt.";
			var q = peer;
			ping.textContent = q == null ? "" : peers.map(z -> (z.transport == "webrtc" ? "liaison directe" : "liaison par le serveur") + " · ping " + Math.round(z.rtt) + " ms").join(" — ");
		};
		refresh();
		var timer = 0;
		timer = Browser.window.setInterval(() -> if (peers.length > 0 && box.isConnected) refresh() else if (peers.length == 0) Browser.window.clearInterval(timer), 1000);
		// on ramène l'onglet Multijoueur au premier plan
		if (Browser.location.hash != "#multi")
			Browser.location.hash = "multi";
	}

	static function setMine(f:{id:Int, name:String, ready:Bool}->Void) {
		for (x in players)
			if (x.id == myId)
				f(x);
	}

	static function onLobbyMessage(from:Dynamic, m:Dynamic) {
		if (isHost) {
			var id = guestId(from);
			var x = null;
			for (y in players)
				if (y.id == id)
					x = y;
			switch (m.t) {
				case "hello", "name":
					if (x != null)
						x.name = cleanName(m.name, x.name);
					broadcastLobby();
				case "ready":
					if (x != null)
						x.ready = m.ready == true;
					broadcastLobby();
					maybeStart();
				case "left":
					// un invité a quitté la partie en cours : tout le monde revient au salon
					if (inGame) {
						sendAll({t: "left", name: nameOf(id)});
						stopGameAndReturn(nameOf(id) + " a quitté la partie.");
					}
			}
		} else {
			switch (m.t) {
				case "lobby":
					myId = Std.int(m.you);
					var ps:Array<Dynamic> = m.players;
					players = [for (y in ps) {id: Std.int(y.id), name: Std.string(y.name), ready: y.ready == true}];
					for (y in players)
						if (y.id == myId)
							myReady = y.ready;
					if (!inGame && m.inGame != null)
						inGameIds = m.inGame;
				case "start":
					launch(m);
				case "left":
					if (inGame)
						stopGameAndReturn(Std.string(m.name) + " a quitté la partie.");
			}
		}
		refresh();
	}

	/** L'hôte lance la partie quand tous les joueurs du salon (au moins deux) sont prêts. **/
	static function maybeStart() {
		if (!isHost || inGame || players.length < 2)
			return;
		for (x in players)
			if (!x.ready)
				return;
		var g:Dynamic = hostGame();
		round++;
		var list = players.slice(0, MAX_PLAYERS);
		var cfg = {
			t: "start",
			mode: g.mode,
			options: g.options,
			families: g.families,
			seed: (Std.int(peer.seed) + round * 7919) & 0x7fffffff,
			round: round,
			names: [for (x in list) x.name],
			ids: [for (x in list) x.id]
		};
		for (x in players)
			x.ready = false;
		sendAll(cfg);
		launch(cfg);
	}

	/** Arrête la partie en cours et revient au salon. **/
	static function stopGameAndReturn(msg:String) {
		if (!inGame)
			return;
		var stop:Dynamic = untyped js.Browser.window.kikiStop;
		if (stop != null)
			stop();
		backToLobby(msg, false);
	}

	/** Fin de partie (ou départ de l'un) : retour au salon, les connexions restent ouvertes. **/
	static function backToLobby(msg:String, iQuit:Bool) {
		if (!inGame)
			return;
		inGame = false;
		inGameIds = [];
		if (iQuit)
			sendAll(isHost ? {t: "left", name: myName()} : {t: "left"});
		doc.body.innerHTML = "";
		doc.body.className = "";
		for (n in savedBody)
			doc.body.appendChild(n);
		doc.title = savedTitle;
		for (q in peers) {
			listen(q);
			if (isHost) {
				var id = guestId(q);
				q.onclose = (r:Dynamic) -> guestLeft(q, id);
			} else
				q.onclose = (r:Dynamic) -> fail("L'hôte s'est déconnecté" + (r != null ? " (" + r + ")" : "") + ".");
		}
		// à deux, si l'autre est parti pendant la partie, sa liaison est fermée
		if (isHost)
			for (q in peers.copy())
				if (q.closed == true)
					guestLeft(q, guestId(q));
		if (resultLine != null)
			resultLine.textContent = msg != null ? msg : "Vous avez quitté la partie.";
		broadcastLobby();
		if (onBack != null)
			onBack();
		refresh();
	}

	/** Appelé au retour au salon (le menu recharge sa sauvegarde et réaffiche l'onglet). **/
	public static var onBack:Void->Void = null;

	/** Pseudo modifié (salon ou paramètres) : le menu recharge la sauvegarde de ce pseudo. **/
	public static var onNameChanged:Void->Void = null;

	/** Remplace le menu par le jeu, dans la même page (les connexions doivent rester ouvertes). **/
	static function launch(cfg:Dynamic) {
		var stop:Dynamic = untyped js.Browser.window.kikiStop;
		if (stop != null)
			stop();
		var ids:Array<Int> = cfg.ids != null ? cfg.ids : [0, myId];
		var idx = ids.indexOf(myId);
		if (idx < 0) {
			// arrivé pendant le lancement : on attend la partie suivante
			inGameIds = ids;
			refresh();
			return;
		}
		myReady = false;
		for (x in players)
			x.ready = false;
		// pendant la partie, les liaisons des joueurs qui ne jouent pas restent au salon
		var gamePeers = isHost ? peers.filter(q -> ids.indexOf(guestId(q)) >= 0) : peers.copy();
		for (q in gamePeers)
			q.onmessage = null;
		if (!inGame) {
			savedBody = [for (n in doc.body.childNodes) n];
			for (n in savedBody)
				n.parentNode.removeChild(n);
			savedTitle = doc.title;
		}
		inGame = true;
		inGameIds = ids;
		broadcastLobby();
		var n = ids.length;
		untyped js.Browser.window.KIKI_NET = {
			peer: gamePeers[0],
			peers: gamePeers,
			players: n,
			index: idx,
			mode: cfg.mode,
			options: cfg.options,
			families: cfg.families,
			seed: cfg.seed,
			round: cfg.round != null ? cfg.round : 1,
			names: cfg.names,
			// messages fiables reçus pendant la partie (salon, départ d'un joueur)
			onReliable: (data:Dynamic, from:Dynamic) -> onReliable(from != null ? from : gamePeers[0], data),
			backToLobby: (msg:String) -> backToLobby(msg, msg == null)
		};
		var names:Array<String> = cfg.names;
		var others = [for (i in 0...n) if (i != idx) StringTools.htmlEscape(names[i]) + " joue " + CHARACTERS[i]];
		doc.title = n > 2 ? "Kikifest à " + n : "Kikifest à deux";
		doc.body.className = "playing";
		doc.body.innerHTML = '<canvas id="game"></canvas><div id="status">Chargement…</div>'
			+ '<div class="help">Vous jouez <b>' + CHARACTERS[idx] + '</b> (' + StringTools.htmlEscape(names[idx]) + ') avec '
			+ StringTools.htmlEscape(keysText(false)) + ' · ' + others.join(" · ") + ' · P : pause · Échap deux fois : quitter</div>';
		var s = doc.createScriptElement();
		s.src = "js/game.js?r=" + Std.string(cfg.round);
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
		name.onchange = () -> if (onNameChanged != null) onNameChanged();
		box.appendChild(name);
		box.appendChild(el("p", "note", "Affiché à l'autre joueur en ligne, et au classement."));
		box.appendChild(el("h3", null, "Pseudo du 2e joueur sur le même clavier"));
		var name2:js.html.InputElement = cast doc.createInputElement();
		name2.maxLength = 20;
		var cur2:String = null;
		try
			cur2 = Browser.window.localStorage.getItem("kikifest.name2")
		catch (e:Dynamic) {}
		name2.value = cur2 != null ? cur2 : "";
		name2.placeholder = "Sandy";
		name2.oninput = () -> try Browser.window.localStorage.setItem("kikifest.name2", StringTools.trim(name2.value)) catch (e:Dynamic) {};
		box.appendChild(name2);
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

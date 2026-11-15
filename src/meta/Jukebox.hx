package meta;

/**
	Choix de la musique du jeu.

	Le thème d'origine (`music.mp3`) et les morceaux déposés dans `web/assets/musiques/`
	(listés par le serveur de l'hôte, `/api/musiques`) forment la liste des morceaux.
	Au démarrage, un morceau est tiré au hasard (avec la graine de la partie : en réseau,
	les deux joueurs tombent sur le même). La touche M passe au morceau suivant, puis coupe
	la musique, puis revient au premier. En réseau, seul l'hôte choisit et l'invité suit.

	Les sons du jeu (`manager.musics`) demandent ici quoi jouer au moment de démarrer :
	- 0 (thème) : le morceau choisi ;
	- 1 (boss) : toujours la musique d'origine du boss ;
	- 2 (« vite ! ») : `hurryUp.mp3` pour le thème d'origine, sinon le morceau choisi joué plus vite.

	La musique n'a aucun effet sur le jeu : ces réglages sont hors du rollback (voir net.Snapshot).
**/
class Jukebox {
	public static inline var ORIGINAL = "music.mp3";
	public static inline var HURRY = "hurryUp.mp3";

	/** Vitesse (et hauteur) d'un morceau ajouté quand « vite ! » apparaît. **/
	public static var HURRY_RATE = 1.25;

	/** Fichiers des morceaux, relatifs à assets/sfx/ (le premier est le thème d'origine). **/
	public static var tracks:Array<String> = [ORIGINAL];

	public static var current = 0;
	public static var off = false;

	/** Sons du jeu (thème, boss, vite) : relancés quand le choix change. **/
	public static var sounds:Array<mtlib.Sound> = [];

	/** Ajoute les morceaux du dossier musiques/ (noms de fichiers donnés par le serveur). **/
	public static function setFiles(files:Array<String>) {
		tracks = [ORIGINAL];
		if (files != null)
			for (f in files)
				tracks.push("../musiques/" + StringTools.urlEncode(f));
	}

	/** Tirage au début de la partie. **/
	public static function pick(seed:Int) {
		current = tracks.length <= 1 ? 0 : ((seed % tracks.length) + tracks.length) % tracks.length;
		off = false;
	}

	/** Touche M : morceau suivant ; après le dernier, musique coupée ; puis retour au premier. **/
	public static function next() {
		if (off) {
			off = false;
			current = 0;
		} else if (current + 1 < tracks.length) {
			current++;
		} else {
			off = true;
		}
		refresh();
	}

	/** Choix reçu de l'hôte. **/
	public static function set(index:Int, isOff:Bool) {
		if (index < 0 || index >= tracks.length)
			index = 0;
		if (index == current && isOff == off)
			return;
		current = index;
		off = isOff;
		refresh();
	}

	/** Nom affiché du morceau en cours. **/
	public static function label():String {
		if (off)
			return "coupée";
		if (current == 0)
			return "thème d'origine";
		var f = StringTools.urlDecode(tracks[current].substr("../musiques/".length));
		var dot = f.lastIndexOf(".");
		return dot > 0 ? f.substr(0, dot) : f;
	}

	/** Quoi jouer pour le son n° slot des musiques du jeu : fichier et vitesse, ou null (musique coupée). **/
	public static function resolve(slot:Int, linkage:String):{linkage:String, rate:Float} {
		if (off)
			return null;
		if (slot == 0)
			return {linkage: tracks[current], rate: 1.0};
		if (slot == 2 && current != 0)
			return {linkage: tracks[current], rate: HURRY_RATE};
		return {linkage: linkage, rate: 1.0};
	}

	/** Relance la musique qui joue avec le nouveau choix. **/
	static function refresh() {
		for (s in sounds)
			s.restart();
	}
}

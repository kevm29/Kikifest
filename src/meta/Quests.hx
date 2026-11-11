package meta;

typedef Requirement = {item:Int, qty:Int};

typedef Quest = {
	id:Int,
	require:Array<Requirement>,
	giveFamilies:Array<Int>,
	removeFamilies:Array<Int>,
	options:Array<String>,
	modes:Array<String>,
};

typedef QuestState = {
	/** familles débloquées, dans l'ordre (ce que le serveur Motion Twin envoyait dans `$families`) */
	families:Array<Int>,
	/** options gagnées (miroir, cauchemar...) */
	options:Array<String>,
	/** modes de jeu gagnés (multicoop, timeattack) */
	modes:Array<String>,
	/** quêtes terminées */
	done:Array<Int>,
};

/**
	Les quêtes d'Hammerfest (xml/quests.xml), recalculées à partir de la collection d'objets du joueur.

	Dans l'original, ce calcul était fait par le serveur de Motion Twin : le jeu envoyait les objets
	ramassés en fin de partie, et recevait au lancement la liste des familles et options débloquées.
**/
class Quests {
	public var list(default, null):Array<Quest> = [];

	/** familles d'objets disponibles dès la première partie */
	public var initialFamilies(default, null):Array<Int> = [];

	/** famille de chaque objet (ids >= 1000 pour les objets à points) */
	public var itemFamily(default, null):Map<Int, Int> = new Map();

	/** objets de chaque famille, dans l'ordre du fichier */
	public var familyItems(default, null):Map<Int, Array<Int>> = new Map();

	public var familyOrder(default, null):Array<Int> = [];

	/**
		@param questsXml contenu de quests.xml
		@param itemXmls contenus de specialItems.xml et scoreItems.xml
	**/
	public function new(questsXml:String, itemXmls:Array<String>) {
		for (src in itemXmls)
			for (f in root(src).elementsNamed("family")) {
				var fid = Std.parseInt(f.get("id"));
				var items = [];
				for (it in f.elementsNamed("item")) {
					var id = Std.parseInt(it.get("id"));
					items.push(id);
					itemFamily.set(id, fid);
				}
				familyItems.set(fid, items);
				familyOrder.push(fid);
			}

		var given = new Map<Int, Bool>();
		for (q in root(questsXml).elementsNamed("quest")) {
			var quest:Quest = {
				id: Std.parseInt(q.get("id")),
				require: [],
				giveFamilies: [],
				removeFamilies: [],
				options: [],
				modes: []
			};
			for (r in q.elementsNamed("require"))
				quest.require.push({item: Std.parseInt(r.get("item")), qty: Std.parseInt(r.get("qty"))});
			for (g in q.elementsNamed("give")) {
				if (g.exists("family")) {
					var f = Std.parseInt(g.get("family"));
					quest.giveFamilies.push(f);
					given.set(f, true);
				}
				if (g.exists("option"))
					quest.options.push(g.get("option"));
				if (g.exists("mode"))
					quest.modes.push(g.get("mode"));
			}
			for (r in q.elementsNamed("remove"))
				quest.removeFamilies.push(Std.parseInt(r.get("family")));
			list.push(quest);
		}

		// les familles d'objets qu'aucune quête ne donne sont celles du départ
		// (0, 7, 18, 1000... : cohérent avec la liste « sysfam » de GameManager)
		for (f in familyOrder)
			if (!given.exists(f))
				initialFamilies.push(f);
	}

	static function root(src:String):Xml {
		if (StringTools.startsWith(src, "\u{FEFF}"))
			src = src.substr(1);
		return Xml.parse(src).firstElement();
	}

	public function isComplete(q:Quest, counts:Map<Int, Int>):Bool {
		for (r in q.require)
			if (count(counts, r.item) < r.qty)
				return false;
		return true;
	}

	public static inline function count(counts:Map<Int, Int>, item:Int):Int {
		var n = counts.get(item);
		return n == null ? 0 : n;
	}

	/** Recalcule les récompenses à partir des objets ramassés (cumul de toutes les parties). */
	public function compute(counts:Map<Int, Int>):QuestState {
		var fams = initialFamilies.copy();
		var options = [];
		var modes = [];
		var done = [];
		var removed = new Map<Int, Bool>();
		for (q in list) {
			if (!isComplete(q, counts))
				continue;
			done.push(q.id);
			for (f in q.giveFamilies)
				if (fams.indexOf(f) < 0)
					fams.push(f);
			for (f in q.removeFamilies)
				removed.set(f, true);
			for (o in q.options)
				if (options.indexOf(o) < 0)
					options.push(o);
			for (m in q.modes)
				if (modes.indexOf(m) < 0)
					modes.push(m);
		}
		// une famille retirée par une quête finie le reste, même si une autre quête la donne
		// (ex. les signes du zodiaque, retirés une fois la constellation complète)
		fams = fams.filter(f -> !removed.exists(f));
		return {families: fams, options: options, modes: modes, done: done};
	}
}

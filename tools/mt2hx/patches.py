#!/usr/bin/env python3
"""
Corrections manuelles appliquées après la conversion automatique.
Chaque entrée : (fichier relatif à src/, texte d'origine, remplacement).
Le texte d'origine doit apparaître exactement une fois (ou au moins une fois avec "all").
"""
import os
import sys

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "src")

PATCHES = [
    ("game/GameManager.hx", 'return MtStd.getVar(MtStd.getRoot(),"$mode") == modeName?.substring(1);', 'return MtStd.getVar(MtStd.getRoot(),"$mode") == (modeName == null ? null : modeName.substring(1));'),
    # AVM1 tolérait undefined.length ; les familles d'objets sont des tableaux à trous
    ("mtlib/Tools.hx", """		var id:Dynamic;
		id = MtStd.getGlobal("setInterval")(function() {
			MtStd.getGlobal("clearInterval")(id);
			f();
		},time);""", """		js.Browser.window.setTimeout(f, time);"""),
    
    ("mtlib/PersistCodec.hx", "public var cache : Array<Void>;", "public var cache : Array<Dynamic>;"),
    ("mtlib/PersistCodec.hx", "public var result : Void;", "public var result : Dynamic;"),
    ("game/mode/Adventure.hx", "manager?.startMode( new mode.Editor(manager,world?.setName,world?.currentId) );", "// éditeur de niveaux non porté"),
    ("game/entity/item/ScoreItem.hx", "while (r==null && j<family[i]?.length) {", "while (r==null && (j:Float) < (family[i]?.length:Float)) {"),
    ("game/mode/GameMode.hx", "while (s==null && j<family[i]?.length) {", "while (s==null && (j:Float) < (family[i]?.length:Float)) {"),
    # les frictions restaient indéfinies si le mode était verrouillé à la 1re image (dx -> NaN)
    ("game/Mode.hx", """	public function updateConstants()  untyped {
		if (fl_lock) {""", """	public function updateConstants()  untyped {
		if (xFriction == null) {
			xFriction = Math.pow(Data.FRICTION_X, Timer.tmod);
			yFriction = Math.pow(Data.FRICTION_Y, Timer.tmod);
		}
		if (fl_lock) {"""),
    ("game/mode/GameMode.hx", "max = ( pl[i]?.lives>max ) ? pl[i]?.lives : max;", "max = ( (pl[i]?.lives:Float) > (max:Float) ) ? pl[i]?.lives : max;"),
    # anti-triche : le calcul de world.csum est commenté dans SetManager d'origine, donc ce test
    # échouait toujours (« argh ») et les objets de la partie n'étaient jamais envoyés
    ("game/mode/Adventure.hx", 'if(GameManager.HH.get("$"+Md5.encode(world?.setName))!="$"+Md5.encode(""+world?.csum)) {GameManager.fatal("argh"); return;}', '// test anti-triche retiré (world.csum n\'est plus calculé)'),
    # --- Kikifest, étude du mode 3-4 joueurs (?joueurs=3 ou 4) : joueurs 3-4, teintes, scores dans la barre ---
    ('game/mode/MultiCoop.hx', '\t\t\tvar p2:Dynamic = insertPlayer(14,-2);\n\t\t\tp2?.ctrl?.setKeys(82/*R*/, 70/*F*/, 68/*D*/, 71/*G*/, 65/*A*/) ;\n\t\t}\n\t\telse {', '\t\t\tvar p2:Dynamic = insertPlayer(14,-2);\n\t\t\tp2?.ctrl?.setKeys(82/*R*/, 70/*F*/, 68/*D*/, 71/*G*/, 65/*A*/) ;\n\t\t\t// Kikifest (étude) : 3e et 4e joueurs, ?joueurs=3 ou 4\n\t\t\tvar n:Dynamic = Std.parseInt(""+MtStd.getVar(MtStd.getRoot(),"$joueurs"));\n\t\t\tvar cols:Array<Int> = [9, 10];\n\t\t\t{ var k:Dynamic=2; while (n!=null && k<n && k<4) { insertPlayer(cols[k-2],-2); k++; } }\n\t\t}\n\t\telse {'),
    ('game/mode/MultiCoop.hx', '\t\t\t{ if (p != null) p.head\t\t\t= p?.defaultHead; }\n\t\t}\n//\t\tp.ctrl.fl_upKick = false;\n\t}', '\t\t\t{ if (p != null) p.head\t\t\t= p?.defaultHead; }\n\t\t}\n\t\tif ( p?.pid>=2 ) {\n\t\t\t// Kikifest (étude) : apparences des joueurs 3 et 4 (Igor et Sandy teintés)\n\t\t\t{ if (p != null) p.name\t\t\t= p?.pid==2 ? "Joueur 3" : "Joueur 4"; }\n\t\t\t{ if (p != null) p.skin\t\t\t= p?.pid-1; }\n\t\t\t{ if (p != null) p.darkColor\t\t= p?.pid==2 ? 0x22227a : 0x8a4b00; }\n\t\t\tif ( p?.pid==3 ) {\n\t\t\t\t{ if (p != null) p.defaultHead\t= RootData.HEAD_SANDY; }\n\t\t\t\t{ if (p != null) p.head\t\t\t= p?.defaultHead; }\n\t\t\t}\n\t\t}\n//\t\tp.ctrl.fl_upKick = false;\n\t}'),
    ('game/mode/MultiCoop.hx', '\t\t}\n//\t\tp.ctrl.fl_upKick = false;\n\t}', '\t\t}\n//\t\tp.ctrl.fl_upKick = false;\n\t}\n\n\n\t/*------------------------------------------------------------------------\n\tKikifest (étude) : teinte des joueurs 3 et 4 (remise après un clignotement)\n\t------------------------------------------------------------------------*/\n\toverride public function main()  untyped {\n\t\tsuper.main();\n\t\tvar pl:Dynamic = getPlayerList();\n\t\t{ var i:Dynamic=0; while (i<pl?.length) {\n\t\t\tvar p:Dynamic = pl[i];\n\t\t\tif ( p?.pid>=2 && p?.color==null && (p?.fl_alphaBlink || !p?.fl_blinked) ) {\n\t\t\t\tp?.setColorHex( 45, p?.pid==2 ? 0x2a9a3a : 0x3a5cff );\n\t\t\t}\n\t\ti++; } }\n\t}'),
    ('game/gui/GameInterface.hx', '\n\n\t\t// Init spécifiques aux players\n\t\tfakeScores\t\t= new Array();', '\n\n\t\t// Kikifest (étude 3-4 joueurs) : scores des joueurs 3 et 4 au milieu de la barre\n\t\tvar npl:Dynamic = game?.countList(RootData.PLAYER);\n\t\t{ var k:Dynamic=2; while (k<npl && k<4) {\n\t\t\tvar s0:Dynamic = scores[0];\n\t\t\tvar tf:Dynamic = mc?.createTextField("$score"+k, 900+k, 32+(k-2)*88, s0?._y, 80, s0?.__h);\n\t\t\t{ if (tf != null) tf.__def = s0?.__def; }\n\t\t\t{ if (tf != null) tf.format = s0?.format; }\n\t\t\tscores[k] = tf;\n\t\tk++; } }\n\n\t\t// Init spécifiques aux players\n\t\tfakeScores\t\t= new Array();'),
    ('game/gui/GameInterface.hx', '\n\t\t\tclearExtends(pid);\n\t\t\t{ if (scores[pid] != null) scores[pid].textColor = RootData.BASE_COLORS[0]; }\n\t\t\tFxManager.addGlow( ((scores[pid]):Dynamic), GLOW_COLOR, 2);\n\t\t', '\n\t\t\tclearExtends(pid);\n\t\t\t{ if (scores[pid] != null) scores[pid].textColor = pid==2 ? 0x8cf09a : (pid==3 ? 0xa8b8ff : RootData.BASE_COLORS[0]); }\n\t\t\tFxManager.addGlow( ((scores[pid]):Dynamic), GLOW_COLOR, 2);\n\t\t'),
    ('game/gui/GameInterface.hx', '\t------------------------------------------------------------------------*/\n\tpublic function setLives(pid:Dynamic,v:Dynamic)  untyped {\n\t\tvar baseX:Dynamic\t= BASE_X;\n\t\tvar baseWid:Dynamic\t= BASE_WIDTH;', '\t------------------------------------------------------------------------*/\n\tpublic function setLives(pid:Dynamic,v:Dynamic)  untyped {\n\t\tif ( pid>=2 ) { currentLives[pid] = v; return; } // Kikifest (étude) : vies des joueurs 3-4 écrites avec le score\n\t\tvar baseX:Dynamic\t= BASE_X;\n\t\tvar baseWid:Dynamic\t= BASE_WIDTH;'),
    ('game/gui/GameInterface.hx', '\t\t\t\t\t\tfakeScores[pid] = realScores[pid];\n\t\t\t\t\t}\n\t\t\t\t\t{ if (scores[pid] != null) scores[pid].text = getScoreTxt(fakeScores[pid]); }\n\t\t\t\t}\n\t\t\t', '\t\t\t\t\t\tfakeScores[pid] = realScores[pid];\n\t\t\t\t\t}\n\t\t\t\t\t{ if (scores[pid] != null) scores[pid].text = getScoreTxt(fakeScores[pid]) + (pid>=2 ? " ♥"+currentLives[pid] : ""); }\n\t\t\t\t}\n\t\t\t'),
]


def main():
    ok = True
    for entry in PATCHES:
        f, a, b = entry[:3]
        allow_many = len(entry) > 3 and entry[3] == "all"
        p = os.path.join(ROOT, f)
        s = open(p, encoding="utf-8").read()
        n = s.count(a)
        if n == 0 or (n != 1 and not allow_many):
            print(f"PATCH ÉCHOUÉ ({n} occurrences) : {f} : {a[:60]!r}")
            ok = False
            continue
        s = s.replace(a, b)
        open(p, "w", encoding="utf-8").write(s)
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()

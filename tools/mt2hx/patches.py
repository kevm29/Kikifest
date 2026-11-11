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

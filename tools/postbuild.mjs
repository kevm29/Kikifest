// Après compilation : les identifiants MotionTypes `$nom` (écrits __S_nom en Haxe) retrouvent leur nom.
import fs from "node:fs";
const f = process.argv[2];
const src = fs.readFileSync(f, "utf8");
fs.writeFileSync(f, src.replace(/\b__S_(\w+)/g, (_, n) => "$" + n));

# Kikifest

Adaptation web de **Hammerfest** (Motion Twin, 2006) pour jouer **à deux en réseau**,
la partie étant hébergée chez l'un des deux joueurs.

Le jeu d'origine, son code et ses ressources ont été publiés par Motion Twin sous licence
CC BY-NC-SA 4.0 : https://github.com/motion-twin/WebGamesArchives/tree/main/Hammerfest.
Kikifest reste sous la même licence (voir [LICENSE.txt](LICENSE.txt)) : pas d'usage commercial,
crédit à Motion Twin, partage dans les mêmes conditions.

Le plan technique est dans [docs/PLAN.md](docs/PLAN.md).

## Lancer le jeu

```sh
node server/serve.mjs 8080
```

Puis ouvrir http://localhost:8080/ dans le navigateur. Le jeu démarre en mode **coopération à deux
sur le même clavier** (en attendant le réseau) :

- Igor : flèches pour bouger et sauter, Entrée pour poser une bombe ;
- Sandy : R D F G pour bouger et sauter, A pour poser une bombe.

Paramètres d'adresse : `?mode=` (mode de jeu, `multicoop` par défaut), `?seed=` (graine du hasard).
La visionneuse des ressources est sur http://localhost:8080/viewer.html.

## Reconstruire

- `web/js/game.js` : `haxe game.hxml` (Haxe 4).
- `src/game` est **généré** depuis le code MotionTypes d'origine par `tools/mt2hx/regen.sh`
  (convertisseur `mt2hx.py` puis corrections de `patches.py`) ; seul `src/game/Boot.hx` est écrit à la main.
  Le moteur d'affichage Flash (`src/swf`) et la bibliothèque standard MotionTypes (`src/mtlib`, `src/mtflash`)
  sont écrits à la main.
- Les graphismes : `tools/extract` (extraction du SWF), puis `tools/extract/rasterize.cjs` (planches d'images).

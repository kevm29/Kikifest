# Kikifest

Adaptation web de **Hammerfest** (Motion Twin, 2006) pour jouer **à deux en réseau**,
la partie étant hébergée chez l'un des deux joueurs.

Le jeu d'origine, son code et ses ressources ont été publiés par Motion Twin sous licence
CC BY-NC-SA 4.0 : https://github.com/motion-twin/WebGamesArchives/tree/main/Hammerfest.
Kikifest reste sous la même licence (voir [LICENSE.txt](LICENSE.txt)) : pas d'usage commercial,
crédit à Motion Twin, partage dans les mêmes conditions.

## Jouer à deux

L'hôte double-clique sur `Heberger-Windows.bat` (ou `Heberger-Mac.command`, ou lance `node server/serve.mjs`) ;
le menu s'ouvre. Dans l'onglet **Multijoueur**, il crée une partie et envoie le lien à l'autre joueur.
Chacun joue sur son clavier, avec les touches de ses **Paramètres** (volumes musique et bruitages, pseudo, touches).
Détails : [docs/HEBERGER.md](docs/HEBERGER.md), et pour le réseau [docs/NETCODE.md](docs/NETCODE.md).

Le plan technique est dans [docs/PLAN.md](docs/PLAN.md).

## Lancer le jeu

```sh
node server/serve.mjs 8080
```

Puis ouvrir http://localhost:8080/ : le menu (modes de jeu, frigo, quêtes, classement, multijoueur, paramètres).
Le jeu seul est sur http://localhost:8080/jeu.html. Sans invité, on joue l'Aventure en solo (sans Sandy) ;
l'Aventure à deux existe aussi sur un même clavier (2e jeu de touches dans les Paramètres).

Paramètres d'adresse de `jeu.html` : `?mode=` (mode de jeu, `solo` par défaut : Aventure sans Sandy), `?seed=` (graine du hasard).
`?families=` force les familles d'objets débloquées, `?nosave` n'enregistre pas la partie.

### Quêtes et collection

Comme sur le site d'origine, les objets ramassés s'additionnent d'une partie à l'autre et débloquent
les quêtes de `quests.xml` (vies supplémentaires, nouvelles familles d'objets, options, modes).
Le serveur de Motion Twin faisait ce calcul ; ici, la collection est gardée dans le navigateur
(`localStorage`, clé `kikifest.collection`) et les quêtes sont recalculées au lancement (`src/meta`).
Le menu (`src/menu`, `haxe menu.hxml`) affiche le frigo et les quêtes.

La visionneuse des ressources est sur http://localhost:8080/viewer.html.

## Reconstruire

- `web/js/game.js` : `haxe game.hxml` (Haxe 4).
- `src/game` est **généré** depuis le code MotionTypes d'origine par `tools/mt2hx/regen.sh`
  (convertisseur `mt2hx.py` puis corrections de `patches.py`) ; seul `src/game/Boot.hx` est écrit à la main.
  Le moteur d'affichage Flash (`src/swf`) et la bibliothèque standard MotionTypes (`src/mtlib`, `src/mtflash`)
  sont écrits à la main.
- Les graphismes : `tools/extract` (extraction du SWF), puis `tools/extract/rasterize.cjs` (planches d'images)
  et `tools/extract/framescripts.mjs` (scripts des animations, depuis un export `-export script` de JPEXS).

# Plan technique de Kikifest

## Objectif

Rejouer à Hammerfest à deux, chacun sur son ordinateur, sans latence ressentie.
La partie est hébergée chez l'un des deux joueurs (l'« hôte »).

## Choix

- **Port web** : le jeu tourne dans le navigateur, sans Flash.
- **Haxe → JavaScript** : le code d'origine est en MotionTypes, l'ancêtre de Haxe.
  La conversion est donc presque mécanique, fichier par fichier.
- **Ressources d'origine** : les graphismes, animations, sons et niveaux sont extraits
  de `game.swf` et des XML publiés par Motion Twin (`tools/extract`).
- **Moteur d'affichage façon Flash** (`src/swf`) : une émulation légère des MovieClip AS2
  (timeline, `attachMovie`, `gotoAndStop`, `_x`, `_xscale`, enfants nommés...),
  rendue sur un canvas. Le code du jeu peut ainsi rester très proche de l'original.
- **Réseau : rollback netcode** (comme les jeux de combat en ligne).
  - Chaque joueur simule toute la partie. Ses propres touches s'appliquent immédiatement.
  - Seules les touches circulent. Quand celles de l'autre arrivent, le jeu revient
    quelques images en arrière et rejoue, de façon invisible.
  - Conditions : simulation **déterministe** (pas de temps fixe à 40 images/s,
    générateur aléatoire à graine commune, aucune dépendance au rendu) et
    **sauvegarde/restauration** rapide de l'état du jeu.
  - Transport : **WebRTC DataChannel** non fiable et non ordonné, en pair à pair.
    Le serveur Node de l'hôte (`server/`) sert le jeu et la mise en relation.

## Étapes

1. ✅ Extraction des ressources depuis `game.swf` (formes SVG, timelines, sons, XML).
2. ✅ Moteur MovieClip en Haxe et visionneuse de symboles (`web/viewer.html`).
3. Porter la logique du jeu : `GameManager`, `mode/Adventure`, `mode/MultiCoop`,
   entités (joueur, bombes, fruits), physique, niveaux (`levels/*`).
   Remplacer `Std.random` par un générateur à graine, et `Timer.tmod` par un pas fixe.
   Bouchonner le chargeur (`Loader.mt`), qui parlait au serveur Motion Twin.
4. Coop locale à deux sur un clavier dans le navigateur (comme l'original).
5. Séparer la simulation du rendu, et ajouter sauvegarde/restauration de l'état.
6. Rollback netcode + WebRTC, salon hôte/invité, test à deux.
   ✅ Salon, signalisation WebRTC, ouverture du port (UPnP) et repli par le serveur de l'hôte
   (`server/`, `web/index.html`, `web/js/kikinet.js`, guide `docs/HEBERGER.md`).
7. Finitions : sons, menus, options (cauchemar, miroir), scores.

## Lancer la visionneuse

```
haxe viewer.hxml          # compile src/ vers web/js/viewer.js
node server/serve.mjs     # puis ouvrir http://localhost:8080/viewer.html
```

## Régénérer les ressources

Il faut Java, Node et JPEXS Free Flash Decompiler (`ffdec-cli.jar`) :

```
cd tools/extract && npm install
node extract.mjs <dossier Hammerfest de WebGamesArchives> ../../web/assets <ffdec-cli.jar>
```

Source utilisée : motion-twin/WebGamesArchives, commit `8b8e2f202e1fa8cdf1d96e4140dad0cba458054e`.

## Limites connues du moteur d'affichage

- Les morph shapes sont affichées dans leur forme de départ.
- Les filtres Flash (lueur, flou) ne sont pas encore rendus.
- 98 scripts de frame non triviaux sont à porter à la main
  (liste dans `web/assets/gfx/todo-scripts.json`).
- Les transformations de couleur utilisent `ctx.filter`, absent de Safari.

# Rollback netcode

Couche réseau de Kikifest, indépendante du jeu : `src/net/`.
Principe : chaque joueur simule toute la partie ; seules les touches circulent.
Ses propres touches s'appliquent tout de suite, celles de l'autre sont prédites,
et quand les vraies arrivent, le jeu revient en arrière et rejoue, sans que ça se voie.

## Ce que le jeu doit fournir

```haxe
interface RollbackGame<S> {
  function advance(inputs:Array<Int>):Void; // un pas fixe de 1/40 s
  function save():S;                        // copie complète de l'état
  function load(state:S):Void;              // restauration (sans garder de référence)
  function checksum():Int;                  // empreinte de l'état (net.rollback.Checksum)
}
```

- `inputs[0]` = touches de l'hôte (Igor), `inputs[1]` = invité (Sandy), masques de bits sur 16 bits.
- `advance` ne doit lire ni le clavier, ni l'horloge, ni `Math.random`.
  Le générateur aléatoire, à graine commune, fait partie de l'état sauvegardé.
- Éviter `Math.sin/cos/pow/exp` dans la simulation : leurs derniers bits peuvent
  varier d'un navigateur à l'autre. Les `+ - * /` et `Math.sqrt` sont sûrs.
- Ne pas dépendre de l'ordre d'itération d'une `Map` ou d'un objet.
- Pendant les frames rejouées, `session.resimulating` vaut `true` : ne pas jouer
  de son ni lancer d'effet ponctuel à ce moment-là.

`net.rollback.SyncTest` vérifie tout ça en local : à chaque frame, il revient
quelques frames en arrière, rejoue, et signale la première frame où l'empreinte change.
C'est le test à faire passer avant d'essayer en réseau.

## Boucle de jeu

```haxe
var session = new RollbackSession(jeu, transport, {
  localPlayer: 0,                       // 0 = hôte, 1 = invité
  now: () -> js.Browser.window.performance.now(),
  inputDelay: 2,                        // frames de délai sur ses propres touches
});
session.onDesync = (frame, local, distant) -> trace('désynchro à la frame $frame');

// 40 fois par seconde, à pas fixe :
switch (session.tick(lireClavier())) {
  case Advanced:          // le jeu a avancé (après d'éventuelles frames rejouées)
  case WaitingForRemote:  // trop d'avance sans nouvelles de l'autre : jeu figé
  case SlowingDown:       // on saute une frame pour laisser l'autre rattraper
}
afficher(jeu);
```

`session.poll()` traite le réseau sans avancer (pause, fin de partie).
`session.silenceMs()` donne le temps écoulé depuis le dernier message reçu (déconnexion).

## Réglages

| Option | Défaut | Effet |
|---|---|---|
| `inputDelay` | 2 | Délai (en frames de 25 ms) sur ses propres touches. Masque la moitié du ping : moins de corrections visibles, mais commandes un peu moins vives. Modifiable en cours de partie. Avec 50 ms de délai, un ping jusqu'à ~100 ms ne provoque quasiment aucune correction. |
| `maxPrediction` | 8 | Nombre maximal de frames simulées sans les touches de l'autre (200 ms). Au-delà, le jeu attend. |
| `checksumInterval` | 20 | Fréquence de comparaison des empreintes (toutes les 0,5 s). |
| `frameMs` | 25 | Durée d'une frame. |

## Protocole

Messages binaires sur un canal non fiable et non ordonné (WebRTC DataChannel,
`maxRetransmits: 0`). Pertes, doublons et désordre sont tolérés :

- **Touches** (à chaque frame) : toutes les touches locales que l'autre n'a pas encore
  acquittées, l'acquittement de ses touches, la frame courante et l'avance mesurée.
  Une touche perdue est donc renvoyée dans le message suivant.
- **Empreinte** : une fois une frame confirmée des deux côtés, son empreinte est envoyée ;
  une différence déclenche `onDesync`.
- **Ping/pong** toutes les 250 ms, pour le ping et le recalage des horloges.

Recalage des horloges (comme GGPO) : chacun estime son avance sur l'autre, en tenant
compte du ping ; toutes les 40 frames, celui qui est devant saute la moitié de l'écart.

## Transport

`net.transport.Transport` est une interface (`send(Bytes)`, `onMessage`) :

- `KikiNetTransport` : branche la session sur le salon `web/js/kikinet.js`
  (WebRTC, avec repli par le serveur de l'hôte).
- `DirectTransport` : deux extrémités en mémoire.
- `LagTransport` : simule latence, gigue, pertes et doublons (tests et démo).

## Tests et démo

```
haxe tests.hxml       # tests déterministes sur réseau simulé (Node)
haxe netdemo.hxml     # compile web/js/netdemo.js
```

- `web/netdemo.html` : les deux joueurs dans la même page, avec ping, gigue, pertes et
  délai réglables. Chaque moitié montre la partie vue par un joueur.
- `web/netdemo.html?online` : la même démo à deux ordinateurs, via le salon.

Les tests couvrent : déterminisme (SyncTest), détection d'un champ oublié dans `save()`,
parties de 60 s sur 4 qualités de réseau (jusqu'à 150 ms, 15 % de pertes) et 3 délais,
comparées à une partie rejouée sans réseau, horloge d'un joueur 2 % trop rapide,
détection d'une désynchro, coupure réseau de 2 s puis reprise.

## Branchement dans Kikifest

- **Photo de l'état** (`src/net/Snapshot.hx`) : plutôt qu'un `save`/`load` écrit à la main pour les
  centaines de classes converties, on parcourt tout le graphe d'objets accessible depuis le
  gestionnaire, le clip racine et les statiques de toutes les classes, et on garde une copie
  superficielle de chaque objet. Restaurer réécrit ces copies dans les mêmes objets (les références
  restent valables, l'ordre des clés et les trous des tableaux sont conservés). Sont laissés de côté :
  ressources du SWF, DOM, sons, clips retirés de l'affichage, textes (`Lang`) et constantes (`Data`).
  Environ 4 000 objets, 2 à 3 ms par photo.
- **Sauvegarde clairsemée** (`saveEvery: 4`) : une frame dont on connaît déjà les touches de l'autre
  ne sera jamais rejouée, donc on ne la photographie pas ; parmi les frames prédites, on photographie
  la première puis une sur quatre. Quand les touches arrivent à temps (ping < ~100 ms avec 2 frames de
  délai), il n'y a presque aucune photo.
- **Touches** : le jeu ne lit plus le clavier. `Boot` transforme les touches enfoncées en masque
  d'actions (`meta.Settings` : haut, bas, gauche, droite, bombe, pause, carte), le masque passe par
  le réseau, puis chaque joueur (par `pid`) reçoit des codes virtuels (1001-1005 pour Igor,
  1011-1015 pour Sandy) dans `mtlib.Key`. Chacun règle ses touches dans les Paramètres du menu.
- Pendant les frames rejouées, les bruitages sont coupés (la musique peut démarrer).

Tests dans le vrai jeu (serveur lancé) :
- `node tools/test/synctest.cjs [url] [frames] [recul]` : SyncTest (retour en arrière et rejeu à chaque frame).
- `node tools/test/online.cjs [secondes] [relay|direct] [latence ms]` : deux navigateurs, l'un héberge
  depuis l'onglet Multijoueur, l'autre ouvre le lien ; jeu au hasard des deux côtés, empreintes comparées.
  Le jeu accepte `?lag=80` (latence simulée) pour forcer des rollbacks.

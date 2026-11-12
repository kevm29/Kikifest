# Étude : Kikifest à 3 ou 4 joueurs

Branche d'étude `claude/project-thread-wxs0i7`, séparée de `main`. Rien n'y change le jeu à 2.

## En bref

C'est faisable, et le plus dur (le réseau) tient déjà en test. Le rollback marche à 4 joueurs sur un
réseau simulé, et le vrai jeu accepte 4 personnages en Coop. Ce qui reste à faire, c'est surtout de
brancher le salon et le serveur sur plusieurs invités, puis de trancher quelques règles de jeu.

| Sujet | Verdict | Détail |
|---|---|---|
| Réseau (rollback) | ✅ prototype testé | `GroupSession` : 2 à 4 joueurs, tests OK jusqu'à 150 ms et 15 % de pertes |
| Personnages | ✅ prototype | Joueur 3 = Igor teinté vert, joueur 4 = Sandy teintée bleue |
| Interface (scores, vies) | ✅ prototype | Scores des joueurs 3 et 4 au milieu de la barre, avec leurs vies (♥) |
| Coût en calcul | ✅ OK | Une frame coûte 0,3 ms à 4 contre 0,18 ms à 2. La photo de l'état coûte environ 3 ms dans les deux cas |
| Latence ressentie | ⚠️ un peu plus de corrections | La partie suit le joueur le plus lent. Voir plus bas |
| Salon et serveur | ⏳ à faire | Aujourd'hui, une partie compte 1 hôte et 1 invité |
| Règles (vies, fin de partie, quêtes) | ❓ à décider | Voir « Questions » |

## Essayer le prototype (en local, un seul clavier)

```
jeu.html?mode=multicoop&joueurs=4     (ou joueurs=3)
```

Igor et Sandy se jouent comme d'habitude, avec les touches 1 et les touches 2. Les joueurs 3 et 4 sont
des robots qui se promènent et posent des bombes au hasard, juste pour voir 4 personnages à l'écran.

## Le réseau

### Comment ça marche à plusieurs

Le principe reste celui de la partie à deux : chacun simule toute la partie et seules les touches
circulent. `net.rollback.GroupSession` le généralise :

- chacun envoie ses touches à tous les autres, dans un seul message ;
- les touches de chaque autre joueur sont prédites séparément (on répète la dernière touche connue) ;
- une frame devient définitive quand on connaît les touches de **tous** les joueurs ;
- l'horloge se recale sur le joueur le plus en retard ;
- les empreintes sont comparées avec chaque joueur, et une désynchronisation dit de quel joueur elle vient.

Chaque message porte le numéro de son auteur et se suffit à lui-même. L'hôte peut donc se contenter
de **faire suivre** aux autres ce qu'il reçoit (`GroupTransport` avec `relay = true`). Ça laisse le
choix entre deux façons de relier les joueurs :

- **Maillage** : chaque joueur se relie directement à chaque autre (6 liaisons WebRTC à 4).
  C'est le plus rapide, mais il faut que chaque paire d'invités arrive à se joindre.
- **Étoile** : les invités ne se relient qu'à l'hôte, qui fait suivre. C'est plus simple et ça
  réutilise tel quel le salon d'aujourd'hui (une liaison par invité). En contrepartie, entre deux
  invités, le trajet passe par l'hôte et le ping s'additionne.

Recommandation : commencer par l'étoile, qui marche avec ce qui existe déjà, puis ajouter les
liaisons directes entre invités quand elles s'établissent. La session accepte les deux en même temps,
puisque les doublons sont sans danger.

### Résultats des tests (réseau simulé, parties de 60 s)

`haxe tests-groupe.hxml` : à chaque fois, toutes les parties finissent identiques entre elles et
identiques à une partie rejouée sans réseau.

| Cas | Retours en arrière par joueur et par minute | Plus long retour | Ping le plus mauvais |
|---|---|---|---|
| 2 joueurs, internet 40-80 ms | 89 | 4 frames | 105 ms |
| 3 joueurs, internet 40-80 ms | 282 | 7 frames | 184 ms |
| 4 joueurs, maillage, internet 40-80 ms | 481 | 7 frames | 189 ms |
| 4 joueurs, étoile, 40 ms vers l'hôte | 467 | 6 frames | 175 ms |
| 4 joueurs, étoile, délai 3 frames | 220 | 5 frames | 175 ms |
| 4 joueurs, très mauvais réseau (150 ms, 15 % de pertes) | 729 | 8 frames | 349 ms |

À quoi s'attendre : avec plus de joueurs, il y a plus de chances qu'une touche arrive « en retard »,
donc plus de petites corrections (un personnage qui saute de quelques pixels). À 4 sur internet, il
faudra sans doute passer le délai des touches de 2 à 3 frames (75 ms au lieu de 50 ms) : ça divise
les corrections par deux, mais les commandes répondent un poil moins vite. Ce réglage sera à essayer
pour de vrai.

### Coût en calcul (mesuré dans le vrai jeu, Chromium)

| | 2 joueurs | 4 joueurs |
|---|---|---|
| Une frame de jeu | 0,18 ms | 0,29 ms |
| Photo de l'état | 2,9 ms | 3,1 ms |
| Restauration | 1,7 ms | 1,9 ms |
| SyncTest (retour en arrière de 6 frames à chaque frame) | OK | OK |

Avec les chiffres du test « 4 joueurs, internet », le rollback prend environ 8 % du temps de calcul,
à peu près comme à deux. Le jeu reste donc déterministe à 4, et ce n'est pas le rollback qui le
ralentit. Le léger ralentissement déjà signalé à 2 joueurs vient d'ailleurs, sans doute de
l'affichage, et il faudra le corriger avant de passer à 4.

## Ce qui reste à faire pour jouer à 4 en ligne

1. **Serveur** (`server/serve.mjs`) : une partie accepte jusqu'à 3 invités au lieu d'un, chacun
   reçoit un numéro (1, 2, 3). Le serveur fait déjà passer les messages WebRTC entre l'hôte et
   chaque invité.
2. **Salon** (`src/menu/Online.hx`, `web/js/kikinet.js`) : liste des joueurs présents, « Je suis
   prêt » pour chacun, la partie démarre quand tout le monde est prêt. L'hôte garde une liaison
   par invité.
3. **Jeu** (`Boot.hx`) : remplacer `RollbackSession` par `GroupSession` avec un `GroupTransport`
   (avec relais chez l'hôte), et passer le nombre de joueurs dans `KIKI_NET.players`. Le reste est
   déjà prêt sur cette branche.
4. **Départ d'un joueur** : à 2, celui qui reste continue seul. À 4, il faut que les 3 autres
   tombent d'accord sur la frame à partir de laquelle le partant ne joue plus (ses touches valent
   alors « rien »), sinon les parties divergent. C'est le point le plus délicat du réseau. On peut
   commencer plus simplement : si quelqu'un part, la partie s'arrête pour tout le monde.
5. **Tests à deux ordinateurs ou plus** : `tools/test/online.cjs` à étendre à 3 ou 4 navigateurs.

Chaque étape se fait sans toucher au mode à 2 joueurs.

## Questions de jeu à trancher

- **Vies** : en Coop d'origine, chaque joueur commence avec la moitié des vies du solo. À 4, faut-il
  garder ça, ou passer à une réserve commune ?
- **Fin de partie** : pour la partie à deux, tu as demandé que la partie s'arrête quand un joueur
  perd. À 4, est-ce qu'on garde cette règle, ou est-ce que les autres continuent tant qu'il en reste
  un en vie ?
- **Apparence** : les joueurs 3 et 4 sont pour l'instant Igor et Sandy teintés. On peut aussi leur
  donner une tête différente parmi celles du jeu (afro, couronne, Igorette…).
- **Quêtes et classement** : même règle qu'à deux (chacun garde sa collection, les objets ramassés
  vont à tout le monde, bonus de l'hôte), et au classement une ligne par partie avec les 3 ou 4 pseudos.
- **Niveaux** : ils ont été dessinés pour 1 ou 2 joueurs. À 4, ça devient plus facile. Faut-il
  davantage d'ennemis ?

## Fichiers de cette branche

- `src/net/rollback/GroupSession.hx` : la session de rollback pour 2 à 4 joueurs.
- `src/net/transport/GroupTransport.hx` : une liaison par autre joueur, avec relais possible chez l'hôte.
- `tests/GroupTest.hx` et `tests-groupe.hxml` : les tests en réseau simulé.
- `src/netdemo/DemoGame.hx` : le petit jeu de test accepte maintenant 2 à 4 joueurs.
- `src/game/mode/MultiCoop.hx`, `src/game/gui/GameInterface.hx` : les joueurs 3 et 4 et la barre de
  scores. Comme `src/game` est généré, ces changements sont aussi notés dans `tools/mt2hx/patches.py`.
- `src/game/Boot.hx` : `?joueurs=`, les touches des joueurs 3 et 4 et les robots du mode local.

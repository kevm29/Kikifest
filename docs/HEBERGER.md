# Héberger une partie de Kikifest

L'un des deux joueurs, l'**hôte**, lance un petit serveur sur son ordinateur.
L'autre joueur, l'**invité**, n'installe rien : il ouvre simplement le lien reçu dans son navigateur.

## 1. Lancer le serveur (hôte)

Il faut [Node.js](https://nodejs.org) (version « LTS », 18 ou plus), à installer une seule fois.

Puis, dans le dossier de Kikifest :

| Système | Ce qu'il faut faire |
|---|---|
| Windows | double-cliquer sur `Heberger-Windows.bat` |
| Mac | double-cliquer sur `Heberger-Mac.command` (la première fois : clic droit › Ouvrir) |
| Linux | `./heberger-linux.sh` |
| Ou partout | `node server/serve.mjs` |

Le navigateur s'ouvre sur le menu du jeu, `http://localhost:8080/`. Laissez la fenêtre noire ouverte pendant la partie.

Sous Windows, le pare-feu demande la première fois s'il faut autoriser Node.js :
répondez **Autoriser**, sinon l'invité ne pourra pas se connecter.

## 2. Créer la partie et envoyer le lien

Dans le menu, ouvrez l'onglet **Multijoueur** et cliquez sur **Créer une partie et inviter quelqu'un**. La page affiche un code (par exemple `K7RQM`) et un lien à copier.
Envoyez le lien à l'autre joueur (SMS, Discord...). En l'ouvrant, il rejoint directement la partie.
Il peut aussi ouvrir l'adresse sans le code et taper le code dans l'onglet Multijoueur.
Dès qu'il est connecté, la partie (Aventure à deux) démarre chez les deux : l'hôte joue Igor, l'invité Sandy,
chacun avec les touches réglées dans ses **Paramètres**. La partie démarre avec les bonus de quêtes et les options
cochées de l'hôte ; à la fin, les objets ramassés s'ajoutent au frigo de chacun.

Si personne ne vient, le lien « Jouer seul » lance l'Aventure en solo, sans Sandy.

- **Même Wi-Fi** (vous êtes dans la même maison) : utilisez le lien « même Wi-Fi ». Rien d'autre à faire.
- **Par internet** : utilisez le lien « par internet ». Il faut que votre box laisse entrer l'invité (étape 3).

## 3. Ouvrir le port de la box (seulement par internet)

Le serveur essaie de l'ouvrir **tout seul** (UPnP) au démarrage. S'il y arrive, la fenêtre affiche
« Port 8080 ouvert automatiquement sur votre box » : vous n'avez rien à faire.

Sinon, il faut le faire une fois à la main dans l'interface de votre box :

1. Ouvrez l'interface de la box dans le navigateur. Selon l'opérateur :
   Free `mafreebox.freebox.fr`, Orange `192.168.1.1`, SFR `192.168.1.1` (ou `192.168.0.1`), Bouygues `192.168.1.254`.
2. Cherchez « Redirection de ports », « NAT/PAT » ou « Gestion des ports ».
3. Ajoutez une règle :
   - protocole **TCP**
   - port externe **8080**, port interne **8080**
   - appareil / IP de destination : **l'adresse locale affichée par le serveur** (par exemple `192.168.1.23`)
4. Enregistrez, puis relancez le serveur.

Autre possibilité : activer l'UPnP dans la box (souvent dans la même page), puis relancer le serveur.

Si le port 8080 est déjà pris, choisissez-en un autre : `node server/serve.mjs 8081`
(et utilisez 8081 dans la redirection).

## Comment ça marche, et la latence

- Le serveur sert les fichiers du jeu et met les deux navigateurs en relation (« signalisation »).
- Les deux navigateurs se connectent ensuite **en direct** (WebRTC, pair à pair) : c'est le trajet
  le plus court possible entre vous deux. Des serveurs publics « STUN » (Google, Cloudflare)
  aident seulement à trouver le chemin ; aucune donnée de jeu ne passe par eux.
- Si la connexion directe échoue (certaines box ou réseaux d'entreprise la bloquent), les messages passent
  automatiquement **par le serveur de l'hôte**. Comme ce serveur est chez l'hôte, c'est quasiment aussi rapide.
  Sous le jeu, une ligne indique le mode utilisé et le ping.

## En cas de souci

| Problème | Que faire |
|---|---|
| L'invité voit « Ce site est inaccessible » | Le port n'est pas ouvert (étape 3), ou le pare-feu de l'ordinateur bloque Node.js. |
| La fenêtre parle de « CGNAT », « 4G » ou « box derrière une autre box » | Votre accès internet n'a pas d'adresse publique : l'invité ne peut pas vous joindre. Demandez une « IP fixe/full-stack » à votre opérateur (souvent gratuit), faites héberger l'autre joueur, ou passez par un VPN de jeu comme [Tailscale](https://tailscale.com) ou [ZeroTier](https://zerotier.com) (les deux l'installent, puis l'invité utilise l'adresse Tailscale/ZeroTier de l'hôte). |
| « Aucune partie avec le code... » | L'hôte a fermé la page ou le serveur ; il recrée une partie et renvoie le lien. |
| « Le port 8080 est déjà utilisé » | Kikifest tourne déjà dans une autre fenêtre, ou choisissez un autre port. |

## Réglages avancés

Copiez `server/config.example.json` en `server/config.json` et adaptez :
`port`, `upnp` (false pour ne pas toucher à la box), `openBrowser`, et `iceServers`
pour ajouter votre propre serveur TURN (relais WebRTC). Retirez l'exemple TURN si vous n'en avez pas :
un serveur TURN qui ne répond pas ralentit la connexion. Sans TURN, le repli par le serveur de l'hôte suffit.

Options de la ligne de commande : `node server/serve.mjs [port] [--no-upnp] [--no-open]`.
Pour tester le mode relais : ajoutez `?relay=1` à l'adresse de la page, chez les deux joueurs.

## Pour les développeurs

L'onglet Multijoueur (`src/menu/Online.hx`) crée ou rejoint la partie avec `web/js/kikinet.js`,
échange les pseudos puis la configuration de l'hôte (mode, options, familles, graine), et charge le jeu
dans la même page (`window.KIKI_NET`), pour garder la connexion. Le jeu (`src/game/Boot.hx`) branche
alors la session rollback (`src/net`, voir [NETCODE.md](NETCODE.md)).
L'objet `peer` est décrit en tête de `web/js/kikinet.js` (`role`, `seed`, `send`, `sendReliable`, `onmessage`...).

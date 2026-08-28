# Sync

`Sync` complète HTTP avec trois transports persistants :

| API | Transport | Sémantique | Usage |
| --- | --- | --- | --- |
| `Sync.Session` | TCP | fiable et ordonné | commandes, chat, événements |
| `Sync.SecureSession` | TCP chiffré et authentifié | fiable, ordonné et confidentiel | chat privé, contrôle authentifié |
| `Sync.Netcode` | UDP | non fiable et non ordonné | état fréquent, curseurs, télémétrie |

## Sessions fiables

Une session conserve les limites des messages et associe un canal `uint16` à
chaque charge binaire ou UTF-8. `send_text` encode en UTF-8 et `Message.text()`
le valide. La fermeture des connexions et listeners est explicite et idempotente.
Une `Session` simple ne chiffre ni n’authentifie ses pairs.

## Sessions sécurisées

`SecureSession` effectue un échange de clés authentifié, puis chiffre chaque
message. L’application distribue hors bande une invitation aléatoire de 256
bits ; ce n’est ni un mot de passe utilisateur, ni une identité durable. Le
protocole repose sur X25519, HKDF-SHA256 et ChaCha20-Poly1305 fournis par
`STD.Crypto`.

La session ne masque pas les adresses IP et ne fournit ni PKI publique, ni
révocation, ni récupération de compte, ni traversée NAT. Toute personne qui
possède l’invitation appartient à la session.

## Datagrammes orientés fraîcheur

`Netcode.Host` échange des datagrammes bornés avec canal, numéro de séquence et
octets opaques. `receive_into` réutilise un stockage appartenant à l’appelant.
`Freshness.tracker` classe chaque mise à jour par source et canal comme
`first`, `newer`, `duplicate` ou `stale`, sans conserver le corps.

`Heartbeat` fournit ping/pong et suivi de disponibilité avec une horloge
monotone injectée par l’application. `Statistics` accumule envois, réceptions,
pertes estimées, doublons et données périmées. Ces outils ne rendent pas UDP
fiable : les commandes qui doivent arriver appartiennent à `Session` ou
`SecureSession`.

La limite par défaut est de 1 200 octets afin de réduire le risque de
fragmentation IP. La limite dure de 65 000 octets n’est pas une recommandation
pour Internet.

## Politique de ressources

Les options règlent limites de message, connexions en attente et délais de
connexion, acceptation, lecture et écriture. `Sync.ErrorKind` distingue erreurs
de configuration, réseau, délai, fermeture, format, version, limites, texte,
clé, handshake, authentification et chiffrement.

Les frames Session ont un en-tête réseau fixe de douze octets et une limite
dure de 16 Mio. Les datagrammes Netcode ont un en-tête de seize octets et sont
validés indépendamment. `SecureSession` encapsule les frames Session après son
handshake ; Netcode reste volontairement en clair.

## Recettes

- [Échange de messages fiable](Recipes/Message-round-trip.md)
- [Session de chat sécurisée](Recipes/Secure-chat.md)
- [Échange Netcode orienté fraîcheur](Recipes/Netcode-round-trip.md)
- [Heartbeat et mesure réseau](Recipes/Heartbeat-round-trip.md)

## Développement

```text
silex link Packages/Sync
silex test Packages/Sync/Tests
```

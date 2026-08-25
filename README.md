# Sync for Silex

`Sync` is the communication and synchronization layer for games and
interactive applications. It will connect long-lived participants, exchange
messages with explicit delivery guarantees, coordinate time and keep shared
state synchronized when ordinary HTTP request-response flows are not enough.

The repository currently establishes the package boundary and its intended
responsibilities. It does not expose a runtime communication API yet. The first
public capability will be added only with an executable consumer that proves a
complete use case.

## Place in the Silex stack

`STD.Network` owns portable network primitives such as endpoints, TCP streams
and UDP sockets. `HTTP` owns bounded HTTP/1.1 clients and application servers.
`Sync` will build persistent, application-level communication and
synchronization semantics above those foundations without duplicating them.

A typical connected game can use HTTP for authentication, matchmaking,
configuration and downloads, then use Sync for the live session. A chat,
collaborative editor or distributed simulation can use the same Sync
capabilities without adopting multiplayer-specific concepts.

## Intended capability areas

The following names describe the current design territory, not committed
public modules:

- sessions and participant lifetime;
- message channels with explicit reliability, ordering and freshness;
- latency measurement, heartbeats, clocks and ticks;
- shared-state snapshots, deltas and replication;
- reconnection and bounded resource policies;
- game-oriented netcode such as interpolation, prediction, reconciliation and
  rollback.

`Sync.Netcode` is expected to specialize Sync for demanding game simulations.
Core communication and synchronization must remain useful to non-game
applications through capabilities such as `Sync.Session`, messaging and
replication.

## Non-goals

Sync is not a replacement for raw sockets or HTTP. It does not claim hard
real-time scheduling, transparent offline file synchronization or database
consensus. Transport, topology and delivery policies will remain explicit
where they change observable latency, reliability or ownership.

## Development

Sync is not registered in Silex Registry yet. Link the local checkout and the
isolated consumer explicitly:

```text
silex link Packages/Sync
silex link Packages/Sync --workspace Packages/Sync/Tests/Consumer
silex test Packages/Sync/Tests/Consumer/Tests
```

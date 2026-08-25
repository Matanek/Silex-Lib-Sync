# Sync for Silex

`Sync` provides persistent communication primitives for games and interactive
applications. It complements HTTP with two deliberately different transports:

| Capability | Transport | Delivery | Good fit |
| --- | --- | --- | --- |
| `Sync.Session` | TCP | reliable and ordered | control messages, chat, commands, collaborative events |
| `Sync.Netcode` | UDP | unreliable and unordered | frequent game state, cursors, telemetry and other freshness-first updates |

The names describe communication semantics rather than a multiplayer product,
so the same package can serve a game, chat client, collaborative editor or
distributed simulation.

Sync is not registered in Silex Registry yet. Link the local checkout before
using it.

## Reliable sessions

A session preserves message boundaries and attaches a `uint16` channel to each
binary or UTF-8 payload. Channels are application routing labels in this first
version; every message still inherits TCP's reliable, ordered delivery.

```sx
use Sync
use Sync.Session

var listener = try Session.listen("127.0.0.1", 9000)
var connection = try listener.accept()

let message = try connection.receive()
print("channel $(message.channel): $(try message.text())")
try connection.send_text(2, "welcome")
```

A client can connect by hostname and port or by an already resolved
`STD.Network.Endpoint`:

```sx
var by_name = try Session.connect("example.com", 9000)
var by_endpoint = try Session.connect_endpoint(endpoint)
```

`Connection.send` accepts a shared byte view without converting it to text.
`send_text` encodes UTF-8, while `Message.text()` validates UTF-8 explicitly.
`local_endpoint` and `peer_endpoint` expose the established endpoints.
`Connection.close` and `Listener.close` are explicit and idempotent; dropping
either resource also closes its owned socket.

See [MessageRoundTrip.sx](Examples/MessageRoundTrip.sx) for a complete,
self-contained client/server exchange.

## Freshness-first datagrams

`Netcode.Host` exchanges bounded UDP datagrams carrying a channel, a sequence
number and opaque bytes. It does not hide UDP semantics: packets may be lost,
duplicated or reordered. The application decides which updates matter.

```sx
use Sync
use Sync.Netcode

var host = try Netcode.bind("127.0.0.1", 9001)
var sequence = Netcode.Sequencer()

let state:uint8[] = [12, 34, 56]
try host.send(peer, 1, sequence.take(), @state[0:state.count()])

var storage:uint8[1_200]
var storage_view = &storage[0:storage.count()]
let update = try host.receive_into(storage_view)

if Netcode.is_newer(update.sequence, last_sequence) {
    // Decode storage_view[0:update.payload_bytes] and apply the fresh state.
}
```

`receive_into` reuses caller-owned storage and is the preferred hot-path API;
it performs no payload allocation. `receive` is a convenient alternative that
returns an owned payload copy. Sending reuses storage owned by the host.

Sequence numbers wrap safely at `uint32`'s maximum. `Sequencer` creates them,
while `is_newer` compares them using the usual half-range rule. They provide
freshness metadata only: Sync does not automatically discard stale packets.

The default payload limit is 1,200 bytes, a conservative size chosen to reduce
IP fragmentation risk. The configurable hard ceiling is 65,000 bytes, but a
larger allowed payload does not make large UDP packets suitable for the public
Internet. `Netcode.bind` accepts numeric IPv4 or IPv6 addresses; `bind_endpoint`
and `open` support already resolved endpoints and client-style sockets.

See [NetcodeRoundTrip.sx](Examples/NetcodeRoundTrip.sx) for a complete loopback
exchange.

## Configure resource policy

Session defaults allow messages up to one MiB, bound pending connections to
128, apply ten-second connect and write timeouts, and leave accept and read
waits unbounded for long-lived idle sessions.

```sx
let options = Session.default_options()
    .with_message_limit(64 * 1024)
    .with_connect_timeout(5_000)
    .with_accept_timeout(1_000)
    .with_read_timeout(30_000)
    .with_write_timeout(5_000)
```

Netcode applies its payload limit on both send and receive and exposes read and
write timeouts independently:

```sx
let options = Netcode.default_options()
    .with_payload_limit(1_000)
    .with_read_timeout(16)
    .with_write_timeout(1_000)
```

`Sync.ErrorKind` distinguishes invalid configuration, network failure,
timeout, closure, malformed messages, unsupported versions, message limits and
invalid text.

## Protocol boundaries

Session frames use a fixed twelve-byte, network-order header containing the
`SYNC` signature, protocol version 1, reserved flags, channel and payload
length. The hard payload ceiling is 16 MiB. A malformed or oversized frame
invalidates the connection because continuing could reinterpret body bytes as
a new message.

Netcode datagrams use a fixed sixteen-byte, network-order header containing the
same signature, protocol version 1, datagram kind, channel, sequence and payload
length. Each datagram is independently validated, so a malformed one does not
invalidate the UDP host.

Neither protocol is encrypted or authenticated. Use them only where plain TCP
or UDP is acceptable until Sync owns secure session transports.

## Scope

`STD.Network` owns endpoints and raw TCP/UDP sockets. `HTTP` owns bounded
HTTP/1.1 clients and application servers. Sync adds framed, long-lived
application communication without duplicating those primitives.

A connected game can use HTTP for authentication, matchmaking, configuration
and downloads, `Sync.Session` for reliable control traffic, and `Sync.Netcode`
for frequent state updates.

This foundation intentionally does not yet claim acknowledgements,
retransmission, congestion control, NAT traversal, replication, snapshots,
interpolation, prediction, reconciliation or rollback. Those policies can be
built above the stable Session and Netcode boundaries without confusing their
transport semantics. Sync also does not claim hard real-time scheduling,
transparent offline file synchronization or database consensus.

## Development

Register the checkout and prove both package internals and its isolated public
consumer:

```text
silex link Packages/Sync
silex link Packages/Sync --workspace Packages/Sync/Tests/Consumer
silex test Packages/Sync/Tests/Protocol.sx
silex test Packages/Sync/Tests/NetcodeProtocol.sx
silex test Packages/Sync/Tests/Consumer/Tests
silex run Packages/Sync/Examples/MessageRoundTrip.sx
silex run Packages/Sync/Examples/NetcodeRoundTrip.sx
```

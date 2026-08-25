# Sync for Silex

`Sync` provides persistent communication and shared-state synchronization for
games and interactive applications. Its first public capability,
`Sync.Session`, exchanges bounded messages over long-lived TCP connections
when ordinary HTTP request-response flows are not enough.

Sync is not registered in Silex Registry yet. Link the local checkout before
using it.

## Exchange messages

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

## Configure resource policy

The defaults allow messages up to one MiB, bound pending connections to 128,
apply ten-second connect and write timeouts, and leave accept and read waits
unbounded for long-lived idle sessions.

```sx
let options = Session.default_options()
    .with_message_limit(64 * 1024)
    .with_connect_timeout(5_000)
    .with_accept_timeout(1_000)
    .with_read_timeout(30_000)
    .with_write_timeout(5_000)
```

The hard per-message ceiling is 16 MiB. A sender rejects an oversized payload
before writing any frame bytes. A receiver closes the connection when a peer
declares an oversized payload, sends an invalid signature, selects an
unsupported protocol version or truncates a frame; continuing after those
errors could otherwise reinterpret body bytes as a new message.

`Sync.ErrorKind` distinguishes invalid configuration, network failure,
timeout, closure, malformed frames, unsupported versions, message limits and
invalid text.

## Protocol boundary

Session framing has a fixed twelve-byte, network-order header containing the
`SYNC` signature, protocol version 1, reserved flags, channel and payload
length. The framing is deliberately small and bounded, but it is not encrypted
or authenticated. Applications must use it only where plain TCP is acceptable
until Sync owns a secure session transport.

One connection may carry many application channels, but this initial protocol
does not provide independent channel flow control. A large TCP message can
delay messages following it.

## Place in the Silex stack

`STD.Network` owns endpoints, TCP streams and UDP sockets. `HTTP` owns bounded
HTTP/1.1 clients and application servers. `Sync.Session` adds persistent,
framed application messaging without duplicating those primitives.

A connected game can use HTTP for authentication, matchmaking, configuration
and downloads, then use Sync for the live session. A chat, collaborative
editor or distributed simulation can use the same session API without
adopting multiplayer-specific concepts.

`Sync.Session` is suitable for reliable control messages, chat and
collaborative events. It does not claim to be high-frequency visual netcode:
UDP delivery policies, freshness, snapshots, interpolation, prediction,
reconciliation and rollback belong to the future `Sync.Netcode` capability.

Sync also does not claim hard real-time scheduling, transparent offline file
synchronization or database consensus.

## Development

Register the checkout and prove both the package internals and its isolated
public consumer:

```text
silex link Packages/Sync
silex link Packages/Sync --workspace Packages/Sync/Tests/Consumer
silex test Packages/Sync/Tests/Protocol.sx
silex test Packages/Sync/Tests/Consumer/Tests
silex run Packages/Sync/Examples/MessageRoundTrip.sx
```

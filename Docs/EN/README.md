# Sync

`Sync` complements HTTP with three persistent transports:

| API | Transport | Semantics | Use |
| --- | --- | --- | --- |
| `Sync.Session` | TCP | reliable and ordered | commands, chat, events |
| `Sync.SecureSession` | encrypted authenticated TCP | reliable, ordered, confidential | private chat, authenticated control |
| `Sync.Netcode` | UDP | unreliable and unordered | frequent state, cursors, telemetry |

## Reliable sessions

A session preserves message boundaries and associates a `uint16` channel with
each binary or UTF-8 payload. `send_text` encodes UTF-8 and `Message.text()`
validates it. Connections and listeners close explicitly and idempotently. A
plain `Session` does not encrypt or authenticate its peers.

## Secure sessions

`SecureSession` performs an authenticated key exchange and then encrypts every
message. The application distributes a random 256-bit invitation out of band;
it is neither a user password nor a durable identity. The protocol builds on
X25519, HKDF-SHA256, and ChaCha20-Poly1305 from `STD.Crypto`.

The session does not hide IP addresses and provides no public PKI, revocation,
account recovery, or NAT traversal. Anyone who holds the invitation belongs to
the session.

## Freshness-first datagrams

`Netcode.Host` exchanges bounded datagrams with a channel, sequence number, and
opaque bytes. `receive_into` reuses caller-owned storage. `Freshness.tracker`
classifies each update by source and channel as `first`, `newer`, `duplicate`,
or `stale` without retaining its body.

`Heartbeat` provides ping/pong and liveness tracking with a monotonic clock
injected by the application. `Statistics` accumulates sends, receives,
estimated loss, duplicates, and stale data. These tools do not make UDP
reliable: commands that must arrive belong on `Session` or `SecureSession`.

The default payload limit is 1,200 bytes to reduce IP fragmentation risk. The
65,000-byte hard limit is not a recommendation for Internet traffic.

## Resource policy

Options configure message limits, pending connections, and connect, accept,
read, and write timeouts. `Sync.ErrorKind` distinguishes configuration,
network, timeout, closure, format, version, limit, text, key, handshake,
authentication, and cryptographic errors.

Session frames have a fixed twelve-byte network-order header and a 16 MiB hard
limit. Netcode datagrams have a sixteen-byte header and are validated
independently. `SecureSession` encapsulates Session frames after its handshake;
Netcode intentionally remains cleartext.

## Recipes

- [Reliable message exchange](Recipes/Message-round-trip.md)
- [Secure chat session](Recipes/Secure-chat.md)
- [Freshness-first Netcode exchange](Recipes/Netcode-round-trip.md)
- [Heartbeat and network measurement](Recipes/Heartbeat-round-trip.md)

## Development

```text
silex link Packages/Sync
silex test Packages/Sync/Tests
```

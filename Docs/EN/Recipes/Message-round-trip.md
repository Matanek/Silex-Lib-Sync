# Reliable message exchange

This recipe opens a local listener, connects both endpoints, and exchanges two
messages on separate channels. Port `0` lets the system choose an available
port.

```sx
use Sync
use Sync.Session

func run() Result<void, Sync.Error> {
    var listener = try Session.listen("127.0.0.1", 0)
    let endpoint = try listener.local_endpoint()
    var client = try Session.connect_endpoint(endpoint)
    var server = try listener.accept()

    try client.send_text(1, "hello")
    let incoming = try server.receive()
    print("server received channel $(incoming.channel): $(try incoming.text())")

    try server.send_text(2, "welcome")
    let reply = try client.receive()
    print("client received channel $(reply.channel): $(try reply.text())")

    try client.close()
    try server.close()
    return listener.close()
}

func main() {
    match run() {
        success => {}
        failure(error) => { panic(error.operation + ": " + error.detail) }
    }
}
```

The listener and both connections own their sockets. The recipe closes them
explicitly even though dropping them would also close them.

# Échange de messages fiable

Cette recette ouvre un listener local, connecte les deux extrémités, puis
échange deux messages sur des canaux distincts. Le port `0` laisse le système
choisir un port disponible.

```sx
use Sync
use Sync.Session

func run() Result<void, Sync.Error> {
    var listener = try Session.listen("127.0.0.1", 0) else error { return Result<void,Sync.Error>.failure(error) }
    let endpoint = try listener.local_endpoint() else error { return Result<void,Sync.Error>.failure(error) }
    var client = try Session.connect_endpoint(endpoint) else error { return Result<void,Sync.Error>.failure(error) }
    var server = try listener.accept() else error { return Result<void,Sync.Error>.failure(error) }

    try client.send_text(1, "hello") else error { return Result<void,Sync.Error>.failure(error) }
    let incoming = try server.receive() else error { return Result<void,Sync.Error>.failure(error) }
    print("server received channel $(incoming.channel): $(try incoming.text() else error { return Result<void,Sync.Error>.failure(error) })")

    try server.send_text(2, "welcome") else error { return Result<void,Sync.Error>.failure(error) }
    let reply = try client.receive() else error { return Result<void,Sync.Error>.failure(error) }
    print("client received channel $(reply.channel): $(try reply.text() else error { return Result<void,Sync.Error>.failure(error) })")

    try client.close() else error { return Result<void,Sync.Error>.failure(error) }
    try server.close() else error { return Result<void,Sync.Error>.failure(error) }
    return (try listener.close())
}

func main() {
    match (try run()) {
        success => {}
        failure(error) => { panic(error.operation + ": " + error.detail) }
    }
}
```

Le listener et les deux connexions possèdent leurs sockets : la recette les
ferme explicitement, même si leur destruction les fermerait aussi.

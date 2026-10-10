# Session de chat sécurisée

Le listener doit accepter dans un worker pendant que le client se connecte. La
même invitation authentifie les deux pairs et ne doit être ni journalisée, ni
committée.

```sx
use Sync
use Sync.SecureSession
use STD.Threading

func connection(result:Result<SecureSession.Connection, Sync.Error>) SecureSession.Connection {
    match result {
        success(value) => { return value }
        failure(error) => { panic(error.detail) }
    }
    panic("secure connection result was not handled")
}

func listener(result:Result<SecureSession.Listener, Sync.Error>) SecureSession.Listener {
    match result {
        success(value) => { return value }
        failure(error) => { panic(error.detail) }
    }
    panic("secure listener result was not handled")
}

func message(result:Result<Sync.Message, Sync.Error>) Sync.Message {
    match result {
        success(value) => { return value }
        failure(error) => { panic(error.detail) }
    }
    panic("secure message result was not handled")
}

func endpoint<T>(result:Result<T, Sync.Error>) T {
    match result {
        success(value) => { return value }
        failure(error) => { panic(error.detail) }
    }
    panic("secure endpoint result was not handled")
}

func text(result:Result<str, Sync.Error>) str {
    match result {
        success(value) => { return value }
        failure(error) => { panic(error.detail) }
    }
    panic("secure text result was not handled")
}

func sent(result:Result<void, Sync.Error>) {
    match result {
        success => {}
        failure(error) => { panic(error.detail) }
    }
}

func serve(listener:SecureSession.Listener) {
    var peer = connection((try listener.accept()))
    let incoming = message((try peer.receive()))
    print("server received: $(text((try incoming.text())))")
    sent((try peer.send_text(2, "welcome securely")))
}

struct Server:Threading.Job {
    var listener:SecureSession.Listener
    func execute() { serve(self.listener) }
}

func main() {
    let key = SecureSession.generate_key()
    var server_listener = listener((try SecureSession.listen("127.0.0.1", 0, key)))
    let server_endpoint = endpoint((try server_listener.local_endpoint()))
    var executor = Threading.Executor(worker_count:1)
    var server = executor.submit(Server(listener:server_listener))

    var client = connection((try SecureSession.connect_endpoint(server_endpoint, key)))
    sent((try client.send_text(1, "hello securely")))
    let reply = message((try client.receive()))
    print("client received: $(text((try reply.text())))")
    var completed = server.complete()
}
```

`generate_key()` fournit une invitation aléatoire forte. Pour rejoindre une
session distante, transmettez sa représentation `text()` par un canal distinct,
puis reconstruisez-la avec `parse_key`.

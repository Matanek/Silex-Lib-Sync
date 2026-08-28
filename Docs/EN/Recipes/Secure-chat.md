# Secure chat session

The listener must accept in a worker while the client connects. The same
invitation authenticates both peers and must never be logged or committed.

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
    var peer = connection(listener.accept())
    let incoming = message(peer.receive())
    print("server received: $(text(incoming.text()))")
    sent(peer.send_text(2, "welcome securely"))
}

struct Server:Threading.Job {
    var listener:SecureSession.Listener
    func execute() { serve(self.listener) }
}

func main() {
    let key = SecureSession.generate_key()
    var server_listener = listener(SecureSession.listen("127.0.0.1", 0, key))
    let server_endpoint = endpoint(server_listener.local_endpoint())
    var executor = Threading.Executor(worker_count:1)
    var server = executor.submit(Server(listener:server_listener))

    var client = connection(SecureSession.connect_endpoint(server_endpoint, key))
    sent(client.send_text(1, "hello securely"))
    let reply = message(client.receive())
    print("client received: $(text(reply.text()))")
    var completed = server.complete()
}
```

`generate_key()` provides a strong random invitation. To join a remote session,
send its `text()` representation through a separate channel, then reconstruct
it with `parse_key`.

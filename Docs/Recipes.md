# Recettes Sync

Ces recettes regroupent les échanges loopback complets. Elles complètent les
extraits orientés API du README sans créer de catalogue d’exécutables dans le
package.

## MessageRoundTrip

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

## NetcodeHealthRoundTrip

```sx
use Sync
use Sync.Netcode
use Sync.Netcode.Heartbeat
use STD.Math
use STD.Time.Stopwatch

func status_text(status:Heartbeat.Status) str {
    return match status { waiting => "waiting"; alive => "alive"; timed_out => "timed out" }
}

func run() Result<void, Sync.Error> {
    var server = try Netcode.bind("127.0.0.1", 0)
    var client = try Netcode.bind("127.0.0.1", 0)
    let destination = try server.local_endpoint()
    var timer = Stopwatch()
    timer.start()
    let started = Math.floor(timer.get_elapsed_milliseconds()) as int
    var heartbeat = try Heartbeat.state(started)
    var sequence = Netcode.Sequencer()

    let request = try Heartbeat.ping(started)
    let request_payload = Heartbeat.encode(request)
    try client.send(destination, 65_000, sequence.take(), @request_payload[0:16])
    heartbeat.mark_sent(started)

    let received = try server.receive()
    let decoded_request = try Heartbeat.decode(
        @received.payload[0:received.payload.count()]
    )
    let response = try Heartbeat.pong(decoded_request)
    let response_payload = Heartbeat.encode(response)
    try server.send(received.sender, 65_000, received.sequence, @response_payload[0:16])

    let reply = try client.receive()
    let decoded_response = try Heartbeat.decode(@reply.payload[0:reply.payload.count()])
    let now = Math.floor(timer.get_elapsed_milliseconds()) as int
    let round_trip = try Heartbeat.round_trip_milliseconds(decoded_response, now)
    heartbeat.observe_receive(now)
    print("peer $(status_text(heartbeat.status(now))), round trip $(round_trip) ms")

    try client.close()
    return server.close()
}

func main() {
    match run() {
        success => {}
        failure(error) => { panic(error.operation + ": " + error.detail) }
    }
}
```

## NetcodeRoundTrip

```sx
use Sync
use Sync.Netcode
use Sync.Netcode.Freshness

func run() Result<void, Sync.Error> {
    var server = try Netcode.bind("127.0.0.1", 0)
    var client = try Netcode.bind("127.0.0.1", 0)
    var freshness = try Freshness.tracker()
    let destination = try server.local_endpoint()

    var sequence = Netcode.Sequencer()
    let position:uint8[] = [12, 34, 56]
    try client.send(
        destination,
        1,
        sequence.take(),
        @position[0:position.count()]
    )

    var payload:uint8[1_200]
    var payload_view = &payload[0:payload.count()]
    let update = try server.receive_into(payload_view)
    let decision = try freshness.observe(update)
    if decision.should_apply() {
        print(
            "channel $(update.channel), sequence $(update.sequence), " +
            "$(update.payload_bytes) fresh state bytes"
        )
    }

    try client.close()
    return server.close()
}

func main() {
    match run() {
        success => {}
        failure(error) => { panic(error.operation + ": " + error.detail) }
    }
}
```

## SecureChatRoundTrip

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

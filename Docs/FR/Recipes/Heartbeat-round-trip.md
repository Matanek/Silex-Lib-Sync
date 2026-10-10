# Heartbeat et mesure réseau

Cette boucle locale montre le cycle complet ping/pong. L’application injecte
le temps monotone ; elle peut ainsi partager un échantillon entre plusieurs
pairs et rendre ses tests déterministes.

```sx
use Sync
use Sync.Netcode
use Sync.Netcode.Heartbeat
use STD.Math
use STD.Time.Stopwatch

func run() Result<void, Sync.Error> {
    var server = try Netcode.bind("127.0.0.1", 0) else error { return Result<void,Sync.Error>.failure(error) }
    var client = try Netcode.bind("127.0.0.1", 0) else error { return Result<void,Sync.Error>.failure(error) }
    let destination = try server.local_endpoint() else error { return Result<void,Sync.Error>.failure(error) }
    var timer = Stopwatch()
    timer.start()
    let started = Math.floor(timer.get_elapsed_milliseconds()) as int
    var heartbeat = try Heartbeat.state(started) else error { return Result<void,Sync.Error>.failure(error) }
    var sequence = Netcode.Sequencer()

    let request = try Heartbeat.ping(started) else error { return Result<void,Sync.Error>.failure(error) }
    let request_payload = Heartbeat.encode(request)
    try client.send(destination, 65_000, sequence.take(), @request_payload[0:16]) else error { return Result<void,Sync.Error>.failure(error) }
    heartbeat.mark_sent(started)

    let received = try server.receive() else error { return Result<void,Sync.Error>.failure(error) }
    let decoded_request = try Heartbeat.decode(@received.payload[0:received.payload.count()]) else error { return Result<void,Sync.Error>.failure(error) }
    let response = try Heartbeat.pong(decoded_request) else error { return Result<void,Sync.Error>.failure(error) }
    let response_payload = Heartbeat.encode(response)
    try server.send(received.sender, 65_000, received.sequence, @response_payload[0:16]) else error { return Result<void,Sync.Error>.failure(error) }

    let reply = try client.receive() else error { return Result<void,Sync.Error>.failure(error) }
    let decoded_response = try Heartbeat.decode(@reply.payload[0:reply.payload.count()]) else error { return Result<void,Sync.Error>.failure(error) }
    let now = Math.floor(timer.get_elapsed_milliseconds()) as int
    let round_trip = try Heartbeat.round_trip_milliseconds(decoded_response, now) else error { return Result<void,Sync.Error>.failure(error) }
    heartbeat.observe_receive(now)
    print("round trip $(round_trip) ms")

    try client.close() else error { return Result<void,Sync.Error>.failure(error) }
    return (try server.close())
}

func main() {
    match (try run()) {
        success => {}
        failure(error) => { panic(error.operation + ": " + error.detail) }
    }
}
```

Le canal `65_000` est un choix de l’application, pas une valeur réservée par
Sync. En production, appelez aussi `status(now)` pour distinguer `waiting`,
`alive` et `timed_out`.

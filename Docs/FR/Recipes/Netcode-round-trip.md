# Échange Netcode orienté fraîcheur

Cette recette envoie un état UDP, réutilise un tampon de réception et demande
au tracker si la mise à jour doit être appliquée.

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
    try client.send(destination, 1, sequence.take(), @position[0:position.count()])

    var payload:uint8[1_200]
    var payload_view = &payload[0:payload.count()]
    let update = try server.receive_into(payload_view)
    let decision = try freshness.observe(update)
    if decision.should_apply() {
        print("channel $(update.channel), sequence $(update.sequence), " +
            "$(update.payload_bytes) fresh state bytes")
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

Le tracker ne conserve pas le corps. Le contenu utile reste dans
`payload_view[0:update.payload_bytes]` et doit être décodé avant de réutiliser
le tampon.

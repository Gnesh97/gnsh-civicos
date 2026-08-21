# CivicOS Public API v1

The resource exposes a small, versioned export surface. Mutating integration
calls must include a unique `idempotencyKey`; repeating the same key and payload
returns the stored result without creating another record.

```lua
local result = exports["gnsh-civicos"]:CreateRequest({
    serviceCode = "traffic_signal_failure",
    title = "Signal controller offline",
    description = "The intersection is dark.",
    location = { x = 100.0, y = 200.0, z = 30.0 },
}, {
    sourceResource = "signalgrid",
    externalRef = "signal-123",
    idempotencyKey = "signal-123-v1",
})
```

Available exports:

- `CreateRequest(input, context)` — integration-enabled catalog request.
- `GetRequest(id)` — permission-safe request DTO.
- `UpdateRequest(id, expectedVersion, patch, context)` — title/description allowlist.
- `ResolveRequest(id, expectedVersion, reason, context)` — guarded integration resolve.
- `CreateWorkOrder(requestId, expectedVersion, serviceCode, overrides, context)`.
- `GetWorkOrder(id)` — permission-safe work-order DTO.
- `AddComment(requestId, body, context)` — public integration comment.
- `GetHealth()` — resource/database/provider health.

All results use the standard `{ ok = true, data = ... }` or
`{ ok = false, error = { code, message, details } }` envelope. `expectedVersion`
is mandatory for optimistic concurrency operations. Event delivery uses the
persistent outbox and is at-least-once; consumers should deduplicate by
`correlationId`.

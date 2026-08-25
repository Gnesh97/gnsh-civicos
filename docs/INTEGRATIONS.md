# CivicOS Integrations

Third-party resources should use public exports or the documented callback
contract. Do not write CivicOS tables directly and do not trust client events as
integration authentication.

## Public exports

Available integration boundaries are listed in [`docs/api/API.md`](api/API.md)
and implemented in `server/api/exports.lua`:

- `CreateRequest`, `GetRequest`, `UpdateRequest`, `ResolveRequest`;
- `CreateWorkOrder`, `GetWorkOrder`, `AddComment`;
- `GetHealth`.

Mutation calls require a unique `idempotencyKey`. CivicOS derives the owning
`sourceResource` from FiveM's server-side invoking-resource context and derives
the audit actor as `integration:<resource>`; caller-supplied values for either
field are ignored. `GetRequest` and `GetWorkOrder` are limited to records owned
by that invoking resource. Reusing the same key with a different payload is an
idempotency collision and is rejected.

## Examples

Copy the patterns in [`integrations/examples`](../integrations/examples). Each
example treats CivicOS responses as an envelope (`ok`, `data`, or `error`),
stores the returned reference/version, and retries only with the same logical
idempotency key.

## Events and outbox

Domain events are emitted through `CivicOS.EventBus`. Set the outbox option for
durable integration delivery; the shared worker retries failures and moves
exhausted events to the dead-letter state. Consumers must be idempotent and
must not assume delivery order across independent event names.

## Security boundary

Integration identity is not a player identity. The API validates resource scope,
payload size, versions, state-machine transitions, and idempotency before any
mutation. Keep integration secrets outside the repository and rotate them using
the host/server secret mechanism.

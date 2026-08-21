# CivicOS Abuse Scenario Matrix

This is the S14 abuse contract. Each case must be executed against a disposable
database and a framework adapter with server-side assertions. A passing case is
an expected rejection code plus no persisted state change.

| Case | Input / action | Expected result |
| --- | --- | --- |
| Invalid IDs | Read/update request, work order, inspection, evidence, or crew with `0`, a negative ID, a string ID, and a missing ID | `CORE_NOT_FOUND` or `CORE_INVALID_INPUT`; no query result is exposed |
| Wrong department | Staff actor from department A targets a department B request/work order | `AUTH_FORBIDDEN` / department mismatch; no transition or assignment |
| Wrong assignment | Unassigned technician invokes a field action or assigned-scope read | `FIELD_ACTOR_NOT_ASSIGNED` / `AUTH_FORBIDDEN` |
| State skipping | Submit a direct `created -> completed`, `pending_inspection -> closed`, or invalid request transition | State-machine error; version and audit remain unchanged |
| Duplicate completion | Repeat completion with the same version and action key | First call succeeds; retry returns version conflict or idempotent replay; one completion event |
| Token replay | Reuse a consumed action token, alter its action/entity/version, or use an expired token | `FIELD_TOKEN_REPLAY` / `FIELD_TOKEN_INVALID`; no inventory/checklist mutation |
| Rate-limit abuse | Burst request creation, comments, and generic callbacks beyond configured windows | `RATE_LIMITED`; accepted count never exceeds the configured limit |
| Oversized payload | Strings above schema limits, deeply nested metadata, and payloads above `MaxActionPayloadBytes` | Validation error; no partial insert |
| Malformed vectors | Missing/non-numeric `x`, `y`, or `z`; `NaN`/infinite-like values; location far outside radius | `FIELD_POSITION_UNAVAILABLE` / `FIELD_TOO_FAR`; no field action |
| Idempotency collision | Reuse one integration key with a different payload hash | `IDEMPOTENCY_CONFLICT`; original response and entity remain unchanged |
| Crew boundary | Non-member performs a crew work order action; offline member attempts action | `FIELD_ACTOR_NOT_ASSIGNED`; active crew assignment remains intact |
| Disconnect race | Disconnect, reconnect before grace, then let the original grace callback fire | Reconnected session keeps the solo assignment; stale callback does not release it |

## Evidence to capture

- Response envelope (`ok`, `error.code`, and redacted details).
- Entity version before and after the rejected call.
- Audit/outbox row count before and after.
- Assignment, checklist, inventory, and notification side effects.
- Server log correlation ID for the request.

No client event is considered a security assertion. The server must remain the
source of truth for identity, authorization, distance, state, token consumption,
and idempotency.

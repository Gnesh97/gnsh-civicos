# ADR-001: Server-Authoritative State Changes

- **Status:** Accepted
- **Date:** 2026-08-22
- **Scope:** Request, Work Order, assignment, payment, permissions, items, SLA,
  distance and inspection transitions

## Context

FiveM clients are untrusted and can replay, reorder or forge events. A client
must not be able to skip a lifecycle state, complete work from a distance or
claim a reward by sending a crafted payload.

## Decision

All critical actions are validated and committed server-side. The server checks
authenticated actor, permission, department/assignment scope, entity existence,
current state, expected version, business preconditions, distance, item
availability, idempotency and rate limits before applying a transition. State
changes use the state machine and produce activity, audit and domain-event
records as required.

## Consequences

- Client code stays presentation/intent only.
- Invalid or replayed events return a standard error envelope.
- Server and database work increases, but exploit resistance and auditability are
  explicit product guarantees.

## Rejected alternatives

- Trusting NUI/client state: forgeable and replayable.
- Client-only distance or item checks: trivially bypassed.
- Direct string assignment: skips transition invariants.

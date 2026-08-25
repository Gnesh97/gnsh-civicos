# ADR-005: Optimistic Concurrency and Idempotent Transitions

- **Status:** Accepted
- **Date:** 2026-08-22
- **Scope:** Request/Work Order updates, assignments, public APIs and actions

## Context

Two dispatchers can edit one entity concurrently, and clients can retry a
request after a timeout. Silent last-write-wins and duplicate side effects would
corrupt assignment, payment, SLA and audit state.

## Decision

Persistent Request and Work Order records carry an integer `version`. Mutations
include `expectedVersion` and update atomically only when it matches; conflicts
return a stable concurrency error. Public integration calls accept an
idempotency key. Field actions use one-time, short-lived server-issued action
tokens. Request conversion claims the request version before a guarded batch
insert, so concurrent conversion attempts cannot materialize duplicate child
work orders. Side effects are recorded with correlation/idempotency identifiers.

## Consequences

- Clients must refresh after conflict and may safely retry idempotent calls.
- Every mutation path needs explicit version and idempotency handling.
- Duplicate delivery becomes observable instead of producing duplicate work.

## Rejected alternatives

- Last-write-wins: silently overwrites dispatcher work.
- Client-generated completion/payment flags: forgeable and non-idempotent.
- Infinite-lived tokens: replay window is too large.

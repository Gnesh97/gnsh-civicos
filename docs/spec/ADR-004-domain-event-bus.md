# ADR-004: Domain Event Bus and Integration Fan-Out

- **Status:** Accepted
- **Date:** 2026-08-22
- **Scope:** Core service notifications, audit, integrations and outbox

## Context

Request, Work Order, SLA, notification and integration services should not form a
direct dependency graph. External delivery can fail transiently and must not
silently erase a committed domain transition.

## Decision

Services emit versioned internal domain events after the repository transaction
commits. Subscribers handle audit, notification, read-model and integration
work. External delivery is persisted in a transactional outbox with retry and
at-least-once semantics. Handlers must be idempotent and receive a correlation
identifier.

## Consequences

- Producers stay loosely coupled and new connectors do not require core changes.
- Event ordering and duplicate delivery must be documented and tested.
- Outbox retention and retry workers become operational responsibilities.

## Rejected alternatives

- Direct service-to-service calls everywhere: creates tight coupling and hidden
  failure paths.
- Fire-and-forget external events: loses events during provider/network failure.
- Publishing before commit: consumers can observe state that later rolls back.

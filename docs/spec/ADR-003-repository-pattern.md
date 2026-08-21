# ADR-003: Repository Boundary for Persistence

- **Status:** Accepted
- **Date:** 2026-08-22
- **Scope:** MySQL/MariaDB persistence and all schema-backed services

## Context

Direct SQL scattered through callbacks and services makes migrations, testing,
transactions and security inconsistent. Persistent timestamps, concurrency and
audit records need one controlled boundary.

## Decision

SQL exists only in repository/database adapter modules. Services depend on
repository interfaces, not oxmysql or another provider. Repositories own
parameterized queries, transaction boundaries, mapping, pagination and
optimistic-version updates. Schema changes always ship as migrations.

## Consequences

- Repository tests can run against fixtures or a test database.
- Service code is provider-independent and easier to review.
- Small query methods add some indirection, which is accepted for consistency.

## Rejected alternatives

- SQL in NUI callbacks/services: hard to secure and impossible to swap cleanly.
- Raw DB entities sent to clients: leaks internal fields and PII.
- Metadata-only schema: critical filter fields cannot be indexed reliably.

# Changelog

All notable CivicOS changes are recorded here. Every commit after this file was
introduced must add or amend an entry.

## [Unreleased]

### NUI document display fix

- Changed the closed HTML document surface from visibility-only hiding to
  `display: none`, preventing FiveM from retaining a black full-screen layer.
- Kept the document root and body display transitions covered by the NUI
  lifecycle regression test.

### NUI surface visibility hardening

- Hid the HTML surface itself while CivicOS is closed so FiveM cannot retain a
  black full-screen NUI layer behind the game HUD.
- Applied the visible class to both the document root and body only after an
  explicit open message.
- Added regression coverage for the HTML visibility transition.

### NUI overlay teardown

- Made the closed NUI document transparent at the HTML root so it cannot
  leave a full-screen dark overlay over the game.
- Explicitly clear NUI focus and send a close message when the client resource
  initializes or restarts.
- Extended the NUI lifecycle regression to cover transparent startup state and
  restart cleanup.

### Client adapter startup fix

- Loaded the shared result envelope before client target adapters so target
  validation no longer crashes on a missing `CivicOS.Result` value.
- Added a manifest/load-order regression test covering the shared and server
  script blocks.

### Command-gated NUI visibility

- Kept the CivicOS NUI hidden during resource startup instead of rendering it
  over the game immediately.
- Opened the panel only after the `/civicos` client command sends the NUI open
  message, with Close and Escape closing the panel and releasing focus.
- Added a regression test for the command and open/close message lifecycle.

### oxmysql async export fix

- Switched the database adapter to oxmysql's documented `*_async` exports so
  scalar migration version reads wait for their result instead of returning
  `nil` immediately.
- Prevented duplicate migration/index attempts caused by treating callback
  exports as synchronous operations.
- Expanded the adapter regression test to cover query, scalar, and transaction
  async exports.

### Migration and schema startup guard

- Split SQL migration files into individual statements so oxmysql does not
  require `multipleStatements` to be enabled.
- Included migration SQL files in the FiveM resource package.
- Declared the oxmysql resource dependency so grouped resource startup cannot
  run CivicOS before the database provider is ready.
- Added required-table verification and prevented the scheduler from starting
  when CivicOS schema tables are missing, replacing repeated worker errors with
  one actionable startup failure.
- Added Lua regression coverage for statement splitting and schema checks.
- Added the migration regression to the manual GitHub Actions quality workflow.

### oxmysql export fallback fix

- Fixed the database adapter's CFX export invocation to pass the oxmysql
  provider object, preventing scheduler parameters such as `50` and `100` from
  being interpreted as SQL queries.
- Added a Lua regression test covering query and transaction export calls.
- Added the regression test to the manual GitHub Actions quality workflow.

### Documentation correction

- Updated the README implementation-status line to include completed S15/S16
  release-candidate and release-gate work.

### Final verification snapshot — 2026-08-22

- Passed Node unit tests (5/5), NUI TypeScript typecheck/build, manifest
  validation, EN/TR locale parity, Python script compilation, migration list
  consistency, and release artifact integrity verification.
- Lua 5.5.1 syntax validation now passes for all 115 client/config/server/shared
  Lua files.
- Fixed the reconnect service's method existence check found by the Lua parser.

### S16 — v1.0 release gate

- Added the capability/verification release gate and explicit release blockers.
- Added release artifact integrity and forbidden-content verification.

### S15 — Release candidate tooling

- Added installation, configuration, integration, migration, troubleshooting,
  and release-matrix documentation.
- Added a manual GitHub Actions quality workflow for Lua syntax, NUI typecheck,
  manifest/locale checks, unit tests, and release smoke packaging.
- Added deterministic release packaging and integrity manifest tooling under
  `scripts/`.
- Added NUI TypeScript metadata and static artifact verification.

### S14 — Recovery, resilience, and performance

- Added bounded restart recovery for active requests/work orders, stale
  employee/crew assignments, SLA catch-up, and recovery audit records.
- Added five-minute disconnect grace, solo-assignment release, crew continuity,
  duty reconciliation, and reconnect notifications.
- Added retention cleanup for delivered/dead-lettered outbox events, expired
  idempotency claims, closed-entity audit history, and soft-deleted evidence.
- Added retention indexes and the `010_retention_indexes` migration.
- Added the closed-record retention and archival policy document.
- Added the S14 abuse matrix, performance budget, and load scenarios.
- Added the project README and this changelog.

### Verification note

Automated tests and load execution remain intentionally deferred until the final
verification phase requested by the project owner.

## Phase history

- **S13** `ca7d3c9` — analytics dashboards, health diagnostics, seed mode.
- **S12** `51a44d3` — public API exports, events, idempotency, outbox.
- **S11** `836cfa0` — crews, contributions, incidents, crew assignment.
- **S10** `6071be3` — inspections, evidence, audit, scoped timelines.
- **S09** `2a44917` — persistent SLA, escalation, notifications, scheduler.
- **S08** `2f3faa0` — NUI transport and vertical-slice UI.
- **S07** `44f5c1b` — secure field operations loop and exploit guards.
- **S06** `cfa474b` — work-order conversion, assignment, dependencies.
- **S05** `ffea6ae` — request catalog lifecycle and rate limits.
- **S04** `e06ce71` — departments, employees, RBAC.
- **S03** `821b63d` — framework/provider adapter parity.
- **S02** `4cb650b` — migrations, repositories, cache, persistence.
- **S01** `0015248` — resource skeleton and bootstrap.
- **S00** `8b0c2cb` — frozen CivicOS contracts and specification baseline.

# Changelog

All notable CivicOS changes are recorded here. Every commit after this file was
introduced must add or amend an entry.

## [Unreleased]

### Work-order template runtime loading

- Loaded the work-order template catalog explicitly on the server before its
  validation service, avoiding client/server shared-script ordering ambiguity.
- Included structured API error details in the NUI message so a failed
  conversion identifies the service or template key involved.

### Work-order template catalog wiring

- Loaded `config/workorder_templates.lua` through the FiveM manifest so runtime
  conversion can resolve configured templates.
- Added the missing road-sign, streetlight, property, trash, and dumping
  cleanup templates referenced by the service catalog.
- Added startup validation and regression coverage for catalog/template parity.

### Dispatcher vertical-slice controls

- Added a role-aware Operations section to the NUI for triaging, accepting, or
  rejecting requests and converting accepted requests into work orders.
- Added work-order listing, self-assignment, and guarded status-transition
  buttons that forward the expected version to the server API.
- Added regression coverage for the staff action surface.

### Health diagnostics config status

- Fixed the health check to call the config validator with its declared dot
  contract, so valid provider, duty mode, and locale settings report `healthy`.
- Added a regression test for the diagnostics config validation path.

### QBCore administrator permissions

- Mapped QBCore `god` and `admin` permissions to the CivicOS
  `SYSTEM_ADMIN` role so protected diagnostics and system operations honor the
  framework administrator account.
- Added a regression test covering the QBCore permission lookup and role
  mapping.

### Diagnostics command output

- Made `/civicos_diagnostics` serialize health data safely even when provider
  values contain unsupported runtime types.
- Displayed the diagnostics payload in the invoking player's chat and F8
  console while retaining server-console output.
- Added server and client regression coverage for the command response path.

### QBCore export binding

- Matched FiveM QBCore export calls to the bound colon-call contract used by
  the running server resources.
- Removed the restrictive `exports` type check and invalidated the cached core
  object when `qb-core` restarts.
- Added protected direct-player export calls so a valid QBCore player is found
  before the framework-function fallback.

### QBCore player lookup

- Hardened QBCore core-object retrieval, direct `GetPlayer` support, numeric
  source normalization, and protected framework calls so `/civicos` requests
  work after player load.
- Added a regression test for the QBCore player lookup contract.

### NUI API operation forwarding

- Fixed the NUI callback invoking the dot-based API call helper with colon
  syntax, which sent the NUI table instead of the requested operation.
- Restored bootstrap, request listing, and request submission API calls from
  the panel.
- Added a regression assertion for the client-to-server operation forwarding.

### Request submission feedback

- Waited for the server result before marking a request as submitted.
- Displayed API errors in the form and refreshed the request list automatically
  after a successful create operation.

### Framework callback contract

- Fixed framework adapter callbacks being registered with the adapter table as
  their callback, which caused QBCore job-update errors during server startup.
- Aligned internal framework calls with the adapter's dot-based contract and
  added a regression test covering all lifecycle callback registrations.

### Human-readable service labels

- Converted `service.*` catalog keys to readable title-case labels in the NUI
  selector while keeping service codes unchanged for request submission.
- Added lifecycle regression coverage for service label rendering.

### Client catalog fallback

- Sent a JSON-safe service catalog with the `/civicos` open message from the
  shared resource configuration.
- Kept that catalog when an empty or transport-shaped bootstrap response arrives,
  so the request form remains selectable while the server response loads.
- Added Lua and lifecycle coverage for the open-message catalog fallback.

### Catalog array compatibility

- Normalized numeric-keyed catalog objects as well as native arrays before
  rendering the Citizen service selector.
- Kept the selector and service count populated after FiveM transport shape
  conversions.
- Added NUI regression coverage for catalog normalization.

### Client-side NUI JSON guard

- Sanitized every `SendNUIMessage` payload on the client as a second boundary
  guard for provider/function values arriving from server events.
- Preserved catalog arrays while dropping unsupported, cyclic, and deep values.
- Extended the NUI lifecycle regression to cover the guarded send path.

### JSON-safe NUI API responses

- Sanitized API callback results before `TriggerClientEvent` so functions,
  userdata, cyclic tables, and excessive nesting cannot break NUI JSON encoding.
- Preserved array-shaped catalog data while omitting unsupported values.
- Added a Lua regression test for function, cycle, and depth handling.

### Citizen service catalog rendering

- Re-rendered the Citizen service selector when the asynchronous bootstrap
  response arrives, so configured services can be selected for new requests.
- Added a safe empty-catalog placeholder and preserved an existing selection
  when the catalog refreshes.
- Added regression coverage for the bootstrap-to-service-selector lifecycle.

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

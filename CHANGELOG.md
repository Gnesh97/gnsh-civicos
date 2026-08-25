# Changelog

All notable CivicOS changes are recorded here. Every commit after this file was
introduced must add or amend an entry.

## [Unreleased]

### Input and lifecycle hardening

- Cancel disconnect grace callbacks by persistent identity so reconnecting on a
  different FiveM source slot cannot release restored solo assignments.
- Reject unknown request priorities and invalid, cyclic, oversized, or
  unsupported metadata at request, inspection, evidence, and crew boundaries.
- Keep read permissions from widening evidence attachment or work-order
  transition mutations; write actions now require their own permission key.
- Pin request/work-order list queries to the actor's own or department scope,
  filter internal activity from citizen detail DTOs, and clamp invalid page
  sizes before they reach SQL/API responses.
- Hide internal comment activity from both request-detail and timeline read
  models while retaining it for authorized staff views.
- Restrict incident work-order assignment and dependency details to staff
  read models; citizen incident reads now remain independent of dependency
  internals.
- Bind public integration exports to FiveM's invoking resource and enforce
  owner checks for request/work-order reads and mutations.
- Materialize converted work orders directly as `unassigned` inside the
  conversion transaction, eliminating a race-prone follow-up staging loop.
- Document the invoking-resource ownership rule for integration exports.
- Guard concurrent request conversion transactions so only the caller that
  owns the expected version materializes its work-order batch.

### Security and schema gate hardening

- Bound technician self-assignment to the caller's persistent identity and
  restored department-scoped authorization for dependency removal.
- Startup migration verification now checks every runtime table instead of only
  the seven baseline tables, with missing-table regression coverage.

### Repository metadata

- Refreshed the shared codebase-memory graph artifact after the framework
  parity and verification hardening pass.

### Framework parity and verification hardening

- Corrected QBCore player money/duty method calls to use the framework's
  player-method contract.
- Corrected Qbox export binding, numeric source normalization, native
  `SetJobDuty`, documented lifecycle events, and usable-item registration.
- Hardened ESX export discovery when FiveM exposes a proxy instead of a Lua
  table.
- Added single-player QBCore, Qbox, and ESX adapter contract smoke specs and
  included all Lua unit/integration specs in the manual CI workflow.
- Moved detailed health active-count queries behind a repository boundary.

### Civic Ledger operations workbench

- Redesigned the CivicOS NUI with a responsive Swiss-grid/liquid-glass workbench
  while preserving the existing NUI IDs, close behavior, and API transport.
- Added an inline work-order workspace for server-validated checklists, field
  action start/complete tokens, version-aware updates, and inspection gates.
- Added the read-only `inspection.latest` callback plus frontend wrappers so
  inspection state survives panel refreshes and can be reviewed by the correct
  department scope.
- Added department-scoped checklist reads and explicit loading, empty, error,
  and permission states for operational work.
- Tuned the visual system for FiveM's desktop-only surface; removed
  mobile-specific vertical stacking.
- Loaded authorized work-order detail metadata before evaluating inspection
  gates, correlated late NUI responses to their work order, and restored
  action controls after failed requests.

### Field position validation compatibility

- Accepted FiveM `vector3` values from `GetEntityCoords` in the server-side
  field-operation guard, so completion no longer fails with an unavailable
  player position on supported runtimes.
- Captured the player's client position for NUI-created requests instead of
  persisting the `{ 0, 0, 0 }` placeholder location.

### Work-order transition runtime fallback

- Added a runtime state-machine fallback for deployments where the manifest
  cache has not yet loaded the work-order state module.
- Kept status checks safe when the shared work-order enum table is unavailable,
  allowing `acknowledged` and later transitions to return a normal API result.

### Work-order transition state machine loading

- Loaded the work-order state machine in the server manifest so self-assignment
  can transition safely to `acknowledged` and subsequent operational states.
- Added the load-order assertion to the existing manifest regression test.

### Work-order list runtime resilience

- Added a safe DTO fallback when the work-order domain serializer is not yet
  available during a resource hot reload.
- Included traceback details in callback failure logs so API runtime errors no
  longer appear as an operation-only message.

### Work-order operations listing

- Loaded the work-order domain serializer in the server manifest before the
  work-order service, preventing `workorder.list` callbacks from failing after
  a request is converted.
- Added manifest regression coverage for the required load order.

### Work-order template registry fallback

- Added a server-side fallback loader for the template registry when the
  resource runtime does not expose the manifest-loaded table.
- Return a dedicated registry-unavailable error instead of misreporting every
  service as a missing template.
- Added regression coverage for manifest and fallback loading paths.

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

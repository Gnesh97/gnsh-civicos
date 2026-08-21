# CivicOS v1.0 Release Gate

This checklist is the final acceptance boundary from the implementation plan.
“Implemented” means the code and contract exist; “verified” is only checked
after the final test/load/migration run.

## Capability gate

- [x] 311 citizen requests and own-request tracking
- [x] Service catalog and configurable departments
- [x] Employees, duty/availability, and RBAC
- [x] Work orders, manual dispatch, self assignment, atomic assignment
- [x] Field actions, server distance validation, one-time action tokens
- [x] Checklists, inspection/evidence gates, SLA, escalation, notifications
- [x] Audit and public/internal activity timelines
- [x] Crews, contributions, incidents, and multi-department child work orders
- [x] Public API, idempotency, events, outbox, integration examples
- [x] Analytics basics, health diagnostics, restart and disconnect recovery
- [x] Config validation and EN/TR localization
- [x] QBCore, Qbox, ESX Legacy, and standalone adapters
- [x] Inventory/target/evidence/notify fallback adapters
- [x] CI workflow, release builder, installation/API documentation

## Verification gate (pending final run)

- [ ] Vertical slice passes on QBCore, Qbox, ESX, and standalone.
- [ ] Abuse matrix passes with expected rejection codes and no side effects.
- [ ] Load budgets pass for the small, queue, history, restart, and NUI profiles.
- [ ] Fresh install and upgrade migration matrix passes.
- [ ] Release artifact contains no tests, graph files, source NUI modules,
      secrets, or development-only scripts.
- [ ] Security review finds no critical/high findings.
- [ ] Changelog, version, release manifest, and rollback runbook are attached to
      the release candidate.

## Blockers

Do not merge `dev` into `main` or publish a release when client event spam can
complete work, restart loses active state, migration fresh/upgrade fails,
assignment races remain, SLA continuity is wrong after restart, internal data
leaks to citizen DTOs, or a release artifact includes secrets/dev files.

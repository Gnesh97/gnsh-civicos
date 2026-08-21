# CivicOS

CivicOS is a server-authoritative municipal operations core for FiveM. It
connects citizen requests to departments, work orders, field operations, SLA
tracking, inspections, crews, audit history, and integration APIs without
coupling the domain layer to one framework.

## Current status

Implementation phases S00–S14 are in place on the `dev` branch. The GitHub
repository keeps `main` as the default branch; `dev` is the active development
branch. Automated tests and load execution are intentionally deferred to the
final verification phase, while the scenarios are documented under
[`tests/scenarios`](tests/scenarios).

Implemented capabilities include:

- citizen request lifecycle and configurable service catalog;
- QBCore, Qbox, ESX, and standalone framework adapters;
- departments, employees, duty/availability, RBAC, and scoped authorization;
- work-order conversion, atomic employee/crew assignment, dependencies, and
  field checklists;
- server-side distance checks, one-time action tokens, inventory/notify/target
  provider fallbacks, and exploit guards;
- inspection/evidence gates, persistent SLA/escalation/notification workers,
  audit/activity timelines, analytics, health diagnostics, and seed data;
- public exports, idempotency, domain events, outbox delivery/dead-lettering,
  restart recovery, disconnect grace handling, and retention cleanup.

## Installation

1. Copy this resource to the server resources directory.
2. Start `oxmysql` before `gnsh-civicos`.
3. Add `ensure gnsh-civicos` to `server.cfg`.
4. Set the framework/provider choices in [`config/config.lua`](config/config.lua)
   and [`config/adapters.lua`](config/adapters.lua).
5. Restart the resource. Database migrations run automatically when
   `Config.Database.MigrationOnStart` is enabled.

The framework adapter is selected automatically by default. Set
`Config.Framework.Provider` explicitly when more than one framework resource is
present. Inventory, target, notify, and evidence providers have a `none`
fallback so the core can boot without optional resources.

## Configuration and integrations

- Framework/provider options: [`docs/FRAMEWORKS.md`](docs/FRAMEWORKS.md)
- API contract and callback operations: [`docs/api/API.md`](docs/api/API.md)
- Public export examples: [`integrations/examples`](integrations/examples)
- Configuration values: [`config`](config)
- Migration history: [`sql`](sql)
- Security and permission contracts: [`docs/spec`](docs/spec)
- Retention and archival policy: [`docs/spec/RETENTION_POLICY.md`](docs/spec/RETENTION_POLICY.md)
- Installation: [`docs/INSTALLATION.md`](docs/INSTALLATION.md)
- Configuration: [`docs/CONFIGURATION.md`](docs/CONFIGURATION.md)
- Integrations: [`docs/INTEGRATIONS.md`](docs/INTEGRATIONS.md)
- Migrations: [`docs/MIGRATIONS.md`](docs/MIGRATIONS.md)
- Troubleshooting: [`docs/TROUBLESHOOTING.md`](docs/TROUBLESHOOTING.md)
- Release gate: [`docs/RELEASE_GATE.md`](docs/RELEASE_GATE.md)

Never commit framework credentials, webhook secrets, or provider tokens. Keep
those values in the server's secret/environment configuration.

## Development

Work on `dev`, keep `main` as the release/default branch, and use conventional
commit messages (`feat:`, `fix:`, `docs:`, `test:`, `chore:`, and so on). Every
commit must update [`CHANGELOG.md`](CHANGELOG.md) with the phase or change it
contains. Run the final test, load, abuse, and migration matrix before merging
`dev` into `main`.

The release-candidate CI workflow is available through GitHub Actions
`workflow_dispatch`; it is intentionally manual until the final verification
phase so development pushes do not run the deferred test matrix early.

## License

This repository is maintained as a private CivicOS implementation. Apply the
deployment and distribution terms agreed by the project owner.

# gnsh-civicos (CivicOS)

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
![Version](https://img.shields.io/badge/version-0.1.0-informational.svg)

Server-authoritative municipal operations core for FiveM. CivicOS connects citizen requests to departments, work orders, field operations, SLA tracking, inspections, crews, audit history, and integration APIs without coupling the domain layer to a single framework.

## Capabilities

- **Citizen Request & Service Catalog Lifecycle:** Configurable service catalog (`config/service_catalog.lua`), priority validation, public/internal comment separation, and atomic request-to-work-order conversion.
- **Departments, Crews & RBAC:** Employees, duty/availability states, scoped department authorization, crew assignments, and disconnect/reconnect grace handling.
- **Work Orders & Field Operations:** Work-order templates, dependencies, field checklists, server-side distance checks, one-time action tokens, and inspection/evidence gates.
- **SLA, Escalations & Observability:** Persistent SLA and escalation tracking, audit/activity timelines, analytics, health diagnostics (`/civicos_health`, `/civicos_diagnostics`), and data retention policies.
- **Framework & Optional Provider Adapters:** Automatic or explicit selection across `qbcore`, `qbox`, `esx`, and `standalone`, with `oxmysql` persistence (`sql/001_initial.sql`–`010_retention_indexes.sql`) and safe `none` fallbacks for inventory, target, notify, and evidence providers.
- **Integration Bus & Idempotency:** Invoking-resource-bound public exports, idempotency keys, domain events, outbox delivery/dead-lettering, and startup recovery.

## Installation

1. Copy `gnsh-civicos` into your server's `resources/` directory.
2. Ensure `oxmysql` and your framework (`qb-core`, `qbx_core`, or `es_extended`, if used) start before `gnsh-civicos`.
3. Add `ensure gnsh-civicos` to `server.cfg`.
4. Configure framework and provider choices in [`config/config.lua`](config/config.lua) and [`config/adapters.lua`](config/adapters.lua).
5. Restart the resource. Database migrations run automatically when `Config.Database.MigrationOnStart` is enabled.
6. Open the in-game CivicOS NUI panel with `/civicos` (use **Close** or **Escape** to hide it; the panel starts hidden).

> Keep framework credentials, webhook secrets, and provider tokens in server environment/secret configuration — never commit them to config files.

## Server Exports

Public integration exports require an active invoking FiveM resource (`GetInvokingResource()`) and enforce idempotency keys on mutations (see [`docs/api/API.md`](docs/api/API.md) and [`integrations/`](integrations/README.md)):

- `CreateRequest(input, context)` / `GetRequest(id)` / `UpdateRequest(id, expectedVersion, patch, context)` / `ResolveRequest(id, expectedVersion, reason, context)`
- `CreateWorkOrder(requestId, expectedVersion, serviceCode, overrides, context)` / `GetWorkOrder(id)`
- `AddComment(requestId, body, context)`
- `GetHealth()`

## Verification & Checks

The repository includes Lua 5.4 syntax checks, manifest/locale validators, Node.js unit checks, Lua unit & framework adapter contract specs, and a release-artifact verifier (defined in [`.github/workflows/ci.yml`](.github/workflows/ci.yml)):

```bash
find client config server shared -type f -name '*.lua' -print0 | xargs -0 -n1 luac5.4 -p
python3 scripts/validate_manifest.py
python3 scripts/check_locales.py
node --test tests/unit/*.mjs
for test in tests/unit/*.lua; do lua5.4 "$test"; done
for test in tests/integration/framework/*.lua; do lua5.4 "$test"; done
```

Live FXServer load, abuse, and staging scenarios are documented under [`tests/scenarios/`](tests/scenarios) and [`docs/RELEASE_GATE.md`](docs/RELEASE_GATE.md).

## Documentation

- [`DESIGN.md`](DESIGN.md) · [`PRODUCT.md`](PRODUCT.md) · [`CHANGELOG.md`](CHANGELOG.md)
- [`docs/INSTALLATION.md`](docs/INSTALLATION.md) · [`docs/CONFIGURATION.md`](docs/CONFIGURATION.md) · [`docs/FRAMEWORKS.md`](docs/FRAMEWORKS.md)
- [`docs/api/API.md`](docs/api/API.md) · [`docs/INTEGRATIONS.md`](docs/INTEGRATIONS.md) · [`docs/MIGRATIONS.md`](docs/MIGRATIONS.md)
- [`docs/RELEASE_GATE.md`](docs/RELEASE_GATE.md) · [`docs/ROLLBACK.md`](docs/ROLLBACK.md) · [`docs/TROUBLESHOOTING.md`](docs/TROUBLESHOOTING.md)
- [`docs/spec/`](docs/spec) — ADRs, permission matrix, coding rules, performance budget & retention policy

## Branch Workflow

`main` is the default release branch and `dev` is the integration branch (kept in sync with `main` on release). Commit behavior changes with conventional commits (`feat:`, `fix:`, `docs:`, etc.) and update [`CHANGELOG.md`](CHANGELOG.md).

## License

Licensed under the [MIT License](LICENSE).

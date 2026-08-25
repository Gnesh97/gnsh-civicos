# CivicOS Configuration

The canonical settings are in [`config/config.lua`](../config/config.lua).
Keep customer changes in config files; do not edit server services to customize
normal operations.

## Core settings

| Section | Important keys | Purpose |
| --- | --- | --- |
| `Framework` | `Provider`, `DutyMode` | Adapter selection and duty source |
| `Database` | `Provider`, `MigrationOnStart`, `QueryTimingWarningMs` | Persistence and slow-query diagnostics |
| `Security` | `StrictConfig`, `ValidateUnknownFields`, `RejectAmbiguousFramework` | Startup and boundary validation |
| `RateLimits` | operation → `windowSeconds`, `maxRequests` | Per-source request throttles |
| `FieldOperations` | token TTL, action radius, inventory fallback, payload limit | Server-authoritative field actions |
| `NUI` | `RequestTimeoutMs` | Client/browser request timeout |
| `Scheduler` | `IntervalMs`, `MaxJobsPerTick` | Shared background worker budget |
| `SLA` | `WarningLeadSeconds`, `BatchSize` | Warning/breach processing |
| `Outbox` | `MaxAttempts`, `BatchSize` | Integration delivery/retry budget |
| `Recovery` | `DisconnectGraceSeconds`, `MaxRecoveryBatch` | Restart and disconnect safety |
| `Retention` | outbox/idempotency/audit/evidence days, `IntervalMs` | Cleanup worker policy |

## Framework and providers

Set `Framework.Provider = "auto"` for normal detection. If both QBCore and Qbox
are running, choose one explicitly; CivicOS rejects an ambiguous startup. Set
`Framework.DutyMode` to `framework` to trust native duty events or `civicos` to
manage duty inside CivicOS where the adapter supports it.

Provider names are selected in [`config/adapters.lua`](../config/adapters.lua).
Every provider has a contract and a `none` fallback. A custom adapter should
implement the interface first, then be registered without changing domain
services.

## Catalog, departments, and permissions

- Add or modify services in `config/service_catalog.lua`.
- Map framework jobs to departments in `config/departments.lua`.
- Review role scopes in `config/permissions.lua`.
- Keep lifecycle values from `shared/enums.lua`; do not introduce ad-hoc state
  strings in services.

Set server-owner overrides outside the resource so they do not travel with a
shared repository or release artifact:

```cfg
set civicos_global_admin_identifiers "license:...,fivem:..."
```

Values are comma- or whitespace-separated FiveM identifiers. ACE `god`/`admin`
permissions remain supported as a separate server-side authorization path.

## Production guidance

Use environment/server secret storage for credentials and provider tokens. Keep
`DemoSeed` disabled in production, take a database backup before migration or
retention changes, and record non-default retention values in the deployment
runbook.

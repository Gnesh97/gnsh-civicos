# CivicOS Release Matrix

This matrix is executed during the S15/S16 release gate. It records environment
and adapter coverage without treating a local mock run as a framework pass.

| Environment | Framework/provider | Required scenarios |
| --- | --- | --- |
| QBCore | native duty + configured inventory/target/notify | vertical slice, abuse, restart, reconnect, load |
| Qbox | native duty + configured inventory/target/notify | vertical slice, abuse, restart, reconnect, load |
| ESX Legacy | CivicOS duty fallback + configured providers | vertical slice, abuse, restart, reconnect, load |
| Standalone | `none` providers | vertical slice, security rejection, NUI mock, migration |

## Matrix checks

- Fresh install applies migrations 001–010.
- Upgrade from the previous beta applies only pending migrations.
- QBCore/Qbox native duty and job-change callbacks reconcile employees.
- ESX fallback duty and reconnect reconciliation are persisted.
- No-inventory/no-target mode still enforces server action tokens and distance.
- Restart recovery preserves assigned, working, inspection, and near-SLA state.
- Release artifacts exclude tests, source NUI modules, graph files, secrets, and
  development-only scripts while retaining config, locales, integrations, SQL,
  docs, and runtime files.

# CivicOS Troubleshooting

## Resource does not become ready

- Check that `oxmysql` is started and reachable.
- Check for an ambiguous or unavailable framework provider.
- Read the first `Startup stage ... failed` line; later errors are usually
  consequences.
- Run `/civicos_diagnostics` after the resource starts.

## Migration failure

- Confirm the database user can create tables, indexes, and columns.
- Check the failed SQL and current `civicos_schema_version`.
- Restore from backup before manually repairing a partially applied change.
- Do not mark a migration applied by hand unless the SQL was verified.

## Field action rejected

`FIELD_ACTOR_NOT_ASSIGNED`, `FIELD_TOO_FAR`, token errors, and invalid-state
errors are intentional server protections. Confirm the player is on duty, the
work order/crew assignment is current, the action token is fresh, and the
server can read player coordinates.

## NUI is blank or stuck

- Confirm `web/dist/index.html` is present in the resource package.
- Check the browser console for `civicos:api` transport errors.
- Verify the player is loaded before opening the NUI.
- Use the static mock mode to separate UI rendering from framework/database
  issues.

## Notifications or providers are missing

Check the selected adapter in `config/adapters.lua` and provider capabilities in
the health/diagnostics output. The `none` fallback intentionally stores no
external inventory/target/evidence side effect; install and configure a real
provider when those capabilities are required.

## Slow queues or cleanup

Review slow-query logs, page size, scheduler limits, and the performance budget.
Retention is bounded and protects active records; tune `Config.Retention` only
after a backup and a staging load run.

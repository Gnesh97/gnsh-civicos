# CivicOS Rollback Runbook

Use this runbook when a CivicOS release must be withdrawn. Treat the database
schema and its recorded migration version as authoritative; a code rollback is
not automatically a schema rollback.

## Before changing anything

1. Announce a maintenance window and stop duplicate CivicOS resource instances.
2. Save the current release manifest, Git commit, server log, and
   `/civicos_health` output.
3. Stop `gnsh-civicos` before changing resource files.
4. Take a verified database backup, including `civicos_schema_version` and all
   `civicos_*` tables. Confirm that the backup can be read before proceeding.
5. Record the current schema version and compare it with the target artifact's
   documented migration compatibility.

## Code-only rollback

Use this path when the target artifact supports the already-applied schema.

1. Replace the resource with the previously verified release artifact; do not
   edit or delete migration files in place.
2. Start `oxmysql` and the framework first, then start `gnsh-civicos`.
3. Wait for the `READY` bootstrap state and confirm `/civicos_health` reports the
   expected database and provider capabilities.
4. Verify a read-only request/work-order lookup, one authorized staff action,
   and the scheduler/outbox health before reopening normal traffic.

Never remove rows from `civicos_schema_version` to make an older binary start.
If the older binary cannot read the current schema, stop and use the database
restore path or deploy a forward-compatible fix instead.

## Database restore

Use a database restore only for corruption, a failed migration, or an approved
data rollback during maintenance.

1. Keep CivicOS stopped and preserve the failing logs and schema-version row.
2. Restore the verified backup using the database operator's normal procedure.
3. Start the resource and allow the migration runner to verify checksums and
   apply only migrations that are genuinely pending.
4. Repeat the health, request, work-order, and scheduler checks before release.

Do not mark a migration as applied by hand, partially delete CivicOS tables, or
run an unreviewed down-migration. Schema changes are append-only unless a
future migration explicitly documents a reversible operation.

## Completion evidence

Record the restored artifact commit, database backup identifier, resulting
schema version, health output, and the operator who approved reopening the
server. Add the incident and any follow-up migration to the changelog before
the next release candidate.

# CivicOS Migrations

CivicOS uses ordered, append-only migrations. The database records the applied
version, migration ID, checksum, and timestamp in `civicos_schema_version`.

## Current sequence

| Version | File | Purpose |
| ---: | --- | --- |
| 001 | `sql/001_initial.sql` | Core requests, work orders, workforce, audit, outbox, idempotency tables |
| 002 | `sql/002_indexes.sql` | Queue, assignment, SLA, inbox, audit, and outbox indexes |
| 003 | `sql/003_employee_certifications.sql` | Employee certification records |
| 004 | `sql/004_assignment_reason.sql` | Assignment reason metadata |
| 005 | `sql/005_sla_state.sql` | SLA warning/pause/exemption state |
| 006 | `sql/006_escalations.sql` | Persistent escalation records |
| 007 | `sql/007_evidence_retention.sql` | Evidence tombstones and retention index |
| 008 | `sql/008_crews_contributions.sql` | Crews, memberships, contributions, crew FK |
| 009 | `sql/009_outbox_dead_letter.sql` | Outbox dead-letter timestamp/index |
| 010 | `sql/010_retention_indexes.sql` | Retention worker indexes |

## Upgrade rules

1. Back up the database.
2. Stop duplicate CivicOS resource instances.
3. Deploy the new resource files without editing existing SQL.
4. Start the resource and wait for migration completion.
5. Verify `/civicos_health`, schema version, and application logs.
6. Roll back code only after understanding whether a migration is reversible;
   never delete a row from `civicos_schema_version` in production.

For a new schema change, add the next three-digit SQL file, register its
definition and checksum, document it in this table, and add a migration matrix
scenario before release.

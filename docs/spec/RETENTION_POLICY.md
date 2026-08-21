# CivicOS Retention Policy

Retention is conservative by default. Closed and cancelled requests/work orders
remain queryable; CivicOS does not physically delete operational records as part
of the routine worker. An operator may export/archive them at the database or
storage layer after the required legal/business retention period.

The scheduled cleanup worker only removes:

- delivered or dead-lettered outbox events older than
  `Config.Retention.DeliveredOutboxDays`;
- idempotency claims that are both expired and older than
  `Config.Retention.IdempotencyDays`;
- audit rows older than `Config.Retention.AuditDays` when their request/work
  order is already closed/cancelled (unknown/system entities follow the same
  audit window);
- evidence rows that were already soft-deleted and whose tombstone is older
  than `Config.Retention.EvidenceDays`.

Active request/work-order audit history, active assignments, non-deleted
evidence, pending outbox events, and unexpired idempotency claims are protected
by explicit SQL predicates. Retention changes must be reviewed with the
database backup and privacy policy before deployment.

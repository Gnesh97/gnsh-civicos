# CivicOS Performance Budget

S14 sets a measurable baseline for a single FiveM server using oxmysql. These
are budgets, not a claim that every host will meet them; record the actual
numbers in the load report before release.

## Server budgets

| Area | Budget | Guardrail |
| --- | ---: | --- |
| Normal API callback p95 | 150 ms | No unbounded history or N+1 child query |
| Mutation callback p95 | 250 ms | Version/idempotency checks stay server-side |
| Scheduler tick | 25 jobs/tick | `Scheduler.MaxJobsPerTick` remains enforced |
| SLA batch | 100 rows | One shared worker; no per-entity thread |
| Outbox batch | 50 rows | Delivery is bounded and retried with a dead-letter limit |
| Recovery batch | 500 work orders | Restart normalization is bounded by `Recovery.MaxRecoveryBatch` |
| Cleanup interval | 1 hour | Retention work runs in a bounded scheduled job |
| Queue query | 100 rows/page | `WorkOrderRepository:list` caps page size |

## Client budgets

- Idle field interaction/marker loops target approximately **0.00–0.02 ms**.
- No polling loop may send an API callback while the NUI is closed.
- Work-order, activity, notification, and analytics history must be paginated;
  the full history is never sent in one payload.
- NUI lists should render only the visible page/window and avoid duplicate fetches.

## Database safeguards

- Queue, SLA, outbox, assignment, and retention indexes are migration-managed.
- Retention deletes are limited to delivered/dead-lettered outbox rows, expired
  idempotency rows, soft-deleted evidence, and audit rows for closed entities.
- Active request/work-order audit rows are protected by the cleanup join guard.
- Slow queries are logged when they exceed `Database.QueryTimingWarningMs`.

## Required measurements

For each scenario in `tests/scenarios/load.md`, capture p50/p95/p99 latency,
throughput, scheduler duration, database slow-query count, and client resmon
idle/active values. Compare against this document and fail the release gate when
any budget is exceeded without an approved change record.

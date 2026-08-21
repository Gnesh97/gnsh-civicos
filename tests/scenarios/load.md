# CivicOS Load & Performance Scenarios

Run these scenarios on a staging FiveM server with representative framework,
oxmysql, NUI, and provider adapters. Keep the generated records isolated from
production. Tests are intentionally documented in S14 and are executed in the
final verification phase.

## Dataset profiles

1. **Small:** 100 active requests, 100 work orders, 50 on-duty employees.
2. **Queue:** 500 active requests/work orders across at least four departments.
3. **History:** 1,000+ closed/cancelled requests with comments, activity, audit,
   evidence, SLA, notification, and outbox history.

## Scenarios

| ID | Flow | Measure |
| --- | --- | --- |
| LOAD-01 | Dispatcher opens a paginated queue and moves through five pages | p50/p95 callback latency, query duration, payload size |
| LOAD-02 | 50 employees refresh assigned/crew work orders concurrently | throughput, p95, duplicate queries, authorization failures |
| LOAD-03 | SLA worker processes a full due batch | batch duration, rows changed, notification count |
| LOAD-04 | Outbox worker delivers and retries a full batch | delivery duration, retry/dead-letter counts |
| LOAD-05 | Restart with assigned, working, inspection, and near-breach records | recovery duration, normalized rows, SLA continuity, audit rows |
| LOAD-06 | Cleanup worker with old delivered/dead-lettered events, expired keys, soft-deleted evidence, and active history | rows deleted, active rows preserved, lock duration |
| LOAD-07 | NUI opens analytics/notifications/activities with history profile | first paint, payload size, visible-row rendering, idle resmon |
| LOAD-08 | 50 concurrent integration calls with 10 duplicate idempotency keys | accepted mutations, replay count, collision errors, p95 |

## Pass/fail evidence

- No unbounded SQL result or single full-history payload.
- Scheduler stays within `Scheduler.MaxJobsPerTick` and does not create
  per-entity SLA threads.
- Cleanup never changes active request/work-order, assignment, or non-deleted
  evidence rows.
- Actual measurements are compared to `docs/spec/PERFORMANCE_BUDGET.md`.

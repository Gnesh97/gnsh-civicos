local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS

local CleanupWorker = {}

local function days(value, fallback)
    return math.max(1, math.min(3650, math.floor(tonumber(value) or fallback)))
end

local function cutoff(daysValue)
    -- The value is clamped to a number before being interpolated into SQL.
    return "DATE_SUB(CURRENT_TIMESTAMP(3), INTERVAL " .. tostring(daysValue) .. " DAY)"
end

local function affected(result)
    return result.ok and tonumber(result.data and result.data.affectedRows) or 0
end

function CleanupWorker:run()
    if not CivicOS.DatabaseAdapter then
        return CivicOS.Result.err("CLEANUP_UNAVAILABLE", "Database adapter is not registered.")
    end

    local retention = CivicOS.Config and CivicOS.Config.Retention or {}
    local outboxDays = days(retention.DeliveredOutboxDays, 7)
    local idempotencyDays = days(retention.IdempotencyDays, 2)
    local auditDays = days(retention.AuditDays, 90)
    local evidenceDays = days(retention.EvidenceDays,
        CivicOS.Config and CivicOS.Config.Evidence and CivicOS.Config.Evidence.RetainDays or 30)

    local summary = {
        outbox = 0,
        idempotency = 0,
        audit = 0,
        evidence = 0,
    }

    local outbox = CivicOS.DatabaseAdapter:update([[DELETE FROM civicos_outbox
        WHERE created_at < ]] .. cutoff(outboxDays) .. [[
          AND (delivered_at IS NOT NULL OR dead_lettered_at IS NOT NULL)]])
    if not outbox.ok then return outbox end
    summary.outbox = affected(outbox)

    local idempotency = CivicOS.DatabaseAdapter:update([[DELETE FROM civicos_idempotency
        WHERE expires_at IS NOT NULL
          AND expires_at <= CURRENT_TIMESTAMP(3)
          AND expires_at < ]] .. cutoff(idempotencyDays))
    if not idempotency.ok then return idempotency end
    summary.idempotency = affected(idempotency)

    -- Keep audit history for active requests/work orders. Unknown entity types
    -- are retained only until the configured audit window, then pruned.
    local audit = CivicOS.DatabaseAdapter:update([[DELETE a FROM civicos_audit_logs a
        LEFT JOIN civicos_requests r
            ON a.entity_type = 'request' AND a.entity_id = r.id
        LEFT JOIN civicos_workorders w
            ON a.entity_type = 'workorder' AND a.entity_id = w.id
        WHERE a.created_at < ]] .. cutoff(auditDays) .. [[
          AND (
                (a.entity_type = 'request' AND (r.id IS NULL OR r.status IN ('closed', 'cancelled')))
             OR (a.entity_type = 'workorder' AND (w.id IS NULL OR w.status IN ('closed', 'cancelled')))
             OR a.entity_type NOT IN ('request', 'workorder')
          )]])
    if not audit.ok then return audit end
    summary.audit = affected(audit)

    -- Evidence is soft-deleted first; only the tombstoned rows are eligible
    -- for physical removal, so active evidence can never be touched here.
    local evidence = CivicOS.DatabaseAdapter:update([[DELETE FROM civicos_evidence
        WHERE deleted_at IS NOT NULL AND deleted_at < ]] .. cutoff(evidenceDays))
    if not evidence.ok then return evidence end
    summary.evidence = affected(evidence)

    if CivicOS.AuditService then
        CivicOS.AuditService:record(nil, {
            entityType = "system",
            action = "cleanup",
            after = summary,
        })
    end
    return { ok = true, data = summary }
end

if CivicOS.Scheduler then
    local retention = CivicOS.Config and CivicOS.Config.Retention or {}
    CivicOS.Scheduler:register("cleanup", function()
        return CleanupWorker:run()
    end, tonumber(retention.IntervalMs) or 3600000)
end

CivicOS.CleanupWorker = CleanupWorker
return CleanupWorker

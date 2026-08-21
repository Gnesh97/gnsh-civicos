local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS
local Repository = CivicOS.Repository

local OutboxRepository = {}

function OutboxRepository:create(envelope)
    return Repository.db():insert([[INSERT INTO civicos_outbox
        (event_name, event_version, payload, correlation_id, next_attempt_at)
        VALUES (?, ?, ?, ?, CURRENT_TIMESTAMP(3))]], {
        envelope.eventName, envelope.eventVersion or 1, Repository.encode(envelope), envelope.correlationId,
    })
end

function OutboxRepository:listDue(limit)
    local result = Repository.db():query([[SELECT id, event_name, event_version, payload,
        correlation_id, attempts, next_attempt_at, created_at FROM civicos_outbox
        WHERE delivered_at IS NULL AND dead_lettered_at IS NULL
        AND (next_attempt_at IS NULL OR next_attempt_at <= CURRENT_TIMESTAMP(3))
        ORDER BY id ASC LIMIT ?]], { math.min(math.max(1, tonumber(limit) or 50), 500) })
    if not result.ok then return result end
    for _, row in ipairs(result.data or {}) do row.payload = Repository.decode(row.payload) end
    return { ok = true, data = result.data or {} }
end

function OutboxRepository:markDelivered(id)
    return Repository.db():update("UPDATE civicos_outbox SET delivered_at = CURRENT_TIMESTAMP(3) WHERE id = ? AND delivered_at IS NULL", { id })
end

function OutboxRepository:markFailed(id, attempts, maxAttempts)
    local nextSeconds = math.min(3600, 2 ^ math.min(tonumber(attempts) or 1, 10))
    local limit = tonumber(maxAttempts) or 10
    return Repository.db():update([[UPDATE civicos_outbox SET attempts = attempts + 1,
        next_attempt_at = IF(attempts + 1 >= ?, NULL, DATE_ADD(CURRENT_TIMESTAMP(3), INTERVAL ? SECOND)),
        dead_lettered_at = IF(attempts + 1 >= ?, CURRENT_TIMESTAMP(3), NULL)
        WHERE id = ? AND delivered_at IS NULL AND dead_lettered_at IS NULL]], { limit, nextSeconds, limit, id })
end

CivicOS.OutboxRepository = OutboxRepository
return OutboxRepository

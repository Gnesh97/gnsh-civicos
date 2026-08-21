local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS
local Repository = CivicOS.Repository

local SlaRepository = {}

local columns = [[
    id, entity_type, entity_id, milestone, status, due_at, warning_at,
    met_at, breached_at, paused_at, accumulated_pause_seconds, exempt,
    created_at, updated_at
]]

function SlaRepository:create(event)
    return Repository.db():insert([[INSERT INTO civicos_sla_events
        (entity_type, entity_id, milestone, status, due_at, warning_at, exempt)
        VALUES (?, ?, ?, 'pending', ?, ?, ?)]], {
        event.entityType, event.entityId, event.milestone, event.dueAt, event.warningAt, event.exempt and 1 or 0,
    })
end

function SlaRepository:find(entityType, entityId, milestone)
    return Repository.rows(Repository.db():query("SELECT " .. columns .. [[ FROM civicos_sla_events
        WHERE entity_type = ? AND entity_id = ? AND milestone = ? LIMIT 1]], { entityType, entityId, milestone }))
end

function SlaRepository:findById(id)
    return Repository.rows(Repository.db():query("SELECT " .. columns .. " FROM civicos_sla_events WHERE id = ? LIMIT 1", { id }))
end

function SlaRepository:list(entityType, entityId)
    local sql = "SELECT " .. columns .. " FROM civicos_sla_events"
    local params = {}
    if entityType then
        sql = sql .. " WHERE entity_type = ? AND entity_id = ?"
        params = { entityType, entityId }
    end
    return Repository.rows(Repository.db():query(sql .. " ORDER BY due_at ASC", params))
end

function SlaRepository:listDue(limit)
    local pageSize = math.min(math.max(1, tonumber(limit) or 100), 500)
    return Repository.rows(Repository.db():query("SELECT " .. columns .. [[ FROM civicos_sla_events
        WHERE exempt = 0 AND ((status = 'pending' AND warning_at IS NOT NULL AND warning_at <= CURRENT_TIMESTAMP(3))
            OR ((status = 'pending' OR status = 'warning') AND due_at <= CURRENT_TIMESTAMP(3)))
        ORDER BY due_at ASC LIMIT ?]], { pageSize }))
end

function SlaRepository:markWarning(id)
    local result = Repository.db():update([[UPDATE civicos_sla_events
        SET status = 'warning' WHERE id = ? AND status = 'pending' AND exempt = 0
        AND warning_at IS NOT NULL AND warning_at <= CURRENT_TIMESTAMP(3) AND due_at > CURRENT_TIMESTAMP(3)]], { id })
    if not result.ok then return result end
    return { ok = true, data = { changed = (result.data.affectedRows or 0) > 0 } }
end

function SlaRepository:markBreached(id)
    local result = Repository.db():update([[UPDATE civicos_sla_events
        SET status = 'breached', breached_at = CURRENT_TIMESTAMP(3)
        WHERE id = ? AND (status = 'pending' OR status = 'warning') AND exempt = 0
        AND due_at <= CURRENT_TIMESTAMP(3)]], { id })
    if not result.ok then return result end
    return { ok = true, data = { changed = (result.data.affectedRows or 0) > 0 } }
end

function SlaRepository:markMet(entityType, entityId, milestone)
    local result = Repository.db():update([[UPDATE civicos_sla_events
        SET status = 'met', met_at = CURRENT_TIMESTAMP(3)
        WHERE entity_type = ? AND entity_id = ? AND milestone = ?
        AND status IN ('pending', 'warning', 'paused') AND exempt = 0]], {
        entityType, entityId, milestone,
    })
    if not result.ok then return result end
    return { ok = true, data = { changed = (result.data.affectedRows or 0) > 0 } }
end

function SlaRepository:pause(id)
    local result = Repository.db():update([[UPDATE civicos_sla_events
        SET status = 'paused', paused_at = CURRENT_TIMESTAMP(3)
        WHERE id = ? AND status IN ('pending', 'warning') AND exempt = 0]], { id })
    if not result.ok then return result end
    return { ok = true, data = { changed = (result.data.affectedRows or 0) > 0 } }
end

function SlaRepository:resume(id)
    local result = Repository.db():update([[UPDATE civicos_sla_events
        SET status = 'pending',
            due_at = DATE_ADD(due_at, INTERVAL TIMESTAMPDIFF(SECOND, paused_at, CURRENT_TIMESTAMP(3)) SECOND),
            warning_at = IF(warning_at IS NULL, NULL, DATE_ADD(warning_at, INTERVAL TIMESTAMPDIFF(SECOND, paused_at, CURRENT_TIMESTAMP(3)) SECOND)),
            accumulated_pause_seconds = accumulated_pause_seconds + TIMESTAMPDIFF(SECOND, paused_at, CURRENT_TIMESTAMP(3)),
            paused_at = NULL
        WHERE id = ? AND status = 'paused' AND paused_at IS NOT NULL]], { id })
    if not result.ok then return result end
    return { ok = true, data = { changed = (result.data.affectedRows or 0) > 0 } }
end

function SlaRepository:exempt(id)
    local result = Repository.db():update("UPDATE civicos_sla_events SET exempt = 1, status = 'cancelled' WHERE id = ?", { id })
    if not result.ok then return result end
    return { ok = true, data = { changed = (result.data.affectedRows or 0) > 0 } }
end

CivicOS.SlaRepository = SlaRepository
return SlaRepository

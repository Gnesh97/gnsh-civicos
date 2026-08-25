local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS
local Repository = CivicOS.Repository

local AuditRepository = {}

function AuditRepository:append(entry)
    return Repository.db():insert([[INSERT INTO civicos_audit_logs
        (actor_identifier, actor_type, entity_type, entity_id, action,
         before_json, after_json, correlation_id)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)]], {
        entry.actorIdentifier, entry.actorType or "player", entry.entityType,
        entry.entityId, entry.action, Repository.encode(entry.before),
        Repository.encode(entry.after), entry.correlationId,
    })
end

function AuditRepository:list(entityType, entityId, page, pageSize)
    page = math.max(1, tonumber(page) or 1)
    pageSize = math.min(math.max(1, tonumber(pageSize) or 50), 100)
    local params = { entityType, entityId, pageSize, (page - 1) * pageSize }
    local result = Repository.db():query([[SELECT id, actor_identifier, actor_type,
        entity_type, entity_id, action, before_json, after_json, correlation_id, created_at
        FROM civicos_audit_logs WHERE entity_type = ? AND entity_id = ?
        ORDER BY created_at DESC LIMIT ? OFFSET ?]], params)
    if not result.ok then
        return result
    end
    return Repository.rows(result)
end

CivicOS.AuditRepository = AuditRepository
return AuditRepository

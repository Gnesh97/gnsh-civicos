local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS
local Repository = CivicOS.Repository

local EscalationRepository = {}

function EscalationRepository:create(escalation)
    return Repository.db():insert([[INSERT INTO civicos_escalations
        (entity_type, entity_id, severity, reason, status, metadata)
        VALUES (?, ?, ?, ?, 'open', ?)]], {
        escalation.entityType, escalation.entityId, escalation.severity, escalation.reason,
        Repository.encode(escalation.metadata),
    })
end

function EscalationRepository:findOpen(entityType, entityId, reason)
    return Repository.rows(Repository.db():query([[SELECT id, entity_type, entity_id, severity,
        reason, status, acknowledged_by, acknowledged_at, metadata, created_at, updated_at
        FROM civicos_escalations WHERE entity_type = ? AND entity_id = ? AND reason = ? AND status = 'open'
        LIMIT 1]], { entityType, entityId, reason }))
end

function EscalationRepository:findById(id)
    return Repository.rows(Repository.db():query([[SELECT id, entity_type, entity_id, severity,
        reason, status, acknowledged_by, acknowledged_at, metadata, created_at, updated_at
        FROM civicos_escalations WHERE id = ? LIMIT 1]], { id }))
end

function EscalationRepository:listOpen(departmentId)
    -- Department scoping is applied by the service after entity lookup; this keeps the table generic.
    return Repository.rows(Repository.db():query([[SELECT id, entity_type, entity_id, severity,
        reason, status, acknowledged_by, acknowledged_at, metadata, created_at, updated_at
        FROM civicos_escalations WHERE status = 'open' ORDER BY created_at DESC LIMIT 100]], {}))
end

function EscalationRepository:acknowledge(id, identifier)
    return Repository.db():update([[UPDATE civicos_escalations
        SET status = 'acknowledged', acknowledged_by = ?, acknowledged_at = CURRENT_TIMESTAMP(3)
        WHERE id = ? AND status = 'open']], { identifier, id })
end

CivicOS.EscalationRepository = EscalationRepository
return EscalationRepository

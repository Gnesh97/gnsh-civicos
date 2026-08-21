local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS
local Repository = CivicOS.Repository

local EvidenceRepository = {}

function EvidenceRepository:create(evidence)
    return Repository.db():insert([[INSERT INTO civicos_evidence
        (entity_type, entity_id, evidence_type, provider, url, metadata, created_by_identifier)
        VALUES (?, ?, ?, ?, ?, ?, ?)]], {
        evidence.entityType, evidence.entityId, evidence.evidenceType, evidence.provider,
        evidence.url, Repository.encode(evidence.metadata), evidence.createdByIdentifier,
    })
end

function EvidenceRepository:list(entityType, entityId)
    local result = Repository.db():query([[SELECT id, entity_type, entity_id, evidence_type,
        provider, url, metadata, created_by_identifier, created_at FROM civicos_evidence
        WHERE entity_type = ? AND entity_id = ? AND deleted_at IS NULL ORDER BY created_at ASC]], {
        entityType, entityId,
    })
    if not result.ok then return result end
    for _, row in ipairs(result.data or {}) do row.metadata = Repository.decode(row.metadata) end
    return { ok = true, data = result.data or {} }
end

function EvidenceRepository:remove(id, identifier)
    return Repository.db():update([[UPDATE civicos_evidence SET deleted_at = CURRENT_TIMESTAMP(3),
        deleted_by_identifier = ? WHERE id = ? AND deleted_at IS NULL]], { identifier, id })
end

function EvidenceRepository:findById(id)
    local result = Repository.db():query([[SELECT id, entity_type, entity_id, evidence_type,
        provider, url, metadata, created_by_identifier, created_at, deleted_at FROM civicos_evidence
        WHERE id = ? LIMIT 1]], { id })
    if not result.ok then return result end
    for _, row in ipairs(result.data or {}) do row.metadata = Repository.decode(row.metadata) end
    return { ok = true, data = result.data or {} }
end

CivicOS.EvidenceRepository = EvidenceRepository
return EvidenceRepository

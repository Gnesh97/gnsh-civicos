local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS
local Repository = CivicOS.Repository

local InspectionRepository = {}

local columns = [[id, workorder_id, inspector_identifier, status, notes, metadata,
    created_at, updated_at]]

function InspectionRepository:create(workorderId, inspectorIdentifier, metadata)
    return Repository.db():insert([[INSERT INTO civicos_inspections
        (workorder_id, inspector_identifier, status, metadata) VALUES (?, ?, 'pending', ?)]], {
        workorderId, inspectorIdentifier, Repository.encode(metadata),
    })
end

function InspectionRepository:findById(id)
    return Repository.rows(Repository.db():query("SELECT " .. columns .. " FROM civicos_inspections WHERE id = ? LIMIT 1", { id }))
end

function InspectionRepository:findLatest(workorderId)
    return Repository.rows(Repository.db():query("SELECT " .. columns .. " FROM civicos_inspections WHERE workorder_id = ? ORDER BY id DESC LIMIT 1", { workorderId }))
end

function InspectionRepository:list(workorderId)
    return Repository.rows(Repository.db():query("SELECT " .. columns .. " FROM civicos_inspections WHERE workorder_id = ? ORDER BY created_at DESC", { workorderId }))
end

function InspectionRepository:update(id, expectedStatus, status, notes, metadata)
    local result = Repository.db():update([[UPDATE civicos_inspections
        SET status = ?, notes = ?, metadata = ? WHERE id = ? AND status = ?]], {
        status, notes, Repository.encode(metadata), id, expectedStatus,
    })
    if not result.ok then return result end
    if (result.data.affectedRows or 0) == 0 then
        return Repository.error("CORE_VERSION_CONFLICT", "Inspection state changed; refresh and retry.", { id = id })
    end
    return { ok = true, data = { id = id, status = status } }
end

CivicOS.InspectionRepository = InspectionRepository
return InspectionRepository

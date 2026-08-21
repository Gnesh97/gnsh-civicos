local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS

local EvidenceService = {}
local allowedTypes = {
    photo = true,
    video = true,
    document = true,
    external_url = true,
}

local function errorResult(code, message, details)
    return CivicOS.Result.err(code, message, details)
end

local function validateUri(uri)
    if type(uri) ~= "string" or #uri == 0 then return errorResult("EVIDENCE_INVALID_URI", "Evidence URI is required.") end
    local max = CivicOS.Config and CivicOS.Config.Evidence and CivicOS.Config.Evidence.MaxUriLength or 2048
    if #uri > max then return errorResult("EVIDENCE_INVALID_URI", "Evidence URI is too long.") end
    local scheme, host = uri:match("^(https?)://([^/%?#]+)")
    if not scheme or not host then return errorResult("EVIDENCE_INVALID_URI", "Evidence URI must use http or https.") end
    local domains = CivicOS.Config and CivicOS.Config.Evidence and CivicOS.Config.Evidence.AllowedDomains or {}
    if #domains > 0 then
        local allowed = false
        for _, domain in ipairs(domains) do
            if host == domain or host:sub(-#domain - 1) == "." .. domain then allowed = true break end
        end
        if not allowed then return errorResult("EVIDENCE_DOMAIN_FORBIDDEN", "Evidence domain is not allowed.") end
    end
    return { ok = true, data = { scheme = scheme, host = host } }
end

local function entityAuth(source, entityType, entityId, permission)
    if entityType == "workorder" then
        local workorder = CivicOS.WorkOrderRepository:findById(entityId)
        if not workorder.ok then return workorder end
        local entity = workorder.data[1]
        if not entity then return errorResult("CORE_NOT_FOUND", "Work order not found.") end
        local employee = entity.assigned_employee_id and CivicOS.EmployeeRepository:findById(entity.assigned_employee_id)
        local assigned = employee and employee.ok and employee.data[1] and employee.data[1].persistent_identifier
        local resource = { assignedIdentifier = assigned, departmentId = entity.department_id }
        local auth = CivicOS.Authorization:can(source, permission, resource)
        if not auth.ok and (permission == "workorder.read.assigned" or permission == "field.evidence.attach") then
            auth = CivicOS.Authorization:can(source, "workorder.read.department", { departmentId = entity.department_id })
        end
        return auth, entity
    elseif entityType == "request" then
        local request = CivicOS.RequestRepository:findById(entityId)
        if not request.ok then return request end
        local entity = request.data[1]
        if not entity then return errorResult("CORE_NOT_FOUND", "Request not found.") end
        local auth
        if permission == "field.evidence.attach" then
            auth = CivicOS.Authorization:can(source, permission, { departmentId = entity.department_id })
        else
            auth = CivicOS.Authorization:can(source, "request.read.own", { ownerIdentifier = entity.requester_identifier })
            if not auth.ok then auth = CivicOS.Authorization:can(source, "request.read.department", { departmentId = entity.department_id }) end
        end
        return auth, entity
    end
    return errorResult("EVIDENCE_ENTITY_INVALID", "Evidence entity type is invalid.")
end

function EvidenceService:add(source, entityType, entityId, evidenceType, uri, metadata)
    if not allowedTypes[evidenceType] then return errorResult("EVIDENCE_TYPE_INVALID", "Evidence type is invalid.") end
    local auth = entityAuth(source, entityType, entityId, "field.evidence.attach")
    if not auth.ok then return auth end
    local validUri = validateUri(uri)
    if not validUri.ok then return validUri end
    local stored = CivicOS.Evidence:store(source, uri, metadata)
    if not stored.ok then return stored end
    local identity = CivicOS.Authorization:identity(source)
    if not identity.ok then return identity end
    local created = CivicOS.EvidenceRepository:create({
        entityType = entityType,
        entityId = entityId,
        evidenceType = evidenceType,
        provider = CivicOS.Evidence.name,
        url = stored.data.uri or uri,
        metadata = stored.data.metadata or metadata,
        createdByIdentifier = identity.data.persistentIdentifier,
    })
    if not created.ok then return created end
    if CivicOS.AuditService then CivicOS.AuditService:record(source, { entityType = entityType, entityId = entityId, action = "evidence_added", after = { evidenceId = created.data, evidenceType = evidenceType } }) end
    return { ok = true, data = { id = created.data, entityType = entityType, entityId = entityId, evidenceType = evidenceType, url = stored.data.uri or uri } }
end

function EvidenceService:list(source, entityType, entityId)
    local auth = entityAuth(source, entityType, entityId, "workorder.read.assigned")
    if not auth.ok then return auth end
    local result = CivicOS.EvidenceRepository:list(entityType, entityId)
    if not result.ok then return result end
    local public = {}
    for _, item in ipairs(result.data) do
        public[#public + 1] = {
            id = item.id,
            entityType = item.entity_type,
            entityId = item.entity_id,
            type = item.evidence_type,
            provider = item.provider,
            url = item.url,
            metadata = item.metadata,
            createdBy = item.created_by_identifier,
            createdAt = item.created_at,
        }
    end
    return { ok = true, data = public }
end

function EvidenceService:remove(source, id)
    local evidence = CivicOS.EvidenceRepository:findById(id)
    if not evidence.ok then return evidence end
    local entity = evidence.data[1]
    if not entity then return errorResult("CORE_NOT_FOUND", "Evidence not found.") end
    local auth = entityAuth(source, entity.entity_type, entity.entity_id, "field.evidence.attach")
    if not auth.ok then return auth end
    local identity = CivicOS.Authorization:identity(source)
    if not identity.ok then return identity end
    local removed = CivicOS.EvidenceRepository:remove(id, identity.data.persistentIdentifier)
    if not removed.ok then return removed end
    if CivicOS.AuditService then CivicOS.AuditService:record(source, { entityType = entity.entity_type, entityId = entity.entity_id, action = "evidence_removed", after = { evidenceId = id } }) end
    return { ok = true, data = { id = id, changed = (removed.data.affectedRows or 0) > 0 } }
end

CivicOS.EvidenceService = EvidenceService
return EvidenceService

local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS

local EscalationService = {}

local function errorResult(code, message, details)
    return CivicOS.Result.err(code, message, details)
end

function EscalationService:create(entityType, entityId, severity, reason, metadata)
    local existing = CivicOS.EscalationRepository:findOpen(entityType, entityId, reason)
    if not existing.ok then return existing end
    if existing.data[1] then return { ok = true, data = existing.data[1].id, duplicate = true } end
    local created = CivicOS.EscalationRepository:create({
        entityType = entityType,
        entityId = entityId,
        severity = severity or "warning",
        reason = reason,
        metadata = metadata,
    })
    if not created.ok then return created end
    if CivicOS.NotificationService and entityType == "request" then
        CivicOS.NotificationService:forRequest(entityId, "escalation", "civicos.escalation.title", "civicos.escalation.body", {
            escalationId = created.data,
            severity = severity,
            reason = reason,
        })
    end
    if CivicOS.AuditRepository then
        CivicOS.AuditRepository:append({ entityType = entityType, entityId = entityId, action = "escalated", after = { severity = severity, reason = reason } })
    end
    return { ok = true, data = created.data }
end

function EscalationService:list(source)
    local identity = CivicOS.Authorization:identity(source)
    if not identity.ok then return identity end
    local auth = CivicOS.Authorization:can(source, "audit.read", { departmentId = identity.data.departmentId })
    if not auth.ok then return auth end
    local result = CivicOS.EscalationRepository:listOpen(auth.data.identity.departmentId)
    if not result.ok or auth.data.scope == "global" then return result end
    local scoped = {}
    for _, item in ipairs(result.data) do
        if item.entity_type == "request" then
            local request = CivicOS.RequestRepository:findById(item.entity_id)
            if request.ok and request.data[1] and request.data[1].department_id == auth.data.identity.departmentId then
                scoped[#scoped + 1] = item
            end
        end
    end
    return { ok = true, data = scoped }
end

function EscalationService:acknowledge(source, id)
    local escalation = CivicOS.EscalationRepository:findById(id)
    if not escalation.ok then return escalation end
    if not escalation.data[1] then return errorResult("CORE_NOT_FOUND", "Escalation not found.") end
    local event = escalation.data[1]
    local resource = {}
    if event.entity_type == "request" then
        local request = CivicOS.RequestRepository:findById(event.entity_id)
        if not request.ok then return request end
        resource.departmentId = request.data[1] and request.data[1].department_id
    end
    local auth = CivicOS.Authorization:can(source, "audit.read", resource)
    if not auth.ok then return auth end
    local result = CivicOS.EscalationRepository:acknowledge(id, auth.data.identity.persistentIdentifier)
    if not result.ok then return result end
    return { ok = true, data = { id = id, changed = (result.data.affectedRows or 0) > 0 } }
end

CivicOS.EscalationService = EscalationService
return EscalationService

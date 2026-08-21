local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS

local AuditService = {}
local redactedKeys = { token = true, secret = true, password = true, license = true, identifier = true }

local function redact(value, depth)
    if depth > 6 then return "[TRUNCATED]" end
    if type(value) == "table" then
        local result = {}
        for key, item in pairs(value) do
            if redactedKeys[string.lower(tostring(key))] then
                result[key] = "[REDACTED]"
            else
                result[key] = redact(item, depth + 1)
            end
        end
        return result
    end
    if type(value) == "string" and #value > 512 then return value:sub(1, 512) .. "..." end
    if type(value) == "number" or type(value) == "boolean" or type(value) == "string" then return value end
    return nil
end

function AuditService:record(source, entry)
    entry = type(entry) == "table" and entry or {}
    local actorIdentifier, actorType = entry.actorIdentifier, entry.actorType or "player"
    if source and not actorIdentifier and CivicOS.Authorization then
        local identity = CivicOS.Authorization:identity(source)
        if identity.ok then actorIdentifier = identity.data.persistentIdentifier end
    end
    return CivicOS.AuditRepository:append({
        actorIdentifier = actorIdentifier or "system",
        actorType = actorType,
        entityType = entry.entityType or "system",
        entityId = entry.entityId,
        action = entry.action or "update",
        before = redact(entry.before, 0),
        after = redact(entry.after, 0),
        correlationId = entry.correlationId,
    })
end

local function resourceFor(entityType, entityId)
    if entityType == "request" then
        local request = CivicOS.RequestRepository:findById(entityId)
        return request.ok and request.data[1] and { departmentId = request.data[1].department_id } or {}
    elseif entityType == "workorder" then
        local workorder = CivicOS.WorkOrderRepository:findById(entityId)
        return workorder.ok and workorder.data[1] and { departmentId = workorder.data[1].department_id } or {}
    end
    return {}
end

function AuditService:list(source, entityType, entityId, page, pageSize)
    local auth = CivicOS.Authorization:can(source, "audit.read", resourceFor(entityType, entityId))
    if not auth.ok then return auth end
    local result = CivicOS.AuditRepository:list(entityType, entityId, page, pageSize)
    if not result.ok then return result end
    local rows = {}
    for _, item in ipairs(result.data) do
        rows[#rows + 1] = {
            id = item.id,
            actorType = item.actor_type,
            actorIdentifier = item.actor_identifier,
            entityType = item.entity_type,
            entityId = item.entity_id,
            action = item.action,
            before = CivicOS.Repository.decode(item.before_json),
            after = CivicOS.Repository.decode(item.after_json),
            correlationId = item.correlation_id,
            createdAt = item.created_at,
        }
    end
    return { ok = true, data = rows }
end

CivicOS.AuditService = AuditService
return AuditService

local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS

local ActivityService = {}
local publicTypes = {
    created = true,
    transition = true,
    updated = true,
    comment_added = true,
    workorder_created = true,
    workorder_sync = true,
    sla_met = true,
}

local function errorResult(code, message, details)
    return CivicOS.Result.err(code, message, details)
end

function ActivityService:request(source, requestId, page, pageSize)
    local request = CivicOS.RequestRepository:findById(requestId)
    if not request.ok then return request end
    local entity = request.data[1]
    if not entity then return errorResult("CORE_NOT_FOUND", "Request not found.") end
    local staff = CivicOS.Authorization:can(source, "request.comment.internal", { departmentId = entity.department_id })
    if not staff.ok then
        local own = CivicOS.Authorization:can(source, "request.read.own", { ownerIdentifier = entity.requester_identifier })
        if not own.ok then return own end
    end
    local result = CivicOS.RequestRepository:listActivity(requestId, page, pageSize)
    if not result.ok then return result end
    local items = {}
    for _, activity in ipairs(result.data) do
        if staff.ok or publicTypes[activity.activity_type] then
            items[#items + 1] = {
                id = activity.id,
                requestId = activity.request_id,
                type = activity.activity_type,
                data = CivicOS.Repository.decode(activity.public_data),
                createdAt = activity.created_at,
            }
        end
    end
    return { ok = true, data = items }
end

function ActivityService:workorder(source, workorderId, page, pageSize)
    local result = CivicOS.AuditService:list(source, "workorder", workorderId, page, pageSize)
    if not result.ok then return result end
    local items = {}
    for _, audit in ipairs(result.data) do
        items[#items + 1] = {
            id = audit.id,
            type = audit.action,
            data = audit.after,
            createdAt = audit.createdAt,
        }
    end
    return { ok = true, data = items }
end

CivicOS.ActivityService = ActivityService
return ActivityService

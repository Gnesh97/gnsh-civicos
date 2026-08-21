local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS

local SlaService = {}

local function errorResult(code, message, details)
    return CivicOS.Result.err(code, message, details)
end

local function dueAt(seconds)
    return os.date("!%Y-%m-%d %H:%M:%S", os.time() + math.max(1, tonumber(seconds) or 1))
end

local function warningAt(seconds)
    local lead = CivicOS.Config and CivicOS.Config.SLA and CivicOS.Config.SLA.WarningLeadSeconds or 300
    return os.date("!%Y-%m-%d %H:%M:%S", os.time() + math.max(0, (tonumber(seconds) or 1) - lead))
end

local function scopedAuth(source, event)
    local resource = {}
    if event and event.entity_type == "request" then
        local request = CivicOS.RequestRepository:findById(event.entity_id)
        if not request.ok then return request end
        if request.data[1] then resource.departmentId = request.data[1].department_id end
    end
    return CivicOS.Authorization:can(source, "sla.manage", resource)
end

function SlaService:createForRequest(requestId, catalog)
    if not catalog or type(catalog.sla) ~= "table" then return errorResult("SLA_INVALID", "SLA configuration is missing.") end
    for _, milestone in ipairs({ "acknowledge", "dispatch", "arrival", "resolution" }) do
        local existing = CivicOS.SlaRepository:find("request", requestId, milestone)
        if not existing.ok then return existing end
        if not existing.data[1] then
            local seconds = tonumber(catalog.sla[milestone])
            if not seconds then return errorResult("SLA_INVALID", "SLA milestone duration is invalid.", { milestone = milestone }) end
            local created = CivicOS.SlaRepository:create({
                entityType = "request",
                entityId = requestId,
                milestone = milestone,
                dueAt = dueAt(seconds),
                warningAt = warningAt(seconds),
            })
            if not created.ok then return created end
        end
    end
    return { ok = true, data = true }
end

function SlaService:markMilestone(requestId, milestone, actorIdentifier)
    if not requestId then return { ok = true, data = false } end
    local result = CivicOS.SlaRepository:markMet("request", requestId, milestone)
    if not result.ok then return result end
    if result.data.changed and CivicOS.RequestRepository then
        CivicOS.RequestRepository:addActivity(requestId, actorIdentifier, "sla_met", { milestone = milestone })
    end
    return result
end

function SlaService:processDue()
    local batch = CivicOS.Config and CivicOS.Config.SLA and CivicOS.Config.SLA.BatchSize or 100
    local due = CivicOS.SlaRepository:listDue(batch)
    if not due.ok then return due end
    local processed = 0
    for _, event in ipairs(due.data) do
        local breached = CivicOS.SlaRepository:markBreached(event.id)
        if breached.ok and breached.data.changed then
            processed = processed + 1
            local request = CivicOS.RequestRepository:findById(event.entity_id)
            local priority = request.ok and request.data[1] and request.data[1].priority
            if CivicOS.NotificationService then
                CivicOS.NotificationService:forRequest(event.entity_id, "sla_breach", "civicos.sla.breach.title", "civicos.sla.breach.body", {
                    milestone = event.milestone,
                    eventId = event.id,
                })
            end
            if (priority == "critical" or priority == "urgent") and CivicOS.EscalationService then
                CivicOS.EscalationService:create("request", event.entity_id, "critical", "sla_breach", { milestone = event.milestone })
            end
        elseif event.status == "pending" then
            local warning = CivicOS.SlaRepository:markWarning(event.id)
            if warning.ok and warning.data.changed then
                processed = processed + 1
                if CivicOS.NotificationService then
                    CivicOS.NotificationService:forRequest(event.entity_id, "sla_warning", "civicos.sla.warning.title", "civicos.sla.warning.body", {
                        milestone = event.milestone,
                        eventId = event.id,
                    })
                end
            end
        end
    end
    return { ok = true, data = { processed = processed } }
end

function SlaService:pause(source, id)
    local event = CivicOS.SlaRepository:findById(id)
    if not event.ok then return event end
    if not event.data[1] then return errorResult("CORE_NOT_FOUND", "SLA event not found.") end
    local auth = scopedAuth(source, event.data[1])
    if not auth.ok then return auth end
    return CivicOS.SlaRepository:pause(id)
end

function SlaService:resume(source, id)
    local event = CivicOS.SlaRepository:findById(id)
    if not event.ok then return event end
    if not event.data[1] then return errorResult("CORE_NOT_FOUND", "SLA event not found.") end
    local auth = scopedAuth(source, event.data[1])
    if not auth.ok then return auth end
    return CivicOS.SlaRepository:resume(id)
end

function SlaService:exempt(source, id)
    local event = CivicOS.SlaRepository:findById(id)
    if not event.ok then return event end
    if not event.data[1] then return errorResult("CORE_NOT_FOUND", "SLA event not found.") end
    local auth = scopedAuth(source, event.data[1])
    if not auth.ok then return auth end
    return CivicOS.SlaRepository:exempt(id)
end

function SlaService:list(source, requestId)
    local request = CivicOS.RequestRepository:findById(requestId)
    if not request.ok then return request end
    if not request.data[1] then return errorResult("CORE_NOT_FOUND", "Request not found.") end
    local auth = CivicOS.Authorization:can(source, "sla.read", { departmentId = request.data[1].department_id })
    if not auth.ok then return auth end
    return CivicOS.SlaRepository:list("request", requestId)
end

CivicOS.SlaService = SlaService
return SlaService

local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS

local RequestService = {}
local referenceCounter = 0

local transitionPermissions = {
    triaged = "request.triage",
    accepted = "request.accept",
    rejected = "request.reject",
    duplicate = "request.triage",
    on_hold = "request.triage",
    converted = "request.convert",
    reopened = "request.reopen",
}

local function errorResult(code, message, details)
    return CivicOS.Result.err(code, message, details)
end

local function nowUtc()
    return os.date("!%Y-%m-%d %H:%M:%S", os.time())
end

local function reference()
    referenceCounter = (referenceCounter + 1) % 1000000
    local suffix = (os.time() % 900000) + referenceCounter
    return string.format("%s-%s-%06d", CivicOS.Constants.REFERENCE_PREFIX, os.date("!%Y"), suffix % 1000000)
end

local function distance(left, right)
    if type(left) ~= "table" or type(right) ~= "table" then return math.huge end
    local dx, dy, dz = (left.x or 0) - (right.x or 0), (left.y or 0) - (right.y or 0), (left.z or 0) - (right.z or 0)
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

local function actorIdentifier(source, context)
    if context and context.actorIdentifier then return context.actorIdentifier end
    if source and CivicOS.Identity then
        local identity = CivicOS.Identity:resolve(source)
        if identity.ok then return identity.data.persistentIdentifier end
    end
    return source and string.format("source:%s", tostring(source)) or "system"
end

local function serviceCode(dto)
    if dto.serviceCode then return dto.serviceCode end
    for _, entry in ipairs(CivicOS.ServiceCatalog.list()) do
        if entry.category == dto.category and (not dto.subcategory or entry.subcategory == dto.subcategory) then
            return entry.code
        end
    end
    return nil
end

local function auditAndActivity(requestId, actor, activityType, publicData)
    CivicOS.RequestRepository:addActivity(requestId, actor, activityType, publicData)
    if CivicOS.AuditRepository then
        CivicOS.AuditRepository:append({
            actorIdentifier = actor,
            entityType = "request",
            entityId = requestId,
            action = activityType,
            after = publicData,
        })
    end
end

local function emit(topic, payload)
    if CivicOS.EventBus and CivicOS.EventBus.emit then
        CivicOS.EventBus.emit(topic, payload)
    elseif type(TriggerEvent) == "function" then
        TriggerEvent("civicos:internal:" .. topic, payload)
    end
end

function RequestService:checkDuplicate(catalog, location)
    local cutoff = os.date("!%Y-%m-%d %H:%M:%S", os.time() - catalog.duplicate.windowSeconds)
    local candidates = CivicOS.RequestRepository:findPotentialDuplicates(catalog.category, catalog.subcategory, cutoff)
    if not candidates.ok then return candidates end
    for _, candidate in ipairs(candidates.data) do
        if distance(location, candidate.location) <= catalog.duplicate.radius then
            return { ok = true, data = { duplicate = true, request = CivicOS.RequestDomain.public(candidate) } }
        end
    end
    return { ok = true, data = { duplicate = false } }
end

function RequestService:create(source, input, context)
    input = type(input) == "table" and input or {}
    context = type(context) == "table" and context or {}
    local sourceType = context.sourceType or input.source or "citizen"
    if sourceType ~= "citizen" and sourceType ~= "integration" and sourceType ~= "staff" then
        return errorResult("CORE_INVALID_INPUT", "Request source is invalid.")
    end
    local code = serviceCode(input)
    if not code then return errorResult("CATALOG_NOT_FOUND", "Service code is required.") end
    local catalog = CivicOS.ServiceCatalogService:get(code, sourceType)
    if not catalog.ok then return catalog end
    local title = CivicOS.Validation.string(input.title, "title", { required = true, maxLength = CivicOS.Constants.Limits.REQUEST_TITLE })
    if not title.ok then return title end
    local description = CivicOS.Validation.string(input.description, "description", { required = true, maxLength = CivicOS.Constants.Limits.REQUEST_DESCRIPTION })
    if not description.ok then return description end
    local location = CivicOS.Validation.vector(input.location, "location")
    if not location.ok then return location end
    local identifier = actorIdentifier(source, context)
    local limited = CivicOS.RateLimit:allow(identifier, "request_create")
    if not limited.ok then return limited end
    local duplicate = self:checkDuplicate(catalog.data, location.data)
    if not duplicate.ok then return duplicate end
    local department = CivicOS.DepartmentService:get(catalog.data.defaultDepartment)
    if not department.ok then return department end
    local created = CivicOS.RequestRepository:create({
        reference = reference(),
        source = sourceType,
        sourceResource = context.sourceResource,
        externalRef = context.externalRef,
        requesterIdentifier = identifier,
        category = catalog.data.category,
        subcategory = catalog.data.subcategory,
        title = title.data,
        description = description.data,
        priority = input.priority or catalog.data.defaultPriority,
        status = CivicOS.Enums.RequestStatus.SUBMITTED,
        departmentId = department.data.id,
        location = location.data,
        metadata = input.metadata,
    })
    if not created.ok then return created end
    local entity = {
        id = created.data,
        reference = "pending",
        status = CivicOS.Enums.RequestStatus.SUBMITTED,
        category = catalog.data.category,
    }
    auditAndActivity(entity.id, identifier, "created", { status = entity.status, category = entity.category })
    emit("request.created", { requestId = entity.id, actorIdentifier = identifier })
    return { ok = true, data = { id = entity.id, duplicateSuggestion = duplicate.data.duplicate and duplicate.data.request or nil } }
end

function RequestService:_authorizeRead(source, entity)
    if not source then return { ok = true, data = true } end
    local own = CivicOS.Authorization:can(source, "request.read.own", { ownerIdentifier = entity.requester_identifier })
    if own.ok then return own end
    return CivicOS.Authorization:can(source, "request.read.department", { departmentId = entity.department_id })
end

function RequestService:get(source, id)
    local result = CivicOS.RequestRepository:findById(id)
    if not result.ok then return result end
    local entity = result.data[1]
    if not entity then return errorResult("CORE_NOT_FOUND", "Request not found.") end
    local authorized = self:_authorizeRead(source, entity)
    if not authorized.ok then return authorized end
    return { ok = true, data = CivicOS.RequestDomain.public(entity) }
end

function RequestService:list(source, filters)
    filters = type(filters) == "table" and filters or {}
    if source then
        local identity = CivicOS.Authorization:identity(source)
        if not identity.ok then return identity end
        if identity.data.role == "CITIZEN" then
            filters.requesterIdentifier = identity.data.persistentIdentifier
        elseif identity.data.departmentName and not filters.departmentId then
            local department = CivicOS.DepartmentService:getPersisted(identity.data.departmentName)
            if department.ok then filters.departmentId = department.data.id end
        end
    end
    local result = CivicOS.RequestRepository:list(filters)
    if not result.ok then return result end
    local public = {}
    for _, entity in ipairs(result.data) do public[#public + 1] = CivicOS.RequestDomain.public(entity) end
    return { ok = true, data = public }
end

function RequestService:transition(source, id, expectedVersion, targetStatus, reason)
    local entityResult = CivicOS.RequestRepository:findById(id)
    if not entityResult.ok then return entityResult end
    local entity = entityResult.data[1]
    if not entity then return errorResult("CORE_NOT_FOUND", "Request not found.") end
    local permission = transitionPermissions[targetStatus]
    if not permission then return errorResult("REQUEST_INVALID_STATE", "Transition target is not service-controlled.") end
    local authorization = CivicOS.Authorization:can(source, permission, { departmentId = entity.department_id })
    if not authorization.ok then return authorization end
    if tonumber(expectedVersion) ~= tonumber(entity.version) then
        return errorResult("CORE_VERSION_CONFLICT", "Request version conflict.", { id = id })
    end
    local transition = CivicOS.RequestStateMachine.transition(entity, targetStatus, {
        actorIdentifier = authorization.data.identity.persistentIdentifier,
        reason = reason,
        occurredAt = nowUtc(),
    })
    if not transition.ok then return transition end
    local updated = CivicOS.RequestRepository:updateStatus(id, expectedVersion, targetStatus)
    if not updated.ok then return updated end
    auditAndActivity(id, authorization.data.identity.persistentIdentifier, "transition", { from = entity.status, to = targetStatus, reason = reason })
    emit("request.status.changed", { requestId = id, from = entity.status, to = targetStatus })
    return updated
end

function RequestService:patch(source, id, expectedVersion, patch)
    patch = type(patch) == "table" and patch or {}
    local entityResult = CivicOS.RequestRepository:findById(id)
    if not entityResult.ok then return entityResult end
    local entity = entityResult.data[1]
    if not entity then return errorResult("CORE_NOT_FOUND", "Request not found.") end
    local authorization = CivicOS.Authorization:can(source, "request.read.own", { ownerIdentifier = entity.requester_identifier })
    if not authorization.ok then return authorization end
    if entity.status ~= CivicOS.Enums.RequestStatus.DRAFT and entity.status ~= CivicOS.Enums.RequestStatus.SUBMITTED then
        return errorResult("REQUEST_INVALID_STATE", "Request cannot be edited in its current state.")
    end
    local title = patch.title and CivicOS.Validation.string(patch.title, "title", { required = true, maxLength = 120 }) or { ok = true, data = entity.title }
    local description = patch.description and CivicOS.Validation.string(patch.description, "description", { required = true, maxLength = 4000 }) or { ok = true, data = entity.description }
    if not title.ok then return title end
    if not description.ok then return description end
    local updated = CivicOS.RequestRepository:updateEditable(id, expectedVersion, title.data, description.data)
    if not updated.ok then return updated end
    auditAndActivity(id, authorization.data.identity.persistentIdentifier, "updated", { fields = { "title", "description" } })
    return { ok = true, data = { id = id, version = expectedVersion + 1 } }
end

CivicOS.RequestService = RequestService
return RequestService

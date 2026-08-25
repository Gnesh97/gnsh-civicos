local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS

local Exports = {}

local function contextOf(context)
    local input = type(context) == "table" and context or {}
    local result = {}
    for key, value in pairs(input) do result[key] = value end
    local getInvokingResource = rawget(_G, "GetInvokingResource")
    local invokingResource = type(getInvokingResource) == "function" and getInvokingResource() or nil
    if type(invokingResource) ~= "string" or invokingResource == "" then
        return nil, CivicOS.Result.err("AUTH_FORBIDDEN", "Public exports require an invoking resource.")
    end
    result.sourceType = "integration"
    result.sourceResource = invokingResource
    result.actorIdentifier = "integration:" .. invokingResource
    return result, nil
end

local function idempotent(name, context, payload, handler)
    if type(context) ~= "table" or type(context.sourceResource) ~= "string" then
        return CivicOS.Result.err("AUTH_FORBIDDEN", "Public export context is invalid.")
    end
    if not context.idempotencyKey then return CivicOS.Result.err("IDEMPOTENCY_REQUIRED", "idempotencyKey is required for integration mutations.") end
    return CivicOS.Idempotency:run("export:" .. name .. ":" .. context.sourceResource, context.idempotencyKey, payload, handler)
end

function Exports.CreateRequest(input, context)
    local normalized, failure = contextOf(context)
    if not normalized then return failure end
    context = normalized
    return idempotent("CreateRequest", context, input, function()
        return CivicOS.RequestService:create(nil, input, context)
    end)
end

function Exports.GetRequest(id)
    local context, failure = contextOf(nil)
    if not context then return failure end
    return CivicOS.RequestService:integrationGet(id, context)
end

function Exports.UpdateRequest(id, expectedVersion, patch, context)
    local normalized, failure = contextOf(context)
    if not normalized then return failure end
    context = normalized
    return idempotent("UpdateRequest", context, { id = id, expectedVersion = expectedVersion, patch = patch }, function()
        return CivicOS.RequestService:integrationPatch(id, expectedVersion, patch, context)
    end)
end

function Exports.ResolveRequest(id, expectedVersion, reason, context)
    local normalized, failure = contextOf(context)
    if not normalized then return failure end
    context = normalized
    return idempotent("ResolveRequest", context, { id = id, expectedVersion = expectedVersion, reason = reason }, function()
        return CivicOS.RequestService:integrationTransition(id, expectedVersion, CivicOS.Enums.RequestStatus.RESOLVED, reason, context)
    end)
end

function Exports.CreateWorkOrder(requestId, expectedVersion, serviceCode, overrides, context)
    local normalized, failure = contextOf(context)
    if not normalized then return failure end
    context = normalized
    return idempotent("CreateWorkOrder", context, { requestId = requestId, expectedVersion = expectedVersion, serviceCode = serviceCode, overrides = overrides }, function()
        return CivicOS.WorkOrderService:convert(nil, requestId, expectedVersion, serviceCode, overrides, context)
    end)
end

function Exports.GetWorkOrder(id)
    local context, failure = contextOf(nil)
    if not context then return failure end
    return CivicOS.WorkOrderService:integrationGet(id, context)
end

function Exports.AddComment(requestId, body, context)
    local normalized, failure = contextOf(context)
    if not normalized then return failure end
    context = normalized
    return idempotent("AddComment", context, { requestId = requestId, body = body }, function()
        local request = CivicOS.RequestRepository:findById(requestId)
        if not request.ok then return request end
        local entity = request.data[1]
        if not entity or entity.source ~= "integration" or (context.sourceResource and entity.source_resource ~= context.sourceResource) then
            return CivicOS.Result.err("AUTH_FORBIDDEN", "Integration cannot comment on this request.")
        end
        local validated = CivicOS.Validation.string(body, "body", { required = true, maxLength = CivicOS.Constants.Limits.COMMENT_BODY })
        if not validated.ok then return validated end
        local created = CivicOS.RequestRepository:addComment(requestId, context.actorIdentifier, "public", validated.data)
        if not created.ok then return created end
        return { ok = true, data = { id = created.data } }
    end)
end

function Exports.GetHealth()
    local db = CivicOS.DatabaseAdapter and CivicOS.DatabaseAdapter:health()
    return { ok = true, data = {
        state = CivicOS.Bootstrap and CivicOS.Bootstrap.state or "UNKNOWN",
        version = CivicOS.Version and CivicOS.Version.version,
        database = db and db.ok == true or false,
        providers = CivicOS.ProviderCapabilities or {},
    } }
end

if type(exports) == "function" then
    exports("CreateRequest", Exports.CreateRequest)
    exports("GetRequest", Exports.GetRequest)
    exports("UpdateRequest", Exports.UpdateRequest)
    exports("ResolveRequest", Exports.ResolveRequest)
    exports("CreateWorkOrder", Exports.CreateWorkOrder)
    exports("GetWorkOrder", Exports.GetWorkOrder)
    exports("AddComment", Exports.AddComment)
    exports("GetHealth", Exports.GetHealth)
end

CivicOS.PublicExports = Exports
return Exports

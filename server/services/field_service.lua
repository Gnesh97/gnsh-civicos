local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS

local FieldService = {}

local function errorResult(code, message, details)
    return CivicOS.Result.err(code, message, details)
end

local function copy(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for key, item in pairs(value) do result[key] = copy(item) end
    return result
end

local function templateFor(entity)
    if entity.metadata and entity.metadata.template then return { ok = true, data = entity.metadata.template } end
    return CivicOS.WorkOrderTemplateService:get(entity.template_key)
end

local function findAction(template, key)
    for _, action in ipairs(template.actions or {}) do
        if action.key == key then return action end
    end
    return nil
end

local function actionMetadata(entity)
    local metadata = copy(entity.metadata or {})
    metadata.fieldActions = type(metadata.fieldActions) == "table" and metadata.fieldActions or {}
    return metadata
end

local function payload(value)
    if type(value) ~= "table" then return {} end
    local maxBytes = CivicOS.Config and CivicOS.Config.FieldOperations and CivicOS.Config.FieldOperations.MaxActionPayloadBytes or 4096
    local encoded
    if type(json) == "table" and type(json.encode) == "function" then
        local ok, result = pcall(json.encode, value)
        encoded = ok and result or nil
    end
    if encoded and #encoded > maxBytes then return nil end
    return copy(value)
end

function FieldService:actions(source, id)
    local result = CivicOS.WorkOrderRepository:findById(id)
    if not result.ok then return result end
    local entity = result.data[1]
    if not entity then return errorResult("CORE_NOT_FOUND", "Work order not found.") end
    local template = templateFor(entity)
    if not template.ok then return template end
    local guard = CivicOS.ExploitGuard:validate(source, entity, { skipDistance = true, states = { on_scene = true, working = true } })
    if not guard.ok then return guard end
    return { ok = true, data = { actions = template.data.actions or {}, version = entity.version } }
end

function FieldService:startAction(source, id, expectedVersion, key)
    local result = CivicOS.WorkOrderRepository:findById(id)
    if not result.ok then return result end
    local entity = result.data[1]
    if not entity then return errorResult("CORE_NOT_FOUND", "Work order not found.") end
    if tonumber(expectedVersion) ~= tonumber(entity.version) then
        return errorResult("CORE_VERSION_CONFLICT", "Work order action version conflict.")
    end
    local template = templateFor(entity)
    if not template.ok then return template end
    local action = findAction(template.data, key)
    if not action then return errorResult("FIELD_ACTION_NOT_FOUND", "Field action not found.", { key = key }) end
    local guard = CivicOS.ExploitGuard:validate(source, entity, {
        states = { on_scene = true, working = true },
        radius = action.radius,
    })
    if not guard.ok then return guard end
    local states = actionMetadata(entity).fieldActions
    local prior = states[key]
    if prior and prior.status == "completed" then return errorResult("FIELD_ACTION_COMPLETED", "Field action has already been completed.") end
    local consumed = { ok = true, data = { consumed = {} } }
    if action.consumeOnStart then
        consumed = CivicOS.InventoryService:consume(source, action.items)
        if not consumed.ok then return consumed end
    end
    local metadata = actionMetadata(entity)
    metadata.fieldActions[key] = {
        status = "started",
        startedAt = os.time(),
        startedBy = guard.data.identity.persistentIdentifier,
        inventoryConsumed = action.consumeOnStart == true,
    }
    local updated = CivicOS.WorkOrderRepository:updateMetadata(id, expectedVersion, metadata)
    if not updated.ok then
        if action.consumeOnStart and consumed.ok and consumed.data and consumed.data.consumed then
            CivicOS.InventoryService:restore(source, consumed.data.consumed)
        end
        return updated
    end
    local token = CivicOS.ActionTokens:issue(source, id, key, updated.data.version)
    if not token.ok then return token end
    return {
        ok = true,
        data = {
            token = token.data.token,
            expiresAt = token.data.expiresAt,
            action = action,
            version = updated.data.version,
        },
    }
end

function FieldService:completeAction(source, id, token, key, expectedVersion, resultPayload)
    local result = CivicOS.WorkOrderRepository:findById(id)
    if not result.ok then return result end
    local entity = result.data[1]
    if not entity then return errorResult("CORE_NOT_FOUND", "Work order not found.") end
    if tonumber(expectedVersion) ~= tonumber(entity.version) then
        return errorResult("CORE_VERSION_CONFLICT", "Work order action version conflict.")
    end
    local template = templateFor(entity)
    if not template.ok then return template end
    local action = findAction(template.data, key)
    if not action then return errorResult("FIELD_ACTION_NOT_FOUND", "Field action not found.", { key = key }) end
    local guard = CivicOS.ExploitGuard:validate(source, entity, {
        states = { on_scene = true, working = true },
        radius = action.radius,
    })
    if not guard.ok then return guard end
    local states = actionMetadata(entity).fieldActions
    local started = states[key]
    if not started or started.status ~= "started" then return errorResult("FIELD_ACTION_NOT_STARTED", "Field action has not been started.") end
    local consumedToken = CivicOS.ActionTokens:consume(source, id, key, token, entity.version)
    if not consumedToken.ok then return consumedToken end
    local consumed
    if action.consumeOnComplete and not started.inventoryConsumed then
        consumed = CivicOS.InventoryService:consume(source, action.items)
        if not consumed.ok then return consumed end
    end
    local safePayload = payload(resultPayload)
    if resultPayload ~= nil and not safePayload then return errorResult("FIELD_ACTION_PAYLOAD_TOO_LARGE", "Field action result is too large.") end
    local metadata = actionMetadata(entity)
    metadata.fieldActions[key] = {
        status = "completed",
        startedAt = started.startedAt,
        completedAt = os.time(),
        startedBy = started.startedBy,
        completedBy = guard.data.identity.persistentIdentifier,
        result = safePayload,
        inventoryConsumed = started.inventoryConsumed or action.consumeOnComplete,
    }
    local updated = CivicOS.WorkOrderRepository:updateMetadata(id, expectedVersion, metadata)
    if not updated.ok then
        if consumed and consumed.ok and consumed.data and consumed.data.consumed then
            CivicOS.InventoryService:restore(source, consumed.data.consumed)
        end
        return updated
    end
    return { ok = true, data = { id = id, action = key, status = "completed", version = updated.data.version } }
end

if type(RegisterNetEvent) == "function" and type(AddEventHandler) == "function" then
    RegisterNetEvent("civicos:server:field:start", function(workorderId, expectedVersion, actionKey)
        local result = FieldService:startAction(source, workorderId, expectedVersion, actionKey)
        if type(TriggerClientEvent) == "function" then TriggerClientEvent("civicos:client:field:result", source, result) end
    end)
    RegisterNetEvent("civicos:server:field:complete", function(workorderId, token, actionKey, expectedVersion, resultPayload)
        local result = FieldService:completeAction(source, workorderId, token, actionKey, expectedVersion, resultPayload)
        if type(TriggerClientEvent) == "function" then TriggerClientEvent("civicos:client:field:result", source, result) end
    end)
end

CivicOS.FieldService = FieldService
return FieldService

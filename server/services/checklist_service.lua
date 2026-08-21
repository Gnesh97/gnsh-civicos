local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS

local ChecklistService = {}

local function errorResult(code, message, details)
    return CivicOS.Result.err(code, message, details)
end

local function copy(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for key, item in pairs(value) do result[key] = copy(item) end
    return result
end

local function definition(item)
    if type(item) == "string" then
        return { key = item, type = "boolean", required = true }
    end
    if type(item) ~= "table" or type(item.key) ~= "string" then return nil end
    local result = copy(item)
    result.type = result.type or "boolean"
    result.required = result.required ~= false
    return result
end

local function templateFor(entity)
    if entity and entity.metadata and entity.metadata.template then
        return { ok = true, data = entity.metadata.template }
    end
    return CivicOS.WorkOrderTemplateService:get(entity and entity.template_key)
end

local function checklistFor(entity)
    local template = templateFor(entity)
    if not template.ok then return template end
    local items = {}
    for _, item in ipairs(template.data.checklist or {}) do
        local parsed = definition(item)
        if not parsed then return errorResult("CHECKLIST_INVALID", "Work order checklist definition is invalid.") end
        items[#items + 1] = parsed
    end
    return { ok = true, data = items }
end

local function stateFor(entity)
    local metadata = copy(entity.metadata or {})
    metadata.checklist = type(metadata.checklist) == "table" and metadata.checklist or {}
    return metadata
end

local function validateValue(item, value)
    if item.type == "boolean" or item.type == "confirmation" then
        return type(value) == "boolean", "Checklist value must be boolean."
    elseif item.type == "text" then
        return type(value) == "string" and #value <= 1000, "Checklist text is invalid."
    elseif item.type == "numeric" then
        return tonumber(value) ~= nil, "Checklist numeric value is invalid."
    elseif item.type == "select" then
        for _, option in ipairs(item.options or {}) do
            if option == value then return true end
        end
        return false, "Checklist selection is invalid."
    elseif item.type == "evidence" then
        return type(value) == "table" or type(value) == "string", "Checklist evidence is invalid."
    end
    return false, "Checklist type is not supported."
end

local function valueComplete(item, value)
    if value == nil then return false end
    if item.type == "boolean" or item.type == "confirmation" then return value == true end
    if item.type == "text" then return type(value) == "string" and value ~= "" end
    if item.type == "numeric" then return tonumber(value) ~= nil end
    if item.type == "select" then return value ~= nil end
    if item.type == "evidence" then return value ~= nil end
    return false
end

function ChecklistService:definitions(entity)
    return checklistFor(entity)
end

function ChecklistService:get(source, id)
    local result = CivicOS.WorkOrderRepository:findById(id)
    if not result.ok then return result end
    local entity = result.data[1]
    if not entity then return errorResult("CORE_NOT_FOUND", "Work order not found.") end
    local employee = entity.assigned_employee_id and CivicOS.EmployeeRepository:findById(entity.assigned_employee_id)
    local assigned = employee and employee.ok and employee.data[1] and employee.data[1].persistent_identifier
    local auth = CivicOS.Authorization:can(source, "workorder.read.assigned", {
        assignedIdentifier = assigned,
        departmentId = entity.department_id,
    })
    if not auth.ok then return auth end
    local items = checklistFor(entity)
    if not items.ok then return items end
    local metadata = stateFor(entity)
    return { ok = true, data = { items = items.data, values = metadata.checklist, version = entity.version } }
end

function ChecklistService:update(source, id, expectedVersion, key, value)
    local result = CivicOS.WorkOrderRepository:findById(id)
    if not result.ok then return result end
    local entity = result.data[1]
    if not entity then return errorResult("CORE_NOT_FOUND", "Work order not found.") end
    local guard = CivicOS.ExploitGuard:validate(source, entity, { states = { on_scene = true, working = true }, radius = 8.0 })
    if not guard.ok then return guard end
    if tonumber(expectedVersion) ~= tonumber(entity.version) then
        return errorResult("CORE_VERSION_CONFLICT", "Work order checklist version conflict.")
    end
    local definitions = checklistFor(entity)
    if not definitions.ok then return definitions end
    local selected
    for _, item in ipairs(definitions.data) do if item.key == key then selected = item break end end
    if not selected then return errorResult("CHECKLIST_ITEM_NOT_FOUND", "Checklist item not found.", { key = key }) end
    local valid, message = validateValue(selected, value)
    if not valid then return errorResult("CHECKLIST_INVALID_VALUE", message, { key = key }) end
    local metadata = stateFor(entity)
    metadata.checklist[key] = copy(value)
    local updated = CivicOS.WorkOrderRepository:updateMetadata(id, expectedVersion, metadata)
    if not updated.ok then return updated end
    if entity.request_id and CivicOS.RequestRepository and CivicOS.RequestRepository.addActivity then
        CivicOS.RequestRepository:addActivity(entity.request_id, guard.data.identity.persistentIdentifier, "checklist_updated", { key = key })
    end
    return { ok = true, data = { id = id, key = key, value = value, version = updated.data.version } }
end

function ChecklistService:validateCompletion(source, entity)
    local guard = CivicOS.ExploitGuard:validate(source, entity, { states = { working = true, pending_inspection = true }, radius = 8.0 })
    if not guard.ok then return guard end
    local definitions = checklistFor(entity)
    if not definitions.ok then return definitions end
    local values = stateFor(entity).checklist
    local missing = {}
    for _, item in ipairs(definitions.data) do
        if item.required and not valueComplete(item, values[item.key]) then missing[#missing + 1] = item.key end
    end
    if #missing > 0 then return errorResult("CHECKLIST_INCOMPLETE", "Required checklist items are incomplete.", { missing = missing }) end
    return { ok = true, data = true }
end

if type(RegisterNetEvent) == "function" and type(AddEventHandler) == "function" then
    RegisterNetEvent("civicos:server:checklist:update", function(workorderId, expectedVersion, key, value)
        local result = ChecklistService:update(source, workorderId, expectedVersion, key, value)
        if type(TriggerClientEvent) == "function" then TriggerClientEvent("civicos:client:checklist:result", source, result) end
    end)
end

CivicOS.ChecklistService = ChecklistService
return ChecklistService

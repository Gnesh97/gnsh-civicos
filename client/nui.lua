local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS

local NUI = { pending = {}, sequence = 0, open = false }

local scalarTypes = { boolean = true, number = true, string = true }

local function jsonSafe(value)
    local active = {}

    local function copy(item, depth)
        local itemType = type(item)
        if item == nil then return nil, false end
        if scalarTypes[itemType] then return item, true end
        if itemType ~= "table" or depth >= 24 or active[item] then return nil, false end

        active[item] = true
        local length = #item
        local array = true
        local keyCount = 0
        for key in pairs(item) do
            if type(key) ~= "number" or key < 1 or key % 1 ~= 0 or key > length then
                array = false
                break
            end
            keyCount = keyCount + 1
        end
        if array and keyCount ~= length then array = false end

        local result = {}
        if array then
            for index = 1, length do
                local child, ok = copy(item[index], depth + 1)
                if ok then result[#result + 1] = child end
            end
        else
            for key, childValue in pairs(item) do
                local keyType = type(key)
                if keyType == "string" or (keyType == "number" and key % 1 == 0) then
                    local child, ok = copy(childValue, depth + 1)
                    if ok then result[keyType == "number" and tostring(key) or key] = child end
                end
            end
        end
        active[item] = nil
        return result, true
    end

    local safeValue, ok = copy(value, 0)
    return ok and safeValue or {}
end

local function send(message)
    if type(SendNUIMessage) == "function" then SendNUIMessage(jsonSafe(message)) end
end

local function catalogPayload()
    local result = {}
    for _, entry in ipairs(CivicOS.ServiceCatalog and CivicOS.ServiceCatalog.list() or {}) do
        result[#result + 1] = { code = entry.code, label = entry.label }
    end
    return result
end

local function nextId()
    NUI.sequence = (NUI.sequence + 1) % 2147483647
    return string.format("nui-%s-%d", GetGameTimer and GetGameTimer() or os.time(), NUI.sequence)
end

function NUI.call(operation, payload, callback)
    local requestId = nextId()
    NUI.pending[requestId] = { callback = callback, operation = operation }
    if type(TriggerServerEvent) == "function" then
        TriggerServerEvent("civicos:server:api:call", requestId, operation, payload or {})
    end
    return requestId
end

function NUI:openView(view, payload)
    self.open = true
    if type(SetNuiFocus) == "function" then SetNuiFocus(true, true) end
    send({ type = "civicos:open", view = view, payload = payload or {} })
end

function NUI:closeView()
    self.open = false
    if type(SetNuiFocus) == "function" then SetNuiFocus(false, false) end
    send({ type = "civicos:close" })
end

if type(RegisterNetEvent) == "function" and type(AddEventHandler) == "function" then
RegisterNetEvent("civicos:client:api:result", function(requestId, result)
        local pending = NUI.pending[requestId]
        NUI.pending[requestId] = nil
        if pending and type(pending.callback) == "function" then pending.callback(result) end
        send({ type = "civicos:api:result", requestId = requestId, operation = pending and pending.operation, result = result })
    end)
end

if type(RegisterNUICallback) == "function" then
    RegisterNUICallback("civicos:api", function(data, callback)
        local requestId = NUI:call(data and data.operation, data and data.payload)
        callback({ ok = true, data = { requestId = requestId } })
    end)
    RegisterNUICallback("civicos:close", function(_, callback)
        NUI:closeView()
        callback({ ok = true })
    end)
end

if type(RegisterCommand) == "function" then
    RegisterCommand("civicos", function()
        if NUI.open then NUI:closeView() else NUI:openView("home", { catalog = catalogPayload() }) end
    end, false)
end

CivicOS.NUI = NUI
NUI:closeView()
return NUI

local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS

local NUI = { pending = {}, sequence = 0, open = false }

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
    if type(SendNUIMessage) == "function" then SendNUIMessage({ type = "civicos:open", view = view, payload = payload or {} }) end
end

function NUI:closeView()
    self.open = false
    if type(SetNuiFocus) == "function" then SetNuiFocus(false, false) end
    if type(SendNUIMessage) == "function" then SendNUIMessage({ type = "civicos:close" }) end
end

if type(RegisterNetEvent) == "function" and type(AddEventHandler) == "function" then
RegisterNetEvent("civicos:client:api:result", function(requestId, result)
        local pending = NUI.pending[requestId]
        NUI.pending[requestId] = nil
        if pending and type(pending.callback) == "function" then pending.callback(result) end
        if type(SendNUIMessage) == "function" then
            SendNUIMessage({ type = "civicos:api:result", requestId = requestId, operation = pending and pending.operation, result = result })
        end
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
        if NUI.open then NUI:closeView() else NUI:openView("home") end
    end, false)
end

CivicOS.NUI = NUI
NUI:closeView()
return NUI

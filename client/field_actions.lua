local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS

local FieldActions = { active = {}, lastResult = nil }

function FieldActions.start(workorderId, version, actionKey)
    if type(TriggerServerEvent) ~= "function" then return false end
    TriggerServerEvent("civicos:server:field:start", workorderId, version, actionKey)
    return true
end

function FieldActions.complete(workorderId, token, actionKey, version, result)
    if type(TriggerServerEvent) ~= "function" then return false end
    TriggerServerEvent("civicos:server:field:complete", workorderId, token, actionKey, version, result)
    return true
end

if type(RegisterNetEvent) == "function" and type(AddEventHandler) == "function" then
    RegisterNetEvent("civicos:client:field:result", function(result)
        FieldActions.lastResult = result
        if result and result.ok and result.data and result.data.token then
            FieldActions.active[result.data.action.key] = result.data
        end
        if type(TriggerEvent) == "function" then TriggerEvent("civicos:client:field:updated", result) end
    end)
end

CivicOS.FieldActions = FieldActions
return FieldActions

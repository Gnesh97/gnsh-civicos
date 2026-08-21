local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS
local Adapter = CivicOS.NotifyInterface.new("standalone")

function Adapter.notify(source, message, notificationType)
    if type(TriggerClientEvent) == "function" then
        TriggerClientEvent("civicos:client:notify", source, { message = message, type = notificationType or "info" })
    end
    return true
end

function Adapter.getCapabilities()
    return { available = true, persistent = false }
end

Adapter.capabilities = Adapter:getCapabilities()
CivicOS.NotifyAdapters = CivicOS.NotifyAdapters or {}
CivicOS.NotifyAdapters.standalone = Adapter
return Adapter

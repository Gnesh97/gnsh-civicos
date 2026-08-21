local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS

local Client = {
    ready = false,
    version = CivicOS.Version and CivicOS.Version.version or "unknown",
}

function Client.start()
    Client.ready = true
    if type(TriggerEvent) == "function" then
        TriggerEvent("civicos:client:ready", { version = Client.version })
    end
end

function Client.stop()
    Client.ready = false
end

CivicOS.Client = Client

if type(CreateThread) == "function" then
    CreateThread(function()
        Client.start()
    end)
else
    Client.start()
end

if type(AddEventHandler) == "function" then
    AddEventHandler("onResourceStop", function(resourceName)
        if type(GetCurrentResourceName) ~= "function" or resourceName == GetCurrentResourceName() then
            Client.stop()
        end
    end)
end

return Client

local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS

if type(RegisterCommand) == "function" then
    RegisterCommand("civicos_health", function(source)
        local result = CivicOS.HealthService:check(source, false)
        local output = type(json) == "table" and type(json.encode) == "function" and json.encode(result) or tostring(result.ok)
        print(output)
        if source and tonumber(source) and tonumber(source) > 0 and type(TriggerClientEvent) == "function" then
            TriggerClientEvent("civicos:client:health", source, result)
        end
    end, false)
end

return true

local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS

local function safeResult(value)
    if CivicOS.Serializers and type(CivicOS.Serializers.jsonSafe) == "function" then
        local ok, sanitized = pcall(CivicOS.Serializers.jsonSafe, value)
        if ok then return sanitized end
    end
    return value
end

local function encode(value)
    if type(json) == "table" and type(json.encode) == "function" then
        local ok, output = pcall(json.encode, value)
        if ok and type(output) == "string" then return output end
    end
    return tostring(value and value.ok or false)
end

if type(RegisterCommand) == "function" then
    RegisterCommand("civicos_diagnostics", function(source)
        local result = CivicOS.HealthService:check(source, true)
        local payload = safeResult(result)
        local output = encode(payload)
        print(output)
        if source and tonumber(source) and tonumber(source) > 0 and type(TriggerClientEvent) == "function" then
            TriggerClientEvent("civicos:client:diagnostics", source, payload, output)
        end
    end, false)
end

return true

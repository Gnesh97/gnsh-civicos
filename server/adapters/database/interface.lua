local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS

local Interface = {}

local sensitiveKeys = {
    password = true,
    token = true,
    secret = true,
    license = true,
    identifier = true,
}

function Interface.redactParams(params)
    if type(params) ~= "table" then
        return {}
    end
    local redacted = {}
    for key, value in pairs(params) do
        if sensitiveKeys[string.lower(tostring(key))] then
            redacted[key] = "[REDACTED]"
        elseif type(value) == "string" and #value > 256 then
            redacted[key] = string.sub(value, 1, 256) .. "..."
        else
            redacted[key] = value
        end
    end
    return redacted
end

function Interface.normalizeError(errorValue, operation)
    local message = type(errorValue) == "table" and errorValue.message or tostring(errorValue)
    local detail = string.format("Database %s failed.", operation or "operation")
    if CivicOS.Result and CivicOS.Result.err then
        return CivicOS.Result.err("DB_QUERY_FAILED", detail, { providerMessage = message })
    end
    return { ok = false, error = { code = "DB_QUERY_FAILED", message = detail, details = {} } }
end

function Interface.new(provider)
    return {
        name = provider or "unknown",
        available = false,
        capabilities = {
            query = false,
            single = false,
            scalar = false,
            insert = false,
            update = false,
            transaction = false,
        },
    }
end

CivicOS.DatabaseInterface = Interface
return Interface

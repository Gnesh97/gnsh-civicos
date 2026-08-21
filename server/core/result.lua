-- Standard success/error envelope for server callbacks, exports and events.

local Result = {}

local unsafeDetailKeys = {
    debug = true,
    stack = true,
    stacktrace = true,
    trace = true,
    token = true,
    secret = true,
    password = true,
}

local function safeDetails(details)
    if type(details) ~= "table" then
        return {}
    end

    local result = {}
    for key, value in pairs(details) do
        if not unsafeDetailKeys[string.lower(tostring(key))] then
            local valueType = type(value)
            if valueType == "string" or valueType == "number" or valueType == "boolean" then
                result[key] = value
            end
        end
    end
    return result
end

function Result.ok(data)
    return {
        ok = true,
        data = data,
    }
end

function Result.err(code, message, details)
    local normalizedCode = type(code) == "string" and code or "CORE_INTERNAL_ERROR"
    local normalizedMessage = type(message) == "string" and message or "An internal error occurred."

    return {
        ok = false,
        error = {
            code = normalizedCode,
            message = normalizedMessage,
            details = safeDetails(details),
        },
    }
end

function Result.isOk(result)
    return type(result) == "table" and result.ok == true
end

function Result.isErr(result)
    return type(result) == "table" and result.ok == false and type(result.error) == "table"
end

return Result

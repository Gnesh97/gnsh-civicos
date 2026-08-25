local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS

local Validation = {}

local function resultError(code, message, details)
    if CivicOS.Result and CivicOS.Result.err then
        return CivicOS.Result.err(code, message, details)
    end
    return { ok = false, error = { code = code, message = message, details = details or {} } }
end

function Validation.string(value, field, options)
    options = type(options) == "table" and options or {}
    if type(value) ~= "string" then
        return resultError("CORE_INVALID_INPUT", string.format("%s must be a string.", field or "value"), { field = field })
    end
    if options.required and value == "" then
        return resultError("CORE_INVALID_INPUT", string.format("%s is required.", field or "value"), { field = field })
    end
    if options.maxLength and #value > options.maxLength then
        return resultError("CORE_INVALID_INPUT", string.format("%s is too long.", field or "value"), { field = field })
    end
    return { ok = true, data = value }
end

function Validation.number(value, field, options)
    options = type(options) == "table" and options or {}
    if type(value) ~= "number" or value ~= value then
        return resultError("CORE_INVALID_INPUT", string.format("%s must be a number.", field or "value"), { field = field })
    end
    if options.integer and value % 1 ~= 0 then
        return resultError("CORE_INVALID_INPUT", string.format("%s must be an integer.", field or "value"), { field = field })
    end
    if options.min and value < options.min or options.max and value > options.max then
        return resultError("CORE_INVALID_INPUT", string.format("%s is outside the allowed range.", field or "value"), { field = field })
    end
    return { ok = true, data = value }
end

function Validation.positiveInteger(value, field)
    return Validation.number(value, field, { integer = true, min = 1 })
end

function Validation.enum(value, field, enumTable)
    if type(enumTable) ~= "table" then
        return resultError("CORE_INVALID_INPUT", "Enum definition is missing.", { field = field })
    end
    for _, enumValue in pairs(enumTable) do
        if value == enumValue then
            return { ok = true, data = value }
        end
    end
    return resultError("CORE_INVALID_INPUT", string.format("%s is not a supported value.", field or "value"), { field = field })
end

function Validation.vector(value, field)
    if type(value) ~= "table" then
        return resultError("CORE_INVALID_INPUT", string.format("%s must be a coordinate object.", field or "location"), { field = field })
    end
    for _, axis in ipairs({ "x", "y", "z" }) do
        local check = Validation.number(value[axis], field .. "." .. axis, { min = -100000.0, max = 100000.0 })
        if not check.ok then
            return check
        end
    end
    return { ok = true, data = { x = value.x, y = value.y, z = value.z, zone = value.zone } }
end

function Validation.object(value, field)
    if type(value) ~= "table" then
        return resultError("CORE_INVALID_INPUT", string.format("%s must be an object.", field or "value"), { field = field })
    end
    return { ok = true, data = value }
end

function Validation.metadata(value, field, options)
    if value == nil then return { ok = true, data = nil } end
    if type(value) ~= "table" then
        return resultError("CORE_INVALID_INPUT", string.format("%s must be an object.", field or "metadata"), { field = field })
    end

    options = type(options) == "table" and options or {}
    local limits = CivicOS.Constants and CivicOS.Constants.Limits or {}
    local maxBytes = tonumber(options.maxBytes) or tonumber(limits.METADATA_BYTES) or 16384
    local maxDepth = tonumber(options.maxDepth) or 8
    local seen = {}

    local function inspect(item, depth)
        local itemType = type(item)
        if itemType == "table" then
            if depth > maxDepth then return false, "depth" end
            if seen[item] then return false, "cycle" end
            seen[item] = true
            for key, child in pairs(item) do
                local keyType = type(key)
                if keyType ~= "string" and keyType ~= "number" then
                    seen[item] = nil
                    return false, "key"
                end
                local valid, reason = inspect(child, depth + 1)
                if not valid then
                    seen[item] = nil
                    return false, reason
                end
            end
            seen[item] = nil
            return true
        end
        if itemType == "nil" or itemType == "string" or itemType == "number" or itemType == "boolean" then
            return true
        end
        return false, "type"
    end

    local structurallyValid, reason = inspect(value, 0)
    if not structurallyValid then
        return resultError("CORE_INVALID_INPUT", "Metadata contains an unsupported value.", { field = field, reason = reason })
    end
    if type(json) ~= "table" or type(json.encode) ~= "function" then
        return resultError("CORE_INVALID_INPUT", "Metadata could not be encoded.", { field = field })
    end
    local encodedOk, encoded = pcall(json.encode, value)
    if not encodedOk or type(encoded) ~= "string" then
        return resultError("CORE_INVALID_INPUT", "Metadata could not be encoded.", { field = field })
    end
    if #encoded > maxBytes then
        return resultError("CORE_INVALID_INPUT", "Metadata is too large.", { field = field, maxBytes = maxBytes })
    end
    return { ok = true, data = value }
end

function Validation.config(config)
    local errors = {}
    if type(config) ~= "table" then
        return resultError("CORE_INVALID_INPUT", "Config must be a table.")
    end
    local framework = config.Framework or {}
    local provider = framework.Provider
    local dutyMode = framework.DutyMode
    local validProviders = { auto = true, qbcore = true, qbox = true, esx = true, standalone = true }
    local validDutyModes = { auto = true, framework = true, civicos = true }
    if not validProviders[provider] then
        errors.provider = "Config.Framework.Provider is invalid."
    end
    if not validDutyModes[dutyMode] then
        errors.dutyMode = "Config.Framework.DutyMode is invalid."
    end
    if type(config.Locale) ~= "string" or config.Locale == "" then
        errors.locale = "Config.Locale is required."
    end
    if next(errors) then
        return resultError("CORE_INVALID_INPUT", "Config validation failed.", errors)
    end
    return { ok = true, data = config }
end

CivicOS.Validation = Validation
return Validation

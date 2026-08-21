local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS

local Repository = {}

function Repository.db()
    return CivicOS.DatabaseAdapter
end

function Repository.encode(value)
    if type(value) ~= "table" then
        return nil
    end
    if type(json) == "table" and type(json.encode) == "function" then
        local ok, encoded = pcall(json.encode, value)
        if ok then
            return encoded
        end
    end
    return nil
end

function Repository.decode(value)
    if type(value) ~= "string" or value == "" then
        return value
    end
    if type(json) == "table" and type(json.decode) == "function" then
        local ok, decoded = pcall(json.decode, value)
        if ok then
            return decoded
        end
    end
    return value
end

function Repository.error(code, message, details)
    if CivicOS.Result and CivicOS.Result.err then
        return CivicOS.Result.err(code, message, details)
    end
    return { ok = false, error = { code = code, message = message, details = details or {} } }
end

function Repository.mapCommon(row)
    if type(row) ~= "table" then
        return row
    end
    local mapped = {}
    for key, value in pairs(row) do
        mapped[key] = value
    end
    if mapped.location_json then
        mapped.location = Repository.decode(mapped.location_json)
        mapped.location_json = nil
    end
    if mapped.metadata then
        mapped.metadata = Repository.decode(mapped.metadata)
    end
    if mapped.checklist_json then
        mapped.checklist = Repository.decode(mapped.checklist_json)
        mapped.checklist_json = nil
    end
    return mapped
end

function Repository.rows(result)
    if not result or not result.ok then
        return result
    end
    local rows = {}
    for _, row in ipairs(result.data or {}) do
        rows[#rows + 1] = Repository.mapCommon(row)
    end
    return { ok = true, data = rows }
end

CivicOS.Repository = Repository
return Repository

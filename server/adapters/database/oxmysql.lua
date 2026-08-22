local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS

local Interface = CivicOS.DatabaseInterface
local Database = Interface and Interface.new("oxmysql") or { name = "oxmysql" }

local function timer()
    if type(GetGameTimer) == "function" then
        return GetGameTimer()
    end
    return math.floor(os.clock() * 1000)
end

local function logger(level, message, context)
    if CivicOS.Logger and type(CivicOS.Logger[level]) == "function" then
        CivicOS.Logger[level]("DB", message, context)
    end
end

local function invoke(method, sql, params)
    local started = timer()
    local ok, result, errorValue

    if type(MySQL) == "table" and type(MySQL[method]) == "table" and type(MySQL[method].await) == "function" then
        ok, result = pcall(MySQL[method].await, sql, params or {})
    elseif type(exports) == "table" and exports.oxmysql then
        -- The plain oxmysql exports are callback-based. Use the documented
        -- *_async aliases so the adapter receives the completed result instead
        -- of treating an immediate nil return as a successful empty response.
        local provider = exports.oxmysql
        local exportName = method .. "_async"
        if type(provider[exportName]) ~= "function" then
            return nil, "oxmysql async export is not available"
        end
        ok, result = pcall(function()
            return provider[exportName](provider, sql, params or {})
        end)
    else
        return nil, "oxmysql provider is not available"
    end

    local elapsed = timer() - started
    local warningMs = CivicOS.Config and CivicOS.Config.Database and CivicOS.Config.Database.QueryTimingWarningMs or 250
    if elapsed >= warningMs then
        logger("warn", string.format("Slow query (%d ms).", elapsed), { operation = method, durationMs = elapsed })
    else
        logger("debug", string.format("Query completed (%d ms).", elapsed), { operation = method, durationMs = elapsed })
    end

    if not ok then
        errorValue = result
        return nil, errorValue
    end
    return result, nil
end

function Database:query(sql, params)
    local rows, errorValue = invoke("query", sql, params)
    if errorValue then
        return Interface.normalizeError(errorValue, "query")
    end
    return { ok = true, data = rows or {} }
end

function Database:single(sql, params)
    local row, errorValue = invoke("single", sql, params)
    if errorValue then
        return Interface.normalizeError(errorValue, "single")
    end
    return { ok = true, data = row }
end

function Database:scalar(sql, params)
    local value, errorValue = invoke("scalar", sql, params)
    if errorValue then
        return Interface.normalizeError(errorValue, "scalar")
    end
    return { ok = true, data = value }
end

function Database:insert(sql, params)
    local id, errorValue = invoke("insert", sql, params)
    if errorValue then
        return Interface.normalizeError(errorValue, "insert")
    end
    return { ok = true, data = id }
end

function Database:update(sql, params)
    local result, errorValue = invoke("update", sql, params)
    if errorValue then
        return Interface.normalizeError(errorValue, "update")
    end
    local affectedRows = type(result) == "table" and (result.affectedRows or result.affected_rows) or result or 0
    return { ok = true, data = { affectedRows = affectedRows } }
end

function Database:transaction(statements)
    if type(MySQL) == "table" and type(MySQL.transaction) == "table" and type(MySQL.transaction.await) == "function" then
        local ok, result = pcall(MySQL.transaction.await, statements)
        if not ok then
            return Interface.normalizeError(result, "transaction")
        end
        return { ok = true, data = result }
    end
    if type(exports) == "table" and exports.oxmysql then
        local provider = exports.oxmysql
        if type(provider.transaction_async) ~= "function" then
            return Interface.normalizeError("oxmysql async transaction export is not available", "transaction")
        end
        local ok, result = pcall(function()
            return provider.transaction_async(provider, statements)
        end)
        if not ok then
            return Interface.normalizeError(result, "transaction")
        end
        return { ok = true, data = result }
    end
    return Interface.normalizeError("oxmysql transaction API is not available", "transaction")
end

function Database:health()
    if type(MySQL) ~= "table" and (type(exports) ~= "table" or not exports.oxmysql) then
        self.available = false
        return Interface.normalizeError("oxmysql provider is not available", "health")
    end
    local result = self:scalar("SELECT 1")
    self.available = result.ok
    return result
end

Database.capabilities = {
    query = true,
    single = true,
    scalar = true,
    insert = true,
    update = true,
    transaction = true,
}

CivicOS.DatabaseAdapter = Database
return Database

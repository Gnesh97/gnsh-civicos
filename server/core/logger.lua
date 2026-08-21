local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS

local Logger = {
    _level = "info",
    _includeTimestamp = true,
    _includeContext = true,
}

local levelRank = {
    debug = 10,
    info = 20,
    warn = 30,
    error = 40,
    fatal = 50,
}

local function timestamp()
    if type(os) == "table" and type(os.date) == "function" then
        return os.date("!%Y-%m-%dT%H:%M:%SZ")
    end
    return "UTC"
end

local function serializeContext(context)
    if not Logger._includeContext or type(context) ~= "table" then
        return ""
    end
    if type(json) == "table" and type(json.encode) == "function" then
        local ok, encoded = pcall(json.encode, context)
        if ok and type(encoded) == "string" then
            return " " .. encoded
        end
    end
    return ""
end

function Logger.configure(options)
    options = type(options) == "table" and options or {}
    Logger._level = levelRank[options.Level] and options.Level or "info"
    Logger._includeTimestamp = options.IncludeTimestamp ~= false
    Logger._includeContext = options.IncludeContext ~= false
end

function Logger.log(level, category, message, context)
    local rank = levelRank[level] or levelRank.info
    if rank < (levelRank[Logger._level] or levelRank.info) then
        return
    end
    local prefix = string.format("[CIVICOS][%s][%s]", string.upper(level), string.upper(category or "CORE"))
    if Logger._includeTimestamp then
        prefix = string.format("[%s]%s", timestamp(), prefix)
    end
    print(string.format("%s %s%s", prefix, tostring(message), serializeContext(context)))
end

function Logger.debug(category, message, context)
    Logger.log("debug", category, message, context)
end

function Logger.info(category, message, context)
    Logger.log("info", category, message, context)
end

function Logger.warn(category, message, context)
    Logger.log("warn", category, message, context)
end

function Logger.error(category, message, context)
    Logger.log("error", category, message, context)
end

function Logger.fatal(category, message, context)
    Logger.log("fatal", category, message, context)
end

function Logger.withContext(context)
    local base = type(context) == "table" and context or {}
    return {
        debug = function(category, message, extra) Logger.debug(category, message, base, extra) end,
        info = function(category, message, extra) Logger.info(category, message, base, extra) end,
        warn = function(category, message, extra) Logger.warn(category, message, base, extra) end,
        error = function(category, message, extra) Logger.error(category, message, base, extra) end,
        fatal = function(category, message, extra) Logger.fatal(category, message, base, extra) end,
    }
end

CivicOS.Logger = Logger
return Logger

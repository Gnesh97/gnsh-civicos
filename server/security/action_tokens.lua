local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS

local ActionTokens = { _entries = {} }
local seeded = false

local function nowMs()
    if type(GetGameTimer) == "function" then return GetGameTimer() end
    return math.floor(os.clock() * 1000)
end

local function randomPart()
    if type(GetRandomIntInRange) == "function" then
        local ok, value = pcall(GetRandomIntInRange, 0, 0x7fffffff)
        if ok and value then return string.format("%08x", value) end
    end
    if not seeded then
        math.randomseed(os.time() + math.floor(os.clock() * 1000000))
        seeded = true
    end
    return string.format("%08x", math.random(0, 0x7fffffff))
end

local function errorResult(code, message, details)
    return CivicOS.Result.err(code, message, details)
end

local function cleanup(timestamp)
    for token, entry in pairs(ActionTokens._entries) do
        if entry.used or entry.expiresAt <= timestamp then
            ActionTokens._entries[token] = nil
        end
    end
end

function ActionTokens:issue(source, entityId, actionKey, version, ttlSeconds)
    local timestamp = nowMs()
    cleanup(timestamp)
    local ttl = tonumber(ttlSeconds)
        or (CivicOS.Config and CivicOS.Config.FieldOperations and CivicOS.Config.FieldOperations.ActionTokenTtlSeconds)
        or 30
    local token = table.concat({ randomPart(), randomPart(), randomPart() }, "-")
    self._entries[token] = {
        source = tostring(source),
        entityId = tostring(entityId),
        actionKey = tostring(actionKey),
        version = tonumber(version),
        expiresAt = timestamp + math.max(1, ttl) * 1000,
        used = false,
    }
    return { ok = true, data = { token = token, expiresAt = self._entries[token].expiresAt } }
end

function ActionTokens:consume(source, entityId, actionKey, token, version)
    if type(token) ~= "string" or token == "" then
        return errorResult("FIELD_ACTION_TOKEN_INVALID", "A field action token is required.")
    end
    local timestamp = nowMs()
    cleanup(timestamp)
    local entry = self._entries[token]
    if not entry then return errorResult("FIELD_ACTION_TOKEN_INVALID", "Field action token is invalid or expired.") end
    if entry.used then return errorResult("FIELD_ACTION_TOKEN_REPLAY", "Field action token was already consumed.") end
    if entry.source ~= tostring(source) or entry.entityId ~= tostring(entityId) or entry.actionKey ~= tostring(actionKey) then
        return errorResult("FIELD_ACTION_TOKEN_BINDING", "Field action token is bound to another action.")
    end
    if entry.version ~= nil and tonumber(version) ~= entry.version then
        return errorResult("FIELD_ACTION_TOKEN_STALE", "Field action token is stale.")
    end
    entry.used = true
    self._entries[token] = nil
    return {
        ok = true,
        data = {
            consumed = true,
            token = token,
            entry = {
                source = entry.source,
                entityId = entry.entityId,
                actionKey = entry.actionKey,
                version = entry.version,
                expiresAt = entry.expiresAt,
            },
        },
    }
end

function ActionTokens:restore(consumed)
    if type(consumed) ~= "table" or type(consumed.token) ~= "string" or type(consumed.entry) ~= "table" then
        return errorResult("FIELD_ACTION_TOKEN_INVALID", "Consumed field action token cannot be restored.")
    end
    local entry = consumed.entry
    local timestamp = nowMs()
    local expiresAt = tonumber(entry.expiresAt)
    if not expiresAt or expiresAt <= timestamp then
        return errorResult("FIELD_ACTION_TOKEN_INVALID", "Consumed field action token has expired.")
    end
    if self._entries[consumed.token] then
        return errorResult("FIELD_ACTION_TOKEN_REPLAY", "Field action token is already active.")
    end
    self._entries[consumed.token] = {
        source = entry.source,
        entityId = entry.entityId,
        actionKey = entry.actionKey,
        version = entry.version,
        expiresAt = expiresAt,
        used = false,
    }
    return { ok = true, data = { restored = true } }
end

CivicOS.ActionTokens = ActionTokens
return ActionTokens

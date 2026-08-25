local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS

local Idempotency = { _locks = {} }

local function errorResult(code, message, details)
    return CivicOS.Result.err(code, message, details)
end

local function hash(value)
    local encoded
    if type(json) == "table" and type(json.encode) == "function" then
        local ok, result = pcall(json.encode, value)
        encoded = ok and result or nil
    end
    encoded = encoded or tostring(value)
    local result = 2166136261
    for index = 1, #encoded do
        result = (result ~ string.byte(encoded, index))
        result = (result * 16777619) % 4294967296
    end
    return string.format("%08x", result)
end

local function decode(value)
    if type(value) ~= "string" or value == "" then return nil end
    if type(json) == "table" and type(json.decode) == "function" then
        local ok, result = pcall(json.decode, value)
        if ok then return result end
    end
    return nil
end

function Idempotency:run(scopeKey, idempotencyKey, payload, handler, ttlSeconds)
    if type(scopeKey) ~= "string" or scopeKey == "" or #scopeKey > 160 then return errorResult("IDEMPOTENCY_INVALID", "Idempotency scope is invalid.") end
    if type(idempotencyKey) ~= "string" or idempotencyKey == "" or #idempotencyKey > 160 then return errorResult("IDEMPOTENCY_REQUIRED", "Idempotency key is required.") end
    if type(handler) ~= "function" then return errorResult("IDEMPOTENCY_INVALID", "Idempotency handler is invalid.") end
    local lockKey = scopeKey .. ":" .. idempotencyKey
    if self._locks[lockKey] then return errorResult("IDEMPOTENCY_IN_PROGRESS", "An identical request is already being processed.") end
    local requestHash = hash(payload)
    CivicOS.DatabaseAdapter:update("DELETE FROM civicos_idempotency WHERE scope_key = ? AND idempotency_key = ? AND expires_at IS NOT NULL AND expires_at <= CURRENT_TIMESTAMP(3)", { scopeKey, idempotencyKey })
    local existing = CivicOS.DatabaseAdapter:single([[SELECT request_hash, response_json, expires_at
        FROM civicos_idempotency WHERE scope_key = ? AND idempotency_key = ?
        AND (expires_at IS NULL OR expires_at > CURRENT_TIMESTAMP(3)) LIMIT 1]], { scopeKey, idempotencyKey })
    if not existing.ok then return existing end
    if existing.data then
        if existing.data.request_hash ~= requestHash then return errorResult("IDEMPOTENCY_KEY_REUSED", "Idempotency key was used with another payload.") end
        local replay = decode(existing.data.response_json)
        if replay then return replay end
        return errorResult("IDEMPOTENCY_IN_PROGRESS", "An identical request is already being processed.")
    end
    local expires = os.date("!%Y-%m-%d %H:%M:%S", os.time() + (tonumber(ttlSeconds) or 86400))
    local claim = CivicOS.DatabaseAdapter:insert([[INSERT INTO civicos_idempotency
        (scope_key, idempotency_key, request_hash, response_json, expires_at) VALUES (?, ?, ?, NULL, ?)]], {
        scopeKey, idempotencyKey, requestHash, expires,
    })
    if not claim.ok then
        local duplicate = CivicOS.DatabaseAdapter:single([[SELECT request_hash, response_json
            FROM civicos_idempotency WHERE scope_key = ? AND idempotency_key = ? LIMIT 1]], { scopeKey, idempotencyKey })
        if duplicate.ok and duplicate.data and duplicate.data.request_hash == requestHash then
            local replay = decode(duplicate.data.response_json)
            return replay or errorResult("IDEMPOTENCY_IN_PROGRESS", "An identical request is already being processed.")
        end
        return claim
    end
    self._locks[lockKey] = true
    local ok, result = pcall(handler)
    self._locks[lockKey] = nil
    if not ok then return errorResult("IDEMPOTENCY_HANDLER_FAILED", "Idempotent operation failed.") end
    local encoded
    if type(json) == "table" and type(json.encode) == "function" then
        local encodedOk, encodedValue = pcall(json.encode, result)
        encoded = encodedOk and encodedValue or nil
    end
    if not encoded then return errorResult("IDEMPOTENCY_RESPONSE_INVALID", "Operation result could not be stored.") end
    local persisted = CivicOS.DatabaseAdapter:update("UPDATE civicos_idempotency SET response_json = ? WHERE scope_key = ? AND idempotency_key = ?", { encoded, scopeKey, idempotencyKey })
    local affectedRows = type(persisted) == "table" and persisted.ok and persisted.data and tonumber(persisted.data.affectedRows) or nil
    if type(persisted) ~= "table" or not persisted.ok or not affectedRows or affectedRows <= 0 then
        return errorResult("IDEMPOTENCY_PERSIST_FAILED", "Operation completed but its idempotent response could not be stored.", type(persisted) == "table" and persisted.error or nil)
    end
    return result
end

CivicOS.Idempotency = Idempotency
return Idempotency

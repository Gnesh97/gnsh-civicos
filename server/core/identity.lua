local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS

local Identity = {
    _cache = {},
    _started = false,
}

local function errorResult(code, message, details)
    return CivicOS.Result.err(code, message, details)
end

function Identity:resolve(source)
    if not CivicOS.Framework then
        return errorResult("ADAPTER_UNAVAILABLE", "Framework adapter is not initialized.")
    end
    local cached = self._cache[source]
    if cached then
        return { ok = true, data = cached, cached = true }
    end
    if not CivicOS.Framework:isPlayerLoaded(source) then
        return errorResult("AUTH_PLAYER_NOT_LOADED", "Player is not loaded.", { source = source })
    end
    local identity = CivicOS.Framework:getPlayer(source)
    if type(identity) ~= "table" or not identity.persistentIdentifier then
        return errorResult("AUTH_IDENTITY_UNAVAILABLE", "Player identity is unavailable.", { source = source })
    end
    self._cache[source] = identity
    return { ok = true, data = identity }
end

function Identity:public(identity)
    identity = identity or {}
    return {
        source = identity.source,
        characterId = identity.characterId,
        displayName = identity.displayName,
        framework = identity.framework,
        job = identity.job,
    }
end

function Identity:clear(source)
    self._cache[source] = nil
end

function Identity:start()
    if self._started or not CivicOS.Framework then
        return
    end
    self._started = true
    CivicOS.Framework:onPlayerLoaded(function(identity)
        self._cache[identity.source] = identity
    end)
    CivicOS.Framework:onPlayerUnloaded(function(source)
        self:clear(source)
    end)
    CivicOS.Framework:onJobChanged(function(identity)
        self._cache[identity.source] = identity
    end)
    CivicOS.Framework:onDutyChanged(function(identity)
        self._cache[identity.source] = identity
    end)
end

CivicOS.Identity = Identity
return Identity

local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS

local Cache = {
    _collections = {
        requests = {},
        workorders = {},
        employees = {},
    },
    _enabled = true,
    _ttlSeconds = 30,
}

local function now()
    if type(os) == "table" and type(os.time) == "function" then
        return os.time()
    end
    return 0
end

function Cache.configure(options)
    options = type(options) == "table" and options or {}
    Cache._enabled = options.Enabled ~= false
    Cache._ttlSeconds = tonumber(options.ActiveStateTtlSeconds) or 30
end

function Cache.set(collection, id, value)
    if not Cache._enabled or not Cache._collections[collection] then
        return value
    end
    Cache._collections[collection][id] = { value = value, expiresAt = now() + Cache._ttlSeconds }
    return value
end

function Cache.get(collection, id)
    if not Cache._enabled or not Cache._collections[collection] then
        return nil
    end
    local entry = Cache._collections[collection][id]
    if not entry then
        return nil
    end
    if entry.expiresAt < now() then
        Cache._collections[collection][id] = nil
        return nil
    end
    return entry.value
end

function Cache.invalidate(collection, id)
    if Cache._collections[collection] then
        Cache._collections[collection][id] = nil
    end
end

function Cache.clear(collection)
    if collection and Cache._collections[collection] then
        Cache._collections[collection] = {}
        return
    end
    Cache._collections = { requests = {}, workorders = {}, employees = {} }
end

function Cache.getOrLoad(collection, id, loader)
    local cached = Cache.get(collection, id)
    if cached ~= nil then
        return { ok = true, data = cached, cached = true }
    end
    local loaded = loader()
    if type(loaded) == "table" and loaded.ok and loaded.data ~= nil then
        Cache.set(collection, id, loaded.data)
    end
    return loaded
end

CivicOS.Cache = Cache
return Cache

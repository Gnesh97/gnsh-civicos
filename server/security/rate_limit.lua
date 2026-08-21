local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS

local RateLimit = { _buckets = {} }

local function now()
    if type(os) == "table" and type(os.time) == "function" then return os.time() end
    return 0
end

function RateLimit:configure(definitions)
    self._definitions = definitions or {}
end

function RateLimit:allow(identifier, bucketName)
    local definition = self._definitions and self._definitions[bucketName] or { windowSeconds = 60, maxRequests = 10 }
    local key = string.format("%s:%s", tostring(identifier), tostring(bucketName))
    local timestamp = now()
    local bucket = self._buckets[key]
    if not bucket or timestamp - bucket.startedAt >= definition.windowSeconds then
        bucket = { startedAt = timestamp, count = 0 }
        self._buckets[key] = bucket
    end
    if bucket.count >= definition.maxRequests then
        if CivicOS.Logger then
            CivicOS.Logger.warn("SECURITY", "Rate limit denied.", { bucket = bucketName })
        end
        return CivicOS.Result.err("SECURITY_RATE_LIMITED", "Too many requests. Try again later.", { bucket = bucketName })
    end
    bucket.count = bucket.count + 1
    return { ok = true, data = { remaining = definition.maxRequests - bucket.count } }
end

CivicOS.RateLimit = RateLimit
return RateLimit

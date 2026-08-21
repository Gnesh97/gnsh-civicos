local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS

local Serializers = {}

function Serializers.paginated(items, page, pageSize, total)
    return {
        items = items or {},
        page = math.max(1, tonumber(page) or 1),
        pageSize = math.min(tonumber(pageSize) or 50, 100),
        total = tonumber(total) or #(items or {}),
    }
end

function Serializers.safeError(result)
    if result and result.ok == false and result.error then
        return CivicOS.Result.err(result.error.code, result.error.message, result.error.details)
    end
    return result
end

CivicOS.Serializers = Serializers
return Serializers

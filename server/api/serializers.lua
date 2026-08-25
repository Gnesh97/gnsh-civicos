local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS

local Serializers = {}

local scalarTypes = {
    boolean = true,
    number = true,
    string = true,
}

-- API results cross the server/client JSON boundary. Keep that boundary
-- explicit: framework/provider objects can contain functions, userdata, or
-- cyclic references that FiveM's JSON encoder cannot represent.
function Serializers.jsonSafe(value, options)
    options = type(options) == "table" and options or {}
    local maxDepth = tonumber(options.maxDepth) or 24
    if maxDepth < 1 then maxDepth = 1 end
    local active = {}

    local function copy(item, depth)
        local itemType = type(item)
        if item == nil then return nil, false end
        if scalarTypes[itemType] then return item, true end
        if itemType ~= "table" or depth >= maxDepth or active[item] then
            return nil, false
        end

        active[item] = true
        local length = #item
        local array = true
        local keyCount = 0
        for key in pairs(item) do
            if type(key) ~= "number" or key < 1 or key % 1 ~= 0 or key > length then
                array = false
                break
            end
            keyCount = keyCount + 1
        end
        if array and keyCount ~= length then array = false end

        local result = {}
        if array then
            for index = 1, length do
                local child, ok = copy(item[index], depth + 1)
                if ok then result[#result + 1] = child end
            end
        else
            for key, childValue in pairs(item) do
                local keyType = type(key)
                if keyType == "string" or (keyType == "number" and key % 1 == 0) then
                    local child, ok = copy(childValue, depth + 1)
                    if ok then
                        result[keyType == "number" and tostring(key) or key] = child
                    end
                end
            end
        end
        active[item] = nil
        return result, true
    end

    local safeValue, ok = copy(value, 0)
    return ok and safeValue or {}
end

function Serializers.paginated(items, page, pageSize, total)
    return {
        items = items or {},
        page = math.max(1, tonumber(page) or 1),
        pageSize = math.min(math.max(1, tonumber(pageSize) or 50), 100),
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

local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS
local Adapter = CivicOS.TargetInterface.new("ox_target")

local function resource()
    return type(exports) == "table" and exports.ox_target or nil
end

function Adapter.addBoxZone(options)
    local target = resource()
    if not target or type(target.addBoxZone) ~= "function" then
        return nil
    end
    local ok, result = pcall(target.addBoxZone, options)
    return ok and result or nil
end

function Adapter.removeZone(id)
    local target = resource()
    if target and type(target.removeZone) == "function" then
        target.removeZone(id)
    end
    return true
end

function Adapter.getCapabilities()
    return { available = true, zones = true, interactions = true, fallbackMarker = false }
end

Adapter.capabilities = Adapter:getCapabilities()
CivicOS.TargetAdapters = CivicOS.TargetAdapters or {}
CivicOS.TargetAdapters.ox_target = Adapter
return Adapter

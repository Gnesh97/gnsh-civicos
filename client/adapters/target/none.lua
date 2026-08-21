local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS
local Adapter = CivicOS.TargetInterface.new("none")

function Adapter.addBoxZone()
    return nil
end

function Adapter.removeZone()
    return true
end

function Adapter.getCapabilities()
    return { available = false, zones = false, interactions = false, fallbackMarker = true }
end

Adapter.capabilities = Adapter:getCapabilities()
CivicOS.TargetAdapters = CivicOS.TargetAdapters or {}
CivicOS.TargetAdapters.none = Adapter
return Adapter

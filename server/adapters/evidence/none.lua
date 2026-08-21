local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS
local Adapter = CivicOS.EvidenceInterface.new("none")

function Adapter.store(_, uri, metadata)
    return { ok = true, data = { uri = uri, metadata = metadata } }
end

function Adapter.remove()
    return { ok = true, data = true }
end

function Adapter.getCapabilities()
    return { available = false, remote = false, remove = true }
end

Adapter.capabilities = Adapter:getCapabilities()
CivicOS.EvidenceAdapters = CivicOS.EvidenceAdapters or {}
CivicOS.EvidenceAdapters.none = Adapter
return Adapter

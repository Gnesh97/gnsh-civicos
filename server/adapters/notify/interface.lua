local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS

local Interface = {}

function Interface.new(name)
    return { name = name, capabilities = { available = false, persistent = false } }
end

function Interface.validate(adapter)
    if type(adapter.notify) ~= "function" or type(adapter.getCapabilities) ~= "function" then
        return CivicOS.Result.err("ADAPTER_INVALID", "Notify adapter contract is incomplete.")
    end
    return CivicOS.Result.ok(true)
end

CivicOS.NotifyInterface = Interface
return Interface

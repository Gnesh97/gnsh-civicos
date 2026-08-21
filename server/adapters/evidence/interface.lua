local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS

local Interface = {}

function Interface.new(name)
    return { name = name, capabilities = { available = false, remote = false, remove = false } }
end

function Interface.validate(adapter)
    for _, method in ipairs({ "store", "remove", "getCapabilities" }) do
        if type(adapter[method]) ~= "function" then
            return CivicOS.Result.err("ADAPTER_INVALID", "Evidence adapter contract is incomplete.", { method = method })
        end
    end
    return CivicOS.Result.ok(true)
end

CivicOS.EvidenceInterface = Interface
return Interface

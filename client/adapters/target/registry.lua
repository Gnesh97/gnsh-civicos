local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS

local Registry = { selected = nil }

local function started(resource)
    return type(GetResourceState) == "function" and GetResourceState(resource) == "started"
end

function Registry:initialize()
    local configured = CivicOS.Adapters and CivicOS.Adapters.Target or "auto"
    local provider = configured == "auto" and (started("ox_target") and "ox_target" or "none") or configured
    if provider == "ox_target" and not started("ox_target") then
        return CivicOS.Result.err("ADAPTER_UNAVAILABLE", "Configured target provider is not running.", { provider = provider })
    end
    local adapter = CivicOS.TargetAdapters and CivicOS.TargetAdapters[provider]
    if not adapter then
        return CivicOS.Result.err("ADAPTER_UNAVAILABLE", "Target adapter is not registered.", { provider = provider })
    end
    local contract = CivicOS.TargetInterface.validate(adapter)
    if not contract.ok then return contract end
    self.selected = adapter
    CivicOS.Target = adapter
    CivicOS.TargetCapabilities = adapter:getCapabilities()
    return { ok = true, data = CivicOS.TargetCapabilities }
end

CivicOS.TargetRegistry = Registry
return Registry

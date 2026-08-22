local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS
local Shared = CivicOS.FrameworkShared

local Registry = {
    selected = nil,
    initialized = false,
}

local function errorResult(code, message, details)
    if CivicOS.Result and CivicOS.Result.err then
        return CivicOS.Result.err(code, message, details)
    end
    return { ok = false, error = { code = code, message = message, details = details or {} } }
end

local function detect()
    local qb = Shared.resourceStarted("qb-core")
    local qbox = Shared.resourceStarted("qbx_core")
    local esx = Shared.resourceStarted("es_extended")
    if qb and qbox then
        return nil, errorResult("ADAPTER_AMBIGUOUS", "qb-core and qbx_core are both running; set Config.Framework.Provider explicitly.")
    end
    if qbox then return "qbox" end
    if qb then return "qbcore" end
    if esx then return "esx" end
    return "standalone"
end

local function chooseProvider()
    local configured = CivicOS.Config and CivicOS.Config.Framework and CivicOS.Config.Framework.Provider or "auto"
    if configured ~= "auto" then
        if configured ~= "standalone" and not Shared.resourceStarted(
            configured == "qbcore" and "qb-core" or configured == "qbox" and "qbx_core" or "es_extended"
        ) then
            return nil, errorResult("ADAPTER_UNAVAILABLE", string.format("Configured framework is not running: %s", configured), { provider = configured })
        end
        return configured
    end
    return detect()
end

function Registry:initialize()
    if self.initialized then
        return { ok = true, data = self.selected }
    end
    local provider, detectError = chooseProvider()
    if not provider then
        return detectError
    end
    local adapter = CivicOS.FrameworkAdapters and CivicOS.FrameworkAdapters[provider]
    if not adapter then
        return errorResult("ADAPTER_UNAVAILABLE", "Framework adapter is not registered.", { provider = provider })
    end
    local contract = CivicOS.FrameworkInterface.validate(adapter)
    if not contract.ok then
        return contract
    end
    self.selected = adapter
    self.initialized = true
    CivicOS.Framework = adapter
    CivicOS.FrameworkCapabilities = adapter.getCapabilities()
    if CivicOS.Logger then
        CivicOS.Logger.info("CORE", "Framework adapter selected.", { provider = provider, capabilities = CivicOS.FrameworkCapabilities })
    end
    return { ok = true, data = adapter }
end

function Registry:reset()
    self.selected = nil
    self.initialized = false
    CivicOS.Framework = nil
end

CivicOS.AdapterRegistry = Registry
return Registry

local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS

local Providers = {}

local function errorResult(code, message, details)
    return CivicOS.Result.err(code, message, details)
end

local function started(resource)
    return type(GetResourceState) == "function" and GetResourceState(resource) == "started"
end

function Providers.initialize()
    local config = CivicOS.Config or {}
    local adapterConfig = CivicOS.Adapters or {}

    local inventoryName = adapterConfig.Inventory or "auto"
    if inventoryName == "auto" then
        inventoryName = started("ox_inventory") and "ox_inventory" or "none"
    end
    if inventoryName == "ox_inventory" and not started("ox_inventory") then
        return errorResult("ADAPTER_UNAVAILABLE", "Configured inventory provider is not running.", { provider = inventoryName })
    end
    local inventory = CivicOS.InventoryAdapters and CivicOS.InventoryAdapters[inventoryName]
    if not inventory then
        return errorResult("ADAPTER_UNAVAILABLE", "Inventory adapter is not registered.", { provider = inventoryName })
    end
    local inventoryContract = CivicOS.InventoryInterface.validate(inventory)
    if not inventoryContract.ok then return inventoryContract end

    local notifyName = adapterConfig.Notify or "standalone"
    local notify = CivicOS.NotifyAdapters and CivicOS.NotifyAdapters[notifyName]
    if not notify then
        return errorResult("ADAPTER_UNAVAILABLE", "Notify adapter is not registered.", { provider = notifyName })
    end
    local notifyContract = CivicOS.NotifyInterface.validate(notify)
    if not notifyContract.ok then return notifyContract end

    CivicOS.Inventory = inventory
    CivicOS.Notify = notify
    CivicOS.ProviderCapabilities = {
        inventory = inventory:getCapabilities(),
        notify = notify:getCapabilities(),
    }
    return { ok = true, data = CivicOS.ProviderCapabilities }
end

CivicOS.ProviderAdapters = Providers
return Providers

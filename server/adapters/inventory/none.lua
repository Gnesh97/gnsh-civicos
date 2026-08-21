local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS
local Adapter = CivicOS.InventoryInterface.new("none")

function Adapter.hasItem()
    return { ok = true, data = false }
end

function Adapter.addItem()
    return { ok = false, error = { code = "INVENTORY_UNAVAILABLE", message = "Inventory provider is disabled.", details = {} } }
end

function Adapter.removeItem()
    return { ok = false, error = { code = "INVENTORY_UNAVAILABLE", message = "Inventory provider is disabled.", details = {} } }
end

function Adapter.getCapabilities()
    return { available = false, metadata = false, usableItems = false }
end

Adapter.capabilities = Adapter:getCapabilities()
CivicOS.InventoryAdapters = CivicOS.InventoryAdapters or {}
CivicOS.InventoryAdapters.none = Adapter
return Adapter

local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS
local Adapter = CivicOS.InventoryInterface.new("ox_inventory")

local function resource()
    return type(exports) == "table" and exports.ox_inventory or nil
end

function Adapter.hasItem(source, item, count, metadata)
    local ox = resource()
    if not ox or type(ox.Search) ~= "function" then
        return { ok = false, error = { code = "INVENTORY_UNAVAILABLE", message = "ox_inventory is not running.", details = {} } }
    end
    local ok, result = pcall(ox.Search, source, "count", item, metadata)
    if not ok then
        return { ok = false, error = { code = "INVENTORY_QUERY_FAILED", message = "Inventory lookup failed.", details = {} } }
    end
    return { ok = true, data = (tonumber(result) or 0) >= (tonumber(count) or 1) }
end

function Adapter.addItem(source, item, count, metadata)
    local ox = resource()
    if not ox or type(ox.AddItem) ~= "function" then
        return { ok = false, error = { code = "INVENTORY_UNAVAILABLE", message = "ox_inventory is not running.", details = {} } }
    end
    local ok, result = pcall(ox.AddItem, source, item, count, metadata)
    return ok and { ok = result ~= false, data = result } or { ok = false, error = { code = "INVENTORY_UPDATE_FAILED", message = "Inventory update failed.", details = {} } }
end

function Adapter.removeItem(source, item, count, metadata)
    local ox = resource()
    if not ox or type(ox.RemoveItem) ~= "function" then
        return { ok = false, error = { code = "INVENTORY_UNAVAILABLE", message = "ox_inventory is not running.", details = {} } }
    end
    local ok, result = pcall(ox.RemoveItem, source, item, count, metadata)
    return ok and { ok = result ~= false, data = result } or { ok = false, error = { code = "INVENTORY_UPDATE_FAILED", message = "Inventory update failed.", details = {} } }
end

function Adapter.getCapabilities()
    return { available = true, metadata = true, usableItems = true }
end

Adapter.capabilities = Adapter:getCapabilities()
CivicOS.InventoryAdapters = CivicOS.InventoryAdapters or {}
CivicOS.InventoryAdapters.ox_inventory = Adapter
return Adapter

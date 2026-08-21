local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS

local InventoryService = {}

local function errorResult(code, message, details)
    return CivicOS.Result.err(code, message, details)
end

local function requirements(items)
    local result = {}
    for _, entry in ipairs(items or {}) do
        if type(entry) == "table" and type(entry.item) == "string" and entry.item ~= "" then
            result[#result + 1] = {
                item = entry.item,
                count = math.max(1, tonumber(entry.count) or 1),
                metadata = entry.metadata,
            }
        end
    end
    return result
end

local function providerAvailable()
    return CivicOS.Inventory and CivicOS.Inventory.capabilities and CivicOS.Inventory.capabilities.available == true
end

function InventoryService:check(source, items)
    local needed = requirements(items)
    if #needed == 0 then return { ok = true, data = { required = needed } } end
    if not providerAvailable() then
        local allow = CivicOS.Config and CivicOS.Config.FieldOperations and CivicOS.Config.FieldOperations.AllowNoInventory
        if allow then return { ok = true, data = { required = needed, skipped = true } } end
        return errorResult("INVENTORY_UNAVAILABLE", "An inventory provider is required for this action.")
    end
    for _, entry in ipairs(needed) do
        local available = CivicOS.Inventory:hasItem(source, entry.item, entry.count, entry.metadata)
        if not available.ok then return available end
        if not available.data then
            return errorResult("FIELD_ITEM_REQUIRED", "Required field item is missing.", { item = entry.item, count = entry.count })
        end
    end
    return { ok = true, data = { required = needed } }
end

function InventoryService:consume(source, items)
    local checked = self:check(source, items)
    if not checked.ok or checked.data.skipped or #checked.data.required == 0 then return checked end
    local consumed = {}
    for _, entry in ipairs(checked.data.required) do
        local removed = CivicOS.Inventory:removeItem(source, entry.item, entry.count, entry.metadata)
        if not removed.ok then
            for _, prior in ipairs(consumed) do
                CivicOS.Inventory:addItem(source, prior.item, prior.count, prior.metadata)
            end
            return errorResult("FIELD_ITEM_CONSUME_FAILED", "Required field item could not be consumed.", { item = entry.item })
        end
        consumed[#consumed + 1] = entry
    end
    return { ok = true, data = { required = checked.data.required, consumed = consumed } }
end

function InventoryService:restore(source, items)
    if not providerAvailable() then return { ok = true, data = false } end
    for _, entry in ipairs(requirements(items)) do
        local restored = CivicOS.Inventory:addItem(source, entry.item, entry.count, entry.metadata)
        if not restored.ok then return restored end
    end
    return { ok = true, data = true }
end

CivicOS.InventoryService = InventoryService
return InventoryService

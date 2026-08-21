local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS

local Routes = { current = nil }

local function vector(value)
    if type(value) ~= "table" or tonumber(value.x) == nil or tonumber(value.y) == nil or tonumber(value.z) == nil then return nil end
    return { x = tonumber(value.x), y = tonumber(value.y), z = tonumber(value.z) }
end

function Routes:set(workorder)
    local location = vector(workorder and workorder.location)
    if not location then return false end
    self.current = { id = workorder.id, location = location, reference = workorder.reference }
    if type(SetNewWaypoint) == "function" then SetNewWaypoint(location.x, location.y) end
    return true
end

function Routes:clear()
    self.current = nil
end

if type(RegisterNetEvent) == "function" and type(AddEventHandler) == "function" then
    RegisterNetEvent("civicos:client:route:set", function(workorder) Routes:set(workorder) end)
    RegisterNetEvent("civicos:client:route:clear", function() Routes:clear() end)
end

CivicOS.Routes = Routes
return Routes

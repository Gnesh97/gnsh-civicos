local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS

local Interactions = { zones = {} }

function Interactions:register(workorder, actionKey)
    if not workorder or not workorder.id or not workorder.location then return nil end
    local zoneId
    if CivicOS.Target and CivicOS.Target.capabilities and CivicOS.Target.capabilities.interactions then
        zoneId = CivicOS.Target.addBoxZone({
            name = string.format("civicos_workorder_%s_%s", workorder.id, actionKey),
            coords = workorder.location,
            size = vec3 and vec3(2.0, 2.0, 2.0) or { x = 2.0, y = 2.0, z = 2.0 },
            rotation = 0.0,
            debug = false,
            options = {
                {
                    name = actionKey,
                    label = actionKey,
                    onSelect = function()
                        if CivicOS.FieldActions then CivicOS.FieldActions:start(workorder.id, workorder.version, actionKey) end
                    end,
                },
            },
        })
    end
    self.zones[#self.zones + 1] = { id = zoneId, workorderId = workorder.id, actionKey = actionKey }
    return zoneId
end

function Interactions:clear()
    for _, zone in ipairs(self.zones) do
        if zone.id and CivicOS.Target and CivicOS.Target.removeZone then CivicOS.Target.removeZone(zone.id) end
    end
    self.zones = {}
end

CivicOS.Interactions = Interactions
return Interactions

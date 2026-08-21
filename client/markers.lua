local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS

local Markers = { enabled = true }

function Markers:draw(route)
    if not self.enabled or not route or not route.location or type(DrawMarker) ~= "function" then return end
    local point = route.location
    DrawMarker(1, point.x, point.y, point.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
        1.0, 1.0, 1.0, 52, 152, 219, 145, false, true, 2, false, nil, nil, false)
end

if type(CreateThread) == "function" then
    CreateThread(function()
        while true do
            local route = CivicOS.Routes and CivicOS.Routes.current
            if route then
                Markers:draw(route)
                Wait(0)
            else
                Wait(500)
            end
        end
    end)
end

CivicOS.Markers = Markers
return Markers

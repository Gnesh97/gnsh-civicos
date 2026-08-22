local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS

local function display(result, output)
    local message = type(output) == "string" and output or "Diagnostics response unavailable."
    if type(TriggerEvent) == "function" then
        TriggerEvent("chat:addMessage", {
            color = { 48, 153, 214 },
            multiline = true,
            args = { "CivicOS", message },
        })
    end
    if type(print) == "function" then
        print(string.format("[CivicOS] %s", message))
    end
    return result
end

if type(RegisterNetEvent) == "function" and type(AddEventHandler) == "function" then
    RegisterNetEvent("civicos:client:diagnostics", function(result, output)
        display(result, output)
    end)
end

CivicOS.Diagnostics = { display = display }
return CivicOS.Diagnostics

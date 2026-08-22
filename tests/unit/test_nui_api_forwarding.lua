-- Regression test for forwarding NUI API operations to the server event.
-- Run from the resource root with: lua tests/unit/test_nui_api_forwarding.lua

_G.CivicOS = {}
local callbacks = {}
local serverCall

_G.RegisterNUICallback = function(name, callback)
    callbacks[name] = callback
end
_G.RegisterNetEvent = function() end
_G.AddEventHandler = function() end
_G.RegisterCommand = function() end
_G.SendNUIMessage = function() end
_G.SetNuiFocus = function() end
_G.GetGameTimer = function() return 1 end
_G.TriggerServerEvent = function(eventName, requestId, operation, payload)
    serverCall = { eventName, requestId, operation, payload }
end

dofile("client/nui.lua")

local response
callbacks["civicos:api"]({ operation = "request.list", payload = { page = 1 } }, function(value)
    response = value
end)

assert(serverCall and serverCall[1] == "civicos:server:api:call", "NUI must call the CivicOS server API event")
assert(serverCall[3] == "request.list", "NUI must forward the API operation as a string")
assert(serverCall[4].page == 1, "NUI must forward the API payload")
assert(response and response.ok == true and response.data.requestId == serverCall[2], "NUI callback must return the request id")

print("NUI API forwarding regression: PASS")

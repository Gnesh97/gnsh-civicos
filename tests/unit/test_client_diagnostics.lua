-- Regression test for displaying server diagnostics in the player chat.
-- Run from the resource root with: lua tests/unit/test_client_diagnostics.lua

local handler
local chatMessage

_G.RegisterNetEvent = function(name, callback)
    if name == "civicos:client:diagnostics" then handler = callback end
end
_G.AddEventHandler = function() end
_G.TriggerEvent = function(name, payload)
    if name == "chat:addMessage" then chatMessage = payload end
end
_G.print = function() end

dofile("client/diagnostics.lua")

assert(type(handler) == "function", "client diagnostics event must be registered")
handler({ ok = true, data = { status = "healthy" } }, "{diagnostics}")

assert(chatMessage and chatMessage.args, "client diagnostics must send a chat message")
assert(chatMessage.args[1] == "CivicOS", "diagnostics chat message must identify CivicOS")
assert(chatMessage.args[2] == "{diagnostics}", "diagnostics chat message must contain the server payload")

print("Client diagnostics display: PASS")

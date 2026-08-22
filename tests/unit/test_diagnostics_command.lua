-- Regression test for returning diagnostics to the player that ran the command.
-- Run from the resource root with: lua tests/unit/test_diagnostics_command.lua

local registered
local clientEvent
local printed

_G.CivicOS = {
    HealthService = {
        check = function(_, source, detailed)
            assert(source == 7, "diagnostics must receive the command source")
            assert(detailed == true, "diagnostics must request detailed health data")
            return { ok = true, data = { status = "healthy" } }
        end,
    },
    Serializers = {
        jsonSafe = function(value)
            return value
        end,
    },
}

_G.RegisterCommand = function(name, callback)
    if name == "civicos_diagnostics" then registered = callback end
end
_G.TriggerClientEvent = function(eventName, target, result, output)
    clientEvent = { eventName, target, result, output }
end
_G.json = { encode = function() return "{diagnostics}" end }
_G.print = function(value) printed = value end

dofile("server/commands/diagnostics.lua")

assert(type(registered) == "function", "diagnostics command must be registered")
registered(7)

assert(clientEvent and clientEvent[1] == "civicos:client:diagnostics", "diagnostics must emit a client event")
assert(clientEvent[2] == 7, "diagnostics must target the command source")
assert(clientEvent[3] and clientEvent[3].ok == true, "diagnostics must forward the health result")
assert(clientEvent[4] == "{diagnostics}", "diagnostics must forward a printable payload")
assert(printed == "{diagnostics}", "diagnostics must print the payload to the server console")

print("Diagnostics command response: PASS")

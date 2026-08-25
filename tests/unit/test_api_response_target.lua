-- Regression test for retaining the event source while a server API handler yields.
-- Run from the resource root with: lua tests/unit/test_api_response_target.lua

local apiHandler
local clientEvent

_G.CivicOS = {
    Authorization = {
        identity = function(_, target)
            return { ok = true, data = { persistentIdentifier = "citizen:" .. target } }
        end,
    },
    RateLimit = {
        allow = function()
            return { ok = true }
        end,
    },
    Serializers = {
        safeError = function(value) return value end,
        jsonSafe = function(value) return value end,
    },
    Result = {
        err = function(code, message, details)
            return { ok = false, error = { code = code, message = message, details = details } }
        end,
    },
    HealthService = {
        check = function()
            -- Database-backed handlers can yield, after which FiveM's global source is no longer valid.
            _G.source = nil
            return { ok = true, data = { healthy = true } }
        end,
    },
}

_G.RegisterNetEvent = function(name, callback)
    if name == "civicos:server:api:call" then apiHandler = callback end
end
_G.AddEventHandler = function() end
_G.TriggerClientEvent = function(eventName, target, requestId, result)
    clientEvent = { eventName, target, requestId, result }
end

dofile("server/api/callbacks.lua")

assert(type(apiHandler) == "function", "server API event handler must be registered")

_G.source = 42
apiHandler("request-1", "health", {})

assert(clientEvent and clientEvent[1] == "civicos:client:api:result", "server must respond through the client API event")
assert(clientEvent[2] == 42, "server must retain the original event source after a yielding API handler")
assert(clientEvent[3] == "request-1", "server must return the originating request id")
assert(clientEvent[4] and clientEvent[4].ok == true, "server must forward the handler result")

print("API response target regression: PASS")

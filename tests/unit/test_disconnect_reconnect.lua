-- Regression coverage for reconnecting on a different FiveM source slot.
-- Run from the resource root with: lua tests/unit/test_disconnect_reconnect.lua

local function errorResult(code, message, details)
    return { ok = false, error = { code = code, message = message, details = details or {} } }
end

local scheduled = {}
local releases = 0
local reconnectNotifications = 0

_G.SetTimeout = function(_, callback)
    scheduled[#scheduled + 1] = callback
end

_G.CivicOS = {
    Result = { err = errorResult },
    Config = { Recovery = { DisconnectGraceSeconds = 300, MaxRecoveryBatch = 10 } },
    EmployeeRepository = {
        findByIdentifier = function(_, identifier)
            return { ok = true, data = { { id = identifier == "license:one" and 11 or 12 } } }
        end,
        updateAvailability = function()
            return { ok = true, data = {} }
        end,
    },
    WorkOrderRepository = {
        list = function()
            return {
                ok = true,
                data = {
                    { id = 7, version = 1, status = "assigned", assigned_crew_id = nil },
                },
            }
        end,
        releaseAssignment = function()
            releases = releases + 1
            return { ok = true, data = { affectedRows = 1 } }
        end,
    },
    CrewRepository = {
        restoreMemberStatus = function()
            return { ok = true, data = {} }
        end,
    },
    NotificationService = {
        create = function()
            reconnectNotifications = reconnectNotifications + 1
            return { ok = true, data = {} }
        end,
    },
}

local disconnect = dofile("server/services/disconnect_service.lua")

disconnect:onLoaded({ source = 1, persistentIdentifier = "license:one", job = { onDuty = true } })
disconnect:onUnloaded(1)
assert(#scheduled == 1, "disconnect should schedule a grace callback")

-- The player reconnects through a different source slot before grace expires.
disconnect:onLoaded({ source = 2, persistentIdentifier = "license:one", job = { onDuty = true } })
scheduled[1]()
assert(releases == 0, "a reconnect on another source must cancel the stale release")
assert(reconnectNotifications == 1, "a cross-source reconnect should restore notifications")

-- A player that does not reconnect still releases the solo assignment at timeout.
disconnect:onLoaded({ source = 3, persistentIdentifier = "license:two", job = { onDuty = true } })
disconnect:onUnloaded(3)
assert(#scheduled == 2, "a second disconnect should schedule another callback")
scheduled[2]()
assert(releases == 1, "an expired disconnect grace must release the solo assignment")

print("disconnect cross-source reconnect regression: PASS")

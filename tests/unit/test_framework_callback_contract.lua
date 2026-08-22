-- Regression test for framework callback registration using the adapter's dot contract.
-- Run from the resource root with: lua tests/unit/test_framework_callback_contract.lua

local registrations = {}
local function register(name)
    return function(callback)
        assert(type(callback) == "function", name .. " must receive a function callback")
        registrations[name] = callback
    end
end

_G.CivicOS = {
    Framework = {
        onPlayerLoaded = register("onPlayerLoaded"),
        onPlayerUnloaded = register("onPlayerUnloaded"),
        onJobChanged = register("onJobChanged"),
        onDutyChanged = register("onDutyChanged"),
    },
}

dofile("server/core/identity.lua")
dofile("server/services/employee_service.lua")
dofile("server/services/disconnect_service.lua")
dofile("server/services/crew_service.lua")

CivicOS.Identity:start()
CivicOS.EmployeeService:start()
CivicOS.DisconnectService:start()
CivicOS.CrewService:start()

for _, name in ipairs({ "onPlayerLoaded", "onPlayerUnloaded", "onJobChanged", "onDutyChanged" }) do
    assert(type(registrations[name]) == "function", name .. " callback must be registered")
end

print("Framework callback contract regression: PASS")

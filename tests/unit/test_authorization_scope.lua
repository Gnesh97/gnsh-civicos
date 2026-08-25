-- Regression coverage for the central assigned-scope authorization contract.
-- Run from the resource root with: lua tests/unit/test_authorization_scope.lua

local function errorResult(code, message, details)
    return { ok = false, error = { code = code, message = message, details = details or {} } }
end

local identity = {
    source = 10,
    persistentIdentifier = "license:technician",
    departmentId = 4,
    departmentName = "dot",
    role = nil,
    job = { name = "technician", grade = 1, gradeName = "technician" },
}

_G.CivicOS = {
    Result = { err = errorResult },
    Permissions = {
        GlobalAdminIdentifiers = {},
        JobRoleMapping = {},
        Roles = {
            TECHNICIAN = {
                scope = "assigned",
                permissions = { "workorder.self_assign" },
            },
        },
    },
    EmployeeService = {
        get = function(_, source)
            assert(source == identity.source, "authorization should resolve the requesting source")
            return { ok = true, data = identity }
        end,
    },
    DepartmentService = {
        isSupervisor = function()
            return { ok = true, data = false }
        end,
    },
}

local authorization = dofile("server/security/authorization.lua")
local allowed = authorization:can(10, "workorder.self_assign", {
    assignedIdentifier = identity.persistentIdentifier,
})
assert(allowed.ok, "assigned scope should accept the caller's own persistent identifier")

local denied = authorization:can(10, "workorder.self_assign", {
    assignedIdentifier = "license:another-technician",
})
assert(not denied.ok and denied.error.code == "AUTH_FORBIDDEN", "assigned scope must reject another employee")

print("authorization assigned scope regression: PASS")

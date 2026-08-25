-- Regression coverage for technician self-assignment authorization scope.
-- Run from the resource root with: lua tests/unit/test_dispatch_scope.lua

local function errorResult(code, message)
    return { ok = false, error = { code = code, message = message } }
end

local identity = {
    persistentIdentifier = "license:technician",
    departmentId = 4,
    departmentName = "dot",
    role = "TECHNICIAN",
}

local capturedResource

_G.CivicOS = {
    Result = { err = errorResult },
    Authorization = {
        identity = function(_, source)
            assert(source == 10, "self assignment should resolve the caller identity")
            return { ok = true, data = identity }
        end,
        can = function(_, source, permission, resource)
            assert(source == 10, "self assignment should authorize the caller")
            assert(permission == "workorder.self_assign", "self assignment permission is incorrect")
            capturedResource = resource
            return { ok = true, data = { identity = identity, role = identity.role, scope = "assigned" } }
        end,
    },
    EmployeeRepository = {
        findByIdentifier = function(_, identifier)
            assert(identifier == identity.persistentIdentifier, "employee lookup must use persistent identity")
            return {
                ok = true,
                data = {
                    {
                        id = 22,
                        persistent_identifier = identity.persistentIdentifier,
                        department_id = 4,
                        duty_status = "on_duty",
                        availability_status = "available",
                    },
                },
            }
        end,
    },
    WorkOrderRepository = {
        findById = function(_, id)
            assert(id == 7, "self assignment should look up the requested work order")
            return { ok = true, data = { { id = id, department_id = 4, template_key = "traffic_signal_repair" } } }
        end,
        assignAtomic = function(_, id, version, employeeId, crewId, assignedBy, reason)
            assert(id == 7 and version == 1, "assignment should preserve optimistic concurrency values")
            assert(employeeId == 22 and crewId == nil, "self assignment should target the caller employee")
            assert(assignedBy == identity.persistentIdentifier and reason == "self_assign", "assignment audit context is incorrect")
            return { ok = true, data = { id = id, version = 2, status = "assigned" } }
        end,
    },
    WorkOrderTemplateService = {
        get = function(_, key)
            assert(key == "traffic_signal_repair", "template lookup should use the persisted key")
            return { ok = true, data = { requiredCertifications = {} } }
        end,
    },
}

local dispatch = dofile("server/services/dispatch_service.lua")
local result = dispatch:selfAssign(10, 7, 1)
assert(result.ok, "a valid technician self-assignment should succeed")
assert(capturedResource.assignedIdentifier == identity.persistentIdentifier, "self assignment must bind to the caller identity")
assert(capturedResource.departmentId == identity.departmentId, "self assignment must retain department scope")

print("dispatch authorization scope regression: PASS")

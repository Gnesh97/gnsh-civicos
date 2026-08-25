-- Regression coverage for work-order transition authorization.
-- Read permission must never substitute for workorder.update.assigned.

local function errorResult(code, message, details)
    return { ok = false, error = { code = code, message = message, details = details or {} } }
end

local permissions = {}

_G.CivicOS = {
    Result = { err = errorResult },
    Enums = {
        WorkOrderStatus = {
            ACKNOWLEDGED = "acknowledged",
            COMPLETED = "completed",
            EN_ROUTE = "en_route",
            ON_SCENE = "on_scene",
            CLOSED = "closed",
        },
    },
    WorkOrderRepository = {
        findById = function()
            return {
                ok = true,
                data = {
                    {
                        id = 7,
                        version = 1,
                        status = "assigned",
                        department_id = 4,
                        request_id = nil,
                        template_key = "traffic_signal_repair",
                        assigned_employee_id = 22,
                        assigned_crew_id = nil,
                    },
                },
            }
        end,
        updateStatus = function()
            return { ok = true, data = { id = 7, version = 2, status = "acknowledged" } }
        end,
    },
    EmployeeRepository = {
        findById = function()
            return { ok = true, data = { { persistent_identifier = "license:technician" } } }
        end,
    },
    Authorization = {
        can = function(_, _, permission)
            permissions[#permissions + 1] = permission
            if permission == "workorder.update.assigned" then
                return errorResult("AUTH_FORBIDDEN", "Transition is not allowed.")
            end
            if permission == "workorder.read.department" then
                return { ok = true, data = { identity = { persistentIdentifier = "license:reader" } } }
            end
            return errorResult("AUTH_FORBIDDEN", "Unexpected permission.")
        end,
    },
    WorkOrderDependencyService = {
        hasUnresolved = function()
            return { ok = true, data = false }
        end,
    },
    WorkOrderTemplateService = {
        get = function()
            return { ok = true, data = { inspectionRequired = false } }
        end,
    },
    WorkOrderStateMachine = {
        transition = function()
            return { ok = true, data = true }
        end,
    },
    RequestRepository = {
        findById = function()
            return { ok = true, data = {} }
        end,
    },
    AuditRepository = {
        append = function()
            return { ok = true, data = {} }
        end,
    },
}

local workorders = dofile("server/services/workorder_service.lua")
local result = workorders:transition(10, 7, 1, "acknowledged")
assert(not result.ok and result.error.code == "AUTH_FORBIDDEN", "read permission must not grant transition mutation")
assert(
    #permissions == 2
        and permissions[1] == "workorder.update.assigned"
        and permissions[2] == "workorder.update.assigned",
    "transition must not fall back to a read permission"
)

print("work-order transition scope regression: PASS")

-- Regression coverage for list read-model scope enforcement.
-- Client filters may narrow a query, but must never widen its department or
-- assignment scope.

local function errorResult(code, message, details)
    return { ok = false, error = { code = code, message = message, details = details or {} } }
end

local identities = {}
local capturedRequestFilters
local capturedWorkOrderFilters

_G.CivicOS = {
    Result = { err = errorResult },
    Permissions = {
        Roles = {
            CITIZEN = { scope = "own" },
            TECHNICIAN = { scope = "assigned" },
            DISPATCHER = { scope = "department" },
            SYSTEM_ADMIN = { scope = "global" },
        },
    },
    Authorization = {
        identity = function(_, source)
            return { ok = true, data = identities[source] }
        end,
        hasRolePermission = function(_, role, permission)
            if permission == "request.read.own" then return role == "CITIZEN" or role == "TECHNICIAN" or role == "SYSTEM_ADMIN" end
            if permission == "request.read.department" then return role == "DISPATCHER" or role == "SYSTEM_ADMIN" end
            if permission == "workorder.read.assigned" then return role == "TECHNICIAN" or role == "SYSTEM_ADMIN" end
            if permission == "workorder.read.department" then return role == "DISPATCHER" or role == "SYSTEM_ADMIN" end
            return false
        end,
    },
    RequestRepository = {
        list = function(_, filters)
            capturedRequestFilters = filters
            return { ok = true, data = {} }
        end,
    },
    RequestDomain = {
        public = function(_, entity) return entity end,
    },
    WorkOrderRepository = {
        list = function(_, filters)
            capturedWorkOrderFilters = filters
            return { ok = true, data = {} }
        end,
    },
    WorkOrderDomain = {
        public = function(_, entity) return entity end,
    },
    EmployeeRepository = {
        findByIdentifier = function(_, identifier)
            if identifier == "license:technician" then
                return { ok = true, data = { { id = 42, department_id = 4 } } }
            end
            return { ok = true, data = {} }
        end,
    },
    CrewRepository = {
        list = function() return { ok = true, data = {} } end,
    },
}

local requests = dofile("server/services/request_service.lua")
local workorders = dofile("server/services/workorder_service.lua")

local function setIdentity(role)
    identities[1] = {
        role = role,
        persistentIdentifier = role == "TECHNICIAN" and "license:technician" or "license:citizen",
        departmentId = 4,
        departmentName = "dot",
    }
end

setIdentity("CITIZEN")
local citizenFilters = { departmentId = 99, status = "submitted" }
assert(requests:list(1, citizenFilters).ok, "citizen request list should succeed")
assert(capturedRequestFilters.requesterIdentifier == "license:citizen", "citizen list must be owner scoped")
assert(capturedRequestFilters.departmentId == nil, "citizen list must ignore department filters")
assert(citizenFilters.departmentId == 99, "request list must not mutate caller filters")

setIdentity("TECHNICIAN")
local technicianRequestFilters = { departmentId = 99 }
assert(requests:list(1, technicianRequestFilters).ok, "technician request list should remain owner scoped")
assert(capturedRequestFilters.requesterIdentifier == "license:technician", "technician request list must be owner scoped")
assert(capturedRequestFilters.departmentId == nil, "technician request list must ignore department filters")

setIdentity("DISPATCHER")
assert(requests:list(1, { departmentId = 99 }).ok, "dispatcher request list should succeed")
assert(capturedRequestFilters.departmentId == 4, "department staff request list must be pinned to own department")

setIdentity("SYSTEM_ADMIN")
assert(requests:list(1, { departmentId = 99 }).ok, "system admin request list should succeed")
assert(capturedRequestFilters.departmentId == 99, "global request list may select a department")

setIdentity("TECHNICIAN")
local technicianWorkOrderFilters = { departmentId = 99, employeeId = 999, crewId = 999, crewIds = { 999 } }
assert(workorders:list(1, technicianWorkOrderFilters).ok, "technician work-order list should succeed")
assert(capturedWorkOrderFilters.employeeId == 42, "technician work-order list must use own employee")
assert(capturedWorkOrderFilters.departmentId == 4, "technician work-order list must use own department")
assert(capturedWorkOrderFilters.crewId == nil and capturedWorkOrderFilters.crewIds ~= nil, "technician crew scope must replace caller crew filters")
assert(technicianWorkOrderFilters.employeeId == 999, "work-order list must not mutate caller filters")

setIdentity("DISPATCHER")
assert(workorders:list(1, { departmentId = 99 }).ok, "dispatcher work-order list should succeed")
assert(capturedWorkOrderFilters.departmentId == 4, "department staff work-order list must be pinned to own department")

setIdentity("SYSTEM_ADMIN")
assert(workorders:list(1, { departmentId = 99 }).ok, "system admin work-order list should succeed")
assert(capturedWorkOrderFilters.departmentId == 99, "global work-order list may select a department")

setIdentity("CITIZEN")
local denied = workorders:list(1, {})
assert(not denied.ok and denied.error.code == "AUTH_FORBIDDEN", "citizens must not list work orders")

print("read scope regression: PASS")

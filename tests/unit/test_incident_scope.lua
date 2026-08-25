-- Regression coverage for the incident read model's citizen/staff boundary.
-- Citizens may inspect their request progress, but assignment and dependency
-- identifiers remain staff-only operational data.

local identities = {
    [1] = { own = true, staff = false },
    [2] = { own = false, staff = true },
}
local dependencyReads = 0

_G.CivicOS = {
    Result = {
        err = function(code, message, details)
            return { ok = false, error = { code = code, message = message, details = details or {} } }
        end,
    },
    RequestRepository = {
        findById = function(_, id)
            return { ok = true, data = { { id = id, requester_identifier = "license:citizen", department_id = 4, status = "in_progress" } } }
        end,
    },
    Authorization = {
        can = function(_, source, permission)
            local identity = identities[source]
            if permission == "request.read.own" and identity.own then return { ok = true } end
            if permission == "request.read.department" and identity.staff then return { ok = true } end
            return { ok = false, error = { code = "AUTH_FORBIDDEN" } }
        end,
    },
    WorkOrderRepository = {
        listByRequest = function()
            return {
                ok = true,
                data = {
                    {
                        id = 11,
                        reference = "WO-11",
                        department_id = 4,
                        template_key = "road.sign",
                        priority = "normal",
                        status = "assigned",
                        assigned_employee_id = 42,
                        assigned_crew_id = 7,
                        version = 3,
                    },
                },
            }
        end,
    },
    WorkOrderDependencyRepository = {
        list = function()
            dependencyReads = dependencyReads + 1
            return { ok = true, data = { { id = 1, workorder_id = 11, depends_on_workorder_id = 12, dependency_type = "blocks" } } }
        end,
    },
    WorkOrderDependencyService = {
        hasUnresolved = function() return { ok = true, data = true } end,
    },
    RequestDomain = {
        public = function(entity) return { id = entity.id, status = entity.status } end,
    },
}

local incidents = dofile("server/services/incident_service.lua")

local citizen = incidents:get(1, 9)
assert(citizen.ok, "citizen incident read should succeed")
local citizenWorkorder = citizen.data.workorders[1]
assert(citizenWorkorder.status == "assigned", "citizen should see work-order status")
assert(citizenWorkorder.assignedEmployeeId == nil and citizenWorkorder.assignedCrewId == nil, "citizen must not see assignment identifiers")
assert(citizenWorkorder.dependencies == nil and citizenWorkorder.dependenciesUnresolved == nil, "citizen must not see dependency internals")
assert(citizen.data.canResolve == false, "citizen must not receive staff resolve capability")
assert(dependencyReads == 0, "citizen incident reads must not query dependency internals")

local staff = incidents:get(2, 9)
assert(staff.ok, "staff incident read should succeed")
local staffWorkorder = staff.data.workorders[1]
assert(staffWorkorder.assignedEmployeeId == 42 and staffWorkorder.assignedCrewId == 7, "staff should see assignment identifiers")
assert(#staffWorkorder.dependencies == 1 and staffWorkorder.dependenciesUnresolved == true, "staff should see dependency state")
assert(dependencyReads == 1, "staff incident reads should query dependency state")

print("incident scope regression: PASS")

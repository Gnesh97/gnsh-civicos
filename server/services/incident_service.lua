local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS

local IncidentService = {}

local function errorResult(code, message, details)
    return CivicOS.Result.err(code, message, details)
end

function IncidentService:get(source, requestId)
    local request = CivicOS.RequestRepository:findById(requestId)
    if not request.ok then return request end
    local entity = request.data[1]
    if not entity then return errorResult("CORE_NOT_FOUND", "Request not found.") end
    local own = CivicOS.Authorization:can(source, "request.read.own", { ownerIdentifier = entity.requester_identifier })
    local staff = CivicOS.Authorization:can(source, "request.read.department", { departmentId = entity.department_id })
    if not own.ok and not staff.ok then return own end
    local children = CivicOS.WorkOrderRepository:listByRequest(requestId)
    if not children.ok then return children end
    local publicChildren = {}
    local openCount = 0
    for _, child in ipairs(children.data) do
        local dependencies = CivicOS.WorkOrderDependencyRepository:list(child.id)
        if not dependencies.ok then return dependencies end
        local unresolved = CivicOS.WorkOrderDependencyService:hasUnresolved(child.id)
        local dependencyItems = {}
        for _, dependency in ipairs(dependencies.data) do
            dependencyItems[#dependencyItems + 1] = {
                id = dependency.id,
                workorderId = dependency.workorder_id,
                dependsOnWorkorderId = dependency.depends_on_workorder_id,
                type = dependency.dependency_type,
            }
        end
        if child.status ~= "completed" and child.status ~= "closed" and child.status ~= "cancelled" and child.status ~= "failed" then openCount = openCount + 1 end
        publicChildren[#publicChildren + 1] = {
            id = child.id,
            reference = child.reference,
            departmentId = child.department_id,
            templateKey = child.template_key,
            priority = child.priority,
            status = child.status,
            assignedEmployeeId = child.assigned_employee_id,
            assignedCrewId = child.assigned_crew_id,
            version = child.version,
            dependencies = dependencyItems,
            dependenciesUnresolved = unresolved.ok and unresolved.data or false,
        }
    end
    return { ok = true, data = {
        request = CivicOS.RequestDomain.public(entity),
        workorders = publicChildren,
        openWorkorders = openCount,
        canResolve = openCount == 0 and #publicChildren > 0,
    } }
end

CivicOS.IncidentService = IncidentService
return IncidentService

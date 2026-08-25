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
    local staffView = staff.ok
    for _, child in ipairs(children.data) do
        local dependencyItems = {}
        local unresolved = { ok = true, data = false }
        if staffView then
            local dependencies = CivicOS.WorkOrderDependencyRepository:list(child.id)
            if not dependencies.ok then return dependencies end
            unresolved = CivicOS.WorkOrderDependencyService:hasUnresolved(child.id)
            for _, dependency in ipairs(dependencies.data) do
                dependencyItems[#dependencyItems + 1] = {
                    id = dependency.id,
                    workorderId = dependency.workorder_id,
                    dependsOnWorkorderId = dependency.depends_on_workorder_id,
                    type = dependency.dependency_type,
                }
            end
        end
        if child.status ~= "completed" and child.status ~= "closed" and child.status ~= "cancelled" and child.status ~= "failed" then openCount = openCount + 1 end
        local childView = {
            id = child.id,
            reference = child.reference,
            priority = child.priority,
            status = child.status,
            version = child.version,
        }
        if staffView then
            childView.departmentId = child.department_id
            childView.templateKey = child.template_key
            childView.assignedEmployeeId = child.assigned_employee_id
            childView.assignedCrewId = child.assigned_crew_id
            childView.dependencies = dependencyItems
            childView.dependenciesUnresolved = unresolved.ok and unresolved.data or false
        end
        publicChildren[#publicChildren + 1] = childView
    end
    return { ok = true, data = {
        request = CivicOS.RequestDomain.public(entity),
        workorders = publicChildren,
        openWorkorders = openCount,
        canResolve = staffView and openCount == 0 and #publicChildren > 0 or false,
    } }
end

CivicOS.IncidentService = IncidentService
return IncidentService

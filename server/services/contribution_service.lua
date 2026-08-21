local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS

local ContributionService = {}

local function errorResult(code, message, details)
    return CivicOS.Result.err(code, message, details)
end

local function actorEmployee(source, entity)
    local identity = CivicOS.Authorization:identity(source)
    if not identity.ok then return identity end
    local employee = CivicOS.EmployeeRepository:findByIdentifier(identity.data.persistentIdentifier)
    if not employee.ok then return employee end
    local selected = employee.data[1]
    if not selected then return errorResult("EMPLOYEE_NOT_FOUND", "Employee not found.") end
    if entity.assigned_employee_id and tonumber(entity.assigned_employee_id) ~= tonumber(selected.id) then
        return errorResult("FIELD_ACTOR_NOT_ASSIGNED", "Only the assigned employee may record contribution.")
    end
    if entity.assigned_crew_id then
        local membership = CivicOS.CrewRepository:findMembership(entity.assigned_crew_id, selected.id)
        if not membership.ok then return membership end
        if not membership.data[1] or membership.data[1].status ~= "active" then return errorResult("FIELD_ACTOR_NOT_ASSIGNED", "Employee is not an active crew member.") end
    end
    return { ok = true, data = selected }
end

function ContributionService:recordAction(source, workorderId, actionKey)
    local result = CivicOS.WorkOrderRepository:findById(workorderId)
    if not result.ok then return result end
    local entity = result.data[1]
    if not entity then return errorResult("CORE_NOT_FOUND", "Work order not found.") end
    local employee = actorEmployee(source, entity)
    if not employee.ok then return employee end
    local state = entity.metadata and entity.metadata.fieldActions and entity.metadata.fieldActions[actionKey]
    local started = state and tonumber(state.startedAt) or os.time()
    local completed = state and tonumber(state.completedAt) or os.time()
    local duration = math.min(3600, math.max(0, completed - started))
    return CivicOS.ContributionRepository:create({
        workorderId = workorderId,
        employeeId = employee.data.id,
        contributionType = "field_action",
        actionKey = actionKey,
        durationSeconds = duration,
        metadata = { observed = true },
    })
end

function ContributionService:recordChecklist(source, workorderId, key)
    local result = CivicOS.WorkOrderRepository:findById(workorderId)
    if not result.ok then return result end
    local entity = result.data[1]
    if not entity then return errorResult("CORE_NOT_FOUND", "Work order not found.") end
    local employee = actorEmployee(source, entity)
    if not employee.ok then return employee end
    return CivicOS.ContributionRepository:create({
        workorderId = workorderId,
        employeeId = employee.data.id,
        contributionType = "checklist",
        actionKey = key,
        durationSeconds = 0,
        metadata = { observed = true },
    })
end

function ContributionService:list(source, workorderId)
    local entity = CivicOS.WorkOrderRepository:findById(workorderId)
    if not entity.ok then return entity end
    local row = entity.data[1]
    if not row then return errorResult("CORE_NOT_FOUND", "Work order not found.") end
    local auth = CivicOS.Authorization:can(source, "workorder.read.assigned", { departmentId = row.department_id })
    if not auth.ok then auth = CivicOS.Authorization:can(source, "workorder.read.department", { departmentId = row.department_id }) end
    if not auth.ok then return auth end
    return CivicOS.ContributionRepository:listByWorkorder(workorderId)
end

CivicOS.ContributionService = ContributionService
return ContributionService

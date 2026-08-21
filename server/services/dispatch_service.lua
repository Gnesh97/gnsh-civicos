local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS

local DispatchService = {}

local function errorResult(code, message, details)
    return CivicOS.Result.err(code, message, details)
end

local function validateCandidate(workorder, employee)
    if not employee or not employee.id then return errorResult("EMPLOYEE_NOT_FOUND", "Employee not found.") end
    if workorder.department_id and workorder.department_id ~= employee.department_id then
        return errorResult("DISPATCH_DEPARTMENT_MISMATCH", "Employee belongs to another department.")
    end
    if employee.duty_status ~= "on_duty" then return errorResult("DISPATCH_NOT_ON_DUTY", "Employee is not on duty.") end
    if employee.availability_status ~= "available" then
        return errorResult("DISPATCH_EMPLOYEE_UNAVAILABLE", "Employee is unavailable.")
    end
    local template = CivicOS.WorkOrderTemplateService:get(workorder.template_key)
    if template.ok then
        for _, certification in ipairs(template.data.requiredCertifications or {}) do
            local has = CivicOS.EmployeeService:hasCertification(employee.id, certification)
            if not has.ok then return has end
            if not has.data then return errorResult("DISPATCH_CERTIFICATION_REQUIRED", "Employee lacks required certification.", { certification = certification }) end
        end
    end
    return { ok = true, data = true }
end

function DispatchService:assign(source, workorderId, expectedVersion, employeeId, reason)
    local workorder = CivicOS.WorkOrderRepository:findById(workorderId)
    if not workorder.ok then return workorder end
    local entity = workorder.data[1]
    if not entity then return errorResult("CORE_NOT_FOUND", "Work order not found.") end
    local auth = CivicOS.Authorization:can(source, "workorder.assign", { departmentId = entity.department_id })
    if not auth.ok then return auth end
    local employeeResult = CivicOS.EmployeeRepository:findById(employeeId)
    if not employeeResult.ok then return employeeResult end
    local candidate = employeeResult.data[1]
    local valid = validateCandidate(entity, candidate)
    if not valid.ok then return valid end
    local assigned = CivicOS.WorkOrderRepository:assignAtomic(
        workorderId,
        expectedVersion,
        employeeId,
        nil,
        auth.data.identity.persistentIdentifier,
        reason
    )
    if not assigned.ok then return assigned end
    if CivicOS.Notify and candidate.source then CivicOS.Notify.notify(candidate.source, "A work order was assigned.", "info") end
    return assigned
end

function DispatchService:selfAssign(source, workorderId, expectedVersion)
    local auth = CivicOS.Authorization:can(source, "workorder.self_assign", {})
    if not auth.ok then return auth end
    local employee = CivicOS.EmployeeRepository:findByIdentifier(auth.data.identity.persistentIdentifier)
    if not employee.ok then return employee end
    local candidate = employee.data[1]
    local workorder = CivicOS.WorkOrderRepository:findById(workorderId)
    if not workorder.ok then return workorder end
    local entity = workorder.data[1]
    if not entity then return errorResult("CORE_NOT_FOUND", "Work order not found.") end
    local valid = validateCandidate(entity, candidate)
    if not valid.ok then return valid end
    local assigned = CivicOS.WorkOrderRepository:assignAtomic(
        workorderId,
        expectedVersion,
        candidate.id,
        nil,
        auth.data.identity.persistentIdentifier,
        "self_assign"
    )
    if not assigned.ok then return assigned end
    return assigned
end

CivicOS.DispatchService = DispatchService
return DispatchService

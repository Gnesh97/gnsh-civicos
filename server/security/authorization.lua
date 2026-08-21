local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS

local Authorization = {}

local function errorResult(code, message, details)
    return CivicOS.Result.err(code, message, details)
end

local function contains(values, expected)
    for _, value in ipairs(values or {}) do
        if value == expected then return true end
    end
    return false
end

local function logDenied(source, permission, reason)
    if CivicOS.Logger then
        CivicOS.Logger.warn("SECURITY", "Permission denied.", { source = source, permission = permission, reason = reason })
    end
end

function Authorization:roleFor(identity)
    local mapping = CivicOS.Permissions and CivicOS.Permissions.JobRoleMapping or {}
    local job = identity and identity.job or {}
    local role = mapping[job.gradeName] or mapping[job.name]
    if role then return role end
    if not identity or not identity.departmentName then
        return "CITIZEN"
    end
    local supervisor = CivicOS.DepartmentService:isSupervisor(identity.departmentName, job.grade)
    if supervisor.ok and supervisor.data then
        return "SUPERVISOR"
    end
    return "TECHNICIAN"
end

function Authorization:identity(source)
    if not CivicOS.EmployeeService then
        return errorResult("AUTH_SERVICE_UNAVAILABLE", "Employee service is not registered.")
    end
    local employee = CivicOS.EmployeeService:get(source)
    if not employee.ok then return employee end
    employee.data.role = self:roleFor(employee.data)
    return employee
end

function Authorization:hasRolePermission(role, permission)
    local roleDefinition = CivicOS.Permissions and CivicOS.Permissions.Roles and CivicOS.Permissions.Roles[role]
    return roleDefinition and contains(roleDefinition.permissions, permission) or false
end

function Authorization:can(source, permission, resource)
    local identityResult = self:identity(source)
    if not identityResult.ok then
        logDenied(source, permission, identityResult.error.code)
        return identityResult
    end
    local identity = identityResult.data
    local role = identity.role
    if not self:hasRolePermission(role, permission) then
        logDenied(source, permission, "role")
        return errorResult("AUTH_FORBIDDEN", "You do not have permission for this action.", { permission = permission })
    end

    resource = type(resource) == "table" and resource or {}
    local roleDefinition = CivicOS.Permissions.Roles[role]
    local scope = roleDefinition.scope
    if scope == "global" then
        return { ok = true, data = { identity = identity, role = role, scope = scope } }
    end
    if scope == "own" and resource.ownerIdentifier and resource.ownerIdentifier ~= identity.persistentIdentifier then
        logDenied(source, permission, "owner_scope")
        return errorResult("AUTH_FORBIDDEN", "Resource is outside own scope.")
    end
    if scope == "assigned" and resource.assignedIdentifier and resource.assignedIdentifier ~= identity.persistentIdentifier then
        logDenied(source, permission, "assignment_scope")
        return errorResult("AUTH_FORBIDDEN", "Resource is outside assignment scope.")
    end
    if scope == "department" then
        local sameDepartment = true
        if resource.departmentName ~= nil then
            sameDepartment = sameDepartment and resource.departmentName == identity.departmentName
        end
        if resource.departmentId ~= nil then
            sameDepartment = sameDepartment and resource.departmentId == identity.departmentId
        end
        if not sameDepartment then
            logDenied(source, permission, "department_scope")
            return errorResult("AUTH_FORBIDDEN", "Resource is outside department scope.")
        end
    end
    return { ok = true, data = { identity = identity, role = role, scope = scope } }
end

function Authorization:assert(source, permission, resource)
    return self:can(source, permission, resource)
end

CivicOS.Authorization = Authorization
return Authorization

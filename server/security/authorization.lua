local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS

local Authorization = {}
local adminAcePermissions = { "god", "admin" }
local adminIdentifierTypes = { "license", "fivem" }

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

local function hasAdminAce(source)
    if not source then return false end
    local normalizedSource = tonumber(source) or source

    for _, permission in ipairs(adminAcePermissions) do
        if type(IsPlayerAceAllowed) == "function" then
            local ok, allowed = pcall(IsPlayerAceAllowed, normalizedSource, permission)
            if ok and allowed == true then return true end
        end

        if type(GetPlayerIdentifiers) == "function" and type(IsPrincipalAceAllowed) == "function" then
            local ok, identifiers = pcall(GetPlayerIdentifiers, normalizedSource)
            if ok and type(identifiers) == "table" then
                for _, identifier in ipairs(identifiers) do
                    if type(identifier) == "string" and identifier ~= "" then
                        local principal = identifier:find("identifier.", 1, true) == 1
                            and identifier or ("identifier." .. identifier)
                        local checked, allowed = pcall(IsPrincipalAceAllowed, principal, permission)
                        if checked and allowed == true then return true end
                    end
                end
            end
        end
    end
    return false
end

local function hasConfiguredGlobalAdminIdentifier(source)
    local configured = {}
    local staticConfigured = CivicOS.Permissions and CivicOS.Permissions.GlobalAdminIdentifiers

    local function addConfigured(identifier, enabled)
        if type(identifier) == "number" and type(enabled) == "string" then
            identifier, enabled = enabled, true
        end
        if enabled ~= true or type(identifier) ~= "string" or identifier == "" then return end
        configured[identifier] = true
        configured[identifier:gsub("^identifier%.", "")] = true
    end

    if type(staticConfigured) == "table" then
        for identifier, enabled in pairs(staticConfigured) do
            addConfigured(identifier, enabled)
        end
    end
    if type(GetConvar) == "function" then
        local ok, value = pcall(GetConvar, "civicos_global_admin_identifiers", "")
        if ok and type(value) == "string" then
            for identifier in value:gmatch("[^,%s]+") do addConfigured(identifier, true) end
        end
    end
    if not source or next(configured) == nil then return false end
    local normalizedSource = tonumber(source) or source

    local function matches(identifier)
        if type(identifier) ~= "string" or identifier == "" then return false end
        local normalized = identifier:gsub("^identifier%.", "")
        return configured[normalized] == true or configured[identifier] == true
    end

    if type(GetPlayerIdentifiers) == "function" then
        local ok, identifiers = pcall(GetPlayerIdentifiers, normalizedSource)
        if ok and type(identifiers) == "table" then
            for _, identifier in ipairs(identifiers) do
                if matches(identifier) then return true end
            end
        end
    end

    if type(GetPlayerIdentifierByType) == "function" then
        for _, identifierType in ipairs(adminIdentifierTypes) do
            local ok, identifier = pcall(GetPlayerIdentifierByType, normalizedSource, identifierType)
            if ok and matches(identifier) then return true end
        end
    end
    return false
end

local function liveFrameworkAdmin(identity)
    if not identity or not CivicOS.Framework or type(CivicOS.Framework.isAdmin) ~= "function" then
        return nil
    end
    local ok, isAdmin = pcall(CivicOS.Framework.isAdmin, identity.source)
    return ok and isAdmin == true
end

function Authorization:roleFor(identity)
    if identity then
        if hasConfiguredGlobalAdminIdentifier(identity.source) then return "SYSTEM_ADMIN" end
        local frameworkAdmin = liveFrameworkAdmin(identity)
        if hasAdminAce(identity.source) or frameworkAdmin == true then return "SYSTEM_ADMIN" end
        if identity.isAdmin == true and frameworkAdmin == nil then return "SYSTEM_ADMIN" end
    end
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
    if scope == "own" then
        if not resource.ownerIdentifier or resource.ownerIdentifier ~= identity.persistentIdentifier then
            logDenied(source, permission, "owner_scope")
            return errorResult("AUTH_FORBIDDEN", "Resource is outside own scope.")
        end
    end
    if scope == "assigned" then
        if not resource.assignedIdentifier or resource.assignedIdentifier ~= identity.persistentIdentifier then
            logDenied(source, permission, "assignment_scope")
            return errorResult("AUTH_FORBIDDEN", "Resource is outside assignment scope.")
        end
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

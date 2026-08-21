local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS

local DepartmentService = {}

local function errorResult(code, message, details)
    return CivicOS.Result.err(code, message, details)
end

local function contains(values, expected)
    for _, value in ipairs(values or {}) do
        if value == expected then return true end
    end
    return false
end

function DepartmentService:get(name)
    local definition = CivicOS.Departments and CivicOS.Departments.get(name)
    if not definition then
        return errorResult("DEPARTMENT_NOT_FOUND", "Department not found.", { name = name })
    end
    if definition.active == false then
        return errorResult("DEPARTMENT_DISABLED", "Department is disabled.", { name = name })
    end
    return { ok = true, data = definition }
end

function DepartmentService:getPersisted(name)
    local definition = self:get(name)
    if not definition.ok then return definition end
    if CivicOS.DepartmentRepository then
        local persisted = CivicOS.DepartmentRepository:findByName(name)
        if persisted.ok and persisted.data[1] then
            local merged = {}
            for key, value in pairs(definition.data) do merged[key] = value end
            merged.id = persisted.data[1].id
            return { ok = true, data = merged }
        end
    end
    return definition
end

function DepartmentService:list()
    return { ok = true, data = CivicOS.Departments and CivicOS.Departments.list() or {} }
end

function DepartmentService:resolveForJob(job, framework)
    job = type(job) == "table" and job or {}
    framework = framework or (CivicOS.Framework and CivicOS.Framework.name) or "standalone"
    for _, definition in ipairs(CivicOS.Departments and CivicOS.Departments.list() or {}) do
        local frameworkJobs = definition.jobs and (definition.jobs[framework] or definition.jobs.standalone) or {}
        if contains(frameworkJobs, job.name) then
            return self:getPersisted(definition.name)
        end
    end
    return { ok = true, data = nil }
end

function DepartmentService:isCategoryAllowed(departmentName, category)
    local department = self:get(departmentName)
    if not department.ok then return department end
    if not contains(department.data.allowedCategories, category) then
        return errorResult("DEPARTMENT_CATEGORY_FORBIDDEN", "Category is not enabled for department.", {
            department = departmentName,
            category = category,
        })
    end
    return { ok = true, data = true }
end

function DepartmentService:isSupervisor(departmentName, grade)
    local department = self:get(departmentName)
    if not department.ok then return department end
    return { ok = true, data = contains(department.data.supervisorGrades, tonumber(grade) or 0) }
end

function DepartmentService:seed()
    if not CivicOS.DepartmentRepository then
        return errorResult("DB_REPOSITORY_UNAVAILABLE", "Department repository is not registered.")
    end
    for _, definition in ipairs(CivicOS.Departments and CivicOS.Departments.list() or {}) do
        local result = CivicOS.DepartmentRepository:upsert(definition)
        if not result.ok then return result end
    end
    return { ok = true, data = true }
end

CivicOS.DepartmentService = DepartmentService
return DepartmentService

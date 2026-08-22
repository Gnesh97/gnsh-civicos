local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS

local EmployeeService = {
    _started = false,
}

local availabilityValues = {
    unavailable = true,
    available = true,
    busy = true,
    on_scene = true,
}

local function errorResult(code, message, details)
    return CivicOS.Result.err(code, message, details)
end

local function parseExpiry(value)
    if not value or value == "" then return nil end
    if type(value) == "number" then return value end
    local year, month, day, hour, minute, second = tostring(value):match("^(%d+)%-(%d+)%-(%d+)[ T](%d+):(%d+):(%d+)")
    if year then return os.time({ year = year, month = month, day = day, hour = hour, min = minute, sec = second }) end
    return nil
end

function EmployeeService:sync(source)
    if not CivicOS.Identity then return errorResult("AUTH_IDENTITY_UNAVAILABLE", "Identity resolver is not registered.") end
    local identityResult = CivicOS.Identity:resolve(source)
    if not identityResult.ok then return identityResult end
    local identity = identityResult.data
    local department = CivicOS.DepartmentService:resolveForJob(identity.job, identity.framework)
    if not department.ok then return department end
    identity.departmentName = department.data and department.data.name or nil
    identity.departmentId = department.data and department.data.id or nil
    identity.jobName = identity.job.name
    identity.jobGrade = identity.job.grade
    identity.jobGradeName = identity.job.gradeName
    identity.dutyStatus = identity.job.onDuty and "on_duty" or "off_duty"
    identity.availabilityStatus = identity.job.onDuty and "available" or "offline"
    local persisted = CivicOS.EmployeeRepository:upsert(identity)
    if not persisted.ok then return persisted end
    return { ok = true, data = identity }
end

function EmployeeService:get(source)
    local synced = self:sync(source)
    if not synced.ok then return synced end
    return synced
end

function EmployeeService:listOnDuty(departmentId)
    return CivicOS.EmployeeRepository:listOnDuty(departmentId)
end

function EmployeeService:setAvailability(employeeId, status)
    if not availabilityValues[status] then
        return errorResult("EMPLOYEE_INVALID_AVAILABILITY", "Availability status is invalid.", { status = status })
    end
    return CivicOS.EmployeeRepository:updateAvailability(employeeId, status)
end

function EmployeeService:addCertification(employeeId, certificationKey, expiresAt, metadata)
    if type(certificationKey) ~= "string" or certificationKey == "" then
        return errorResult("CORE_INVALID_INPUT", "Certification key is required.")
    end
    return CivicOS.EmployeeRepository:addCertification(employeeId, certificationKey, expiresAt, metadata)
end

function EmployeeService:removeCertification(employeeId, certificationKey)
    return CivicOS.EmployeeRepository:removeCertification(employeeId, certificationKey)
end

function EmployeeService:listCertifications(employeeId)
    return CivicOS.EmployeeRepository:listCertifications(employeeId)
end

function EmployeeService:hasCertification(employeeId, certificationKey)
    local certifications = self:listCertifications(employeeId)
    if not certifications.ok then return certifications end
    for _, certification in ipairs(certifications.data) do
        if certification.certification_key == certificationKey then
            local expiry = parseExpiry(certification.expires_at)
            if not expiry or expiry >= os.time() then
                return { ok = true, data = true }
            end
        end
    end
    return { ok = true, data = false }
end

function EmployeeService:start()
    if self._started or not CivicOS.Framework then return end
    self._started = true
    CivicOS.Framework.onPlayerLoaded(function(identity)
        self:sync(identity.source)
    end)
    CivicOS.Framework.onJobChanged(function(identity)
        self:sync(identity.source)
    end)
    CivicOS.Framework.onDutyChanged(function(identity)
        self:sync(identity.source)
    end)
end

CivicOS.EmployeeService = EmployeeService
return EmployeeService

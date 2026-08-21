local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS
local Repository = CivicOS.Repository

local EmployeeRepository = {}

function EmployeeRepository:findByIdentifier(identifier)
    return Repository.rows(Repository.db():query([[SELECT id, persistent_identifier, character_id,
        display_name, framework, department_id, job_name, job_grade, job_grade_name,
        duty_status, availability_status, metadata, created_at, updated_at
        FROM civicos_employees WHERE persistent_identifier = ? LIMIT 1]], { identifier }))
end

function EmployeeRepository:findById(id)
    return Repository.rows(Repository.db():query([[SELECT id, persistent_identifier, character_id,
        display_name, framework, department_id, job_name, job_grade, job_grade_name,
        duty_status, availability_status, metadata, created_at, updated_at
        FROM civicos_employees WHERE id = ? LIMIT 1]], { id }))
end

function EmployeeRepository:listOnDuty(departmentId)
    local sql = [[SELECT id, persistent_identifier, character_id, display_name, framework,
        department_id, job_name, job_grade, job_grade_name, duty_status,
        availability_status, metadata, created_at, updated_at
        FROM civicos_employees WHERE duty_status = 'on_duty']]
    local params = {}
    if departmentId then
        sql = sql .. " AND department_id = ?"
        params[#params + 1] = departmentId
    end
    return Repository.rows(Repository.db():query(sql .. " ORDER BY display_name ASC", params))
end

function EmployeeRepository:upsert(identity)
    return Repository.db():query([[INSERT INTO civicos_employees
        (persistent_identifier, character_id, display_name, framework, department_id,
         job_name, job_grade, job_grade_name, duty_status, availability_status, metadata)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE character_id = VALUES(character_id),
        display_name = VALUES(display_name), framework = VALUES(framework),
        department_id = VALUES(department_id), job_name = VALUES(job_name),
        job_grade = VALUES(job_grade), job_grade_name = VALUES(job_grade_name),
        duty_status = VALUES(duty_status), availability_status = VALUES(availability_status),
        metadata = VALUES(metadata)]], {
        identity.persistentIdentifier, identity.characterId, identity.displayName,
        identity.framework, identity.departmentId, identity.jobName, identity.jobGrade or 0,
        identity.jobGradeName, identity.dutyStatus or "off_duty", identity.availabilityStatus or "offline",
        Repository.encode(identity.metadata),
    })
end

function EmployeeRepository:addCertification(employeeId, certificationKey, expiresAt, metadata)
    return Repository.db():query([[INSERT INTO civicos_employee_certifications
        (employee_id, certification_key, expires_at, metadata)
        VALUES (?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE expires_at = VALUES(expires_at), metadata = VALUES(metadata)]], {
        employeeId, certificationKey, expiresAt, Repository.encode(metadata),
    })
end

function EmployeeRepository:removeCertification(employeeId, certificationKey)
    return Repository.db():update(
        "DELETE FROM civicos_employee_certifications WHERE employee_id = ? AND certification_key = ?",
        { employeeId, certificationKey }
    )
end

function EmployeeRepository:listCertifications(employeeId)
    local result = Repository.db():query([[SELECT id, employee_id, certification_key,
        expires_at, metadata, created_at FROM civicos_employee_certifications
        WHERE employee_id = ? ORDER BY certification_key ASC]], { employeeId })
    if not result.ok then return result end
    return Repository.rows(result)
end

function EmployeeRepository:updateAvailability(employeeId, status)
    return Repository.db():update(
        "UPDATE civicos_employees SET availability_status = ? WHERE id = ?",
        { status, employeeId }
    )
end

CivicOS.EmployeeRepository = EmployeeRepository
return EmployeeRepository

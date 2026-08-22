local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS

local CrewService = { _started = false }
local referenceCounter = 0

local function errorResult(code, message, details)
    return CivicOS.Result.err(code, message, details)
end

local function reference()
    referenceCounter = (referenceCounter + 1) % 100000
    return string.format("CR-%s-%05d", os.date("!%Y"), (os.time() + referenceCounter) % 100000)
end

local function sourceEmployee(source)
    local identity = CivicOS.Authorization:identity(source)
    if not identity.ok then return identity end
    local employee = CivicOS.EmployeeRepository:findByIdentifier(identity.data.persistentIdentifier)
    if not employee.ok then return employee end
    if not employee.data[1] then return errorResult("EMPLOYEE_NOT_FOUND", "Employee not found.") end
    return { ok = true, data = { identity = identity.data, employee = employee.data[1] } }
end

local function crew(id)
    local result = CivicOS.CrewRepository:findById(id)
    if not result.ok then return result end
    if not result.data[1] then return errorResult("CREW_NOT_FOUND", "Crew not found.") end
    return { ok = true, data = result.data[1] }
end

function CrewService:create(source, name, departmentId, metadata)
    local actor = sourceEmployee(source)
    if not actor.ok then return actor end
    local auth = CivicOS.Authorization:can(source, "employee.manage", { departmentId = actor.data.employee.department_id })
    if not auth.ok then return auth end
    if type(name) ~= "string" or name == "" or #name > 120 then return errorResult("CREW_INVALID_INPUT", "Crew name is invalid.") end
    local selectedDepartment = tonumber(departmentId) or actor.data.employee.department_id
    if selectedDepartment ~= actor.data.employee.department_id and auth.data.scope ~= "global" then
        return errorResult("CREW_DEPARTMENT_MISMATCH", "Crew must belong to the actor's department.")
    end
    local created = CivicOS.CrewRepository:create({
        reference = reference(),
        name = name,
        departmentId = selectedDepartment,
        leaderEmployeeId = actor.data.employee.id,
        metadata = metadata,
    })
    if not created.ok then return created end
    local member = CivicOS.CrewRepository:addMember(created.data, actor.data.employee.id, "leader")
    if not member.ok then return member end
    return { ok = true, data = { id = created.data, reference = "pending", leaderEmployeeId = actor.data.employee.id } }
end

function CrewService:list(source, departmentId)
    local actor = sourceEmployee(source)
    if not actor.ok then return actor end
    local auth = CivicOS.Authorization:can(source, "employee.read.department", { departmentId = actor.data.employee.department_id })
    if not auth.ok then return auth end
    local selected = tonumber(departmentId) or actor.data.employee.department_id
    if auth.data.scope ~= "global" then selected = actor.data.employee.department_id end
    return CivicOS.CrewRepository:list(selected, "active")
end

function CrewService:members(source, crewId)
    local selected = crew(crewId)
    if not selected.ok then return selected end
    local actor = sourceEmployee(source)
    if not actor.ok then return actor end
    local auth = CivicOS.Authorization:can(source, "employee.read.department", { departmentId = selected.data.department_id })
    if not auth.ok then return auth end
    return CivicOS.CrewRepository:members(crewId)
end

function CrewService:join(source, crewId)
    local selected = crew(crewId)
    if not selected.ok then return selected end
    if selected.data.status ~= "active" then return errorResult("CREW_INACTIVE", "Crew is not active.") end
    local actor = sourceEmployee(source)
    if not actor.ok then return actor end
    if actor.data.employee.department_id ~= selected.data.department_id then return errorResult("CREW_DEPARTMENT_MISMATCH", "Employee belongs to another department.") end
    if actor.data.employee.duty_status ~= "on_duty" then return errorResult("CREW_NOT_ON_DUTY", "Employee must be on duty to join a crew.") end
    return CivicOS.CrewRepository:addMember(crewId, actor.data.employee.id, "member")
end

function CrewService:leave(source, crewId)
    local selected = crew(crewId)
    if not selected.ok then return selected end
    local actor = sourceEmployee(source)
    if not actor.ok then return actor end
    if selected.data.leader_employee_id == actor.data.employee.id then return errorResult("CREW_LEADER_TRANSFER_REQUIRED", "Transfer leadership before leaving the crew.") end
    return CivicOS.CrewRepository:removeMember(crewId, actor.data.employee.id)
end

function CrewService:transfer(source, crewId, employeeId)
    local selected = crew(crewId)
    if not selected.ok then return selected end
    local actor = sourceEmployee(source)
    if not actor.ok then return actor end
    local auth = CivicOS.Authorization:can(source, "employee.manage", { departmentId = selected.data.department_id })
    if not auth.ok and selected.data.leader_employee_id ~= actor.data.employee.id then return auth end
    local member = CivicOS.CrewRepository:findMembership(crewId, employeeId)
    if not member.ok then return member end
    if not member.data[1] or member.data[1].status ~= "active" then return errorResult("CREW_MEMBER_REQUIRED", "New leader must be an active crew member.") end
    local updated = CivicOS.CrewRepository:updateLeader(crewId, employeeId)
    if not updated.ok then return updated end
    CivicOS.CrewRepository:addMember(crewId, employeeId, "leader")
    CivicOS.CrewRepository:addMember(crewId, actor.data.employee.id, "member")
    return { ok = true, data = { crewId = crewId, leaderEmployeeId = employeeId } }
end

function CrewService:disband(source, crewId)
    local selected = crew(crewId)
    if not selected.ok then return selected end
    local actor = sourceEmployee(source)
    if not actor.ok then return actor end
    local auth = CivicOS.Authorization:can(source, "employee.manage", { departmentId = selected.data.department_id })
    if not auth.ok and selected.data.leader_employee_id ~= actor.data.employee.id then return auth end
    local updated = CivicOS.CrewRepository:updateStatus(crewId, "disbanded")
    if not updated.ok then return updated end
    return CivicOS.CrewRepository:removeMember(crewId, actor.data.employee.id)
end

function CrewService:assignWorkorder(source, workorderId, expectedVersion, crewId, reason)
    local workorder = CivicOS.WorkOrderRepository:findById(workorderId)
    if not workorder.ok then return workorder end
    local entity = workorder.data[1]
    if not entity then return errorResult("CORE_NOT_FOUND", "Work order not found.") end
    local auth = CivicOS.Authorization:can(source, "workorder.assign", { departmentId = entity.department_id })
    if not auth.ok then return auth end
    local selected = crew(crewId)
    if not selected.ok then return selected end
    if selected.data.status ~= "active" or selected.data.department_id ~= entity.department_id then
        return errorResult("CREW_ASSIGNMENT_INVALID", "Crew is inactive or belongs to another department.")
    end
    local members = CivicOS.CrewRepository:members(crewId)
    if not members.ok then return members end
    if #members.data == 0 then return errorResult("CREW_EMPTY", "Crew must have an active member.") end
    local assigned = CivicOS.WorkOrderRepository:assignCrewAtomic(workorderId, expectedVersion, crewId, auth.data.identity.persistentIdentifier, reason)
    if not assigned.ok then return assigned end
    if CivicOS.AuditService then CivicOS.AuditService:record(source, { entityType = "workorder", entityId = workorderId, action = "crew_assign", after = { crewId = crewId, reason = reason } }) end
    return assigned
end

function CrewService:start()
    if self._started or not CivicOS.Framework then return end
    self._started = true
    CivicOS.Framework.onPlayerUnloaded(function(identityOrSource)
        local identifier = type(identityOrSource) == "table" and identityOrSource.persistentIdentifier
        if not identifier and tonumber(identityOrSource) and CivicOS.DisconnectService then
            local session = CivicOS.DisconnectService._sessions[tonumber(identityOrSource)]
            identifier = session and session.persistentIdentifier
        end
        if not identifier and tonumber(identityOrSource) and CivicOS.Identity then
            local resolved = CivicOS.Identity:resolve(tonumber(identityOrSource))
            if resolved.ok then identifier = resolved.data.persistentIdentifier end
        end
        if not identifier then return end
        local employee = CivicOS.EmployeeRepository:findByIdentifier(identifier)
        if employee.ok and employee.data[1] then CivicOS.CrewRepository:setMemberStatus(employee.data[1].id, "offline") end
    end)
end

CivicOS.CrewService = CrewService
return CrewService

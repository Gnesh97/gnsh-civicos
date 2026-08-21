local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS
local Repository = CivicOS.Repository

local CrewRepository = {}

local crewColumns = [[id, reference, name, department_id, status, leader_employee_id,
    metadata, created_at, updated_at]]

function CrewRepository:create(crew)
    return Repository.db():insert([[INSERT INTO civicos_crews
        (reference, name, department_id, status, leader_employee_id, metadata)
        VALUES (?, ?, ?, 'active', ?, ?)]], {
        crew.reference, crew.name, crew.departmentId, crew.leaderEmployeeId, Repository.encode(crew.metadata),
    })
end

function CrewRepository:findById(id)
    local result = Repository.db():query("SELECT " .. crewColumns .. " FROM civicos_crews WHERE id = ? LIMIT 1", { id })
    if not result.ok then return result end
    return Repository.rows(result)
end

function CrewRepository:list(departmentId, status)
    local clauses, params = {}, {}
    if departmentId then clauses[#clauses + 1] = "department_id = ?"; params[#params + 1] = departmentId end
    if status then clauses[#clauses + 1] = "status = ?"; params[#params + 1] = status end
    local where = #clauses > 0 and " WHERE " .. table.concat(clauses, " AND ") or ""
    return Repository.rows(Repository.db():query("SELECT " .. crewColumns .. " FROM civicos_crews" .. where .. " ORDER BY name ASC", params))
end

function CrewRepository:updateStatus(id, status)
    return Repository.db():update("UPDATE civicos_crews SET status = ? WHERE id = ?", { status, id })
end

function CrewRepository:updateLeader(id, employeeId)
    return Repository.db():update("UPDATE civicos_crews SET leader_employee_id = ? WHERE id = ? AND status = 'active'", { employeeId, id })
end

function CrewRepository:addMember(crewId, employeeId, role)
    return Repository.db():query([[INSERT INTO civicos_crew_members (crew_id, employee_id, role, status)
        VALUES (?, ?, ?, 'active') ON DUPLICATE KEY UPDATE role = VALUES(role), status = 'active', left_at = NULL]], {
        crewId, employeeId, role or "member",
    })
end

function CrewRepository:removeMember(crewId, employeeId)
    return Repository.db():update([[UPDATE civicos_crew_members SET status = 'left', left_at = CURRENT_TIMESTAMP(3)
        WHERE crew_id = ? AND employee_id = ? AND status = 'active']], { crewId, employeeId })
end

function CrewRepository:members(crewId, activeOnly)
    local sql = [[SELECT id, crew_id, employee_id, role, status, joined_at, left_at
        FROM civicos_crew_members WHERE crew_id = ?]]
    if activeOnly ~= false then sql = sql .. " AND status = 'active'" end
    return Repository.rows(Repository.db():query(sql .. " ORDER BY role DESC, joined_at ASC", { crewId }))
end

function CrewRepository:findMembership(crewId, employeeId)
    return Repository.rows(Repository.db():query([[SELECT id, crew_id, employee_id, role, status, joined_at, left_at
        FROM civicos_crew_members WHERE crew_id = ? AND employee_id = ? LIMIT 1]], { crewId, employeeId }))
end

function CrewRepository:setMemberStatus(employeeId, status)
    return Repository.db():update("UPDATE civicos_crew_members SET status = ? WHERE employee_id = ? AND status = 'active'", { status, employeeId })
end

function CrewRepository:restoreMemberStatus(employeeId)
    return Repository.db():update(
        "UPDATE civicos_crew_members SET status = 'active', left_at = NULL WHERE employee_id = ? AND status = 'offline'",
        { employeeId }
    )
end

CivicOS.CrewRepository = CrewRepository
return CrewRepository

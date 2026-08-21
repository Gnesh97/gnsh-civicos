local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS
local Repository = CivicOS.Repository

local AssignmentRepository = {}

function AssignmentRepository:create(workorderId, employeeId, crewId, status, assignedBy, reason)
    return Repository.db():insert([[INSERT INTO civicos_workorder_assignments
        (workorder_id, employee_id, crew_id, status, assigned_by_identifier, reason)
        VALUES (?, ?, ?, ?, ?, ?)]], { workorderId, employeeId, crewId, status or "active", assignedBy, reason })
end

function AssignmentRepository:release(workorderId, employeeId, reason)
    return Repository.db():update([[UPDATE civicos_workorder_assignments
        SET status = 'released', released_at = CURRENT_TIMESTAMP(3)
        WHERE workorder_id = ? AND employee_id = ? AND status IN ('pending', 'offered', 'accepted', 'active')]], {
        workorderId, employeeId,
    })
end

function AssignmentRepository:list(workorderId)
    return Repository.db():query([[SELECT id, workorder_id, employee_id, crew_id, status,
        assigned_by_identifier, reason, created_at, released_at FROM civicos_workorder_assignments
        WHERE workorder_id = ? ORDER BY created_at ASC]], { workorderId })
end

CivicOS.AssignmentRepository = AssignmentRepository
return AssignmentRepository

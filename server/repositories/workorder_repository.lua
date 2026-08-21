local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS
local Repository = CivicOS.Repository

local WorkOrderRepository = {}

local selectColumns = [[
    id, request_id, reference, department_id, template_key, priority, status,
    assigned_employee_id, assigned_crew_id, location_json, checklist_json,
    metadata, version, created_at, updated_at
]]

function WorkOrderRepository:findById(id)
    return Repository.rows(Repository.db():query("SELECT " .. selectColumns .. " FROM civicos_workorders WHERE id = ? LIMIT 1", { id }))
end

function WorkOrderRepository:list(filters)
    filters = type(filters) == "table" and filters or {}
    local clauses, params = {}, {}
    if filters.status then
        clauses[#clauses + 1] = "status = ?"
        params[#params + 1] = filters.status
    end
    if filters.departmentId then
        clauses[#clauses + 1] = "department_id = ?"
        params[#params + 1] = filters.departmentId
    end
    if filters.employeeId then
        clauses[#clauses + 1] = "assigned_employee_id = ?"
        params[#params + 1] = filters.employeeId
    end
    local where = #clauses > 0 and (" WHERE " .. table.concat(clauses, " AND ")) or ""
    local page = math.max(1, tonumber(filters.page) or 1)
    local pageSize = math.min(tonumber(filters.pageSize) or 50, 100)
    params[#params + 1] = pageSize
    params[#params + 1] = (page - 1) * pageSize
    return Repository.rows(Repository.db():query(
        "SELECT " .. selectColumns .. " FROM civicos_workorders" .. where .. " ORDER BY created_at DESC LIMIT ? OFFSET ?",
        params
    ))
end

function WorkOrderRepository:listByRequest(requestId)
    return Repository.rows(Repository.db():query("SELECT " .. selectColumns .. " FROM civicos_workorders WHERE request_id = ? ORDER BY id ASC", { requestId }))
end

function WorkOrderRepository:create(dto)
    local location = Repository.encode(dto.location)
    local checklist = Repository.encode(dto.checklist)
    local metadata = Repository.encode(dto.metadata)
    return Repository.db():insert([[INSERT INTO civicos_workorders
        (request_id, reference, department_id, template_key, priority, status,
         assigned_employee_id, assigned_crew_id, location_json, checklist_json, metadata, version)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1)]], {
        dto.requestId, dto.reference, dto.departmentId, dto.templateKey, dto.priority or "normal",
        dto.status or "created", dto.assignedEmployeeId, dto.assignedCrewId,
        location, checklist, metadata,
    })
end

function WorkOrderRepository:createManyForRequest(requestId, requestVersion, items)
    local statements = {}
    for _, dto in ipairs(items or {}) do
        statements[#statements + 1] = {
            query = [[INSERT INTO civicos_workorders
                (request_id, reference, department_id, template_key, priority, status,
                 assigned_employee_id, assigned_crew_id, location_json, checklist_json, metadata, version)
                SELECT ?, ?, ?, ?, ?, 'created', NULL, NULL, ?, ?, ?, 1
                FROM civicos_requests WHERE id = ? AND version = ?]],
            values = {
                requestId, dto.reference, dto.departmentId, dto.templateKey, dto.priority,
                Repository.encode(dto.location), Repository.encode(dto.checklist), Repository.encode(dto.metadata),
                requestId, requestVersion,
            },
        }
    end
    statements[#statements + 1] = {
        query = "UPDATE civicos_requests SET status = 'converted', version = version + 1 WHERE id = ? AND version = ?",
        values = { requestId, requestVersion },
    }
    return Repository.db():transaction(statements)
end

function WorkOrderRepository:updateStatus(id, expectedVersion, status)
    local result = Repository.db():update(
        "UPDATE civicos_workorders SET status = ?, version = version + 1 WHERE id = ? AND version = ?",
        { status, id, expectedVersion }
    )
    if not result.ok then
        return result
    end
    if (result.data.affectedRows or 0) == 0 then
        return Repository.error("CORE_VERSION_CONFLICT", "Work order version conflict.", { id = id })
    end
    return { ok = true, data = { id = id, version = expectedVersion + 1, status = status } }
end

function WorkOrderRepository:assign(id, expectedVersion, employeeId, crewId)
    local result = Repository.db():update(
        "UPDATE civicos_workorders SET assigned_employee_id = ?, assigned_crew_id = ?, status = 'assigned', version = version + 1 WHERE id = ? AND version = ?",
        { employeeId, crewId, id, expectedVersion }
    )
    if not result.ok then
        return result
    end
    if (result.data.affectedRows or 0) == 0 then
        return Repository.error("CORE_VERSION_CONFLICT", "Work order assignment conflict.", { id = id })
    end
    return { ok = true, data = { id = id, version = expectedVersion + 1, status = "assigned" } }
end

function WorkOrderRepository:assignAtomic(id, expectedVersion, employeeId, crewId, assignedBy, reason)
    local numericVersion = tonumber(expectedVersion)
    if not numericVersion then
        return Repository.error("CORE_INVALID_INPUT", "Work order version is required.")
    end
    local nextVersion = numericVersion + 1
    local statements = {
        {
            query = [[UPDATE civicos_workorders
                SET assigned_employee_id = ?, assigned_crew_id = ?, status = 'assigned', version = version + 1
                WHERE id = ? AND version = ? AND status IN ('unassigned', 'assigned', 'declined', 'reassigned')]],
            values = { employeeId, crewId, id, numericVersion },
        },
        {
            query = [[UPDATE civicos_workorder_assignments
                SET status = 'released', released_at = CURRENT_TIMESTAMP(3)
                WHERE workorder_id = ? AND status = 'active'
                  AND EXISTS (SELECT 1 FROM civicos_workorders
                    WHERE id = ? AND version = ? AND assigned_employee_id <=> ? AND status = 'assigned')]],
            values = { id, id, nextVersion, employeeId },
        },
        {
            query = [[INSERT INTO civicos_workorder_assignments
                (workorder_id, employee_id, crew_id, status, assigned_by_identifier, reason)
                SELECT ?, ?, ?, 'active', ?, ?
                FROM civicos_workorders
                WHERE id = ? AND version = ? AND assigned_employee_id <=> ? AND status = 'assigned']],
            values = { id, employeeId, crewId, assignedBy, reason, id, nextVersion, employeeId },
        },
    }
    local transaction = Repository.db():transaction(statements)
    if not transaction.ok then return transaction end
    local current = self:findById(id)
    if not current.ok then return current end
    local entity = current.data[1]
    if not entity or tonumber(entity.version) ~= nextVersion
        or tonumber(entity.assigned_employee_id) ~= tonumber(employeeId) then
        return Repository.error("CORE_VERSION_CONFLICT", "Work order assignment conflict.", { id = id })
    end
    return { ok = true, data = { id = id, version = nextVersion, status = "assigned" } }
end

CivicOS.WorkOrderRepository = WorkOrderRepository
return WorkOrderRepository

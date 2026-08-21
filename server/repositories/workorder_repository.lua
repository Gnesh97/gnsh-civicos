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

CivicOS.WorkOrderRepository = WorkOrderRepository
return WorkOrderRepository

local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS
local Repository = CivicOS.Repository

local AnalyticsRepository = {}

local function range(startDate, endDate)
    return startDate, endDate
end

function AnalyticsRepository:summary(startDate, endDate, departmentId)
    local startAt, endAt = range(startDate, endDate)
    local params = { startAt, endAt }
    local departmentClause = ""
    if departmentId then departmentClause = " AND department_id = ?"; params[#params + 1] = departmentId end
    local request = Repository.db():single([[SELECT COUNT(*) AS total,
        SUM(status NOT IN ('closed', 'cancelled')) AS open_count,
        SUM(status = 'resolved') AS resolved_count,
        AVG(TIMESTAMPDIFF(SECOND, created_at, updated_at)) AS average_lifecycle_seconds
        FROM civicos_requests WHERE created_at >= ? AND created_at < DATE_ADD(?, INTERVAL 1 DAY)]] .. departmentClause, params)
    if not request.ok then return request end
    local slaParams = { startAt, endAt }
    local slaClause = ""
    if departmentId then
        slaClause = " AND r.department_id = ?"
        slaParams[#slaParams + 1] = departmentId
    end
    local sla = Repository.db():single([[SELECT COUNT(*) AS total,
        SUM(s.status = 'met') AS met_count,
        SUM(s.status = 'breached') AS breached_count
        FROM civicos_sla_events s JOIN civicos_requests r ON r.id = s.entity_id
        WHERE s.entity_type = 'request' AND s.created_at >= ? AND s.created_at < DATE_ADD(?, INTERVAL 1 DAY)]] .. slaClause, slaParams)
    if not sla.ok then return sla end
    return { ok = true, data = { requests = request.data or {}, sla = sla.data or {} } }
end

function AnalyticsRepository:backlog(startDate, endDate, departmentId)
    local params = { startDate, endDate }
    local clauses = { "created_at >= ?", "created_at < DATE_ADD(?, INTERVAL 1 DAY)", "status NOT IN ('closed', 'cancelled')" }
    if departmentId then clauses[#clauses + 1] = "department_id = ?"; params[#params + 1] = departmentId end
    local result = Repository.db():query([[SELECT department_id, category, status, priority, COUNT(*) AS count
        FROM civicos_requests WHERE ]] .. table.concat(clauses, " AND ") .. " GROUP BY department_id, category, status, priority ORDER BY count DESC", params)
    return result
end

function AnalyticsRepository:employeeMetrics(startDate, endDate, departmentId)
    local params = { startDate, endDate }
    local departmentClause = ""
    if departmentId then departmentClause = " AND e.department_id = ?"; params[#params + 1] = departmentId end
    return Repository.db():query([[SELECT c.employee_id, e.display_name, e.department_id,
        COUNT(*) AS contribution_count, SUM(c.duration_seconds) AS duration_seconds
        FROM civicos_contributions c JOIN civicos_employees e ON e.id = c.employee_id
        WHERE c.created_at >= ? AND c.created_at < DATE_ADD(?, INTERVAL 1 DAY)]] .. departmentClause .. [[
        GROUP BY c.employee_id, e.display_name, e.department_id ORDER BY contribution_count DESC]], params)
end

function AnalyticsRepository:heatmap(startDate, endDate, departmentId)
    local params = { startDate, endDate }
    local departmentClause = ""
    if departmentId then departmentClause = " AND department_id = ?"; params[#params + 1] = departmentId end
    return Repository.db():query([[SELECT category, COUNT(*) AS count FROM civicos_requests
        WHERE created_at >= ? AND created_at < DATE_ADD(?, INTERVAL 1 DAY)]] .. departmentClause .. [[
        GROUP BY category ORDER BY count DESC LIMIT 100]], params)
end

CivicOS.AnalyticsRepository = AnalyticsRepository
return AnalyticsRepository

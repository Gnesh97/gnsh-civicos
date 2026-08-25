local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS
local Repository = CivicOS.Repository

local HealthRepository = {}

local function activeCount(sql)
    local db = Repository.db()
    if not db or type(db.scalar) ~= "function" then
        return Repository.error("DB_UNAVAILABLE", "Database adapter is not available for health counters.")
    end
    local result = db:scalar(sql)
    if type(result) ~= "table" then
        return Repository.error("DB_INVALID_RESULT", "Database health counter returned an invalid result.")
    end
    return result
end

function HealthRepository:activeCounts()
    local requests = activeCount("SELECT COUNT(*) FROM civicos_requests WHERE status NOT IN ('closed', 'cancelled')")
    if not requests.ok then return requests end

    local workorders = activeCount("SELECT COUNT(*) FROM civicos_workorders WHERE status NOT IN ('closed', 'cancelled')")
    if not workorders.ok then return workorders end

    local employees = activeCount("SELECT COUNT(*) FROM civicos_employees WHERE duty_status = 'on_duty'")
    if not employees.ok then return employees end

    return {
        ok = true,
        data = {
            requests = tonumber(requests.data) or 0,
            workorders = tonumber(workorders.data) or 0,
            employees = tonumber(employees.data) or 0,
        },
    }
end

CivicOS.HealthRepository = HealthRepository
return HealthRepository

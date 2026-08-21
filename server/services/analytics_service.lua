local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS

local AnalyticsService = {}

local function errorResult(code, message, details)
    return CivicOS.Result.err(code, message, details)
end

local function parseDate(value, field)
    if type(value) ~= "string" or not value:match("^%d%d%d%d%-%d%d%-%d%d$") then
        return nil, errorResult("ANALYTICS_INVALID_RANGE", string.format("%s must be YYYY-MM-DD.", field))
    end
    return value
end

local function daysBetween(startDate, endDate)
    local sy, sm, sd = startDate:match("^(%d+)%-(%d+)%-(%d+)$")
    local ey, em, ed = endDate:match("^(%d+)%-(%d+)%-(%d+)$")
    local startAt = os.time({ year = tonumber(sy), month = tonumber(sm), day = tonumber(sd), hour = 0 })
    local endAt = os.time({ year = tonumber(ey), month = tonumber(em), day = tonumber(ed), hour = 0 })
    return math.floor((endAt - startAt) / 86400)
end

function AnalyticsService:dashboard(source, startDate, endDate)
    local startValue, startError = parseDate(startDate, "startDate")
    if not startValue then return startError end
    local endValue, endError = parseDate(endDate, "endDate")
    if not endValue then return endError end
    local span = daysBetween(startValue, endValue)
    if span < 0 or span > 90 then return errorResult("ANALYTICS_INVALID_RANGE", "Date range must be between 0 and 90 days.") end
    local identity = CivicOS.Authorization:identity(source)
    if not identity.ok then return identity end
    local auth = CivicOS.Authorization:can(source, "analytics.read", { departmentId = identity.data.departmentId })
    if not auth.ok then return auth end
    local departmentId = auth.data.scope == "global" and nil or identity.data.departmentId
    local summary = CivicOS.AnalyticsRepository:summary(startValue, endValue, departmentId)
    if not summary.ok then return summary end
    local backlog = CivicOS.AnalyticsRepository:backlog(startValue, endValue, departmentId)
    if not backlog.ok then return backlog end
    local employees = CivicOS.AnalyticsRepository:employeeMetrics(startValue, endValue, departmentId)
    if not employees.ok then return employees end
    local heatmap = CivicOS.AnalyticsRepository:heatmap(startValue, endValue, departmentId)
    if not heatmap.ok then return heatmap end
    return { ok = true, data = {
        range = { startDate = startValue, endDate = endValue },
        summary = summary.data,
        backlog = backlog.data,
        employees = employees.data,
        heatmap = heatmap.data,
    } }
end

CivicOS.AnalyticsService = AnalyticsService
return AnalyticsService

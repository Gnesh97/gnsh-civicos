local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS

local HealthService = {}

local function errorResult(code, message, details)
    return CivicOS.Result.err(code, message, details)
end

local function count(sql)
    local result = CivicOS.DatabaseAdapter:scalar(sql)
    return result.ok and tonumber(result.data) or nil
end

function HealthService:check(source, detailed)
    if source and tonumber(source) and tonumber(source) > 0 then
        local auth = CivicOS.Authorization:can(source, "system.config.manage", {})
        if not auth.ok then return auth end
    end
    local config = CivicOS.Validation:config(CivicOS.Config)
    local db = CivicOS.DatabaseAdapter and CivicOS.DatabaseAdapter:health()
    local migration = CivicOS.Migrations and CivicOS.Migrations:currentVersion()
    local result = {
        status = db and db.ok and config.ok and "healthy" or "degraded",
        bootstrap = CivicOS.Bootstrap and CivicOS.Bootstrap.state,
        version = CivicOS.Version and CivicOS.Version.version,
        config = { valid = config.ok, errors = config.error and config.error.details or {} },
        database = { available = db and db.ok == true, migrationVersion = migration and migration.ok and migration.data or nil },
        providers = CivicOS.ProviderCapabilities or {},
        scheduler = {
            running = CivicOS.Scheduler and CivicOS.Scheduler.running or false,
            jobs = CivicOS.Scheduler and CivicOS.Scheduler.jobs and tableCount(CivicOS.Scheduler.jobs) or 0,
        },
        integrations = { publicExports = CivicOS.PublicExports ~= nil },
    }
    if detailed then
        result.active = {
            requests = count("SELECT COUNT(*) FROM civicos_requests WHERE status NOT IN ('closed', 'cancelled')"),
            workorders = count("SELECT COUNT(*) FROM civicos_workorders WHERE status NOT IN ('closed', 'cancelled')"),
            employees = count("SELECT COUNT(*) FROM civicos_employees WHERE duty_status = 'on_duty'"),
        }
    end
    return { ok = true, data = result }
end

function tableCount(value)
    local countValue = 0
    for _ in pairs(value or {}) do countValue = countValue + 1 end
    return countValue
end

CivicOS.HealthService = HealthService
return HealthService

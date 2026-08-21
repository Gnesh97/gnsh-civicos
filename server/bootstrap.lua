local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS

local Bootstrap = {
    state = "IDLE",
    stages = { "CONFIG", "DB", "ADAPTERS", "SERVICES", "JOBS", "READY" },
}

local function log(level, category, message, context)
    if CivicOS.Logger and type(CivicOS.Logger[level]) == "function" then
        CivicOS.Logger[level](category, message, context)
    else
        print(string.format("[CIVICOS][%s][%s] %s", string.upper(level), string.upper(category), message))
    end
end

local function stageConfig()
    if CivicOS.Validation and CivicOS.Config then
        local result = CivicOS.Validation.config(CivicOS.Config)
        if not result.ok then
            error(result.error.message)
        end
    end
    if CivicOS.Logger and CivicOS.Config then
        CivicOS.Logger.configure(CivicOS.Config.Logging)
    end
    if CivicOS.Locale and CivicOS.Config then
        CivicOS.Locale.init(CivicOS.Config.Locale, CivicOS.Config.FallbackLocale)
    end
end

local function stageDatabase()
    -- Database adapter and migration runner are registered in S02. Keeping the
    -- stage explicit makes startup order observable without a silent fallback.
    if CivicOS.DatabaseAdapter and CivicOS.Config.Database.MigrationOnStart then
        local result = CivicOS.DatabaseAdapter.health and CivicOS.DatabaseAdapter:health()
        if result and result.ok == false then
            error(result.error.message)
        end
    else
        log("debug", "DB", "Database stage deferred until persistence adapter is registered.")
    end
end

local function stageAdapters()
    if CivicOS.AdapterRegistry and CivicOS.AdapterRegistry.initialize then
        local result = CivicOS.AdapterRegistry:initialize()
        if result and result.ok == false then
            error(result.error.message)
        end
    else
        log("debug", "CORE", "Adapter stage deferred until provider adapters are registered.")
    end
end

local function stageServices()
    if CivicOS.Container and not CivicOS.Container.isReady() then
        -- Services register before READY; no service resolution is allowed here.
        log("debug", "CORE", "Service container staged.")
    end
end

local function stageJobs()
    if CivicOS.Scheduler and CivicOS.Scheduler.start then
        CivicOS.Scheduler:start()
    else
        log("debug", "CORE", "Background jobs deferred until scheduler is registered.")
    end
end

local stageHandlers = {
    CONFIG = stageConfig,
    DB = stageDatabase,
    ADAPTERS = stageAdapters,
    SERVICES = stageServices,
    JOBS = stageJobs,
}

function Bootstrap.start()
    if Bootstrap.state == "READY" then
        return { ok = true, data = Bootstrap.state }
    end
    for _, stage in ipairs(Bootstrap.stages) do
        Bootstrap.state = stage
        local handler = stageHandlers[stage]
        local ok, err = true, nil
        if handler then
            ok, err = pcall(handler)
        end
        if not ok then
            Bootstrap.state = "FAILED"
            log("fatal", "CORE", string.format("Startup stage %s failed: %s", stage, tostring(err)), { stage = stage })
            return CivicOS.Result and CivicOS.Result.err("CORE_STARTUP_FAILED", "CivicOS startup failed.", { stage = stage })
                or { ok = false, error = { code = "CORE_STARTUP_FAILED", message = "CivicOS startup failed." } }
        end
        log("debug", "CORE", string.format("Startup stage %s complete.", stage))
    end
    if CivicOS.Container then
        CivicOS.Container.markReady()
    end
    Bootstrap.state = "READY"
    log("info", "CORE", "CivicOS ready.", { version = CivicOS.Version and CivicOS.Version.version })
    return { ok = true, data = Bootstrap.state }
end

function Bootstrap.stop()
    if CivicOS.Scheduler and CivicOS.Scheduler.stop then
        CivicOS.Scheduler:stop()
    end
    if CivicOS.Container then
        CivicOS.Container.reset()
    end
    Bootstrap.state = "STOPPED"
end

CivicOS.Bootstrap = Bootstrap

if type(CreateThread) == "function" then
    CreateThread(function()
        Bootstrap.start()
    end)
else
    Bootstrap.start()
end

if type(AddEventHandler) == "function" then
    AddEventHandler("onResourceStop", function(resourceName)
        if type(GetCurrentResourceName) ~= "function" or resourceName == GetCurrentResourceName() then
            Bootstrap.stop()
        end
    end)
end

return Bootstrap

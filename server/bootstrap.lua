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
    if not CivicOS.DatabaseAdapter then
        error("Database adapter is not registered.")
    end
    local health = CivicOS.DatabaseAdapter.health and CivicOS.DatabaseAdapter:health()
    if health and health.ok == false then
        error(health.error.message)
    end
    if CivicOS.Config.Database.MigrationOnStart and CivicOS.Migrations then
        local migration = CivicOS.Migrations.run()
        if not migration.ok then
            error(migration.error.message)
        end
    end
end

local function stageAdapters()
    if CivicOS.AdapterRegistry and CivicOS.AdapterRegistry.initialize then
        local result = CivicOS.AdapterRegistry:initialize()
        if result and result.ok == false then
            error(result.error.message)
        end
        if CivicOS.ProviderAdapters and CivicOS.ProviderAdapters.initialize then
            local providers = CivicOS.ProviderAdapters.initialize()
            if providers and providers.ok == false then
                error(providers.error.message)
            end
        end
        if CivicOS.Identity and CivicOS.Identity.start then
            CivicOS.Identity:start()
        end
    else
        error("Framework adapter registry is not registered.")
    end
end

local function stageServices()
    if CivicOS.Cache and CivicOS.Config then
        CivicOS.Cache.configure(CivicOS.Config.Cache)
    end
    if CivicOS.RateLimit and CivicOS.Config then
        CivicOS.RateLimit:configure(CivicOS.Config.RateLimits)
    end
    if CivicOS.Container and not CivicOS.Container.isReady() then
        if CivicOS.DepartmentService and CivicOS.DepartmentService.seed then
            local seeded = CivicOS.DepartmentService:seed()
            if not seeded.ok then
                error(seeded.error.message)
            end
        end
        if CivicOS.ServiceCatalogService and CivicOS.ServiceCatalogService.start then
            local catalog = CivicOS.ServiceCatalogService:start()
            if not catalog.ok then
                error(catalog.error.message)
            end
        end
        if CivicOS.WorkOrderTemplateService and CivicOS.WorkOrderTemplateService.start then
            local templates = CivicOS.WorkOrderTemplateService:start()
            if not templates.ok then
                error(templates.error.message)
            end
        end
        local registrations = {
            requestRepository = CivicOS.RequestRepository,
            workOrderRepository = CivicOS.WorkOrderRepository,
            employeeRepository = CivicOS.EmployeeRepository,
            departmentRepository = CivicOS.DepartmentRepository,
            auditRepository = CivicOS.AuditRepository,
            departmentService = CivicOS.DepartmentService,
            employeeService = CivicOS.EmployeeService,
            authorization = CivicOS.Authorization,
            serviceCatalog = CivicOS.ServiceCatalogService,
            requestService = CivicOS.RequestService,
            requestCommentService = CivicOS.RequestCommentService,
            workOrderTemplateService = CivicOS.WorkOrderTemplateService,
            workOrderService = CivicOS.WorkOrderService,
            dispatchService = CivicOS.DispatchService,
            workOrderDependencyService = CivicOS.WorkOrderDependencyService,
            inventoryService = CivicOS.InventoryService,
            checklistService = CivicOS.ChecklistService,
            fieldService = CivicOS.FieldService,
            api = CivicOS.Api,
            notificationRepository = CivicOS.NotificationRepository,
            escalationRepository = CivicOS.EscalationRepository,
            slaRepository = CivicOS.SlaRepository,
            notificationService = CivicOS.NotificationService,
            escalationService = CivicOS.EscalationService,
            slaService = CivicOS.SlaService,
            evidenceRepository = CivicOS.EvidenceRepository,
            inspectionRepository = CivicOS.InspectionRepository,
            evidenceService = CivicOS.EvidenceService,
            inspectionService = CivicOS.InspectionService,
            auditService = CivicOS.AuditService,
            activityService = CivicOS.ActivityService,
            contributionService = CivicOS.ContributionService,
            incidentService = CivicOS.IncidentService,
            outboxRepository = CivicOS.OutboxRepository,
            eventBus = CivicOS.EventBus,
            idempotency = CivicOS.Idempotency,
            analyticsRepository = CivicOS.AnalyticsRepository,
            analyticsService = CivicOS.AnalyticsService,
            healthService = CivicOS.HealthService,
        }
        for name, definition in pairs(registrations) do
            if definition and not CivicOS.Container._definitions[name] then
                CivicOS.Container.register(name, definition)
            end
        end
        if CivicOS.EmployeeService and CivicOS.EmployeeService.start then
            CivicOS.EmployeeService:start()
        end
        if CivicOS.CrewService and CivicOS.CrewService.start then
            CivicOS.CrewService:start()
        end
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

local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS

local Seed = { _counter = 0 }

local function errorResult(code, message, details)
    return CivicOS.Result.err(code, message, details)
end

local function reference()
    Seed._counter = (Seed._counter + 1) % 100000
    return string.format("SEED-%s-%05d", os.date("!%Y"), (os.time() + Seed._counter) % 100000)
end

function Seed:run(source)
    if not CivicOS.Features or CivicOS.Features.DemoSeed ~= true then return errorResult("SEED_DISABLED", "Demo seed mode is disabled.") end
    if source and tonumber(source) and tonumber(source) > 0 then
        local auth = CivicOS.Authorization:can(source, "system.config.manage", {})
        if not auth.ok then return auth end
    end
    local fixture = type(LoadResourceFile) == "function" and LoadResourceFile(GetCurrentResourceName(), "tests/fixtures/demo_data.lua") or nil
    local department = CivicOS.DepartmentService:getPersisted("dot")
    if not department.ok then return department end
    local created = CivicOS.RequestRepository:create({
        reference = reference(),
        source = "seed",
        sourceResource = "civicos-demo",
        externalRef = "demo-" .. os.time(),
        requesterIdentifier = "seed:demo",
        category = "traffic_infrastructure",
        subcategory = "traffic_signal_failure",
        title = "Demo traffic signal failure",
        description = "Seeded request for the CivicOS vertical slice.",
        priority = "high",
        status = CivicOS.Enums.RequestStatus.ACCEPTED,
        departmentId = department.data.id,
        location = { x = 100.0, y = 200.0, z = 30.0 },
        metadata = { seed = true, fixtureLoaded = fixture ~= nil },
    })
    if not created.ok then return created end
    local catalog = CivicOS.ServiceCatalogService:get("traffic_signal_failure", "staff")
    if not catalog.ok then return catalog end
    local template = CivicOS.WorkOrderTemplateService:snapshot(catalog.data.workOrderTemplate)
    if not template.ok then return template end
    local workorder = CivicOS.WorkOrderRepository:create({
        requestId = created.data,
        reference = reference(),
        departmentId = department.data.id,
        templateKey = template.data.key,
        priority = "high",
        status = CivicOS.Enums.WorkOrderStatus.UNASSIGNED,
        location = { x = 100.0, y = 200.0, z = 30.0 },
        checklist = template.data.checklist,
        metadata = { template = template.data, seed = true },
    })
    if not workorder.ok then return workorder end
    CivicOS.RequestRepository:updateStatus(created.data, 1, CivicOS.Enums.RequestStatus.CONVERTED)
    if CivicOS.SlaService then CivicOS.SlaService:createForRequest(created.data, catalog.data) end
    return { ok = true, data = { requestId = created.data, workorderId = workorder.data } }
end

CivicOS.SeedService = Seed

if type(RegisterCommand) == "function" then
    RegisterCommand("civicos_seed", function(source)
        local result = Seed:run(source)
        local output = type(json) == "table" and type(json.encode) == "function" and json.encode(result) or tostring(result.ok)
        print(output)
    end, false)
end

return Seed

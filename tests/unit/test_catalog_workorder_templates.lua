-- Regression coverage for service catalog/template wiring.
-- Run from the resource root with: lua tests/unit/test_catalog_workorder_templates.lua

_G.CivicOS = {
    Result = {
        err = function(code, message, details)
            return { ok = false, error = { code = code, message = message, details = details } }
        end,
    },
}

dofile("config/departments.lua")
dofile("config/service_catalog.lua")
dofile("config/workorder_templates.lua")

CivicOS.DepartmentService = {
    get = function(_, name)
        if CivicOS.Departments.get(name) then return { ok = true, data = CivicOS.Departments.get(name) } end
        return CivicOS.Result.err("DEPARTMENT_NOT_FOUND", "Department not found.")
    end,
}

local templateService = dofile("server/services/workorder_template_service.lua")
local started = templateService:start()
assert(started.ok, started.error and started.error.message or "template validation failed")

for _, service in ipairs(CivicOS.ServiceCatalog.list()) do
    assert(CivicOS.WorkOrderTemplates.get(service.workOrderTemplate), service.code .. " has no work-order template")
end

print("Service catalog work-order templates: PASS")

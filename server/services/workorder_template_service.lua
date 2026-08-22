local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS

local TemplateService = { _validated = false }

local function registry()
    local templates = CivicOS.WorkOrderTemplates
    if type(templates) == "table" and type(templates.get) == "function" and type(templates.list) == "function" then
        return templates
    end
    if type(LoadResourceFile) ~= "function" or type(load) ~= "function" or type(GetCurrentResourceName) ~= "function" then
        return nil
    end
    local readOk, source = pcall(LoadResourceFile, GetCurrentResourceName(), "config/workorder_templates.lua")
    if not readOk or type(source) ~= "string" or source == "" then return nil end
    local chunk = load(source, "@config/workorder_templates.lua", "t")
    if type(chunk) ~= "function" then return nil end
    local ok, result = pcall(chunk)
    if not ok then return nil end
    templates = CivicOS.WorkOrderTemplates
    if type(templates) ~= "table" and type(result) == "table" then
        templates = result
        CivicOS.WorkOrderTemplates = templates
    end
    if type(templates) == "table" and type(templates.get) == "function" and type(templates.list) == "function" then
        return templates
    end
    return nil
end

function TemplateService:start()
    if self._validated then return { ok = true, data = true } end
    local templates = registry()
    if not templates then
        return CivicOS.Result.err("WORKORDER_TEMPLATE_REGISTRY_UNAVAILABLE", "Work-order template registry is unavailable.")
    end
    for _, service in ipairs(CivicOS.ServiceCatalog and CivicOS.ServiceCatalog.list() or {}) do
        local templateKey = service.workOrderTemplate
        local template = templates.get(templateKey)
        if not template then
            return CivicOS.Result.err("WORKORDER_TEMPLATE_NOT_FOUND", "Service catalog references a missing work order template.", {
                serviceCode = service.code,
                templateKey = templateKey,
            })
        end
    end
    for _, template in ipairs(templates.list()) do
        if type(template.department) ~= "string" or type(template.actions) ~= "table" or type(template.checklist) ~= "table" then
            return CivicOS.Result.err("WORKORDER_TEMPLATE_INVALID", "Work order template is incomplete.", { key = template.key })
        end
        for _, action in ipairs(template.actions) do
            if type(action) ~= "table" or type(action.key) ~= "string" or type(action.type) ~= "string"
                or tonumber(action.radius) == nil or tonumber(action.duration) == nil
                or type(action.items) ~= "table" then
                return CivicOS.Result.err("WORKORDER_TEMPLATE_INVALID", "Work order action is incomplete.", { key = template.key })
            end
        end
        local department = CivicOS.DepartmentService:get(template.department)
        if not department.ok then return department end
    end
    self._validated = true
    return { ok = true, data = true }
end

function TemplateService:get(key)
    local templates = registry()
    if not templates then
        return CivicOS.Result.err("WORKORDER_TEMPLATE_REGISTRY_UNAVAILABLE", "Work-order template registry is unavailable.")
    end
    local template = templates.get(key)
    if not template then
        return CivicOS.Result.err("WORKORDER_TEMPLATE_NOT_FOUND", "Work order template not found.", { key = key })
    end
    return { ok = true, data = template }
end

function TemplateService:snapshot(key)
    local result = self:get(key)
    if not result.ok then return result end
    local template = result.data
    local snapshot = {}
    for key, value in pairs(template) do
        if type(value) == "table" then
            local copy = {}
            for index, item in pairs(value) do
                if type(item) == "table" then
                    local nested = {}
                    for nestedKey, nestedValue in pairs(item) do nested[nestedKey] = nestedValue end
                    copy[index] = nested
                else
                    copy[index] = item
                end
            end
            snapshot[key] = copy
        else
            snapshot[key] = value
        end
    end
    return { ok = true, data = snapshot }
end

CivicOS.WorkOrderTemplateService = TemplateService
return TemplateService

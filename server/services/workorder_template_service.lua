local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS

local TemplateService = { _validated = false }

function TemplateService:start()
    if self._validated then return { ok = true, data = true } end
    for _, template in ipairs(CivicOS.WorkOrderTemplates and CivicOS.WorkOrderTemplates.list() or {}) do
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
    local template = CivicOS.WorkOrderTemplates and CivicOS.WorkOrderTemplates.get(key)
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

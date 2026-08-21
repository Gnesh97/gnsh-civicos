local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS

local Service = { _validated = false }

function Service:start()
    if self._validated then return { ok = true, data = true } end
    for _, entry in ipairs(CivicOS.ServiceCatalog and CivicOS.ServiceCatalog.list() or {}) do
        local valid = CivicOS.ServiceCatalogDomain.validate(entry)
        if not valid.ok then return valid end
        local department = CivicOS.DepartmentService:get(entry.defaultDepartment)
        if not department.ok then return department end
        local category = CivicOS.DepartmentService:isCategoryAllowed(entry.defaultDepartment, entry.category)
        if not category.ok then return category end
    end
    self._validated = true
    return { ok = true, data = true }
end

function Service:get(code, sourceType)
    local entry = CivicOS.ServiceCatalog and CivicOS.ServiceCatalog.get(code)
    if not entry then
        return CivicOS.Result.err("CATALOG_NOT_FOUND", "Service code not found.", { code = code })
    end
    if sourceType == "citizen" and entry.citizenEnabled ~= true then
        return CivicOS.Result.err("CATALOG_CITIZEN_DISABLED", "Service is not citizen-enabled.", { code = code })
    end
    if sourceType == "integration" and entry.integrationEnabled ~= true then
        return CivicOS.Result.err("CATALOG_INTEGRATION_DISABLED", "Service is not integration-enabled.", { code = code })
    end
    return { ok = true, data = entry }
end

function Service:list()
    local result = {}
    for _, entry in ipairs(CivicOS.ServiceCatalog and CivicOS.ServiceCatalog.list() or {}) do
        result[#result + 1] = CivicOS.ServiceCatalogDomain.public(entry)
    end
    return { ok = true, data = result }
end

CivicOS.ServiceCatalogService = Service
return Service

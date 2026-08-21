local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS

local Domain = {}

function Domain.validate(entry)
    if type(entry) ~= "table" or type(entry.code) ~= "string" then
        return CivicOS.Result.err("CATALOG_INVALID", "Service catalog entry is invalid.")
    end
    if not entry.defaultDepartment or not entry.defaultPriority or not entry.workOrderTemplate then
        return CivicOS.Result.err("CATALOG_INVALID", "Service catalog entry is incomplete.", { code = entry.code })
    end
    if type(entry.sla) ~= "table" or type(entry.duplicate) ~= "table" then
        return CivicOS.Result.err("CATALOG_INVALID", "Service catalog SLA/duplicate rules are missing.", { code = entry.code })
    end
    for _, key in ipairs({ "acknowledge", "dispatch", "arrival", "resolution" }) do
        if type(entry.sla[key]) ~= "number" or entry.sla[key] <= 0 then
            return CivicOS.Result.err("CATALOG_INVALID", "Service catalog SLA is invalid.", { code = entry.code, key = key })
        end
    end
    if type(entry.duplicate.radius) ~= "number" or type(entry.duplicate.windowSeconds) ~= "number" then
        return CivicOS.Result.err("CATALOG_INVALID", "Service catalog duplicate rule is invalid.", { code = entry.code })
    end
    return CivicOS.Result.ok(entry)
end

function Domain.public(entry)
    return {
        code = entry.code,
        category = entry.category,
        subcategory = entry.subcategory,
        label = entry.label,
        defaultDepartment = entry.defaultDepartment,
        defaultPriority = entry.defaultPriority,
        sla = entry.sla,
        citizenEnabled = entry.citizenEnabled == true,
        integrationEnabled = entry.integrationEnabled == true,
        inspectionRequired = entry.inspectionRequired == true,
    }
end

CivicOS.ServiceCatalogDomain = Domain
return Domain

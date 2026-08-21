local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS

local Catalog = {
    traffic_signal_failure = {
        code = "traffic_signal_failure",
        category = "traffic_infrastructure",
        subcategory = "traffic_signal_failure",
        label = "service.traffic_signal_failure",
        defaultDepartment = "dot",
        defaultPriority = "high",
        sla = { acknowledge = 300, dispatch = 600, arrival = 1200, resolution = 2700 },
        duplicate = { radius = 75.0, windowSeconds = 600 },
        requiredCertifications = { "traffic_systems_technician" },
        workOrderTemplate = "traffic_signal_repair",
        citizenEnabled = true,
        integrationEnabled = true,
        inspectionRequired = false,
    },
    pothole = {
        code = "pothole",
        category = "road_maintenance",
        subcategory = "pothole",
        label = "service.pothole",
        defaultDepartment = "publicworks",
        defaultPriority = "normal",
        sla = { acknowledge = 900, dispatch = 1800, arrival = 3600, resolution = 86400 },
        duplicate = { radius = 50.0, windowSeconds = 1800 },
        requiredCertifications = {},
        workOrderTemplate = "pothole_repair",
        citizenEnabled = true,
        integrationEnabled = true,
        inspectionRequired = false,
    },
    damaged_road_sign = {
        code = "damaged_road_sign",
        category = "road_maintenance",
        subcategory = "damaged_road_sign",
        label = "service.damaged_road_sign",
        defaultDepartment = "dot",
        defaultPriority = "normal",
        sla = { acknowledge = 900, dispatch = 1800, arrival = 3600, resolution = 86400 },
        duplicate = { radius = 50.0, windowSeconds = 1800 },
        requiredCertifications = {},
        workOrderTemplate = "road_sign_repair",
        citizenEnabled = true,
        integrationEnabled = true,
        inspectionRequired = false,
    },
    streetlight_failure = {
        code = "streetlight_failure",
        category = "public_property",
        subcategory = "streetlight_failure",
        label = "service.streetlight_failure",
        defaultDepartment = "publicworks",
        defaultPriority = "normal",
        sla = { acknowledge = 900, dispatch = 1800, arrival = 3600, resolution = 86400 },
        duplicate = { radius = 60.0, windowSeconds = 1800 },
        requiredCertifications = {},
        workOrderTemplate = "streetlight_repair",
        citizenEnabled = true,
        integrationEnabled = true,
        inspectionRequired = false,
    },
    public_property_damage = {
        code = "public_property_damage",
        category = "public_property",
        subcategory = "public_property_damage",
        label = "service.public_property_damage",
        defaultDepartment = "publicworks",
        defaultPriority = "high",
        sla = { acknowledge = 600, dispatch = 1200, arrival = 3600, resolution = 86400 },
        duplicate = { radius = 75.0, windowSeconds = 1800 },
        requiredCertifications = {},
        workOrderTemplate = "property_repair",
        citizenEnabled = true,
        integrationEnabled = true,
        inspectionRequired = true,
    },
    overflowing_trash = {
        code = "overflowing_trash",
        category = "sanitation",
        subcategory = "overflowing_trash",
        label = "service.overflowing_trash",
        defaultDepartment = "sanitation",
        defaultPriority = "normal",
        sla = { acknowledge = 900, dispatch = 1800, arrival = 7200, resolution = 86400 },
        duplicate = { radius = 50.0, windowSeconds = 1800 },
        requiredCertifications = {},
        workOrderTemplate = "trash_collection",
        citizenEnabled = true,
        integrationEnabled = true,
        inspectionRequired = false,
    },
    illegal_dumping = {
        code = "illegal_dumping",
        category = "sanitation",
        subcategory = "illegal_dumping",
        label = "service.illegal_dumping",
        defaultDepartment = "sanitation",
        defaultPriority = "high",
        sla = { acknowledge = 600, dispatch = 1200, arrival = 3600, resolution = 86400 },
        duplicate = { radius = 75.0, windowSeconds = 1800 },
        requiredCertifications = {},
        workOrderTemplate = "illegal_dumping_cleanup",
        citizenEnabled = true,
        integrationEnabled = true,
        inspectionRequired = false,
    },
    water_leak = {
        code = "water_leak",
        category = "water_infrastructure",
        subcategory = "water_leak",
        label = "service.water_leak",
        defaultDepartment = "water",
        defaultPriority = "urgent",
        sla = { acknowledge = 300, dispatch = 600, arrival = 1800, resolution = 7200 },
        duplicate = { radius = 75.0, windowSeconds = 900 },
        requiredCertifications = { "water_systems_technician" },
        workOrderTemplate = "water_leak_repair",
        citizenEnabled = true,
        integrationEnabled = true,
        inspectionRequired = false,
    },
}

function Catalog.get(code)
    return Catalog[code]
end

function Catalog.list()
    local result = {}
    for _, entry in pairs(Catalog) do
        if type(entry) == "table" and entry.code then result[#result + 1] = entry end
    end
    table.sort(result, function(left, right) return left.code < right.code end)
    return result
end

CivicOS.ServiceCatalog = Catalog
return Catalog

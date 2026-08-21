local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS

local Templates = {
    traffic_signal_repair = {
        key = "traffic_signal_repair",
        type = "repair",
        department = "dot",
        actions = { "inspect", "repair", "test" },
        checklist = { "power_isolated", "controller_checked", "signal_tested" },
        requiredItems = { { item = "repair_kit", count = 1 } },
        requiredCertifications = { "traffic_systems_technician" },
        inspectionRequired = false,
    },
    pothole_repair = {
        key = "pothole_repair",
        type = "repair",
        department = "publicworks",
        actions = { "secure_area", "repair", "test" },
        checklist = { "area_secured", "surface_repaired", "area_clean" },
        requiredItems = { { item = "road_kit", count = 1 } },
        requiredCertifications = {},
        inspectionRequired = false,
    },
    road_repair = {
        key = "road_repair",
        type = "repair",
        department = "publicworks",
        actions = { "secure_area", "repair", "test" },
        checklist = { "area_secured", "surface_repaired", "area_clean" },
        requiredItems = { { item = "road_kit", count = 1 } },
        requiredCertifications = {},
        inspectionRequired = false,
    },
    water_leak_repair = {
        key = "water_leak_repair",
        type = "repair",
        department = "water",
        actions = { "isolate", "repair", "test" },
        checklist = { "water_isolated", "pipe_repaired", "pressure_tested" },
        requiredItems = { { item = "water_kit", count = 1 } },
        requiredCertifications = { "water_systems_technician" },
        inspectionRequired = false,
    },
}

function Templates.get(key)
    return Templates[key]
end

function Templates.list()
    local result = {}
    for _, template in pairs(Templates) do
        if type(template) == "table" and template.key then result[#result + 1] = template end
    end
    table.sort(result, function(left, right) return left.key < right.key end)
    return result
end

CivicOS.WorkOrderTemplates = Templates
return Templates

local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS

local function action(key, actionType, options)
    options = type(options) == "table" and options or {}
    return {
        key = key,
        type = actionType,
        radius = options.radius or 4.0,
        duration = options.duration or 5000,
        state = options.state or "working",
        items = options.items or {},
        animation = options.animation or {},
        effect = options.effect or {},
        consumeOnStart = options.consumeOnStart == true,
        consumeOnComplete = options.consumeOnComplete ~= false,
    }
end

local Templates = {
    traffic_signal_repair = {
        key = "traffic_signal_repair",
        type = "repair",
        department = "dot",
        actions = {
            action("inspect", "INSPECT", { duration = 5000 }),
            action("repair", "REPAIR", { duration = 9000, items = { { item = "repair_kit", count = 1 } } }),
            action("test", "TEST", { duration = 5000 }),
        },
        checklist = { "power_isolated", "controller_checked", "signal_tested" },
        requiredItems = { { item = "repair_kit", count = 1 } },
        requiredCertifications = { "traffic_systems_technician" },
        inspectionRequired = true,
    },
    pothole_repair = {
        key = "pothole_repair",
        type = "repair",
        department = "publicworks",
        actions = {
            action("secure_area", "SECURE", { duration = 4000 }),
            action("repair", "REPAIR", { duration = 8000, items = { { item = "road_kit", count = 1 } } }),
            action("test", "TEST", { duration = 4000 }),
        },
        checklist = { "area_secured", "surface_repaired", "area_clean" },
        requiredItems = { { item = "road_kit", count = 1 } },
        requiredCertifications = {},
        inspectionRequired = false,
    },
    road_repair = {
        key = "road_repair",
        type = "repair",
        department = "publicworks",
        actions = {
            action("secure_area", "SECURE", { duration = 4000 }),
            action("repair", "REPAIR", { duration = 10000, items = { { item = "road_kit", count = 1 } } }),
            action("test", "TEST", { duration = 5000 }),
        },
        checklist = { "area_secured", "surface_repaired", "area_clean" },
        requiredItems = { { item = "road_kit", count = 1 } },
        requiredCertifications = {},
        inspectionRequired = false,
    },
    road_sign_repair = {
        key = "road_sign_repair",
        type = "repair",
        department = "dot",
        actions = {
            action("inspect", "INSPECT", { duration = 4000 }),
            action("replace_sign", "REPAIR", { duration = 8000 }),
            action("secure_area", "SECURE", { duration = 4000 }),
        },
        checklist = { "area_secured", "sign_replaced", "visibility_checked" },
        requiredItems = {},
        requiredCertifications = {},
        inspectionRequired = false,
    },
    streetlight_repair = {
        key = "streetlight_repair",
        type = "repair",
        department = "publicworks",
        actions = {
            action("inspect", "INSPECT", { duration = 4000 }),
            action("repair", "REPAIR", { duration = 8000 }),
            action("test", "TEST", { duration = 4000 }),
        },
        checklist = { "power_checked", "fixture_repaired", "light_tested" },
        requiredItems = {},
        requiredCertifications = {},
        inspectionRequired = false,
    },
    property_repair = {
        key = "property_repair",
        type = "repair",
        department = "publicworks",
        actions = {
            action("secure_area", "SECURE", { duration = 4000 }),
            action("repair", "REPAIR", { duration = 9000 }),
            action("inspect", "INSPECT", { duration = 4000 }),
        },
        checklist = { "area_secured", "damage_repaired", "site_checked" },
        requiredItems = {},
        requiredCertifications = {},
        inspectionRequired = true,
    },
    trash_collection = {
        key = "trash_collection",
        type = "collection",
        department = "sanitation",
        actions = {
            action("secure_area", "SECURE", { duration = 3000 }),
            action("collect", "COLLECT", { duration = 7000 }),
            action("dispose", "DISPOSE", { duration = 5000 }),
        },
        checklist = { "area_secured", "trash_collected", "site_clean" },
        requiredItems = {},
        requiredCertifications = {},
        inspectionRequired = false,
    },
    illegal_dumping_cleanup = {
        key = "illegal_dumping_cleanup",
        type = "cleanup",
        department = "sanitation",
        actions = {
            action("secure_area", "SECURE", { duration = 4000 }),
            action("remove_dumping", "CLEANUP", { duration = 9000 }),
            action("inspect_site", "INSPECT", { duration = 4000 }),
        },
        checklist = { "area_secured", "dumping_removed", "site_checked" },
        requiredItems = {},
        requiredCertifications = {},
        inspectionRequired = false,
    },
    water_leak_repair = {
        key = "water_leak_repair",
        type = "repair",
        department = "water",
        actions = {
            action("isolate", "SECURE", { duration = 5000 }),
            action("repair", "REPAIR", { duration = 9000, items = { { item = "water_kit", count = 1 } } }),
            action("test", "TEST", { duration = 6000 }),
        },
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

-- Regression coverage for a losing concurrent conversion call.

local findCount = 0
local activityWrites = 0

_G.CivicOS = {
    Result = {
        err = function(code, message, details)
            return { ok = false, error = { code = code, message = message, details = details or {} } }
        end,
    },
    Enums = {
        RequestStatus = { CONVERTED = "converted" },
        WorkOrderStatus = {},
    },
    RequestRepository = {
        findById = function()
            findCount = findCount + 1
            if findCount == 1 then
                return { ok = true, data = { { id = 7, version = 2, status = "accepted", source = "citizen", department_id = 4, priority = "normal", category = "publicworks", subcategory = "road" } } }
            end
            return { ok = true, data = { { id = 7, version = 3, status = "converted", source = "citizen", department_id = 4, priority = "normal", category = "publicworks", subcategory = "road" } } }
        end,
        addActivity = function() activityWrites = activityWrites + 1 end,
    },
    RequestStateMachine = {
        transition = function() return { ok = true, data = {} } end,
    },
    Authorization = {
        can = function() return { ok = true, data = { identity = { persistentIdentifier = "license:dispatcher" } } } end,
    },
    ServiceCatalogService = {
        get = function() return { ok = true, data = { workOrderTemplate = "road.sign" } } end,
    },
    WorkOrderTemplateService = {
        snapshot = function(_, key) return { ok = true, data = { key = key, checklist = {} } } end,
    },
    WorkOrderRepository = {
        createManyForRequest = function() return { ok = true, data = true } end,
        listByRequest = function() return { ok = true, data = { { reference = "WO-created-by-other-call" } } } end,
    },
}

local workorders = dofile("server/services/workorder_service.lua")
local result = workorders:convert(1, 7, 2, "road.sign", nil, nil)
assert(not result.ok and result.error.code == "CORE_VERSION_CONFLICT", "losing conversion must return a version conflict")
assert(activityWrites == 0, "losing conversion must not append a created activity")

print("conversion conflict regression: PASS")

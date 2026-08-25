-- Regression coverage for integration read ownership on request/work-order DTOs.

local requestResource = "alpha-resource"
local workOrderRequest = {
    source = "integration",
    source_resource = requestResource,
}

_G.CivicOS = {
    Result = {
        err = function(code, message, details)
            return { ok = false, error = { code = code, message = message, details = details or {} } }
        end,
    },
    RequestRepository = {
        findById = function(_, id)
            return { ok = true, data = { { id = id, source = "integration", source_resource = requestResource } } }
        end,
    },
    RequestDomain = {
        public = function(entity) return { id = entity.id } end,
    },
    WorkOrderRepository = {
        findById = function(_, id)
            return { ok = true, data = { { id = id, request_id = 4, status = "unassigned" } } }
        end,
    },
    WorkOrderDomain = {
        public = function(entity) return { id = entity.id, status = entity.status } end,
    },
}

local requests = dofile("server/services/request_service.lua")
local workorders = dofile("server/services/workorder_service.lua")

local ownContext = { sourceType = "integration", sourceResource = requestResource }
assert(requests:integrationGet(4, ownContext).ok, "owner integration should read its request")
assert(workorders:integrationGet(8, ownContext).ok, "owner integration should read its work order")

local foreignContext = { sourceType = "integration", sourceResource = "beta-resource" }
local requestDenied = requests:integrationGet(4, foreignContext)
assert(not requestDenied.ok and requestDenied.error.code == "AUTH_FORBIDDEN", "foreign integration must not read request")
local workOrderDenied = workorders:integrationGet(8, foreignContext)
assert(not workOrderDenied.ok and workOrderDenied.error.code == "AUTH_FORBIDDEN", "foreign integration must not read work order")

local invalidContext = requests:integrationGet(4, { sourceResource = requestResource })
assert(not invalidContext.ok and invalidContext.error.code == "AUTH_FORBIDDEN", "non-integration context must be rejected")

print("integration ownership regression: PASS")

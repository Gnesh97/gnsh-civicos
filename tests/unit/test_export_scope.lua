-- Regression coverage for public export ownership and invoking-resource context.

local registered = {}
local captured = {}

_G.GetInvokingResource = function() return "real-resource" end
_G.exports = function(name, handler) registered[name] = handler end

_G.CivicOS = {
    Result = {
        err = function(code, message, details)
            return { ok = false, error = { code = code, message = message, details = details or {} } }
        end,
    },
    Idempotency = {
        run = function(_, key, idempotencyKey, payload, handler)
            captured.idempotencyKey = key
            captured.idempotencyContext = idempotencyKey
            captured.payload = payload
            return handler()
        end,
    },
    RequestService = {
        get = function() error("public export must not call source=nil request get") end,
        integrationGet = function(_, id, context)
            captured.requestGet = { id = id, context = context }
            return { ok = true, data = { id = id } }
        end,
        integrationPatch = function(_, id, expectedVersion, patch, context)
            captured.patch = { id = id, expectedVersion = expectedVersion, patch = patch, context = context }
            return { ok = true, data = { id = id } }
        end,
        create = function(_, _, _, context)
            captured.createContext = context
            return { ok = true, data = { id = 1 } }
        end,
    },
    WorkOrderService = {
        get = function() error("public export must not call source=nil work-order get") end,
        integrationGet = function(_, id, context)
            captured.workOrderGet = { id = id, context = context }
            return { ok = true, data = { id = id } }
        end,
    },
}

local exportsModule = dofile("server/api/exports.lua")
assert(exportsModule == CivicOS.PublicExports, "public exports should be registered")

local request = registered.GetRequest(7)
assert(request.ok and captured.requestGet.id == 7, "GetRequest should use the integration read boundary")
assert(captured.requestGet.context.sourceResource == "real-resource", "GetRequest must use the invoking resource")
assert(captured.requestGet.context.actorIdentifier == "integration:real-resource", "actor identity must be derived from the invoking resource")

local workorder = registered.GetWorkOrder(9)
assert(workorder.ok and captured.workOrderGet.id == 9, "GetWorkOrder should use the integration read boundary")
assert(captured.workOrderGet.context.sourceResource == "real-resource", "GetWorkOrder must use the invoking resource")

local update = registered.UpdateRequest(7, 2, { title = "new" }, {
    sourceResource = "spoofed-resource",
    actorIdentifier = "spoofed-actor",
    idempotencyKey = "k-1",
})
assert(update.ok, "UpdateRequest should be dispatched")
assert(captured.patch.context.sourceResource == "real-resource", "source resource must not be caller-spoofable")
assert(captured.patch.context.actorIdentifier == "integration:real-resource", "actor identifier must not be caller-spoofable")
assert(captured.idempotencyKey == "export:UpdateRequest:real-resource", "idempotency namespace must use the invoking resource")

_G.GetInvokingResource = function() return nil end
local denied = registered.GetRequest(7)
assert(not denied.ok and denied.error.code == "AUTH_FORBIDDEN", "exports without an invoking resource must fail closed")

print("public export scope regression: PASS")

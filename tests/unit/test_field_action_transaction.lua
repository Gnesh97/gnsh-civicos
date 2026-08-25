-- Regression tests for field-action token and inventory rollback ordering.
-- Run from the resource root with: lua tests/unit/test_field_action_transaction.lua

local function resultError(code, message)
    return { ok = false, error = { code = code, message = message } }
end

local consumeMode = "fail"
local tokenConsumeCalls = 0
local tokenRestoreCalls = 0
local inventoryRestoreCalls = 0
local inventoryConsumeCalls = 0
local tokenMode = "ok"
local updateCalls = {}
local updateMode = "ok"
local issueMode = "ok"
local payloadLarge = true

local entity = {
    id = 7,
    version = 1,
    status = "working",
    metadata = {
        template = {
            actions = {
                {
                    key = "repair",
                    consumeOnStart = false,
                    consumeOnComplete = true,
                    items = { { item = "repair_kit", count = 1 } },
                },
            },
        },
        fieldActions = {
            repair = { status = "started", startedAt = 10, startedBy = "employee-1", inventoryConsumed = false },
        },
    },
}

_G.CivicOS = {
    Result = {
        err = resultError,
    },
    Config = { FieldOperations = { MaxActionPayloadBytes = 4 } },
    WorkOrderRepository = {
        findById = function(_, id)
            assert(id == 7, "field action lookup should use work order id")
            return { ok = true, data = { entity } }
        end,
        updateMetadata = function(_, id, expectedVersion, metadata)
            updateCalls[#updateCalls + 1] = { id = id, expectedVersion = expectedVersion, metadata = metadata }
            if updateMode == "fail" then
                return resultError("CORE_VERSION_CONFLICT", "metadata conflict")
            end
            if expectedVersion == 1 then
                return { ok = true, data = { id = id, version = 2, metadata = metadata } }
            end
            return resultError("CORE_VERSION_CONFLICT", "metadata conflict")
        end,
    },
    WorkOrderTemplateService = {},
    ExploitGuard = {
        validate = function()
            return { ok = true, data = { identity = { persistentIdentifier = "employee-1" } } }
        end,
    },
    InventoryService = {
        consume = function()
            inventoryConsumeCalls = inventoryConsumeCalls + 1
            if consumeMode == "fail" then return resultError("FIELD_ITEM_CONSUME_FAILED", "item missing") end
            return { ok = true, data = { consumed = { { item = "repair_kit", count = 1 } } } }
        end,
        restore = function()
            inventoryRestoreCalls = inventoryRestoreCalls + 1
            return { ok = true, data = true }
        end,
    },
    ActionTokens = {
        consume = function()
            tokenConsumeCalls = tokenConsumeCalls + 1
            if tokenMode == "fail" then return resultError("FIELD_ACTION_TOKEN_INVALID", "invalid token") end
            return { ok = true, data = { consumed = true, entry = {} } }
        end,
        restore = function()
            tokenRestoreCalls = tokenRestoreCalls + 1
            return { ok = true, data = true }
        end,
        issue = function()
            if issueMode == "fail" then return resultError("FIELD_ACTION_TOKEN_INVALID", "token unavailable") end
            return { ok = true, data = { token = "token-1", expiresAt = 100 } }
        end,
    },
}

_G.json = {
    encode = function()
        return payloadLarge and "12345" or "{}"
    end,
}

local fieldService = dofile("server/services/field_service.lua")

local result = fieldService:completeAction(42, 7, "token-1", "repair", 1, { result = "large" })
assert(not result.ok and result.error.code == "FIELD_ITEM_CONSUME_FAILED", "inventory failure should be returned")
assert(tokenConsumeCalls == 1, "token must be consumed before inventory")
assert(tokenRestoreCalls == 1, "token should be restored when inventory fails")
assert(inventoryConsumeCalls == 1, "inventory should be attempted once")

consumeMode = "ok"
entity.metadata.template.actions[1].consumeOnComplete = false
tokenConsumeCalls = 0
tokenRestoreCalls = 0
inventoryRestoreCalls = 0
inventoryConsumeCalls = 0
local payloadResult = fieldService:completeAction(42, 7, "token-1", "repair", 1, { result = "large" })
assert(not payloadResult.ok and payloadResult.error.code == "FIELD_ACTION_PAYLOAD_TOO_LARGE", "oversized payload should be rejected")
assert(tokenConsumeCalls == 1, "token should be consumed before payload validation")
assert(tokenRestoreCalls == 1, "token should be restored after payload validation fails")
assert(inventoryConsumeCalls == 0, "inventory should not be consumed when consumeOnComplete is disabled")

entity.metadata.template.actions[1].consumeOnComplete = true
entity.metadata.fieldActions.repair.inventoryConsumed = false
updateMode = "fail"
payloadLarge = false
tokenConsumeCalls = 0
tokenRestoreCalls = 0
inventoryRestoreCalls = 0
inventoryConsumeCalls = 0
local updateResult = fieldService:completeAction(42, 7, "token-1", "repair", 1, {})
assert(not updateResult.ok and updateResult.error.code == "CORE_VERSION_CONFLICT", "metadata failure should be returned")
assert(tokenConsumeCalls == 1, "token should be consumed after all preconditions pass")
assert(tokenRestoreCalls == 1, "consumed token should be restorable when metadata update fails")
assert(inventoryRestoreCalls == 1, "consumed inventory should be restored when metadata update fails")
assert(inventoryConsumeCalls == 1, "inventory should be consumed once")

tokenMode = "fail"
updateMode = "ok"
tokenConsumeCalls = 0
tokenRestoreCalls = 0
inventoryConsumeCalls = 0
local invalidTokenResult = fieldService:completeAction(42, 7, "invalid-token", "repair", 1, {})
assert(not invalidTokenResult.ok and invalidTokenResult.error.code == "FIELD_ACTION_TOKEN_INVALID", "invalid token should be rejected")
assert(tokenConsumeCalls == 1, "invalid token should be checked once")
assert(inventoryConsumeCalls == 0, "invalid token must not consume inventory")
tokenMode = "ok"

updateCalls = {}
inventoryRestoreCalls = 0
issueMode = "fail"
updateMode = "ok"
entity.version = 1
entity.metadata.fieldActions = {}
entity.metadata.template.actions[1].consumeOnStart = true
entity.metadata.template.actions[1].consumeOnComplete = false
local startResult = fieldService:startAction(42, 7, 1, "repair")
assert(not startResult.ok and startResult.error.code == "FIELD_ACTION_TOKEN_INVALID", "token issuance failure should be returned")
assert(inventoryRestoreCalls == 1, "start failure should restore consumed inventory")
assert(#updateCalls == 2, "start failure should roll metadata back after token issuance fails")
assert(updateCalls[2].expectedVersion == 2, "metadata rollback should use updated version")

print("field action transaction regression: PASS")

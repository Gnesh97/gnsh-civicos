-- Regression test for refusing success when idempotent response persistence fails.
-- Run from the resource root with: lua tests/unit/test_idempotency.lua

local rows = {}
local updates = 0
local handlerCalls = 0
local updateMode = "error"

_G.json = {
    encode = function(value)
        return value == true and "true" or "{\"ok\":true}"
    end,
    decode = function(value)
        if value == "true" then return true end
        return nil
    end,
}
_G.CivicOS = {
    Result = {
        err = function(code, message, details)
            return { ok = false, error = { code = code, message = message, details = details or {} } }
        end,
    },
    DatabaseAdapter = {},
}

function CivicOS.DatabaseAdapter:update(sql)
    if sql:match("^DELETE FROM civicos_idempotency") then return { ok = true } end
    updates = updates + 1
    if updateMode == "zero" then return { ok = true, data = { affectedRows = 0 } } end
    if updateMode == "nil" then return nil end
    return { ok = false, error = { code = "DB_WRITE_FAILED", message = "write failed" } }
end

function CivicOS.DatabaseAdapter:single(sql, params)
    local row = rows[params[1] .. ":" .. params[2]]
    return { ok = true, data = row }
end

function CivicOS.DatabaseAdapter:insert(_, params)
    rows[params[1] .. ":" .. params[2]] = {
        request_hash = params[3],
        response_json = nil,
    }
    return { ok = true }
end

local idempotency = dofile("server/core/idempotency.lua")
local first = idempotency:run("test", "key", { value = 1 }, function()
    handlerCalls = handlerCalls + 1
    return true
end)
assert(not first.ok, "persistence failure must not return successful operation result")
assert(first.error.code == "IDEMPOTENCY_PERSIST_FAILED", "persistence failure should have stable error code")
assert(handlerCalls == 1, "handler should run once")
assert(updates == 1, "response persistence should be attempted once")

local second = idempotency:run("test", "key", { value = 1 }, function()
    handlerCalls = handlerCalls + 1
    return true
end)
assert(not second.ok and second.error.code == "IDEMPOTENCY_IN_PROGRESS", "failed persistence must retain claim and block duplicate execution")
assert(handlerCalls == 1, "retry must not execute handler a second time")

updateMode = "zero"
local zeroRows = idempotency:run("test", "zero-rows", { value = 2 }, function()
    return true
end)
assert(not zeroRows.ok and zeroRows.error.code == "IDEMPOTENCY_PERSIST_FAILED", "zero-row persistence must not return success")

updateMode = "nil"
local missingPersistence = idempotency:run("test", "missing-persistence", { value = 3 }, function()
    return true
end)
assert(not missingPersistence.ok and missingPersistence.error.code == "IDEMPOTENCY_PERSIST_FAILED", "missing persistence result must not return success")

print("idempotency response persistence regression: PASS")

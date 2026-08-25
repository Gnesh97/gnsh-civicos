-- Regression coverage for conversion materialization status.

local capturedStatements

_G.CivicOS = {
    Repository = {
        encode = function(value) return value end,
        db = function()
            return {
                transaction = function(_, statements)
                    capturedStatements = statements
                    return { ok = true, data = { affectedRows = 1 } }
                end,
            }
        end,
        rows = function(result) return result end,
    },
}

local repository = dofile("server/repositories/workorder_repository.lua")
local result = repository:createManyForRequest(4, 2, {
    {
        reference = "WO-TEST",
        departmentId = 4,
        templateKey = "road.sign",
        priority = "normal",
    },
})

assert(result.ok, "conversion materialization transaction should succeed")
assert(#capturedStatements == 2, "conversion should use one insert and one request update transaction")
assert(capturedStatements[1].query:find("'unassigned'", 1, true), "materialized work orders must start unassigned atomically")
assert(not capturedStatements[1].query:find("'created'", 1, true), "conversion must not require a follow-up staging update")

print("conversion atomicity regression: PASS")

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
assert(capturedStatements[1].query:find("UPDATE civicos_requests", 1, true), "request version must be claimed before materialization")
assert(capturedStatements[1].query:find("NOT EXISTS", 1, true), "request claim must reject pre-existing work orders")
assert(capturedStatements[2].query:find("'unassigned'", 1, true), "materialized work orders must start unassigned atomically")
assert(capturedStatements[2].query:find("NOT EXISTS", 1, true), "materialization must be guarded against duplicate conversion")
assert(capturedStatements[2].query:find("UNION ALL", 1, true) == nil, "single-item conversion should not need a union")

local secondItem = repository:createManyForRequest(4, 2, {
    { reference = "WO-TEST-1", departmentId = 4, templateKey = "road.sign", priority = "normal" },
    { reference = "WO-TEST-2", departmentId = 4, templateKey = "road.sign", priority = "normal" },
})
assert(secondItem.ok and capturedStatements[2].query:find("UNION ALL", 1, true), "all work orders must share one guarded insert statement")

print("conversion atomicity regression: PASS")

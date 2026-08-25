-- Regression coverage for negative/zero pagination inputs.
-- SQL LIMIT values and API envelopes must stay within the documented bounds.

local calls = {}
local db = {
    query = function(_, sql, params)
        calls[#calls + 1] = { sql = sql, params = params }
        return { ok = true, data = {} }
    end,
}

_G.CivicOS = {
    Repository = {
        db = function() return db end,
        rows = function(result) return result end,
        decode = function(_, value) return value end,
    },
}

local serializers = dofile("server/api/serializers.lua")
assert(serializers.paginated({}, 1, -10).pageSize == 1, "API page size must clamp to one")

local requests = dofile("server/repositories/request_repository.lua")
requests:list({ page = 1, pageSize = -10 })
assert(calls[#calls].params[#calls[#calls].params - 1] == 1, "request query LIMIT must clamp to one")

local workorders = dofile("server/repositories/workorder_repository.lua")
workorders:list({ page = 1, pageSize = 0 })
assert(calls[#calls].params[#calls[#calls].params - 1] == 1, "work-order query LIMIT must clamp to one")

local audits = dofile("server/repositories/audit_repository.lua")
audits:list("workorder", 1, 1, -10)
assert(calls[#calls].params[3] == 1, "audit query LIMIT must clamp to one")

local notifications = dofile("server/repositories/notification_repository.lua")
notifications:list("license:test", false, 1, 0)
assert(calls[#calls].params[2] == 1, "notification query LIMIT must clamp to one")

print("pagination bounds regression: PASS")

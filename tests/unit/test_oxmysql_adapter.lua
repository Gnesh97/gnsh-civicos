-- Regression test for the CFX export fallback used when MySQL.lua is not loaded.
-- Run from the resource root with: lua tests/unit/test_oxmysql_adapter.lua

local calls = {}

local provider = {}
function provider.query(self, sql, params)
    assert(self == provider, "query export must receive its provider object")
    assert(type(sql) == "string", "query export must receive SQL as its second argument")
    calls[#calls + 1] = { method = "query", sql = sql, params = params }
    return {}
end

function provider.transaction(self, statements)
    assert(self == provider, "transaction export must receive its provider object")
    assert(type(statements) == "table", "transaction export must receive statements")
    calls[#calls + 1] = { method = "transaction", statements = statements }
    return true
end

_G.CivicOS = {
    Config = { Database = { QueryTimingWarningMs = 250 } },
    Logger = {
        debug = function() end,
        warn = function() end,
    },
    Result = {
        err = function(code, message)
            return { ok = false, error = { code = code, message = message } }
        end,
    },
}
_G.MySQL = nil
_G.exports = { oxmysql = provider }

dofile("server/adapters/database/interface.lua")
local database = dofile("server/adapters/database/oxmysql.lua")

local queryResult = database:query("SELECT 1", { 100 })
assert(queryResult.ok, "query should succeed through the CFX export fallback")
assert(#calls == 1 and calls[1].method == "query", "query export should be called once")
assert(calls[1].sql == "SELECT 1", "SQL must not be replaced by the parameter value")
assert(calls[1].params[1] == 100, "query parameters must be preserved")

local transactionResult = database:transaction({ { "SELECT 1", {} } })
assert(transactionResult.ok, "transaction should succeed through the CFX export fallback")
assert(#calls == 2 and calls[2].method == "transaction", "transaction export should be called once")

print("oxmysql export fallback regression: PASS (query + transaction)")

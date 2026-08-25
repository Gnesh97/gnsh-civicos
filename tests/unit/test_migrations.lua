-- Regression test for portable, one-statement-at-a-time migration execution.
-- Run from the resource root with: lua tests/unit/test_migrations.lua

local calls = {}
local migrationSql = {
    ["sql/test.sql"] = [[
        CREATE TABLE civicos_test_one (value VARCHAR(32));
        INSERT INTO civicos_test_one (value) VALUES ('semicolon ; stays inside a value');
    ]],
}

_G.CivicOS = {
    Result = {
        err = function(code, message, details)
            return { ok = false, error = { code = code, message = message, details = details or {} } }
        end,
    },
    Logger = {
        error = function() end,
    },
    DatabaseAdapter = {},
}
_G.GetCurrentResourceName = function() return "gnsh-civicos" end
_G.LoadResourceFile = function(_, path) return migrationSql[path] end

function CivicOS.DatabaseAdapter:query(sql)
    calls[#calls + 1] = sql
    return { ok = true, data = {} }
end

local migrations = dofile("server/core/migrations.lua")
local applied = migrations.apply({
    version = 99,
    id = "test_split",
    file = "sql/test.sql",
    checksum = "test-split-v1",
})
assert(applied.ok, "migration should succeed")
assert(#calls == 3, "two SQL statements plus the schema-version insert are expected")
assert(calls[1]:match("^CREATE TABLE civicos_test_one"), "first statement should be CREATE TABLE")
assert(calls[2]:match("semicolon ; stays inside a value"), "quoted semicolon must not split the statement")
assert(calls[3]:match("INSERT INTO civicos_schema_version"), "migration version should be recorded")

function CivicOS.DatabaseAdapter:query(sql)
    if sql:match("information_schema%.tables") then
        return { ok = true, data = {
            { table_name = "civicos_schema_version" },
            { table_name = "civicos_requests" },
            { table_name = "civicos_request_comments" },
            { table_name = "civicos_request_activity" },
            { table_name = "civicos_workorders" },
            { table_name = "civicos_workorder_assignments" },
            { table_name = "civicos_workorder_dependencies" },
            { table_name = "civicos_employees" },
            { table_name = "civicos_employee_certifications" },
            { table_name = "civicos_departments" },
            { table_name = "civicos_sla_events" },
            { table_name = "civicos_escalations" },
            { table_name = "civicos_inspections" },
            { table_name = "civicos_evidence" },
            { table_name = "civicos_audit_logs" },
            { table_name = "civicos_notifications" },
            { table_name = "civicos_crews" },
            { table_name = "civicos_crew_members" },
            { table_name = "civicos_contributions" },
            { table_name = "civicos_outbox" },
            { table_name = "civicos_idempotency" },
        } }
    end
    return { ok = true, data = {} }
end

local schema = migrations.verifyRequiredTables()
assert(schema.ok and schema.data.tables == 21, "required table verification should cover every runtime table")

function CivicOS.DatabaseAdapter:query(sql)
    if sql:match("information_schema%.tables") then
        return { ok = true, data = { { table_name = "civicos_schema_version" } } }
    end
    return { ok = true, data = {} }
end

local missingSchema = migrations.verifyRequiredTables()
assert(
    not missingSchema.ok
        and missingSchema.error.details.missingCount == 20,
    "schema verification should fail when any runtime table is missing"
)

print("migration split + schema verification regression: PASS")

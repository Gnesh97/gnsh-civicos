local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS

local Migrations = {
    definitions = {
        { version = 1, id = "001_initial", file = "sql/001_initial.sql", checksum = "civicos-001-initial-v1" },
        { version = 2, id = "002_indexes", file = "sql/002_indexes.sql", checksum = "civicos-002-indexes-v1" },
        { version = 3, id = "003_employee_certifications", file = "sql/003_employee_certifications.sql", checksum = "civicos-003-certifications-v1" },
        { version = 4, id = "004_assignment_reason", file = "sql/004_assignment_reason.sql", checksum = "civicos-004-assignment-reason-v1" },
        { version = 5, id = "005_sla_state", file = "sql/005_sla_state.sql", checksum = "civicos-005-sla-state-v1" },
        { version = 6, id = "006_escalations", file = "sql/006_escalations.sql", checksum = "civicos-006-escalations-v1" },
        { version = 7, id = "007_evidence_retention", file = "sql/007_evidence_retention.sql", checksum = "civicos-007-evidence-retention-v1" },
        { version = 8, id = "008_crews_contributions", file = "sql/008_crews_contributions.sql", checksum = "civicos-008-crews-contributions-v1" },
        { version = 9, id = "009_outbox_dead_letter", file = "sql/009_outbox_dead_letter.sql", checksum = "civicos-009-outbox-dead-letter-v1" },
        { version = 10, id = "010_retention_indexes", file = "sql/010_retention_indexes.sql", checksum = "civicos-010-retention-indexes-v1" },
    },
}

local requiredTables = {
    "civicos_schema_version",
    "civicos_requests",
    "civicos_request_comments",
    "civicos_request_activity",
    "civicos_workorders",
    "civicos_workorder_assignments",
    "civicos_workorder_dependencies",
    "civicos_employees",
    "civicos_employee_certifications",
    "civicos_departments",
    "civicos_sla_events",
    "civicos_escalations",
    "civicos_inspections",
    "civicos_evidence",
    "civicos_audit_logs",
    "civicos_notifications",
    "civicos_crews",
    "civicos_crew_members",
    "civicos_contributions",
    "civicos_outbox",
    "civicos_idempotency",
}

local function resultError(message, details)
    if CivicOS.Result and CivicOS.Result.err then
        return CivicOS.Result.err("DB_MIGRATION_FAILED", message, details)
    end
    return { ok = false, error = { code = "DB_MIGRATION_FAILED", message = message, details = details or {} } }
end

local function readFile(file)
    if type(LoadResourceFile) ~= "function" then
        return nil, "LoadResourceFile is unavailable"
    end
    local resource = type(GetCurrentResourceName) == "function" and GetCurrentResourceName() or "gnsh-civicos"
    local contents = LoadResourceFile(resource, file)
    if type(contents) ~= "string" or contents == "" then
        return nil, string.format("Migration file is missing or empty: %s", file)
    end
    return contents
end

local function trim(value)
    return (value:gsub("^%s+", ""):gsub("%s+$", ""))
end

-- oxmysql's query endpoint executes one statement at a time unless the
-- connection explicitly enables multipleStatements. Keep migrations portable
-- by splitting on semicolons before sending them to the adapter. The scanner
-- preserves semicolons inside quoted SQL values.
local function splitStatements(sql)
    local statements, buffer = {}, {}
    local quote, index = nil, 1

    local function flush()
        local statement = trim(table.concat(buffer))
        if statement ~= "" then statements[#statements + 1] = statement end
        buffer = {}
    end

    while index <= #sql do
        local character = sql:sub(index, index)
        if quote then
            buffer[#buffer + 1] = character
            if character == "\\" and index < #sql then
                index = index + 1
                buffer[#buffer + 1] = sql:sub(index, index)
            elseif character == quote then
                local escapedQuote = sql:sub(index + 1, index + 1)
                if escapedQuote == quote then
                    index = index + 1
                    buffer[#buffer + 1] = escapedQuote
                else
                    quote = nil
                end
            end
        elseif character == "'" or character == '"' or character == "`" then
            quote = character
            buffer[#buffer + 1] = character
        elseif character == ";" then
            flush()
        else
            buffer[#buffer + 1] = character
        end
        index = index + 1
    end
    flush()
    return statements
end

local function logger(level, message, context)
    if CivicOS.Logger and type(CivicOS.Logger[level]) == "function" then
        CivicOS.Logger[level]("DB", message, context)
    end
end

function Migrations.ensureVersionTable()
    if not CivicOS.DatabaseAdapter then
        return resultError("Database adapter is not registered.")
    end
    local result = CivicOS.DatabaseAdapter:query([[CREATE TABLE IF NOT EXISTS civicos_schema_version (
        version INT NOT NULL PRIMARY KEY,
        migration_id VARCHAR(120) NOT NULL,
        checksum VARCHAR(128) NOT NULL,
        applied_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;]])
    return result
end

function Migrations.currentVersion()
    local result = CivicOS.DatabaseAdapter:scalar("SELECT COALESCE(MAX(version), 0) FROM civicos_schema_version")
    if not result.ok then
        return result
    end
    return { ok = true, data = tonumber(result.data) or 0 }
end

function Migrations.apply(definition)
    local sql, readError = readFile(definition.file)
    if not sql then
        return resultError(readError, { migration = definition.id })
    end

    local statements = splitStatements(sql)
    if #statements == 0 then
        return resultError("Migration file contains no SQL statements.", { migration = definition.id })
    end
    for statementIndex, statement in ipairs(statements) do
        local applied = CivicOS.DatabaseAdapter:query(statement)
        if not applied.ok then
            logger("error", "Migration failed.", {
                migration = definition.id,
                statement = statementIndex,
            })
            return applied
        end
    end
    local recorded = CivicOS.DatabaseAdapter:query(
        "INSERT INTO civicos_schema_version (version, migration_id, checksum) VALUES (?, ?, ?)",
        { definition.version, definition.id, definition.checksum }
    )
    if not recorded.ok then
        return recorded
    end
    logger("info", "Migration applied.", { migration = definition.id, version = definition.version })
    return { ok = true, data = definition.version }
end

function Migrations.verifyRequiredTables()
    if not CivicOS.DatabaseAdapter then
        return resultError("Database adapter is not registered.")
    end
    local result = CivicOS.DatabaseAdapter:query([[SELECT table_name
        FROM information_schema.tables
        WHERE table_schema = DATABASE()
          AND table_name IN (
              'civicos_schema_version', 'civicos_requests',
              'civicos_request_comments', 'civicos_request_activity',
              'civicos_workorders', 'civicos_workorder_assignments',
              'civicos_workorder_dependencies', 'civicos_employees',
              'civicos_employee_certifications', 'civicos_departments',
              'civicos_sla_events', 'civicos_escalations',
              'civicos_inspections', 'civicos_evidence',
              'civicos_audit_logs', 'civicos_notifications',
              'civicos_crews', 'civicos_crew_members',
              'civicos_contributions', 'civicos_outbox',
              'civicos_idempotency'
          )]])
    if not result.ok then return result end

    local found = {}
    for _, row in ipairs(result.data or {}) do
        local name = row.table_name or row.TABLE_NAME
        if type(name) == "string" then found[string.lower(name)] = true end
    end
    local missing = {}
    for _, name in ipairs(requiredTables) do
        if not found[name] then missing[#missing + 1] = name end
    end
    if #missing > 0 then
        return resultError(
            "Required CivicOS tables are missing: " .. table.concat(missing, ", "),
            { missingCount = #missing }
        )
    end
    return { ok = true, data = { tables = #requiredTables } }
end

function Migrations.run()
    if not CivicOS.DatabaseAdapter then
        return resultError("Database adapter is not registered.")
    end
    local tableResult = Migrations.ensureVersionTable()
    if not tableResult.ok then
        return tableResult
    end
    local current = Migrations.currentVersion()
    if not current.ok then
        return current
    end
    for _, definition in ipairs(Migrations.definitions) do
        if definition.version > current.data then
            local applied = Migrations.apply(definition)
            if not applied.ok then
                return applied
            end
            current = { ok = true, data = definition.version }
        end
    end
    return { ok = true, data = current.data }
end

CivicOS.Migrations = Migrations
return Migrations

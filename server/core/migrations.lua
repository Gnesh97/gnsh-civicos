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
    },
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
    local applied = CivicOS.DatabaseAdapter:query(sql)
    if not applied.ok then
        logger("error", "Migration failed.", { migration = definition.id })
        return applied
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

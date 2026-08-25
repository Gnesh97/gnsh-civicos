local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS

local Config = {
    Framework = {
        Provider = "auto",
        DutyMode = "auto",
    },

    Locale = "en",
    FallbackLocale = "en",

    Logging = {
        Level = "info",
        IncludeTimestamp = true,
        IncludeContext = true,
    },

    Database = {
        Provider = "oxmysql",
        QueryTimingWarningMs = 250,
        MigrationOnStart = true,
    },

    Security = {
        StrictConfig = true,
        ValidateUnknownFields = true,
        RejectAmbiguousFramework = true,
    },

    RateLimits = {
        request_create = { windowSeconds = 60, maxRequests = 5 },
        request_comment = { windowSeconds = 60, maxRequests = 10 },
        generic_callback = { windowSeconds = 10, maxRequests = 30 },
    },

    Cache = {
        Enabled = true,
        ActiveStateTtlSeconds = 30,
    },

    FieldOperations = {
        ActionTokenTtlSeconds = 30,
        DefaultActionRadius = 4.0,
        AllowNoInventory = true,
        MaxActionPayloadBytes = 4096,
    },

    NUI = {
        RequestTimeoutMs = 15000,
    },

    Scheduler = {
        IntervalMs = 1000,
        MaxJobsPerTick = 25,
    },

    SLA = {
        WarningLeadSeconds = 300,
        BatchSize = 100,
    },

    Evidence = {
        MaxUriLength = 2048,
        AllowedDomains = {},
        RetainDays = 30,
    },

    Outbox = {
        MaxAttempts = 10,
        BatchSize = 50,
    },

    Recovery = {
        DisconnectGraceSeconds = 300,
        MaxRecoveryBatch = 500,
    },

    Retention = {
        DeliveredOutboxDays = 7,
        IdempotencyDays = 2,
        AuditDays = 90,
        EvidenceDays = 30,
        IntervalMs = 3600000,
    },
}

CivicOS.Config = Config
return Config

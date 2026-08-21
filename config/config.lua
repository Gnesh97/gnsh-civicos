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
}

CivicOS.Config = Config
return Config

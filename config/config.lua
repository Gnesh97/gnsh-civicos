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

    Cache = {
        Enabled = true,
        ActiveStateTtlSeconds = 30,
    },
}

CivicOS.Config = Config
return Config

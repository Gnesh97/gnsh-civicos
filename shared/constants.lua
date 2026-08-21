-- CivicOS immutable contract constants.

local Constants = {
    CIVICOS_VERSION = "0.1.0",
    CONTRACT_VERSION = 1,
    REFERENCE_PREFIX = "311",
    UTC = "UTC",

    Limits = {
        REQUEST_TITLE = 120,
        REQUEST_DESCRIPTION = 4000,
        COMMENT_BODY = 2000,
        METADATA_BYTES = 16384,
        PUBLIC_PAGE_SIZE = 50,
        MAX_PAGE_SIZE = 100,
    },

    Security = {
        ACTION_TOKEN_TTL_SECONDS = 60,
        DEFAULT_RATE_LIMIT_WINDOW_SECONDS = 60,
        DEFAULT_RATE_LIMIT_MAX_REQUESTS = 10,
        MAX_DISTANCE_TOLERANCE_METERS = 5.0,
    },

    Time = {
        SECONDS_PER_MINUTE = 60,
        SECONDS_PER_HOUR = 3600,
        SECONDS_PER_DAY = 86400,
    },

    Framework = {
        SUPPORTED = { "qbcore", "qbox", "esx", "standalone" },
        DUTY_MODES = { "auto", "framework", "civicos" },
    },
}

return Constants

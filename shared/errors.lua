-- Stable, non-sensitive CivicOS error catalogue.

local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS

local Errors = {
    DOMAIN_REASON = "DOMAIN_REASON",

    Codes = {
        INVALID_INPUT = "CORE_INVALID_INPUT",
        UNAUTHENTICATED = "AUTH_UNAUTHENTICATED",
        FORBIDDEN = "AUTH_FORBIDDEN",
        NOT_FOUND = "CORE_NOT_FOUND",
        INVALID_STATE = "CORE_INVALID_STATE",
        VERSION_CONFLICT = "CORE_VERSION_CONFLICT",
        RATE_LIMITED = "SECURITY_RATE_LIMITED",
        TOKEN_INVALID = "SECURITY_TOKEN_INVALID",
        TOKEN_REPLAYED = "SECURITY_TOKEN_REPLAYED",
        OUT_OF_RANGE = "FIELD_OUT_OF_RANGE",
        MISSING_ITEM = "INVENTORY_MISSING_ITEM",
        DUPLICATE = "REQUEST_DUPLICATE",
        PROVIDER_UNAVAILABLE = "INTEGRATION_PROVIDER_UNAVAILABLE",
        MIGRATION_FAILED = "DB_MIGRATION_FAILED",
        INTERNAL_ERROR = "CORE_INTERNAL_ERROR",
    },

    Messages = {
        CORE_INVALID_INPUT = "The submitted data is invalid.",
        AUTH_UNAUTHENTICATED = "Authentication is required.",
        AUTH_FORBIDDEN = "You do not have permission for this action.",
        CORE_NOT_FOUND = "The requested resource was not found.",
        CORE_INVALID_STATE = "The requested state transition is not allowed.",
        CORE_VERSION_CONFLICT = "The resource changed; refresh and retry.",
        SECURITY_RATE_LIMITED = "Too many requests. Try again later.",
        SECURITY_TOKEN_INVALID = "The action token is invalid or expired.",
        SECURITY_TOKEN_REPLAYED = "The action token was already used.",
        FIELD_OUT_OF_RANGE = "The actor is outside the allowed work radius.",
        INVENTORY_MISSING_ITEM = "Required item is not available.",
        REQUEST_DUPLICATE = "A matching request already exists.",
        INTEGRATION_PROVIDER_UNAVAILABLE = "The integration provider is unavailable.",
        DB_MIGRATION_FAILED = "Database migration failed.",
        CORE_INTERNAL_ERROR = "An internal error occurred.",
    },
}

CivicOS.Errors = Errors
return Errors

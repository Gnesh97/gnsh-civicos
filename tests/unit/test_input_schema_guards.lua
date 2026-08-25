-- Regression coverage for enum and metadata validation at client/API boundaries.
-- Run from the resource root with: lua tests/unit/test_input_schema_guards.lua

local function errorResult(code, message, details)
    return { ok = false, error = { code = code, message = message, details = details or {} } }
end

_G.json = {
    encode = function(value)
        if value and value.tooLarge then return string.rep("x", 20) end
        return "{}"
    end,
}

_G.CivicOS = {
    Result = { err = errorResult },
    Constants = {
        Limits = {
            METADATA_BYTES = 8,
            REQUEST_TITLE = 120,
            REQUEST_DESCRIPTION = 4000,
        },
        REFERENCE_PREFIX = "311",
    },
    Enums = {
        Priority = {
            LOW = "low",
            NORMAL = "normal",
            HIGH = "high",
            URGENT = "urgent",
            CRITICAL = "critical",
        },
    },
}

local validation = dofile("server/security/validation.lua")
assert(validation.metadata({ safe = true }, "metadata").ok, "valid metadata should pass")
local large = validation.metadata({ tooLarge = true }, "metadata")
assert(not large.ok and large.error.code == "CORE_INVALID_INPUT", "oversized metadata must be rejected")

local cyclic = {}
cyclic.self = cyclic
local cycleResult = validation.metadata(cyclic, "metadata")
assert(not cycleResult.ok and cycleResult.error.code == "CORE_INVALID_INPUT", "cyclic metadata must be rejected")

CivicOS.ServiceCatalog = {
    list = function()
        return { { code = "traffic_signal_failure", category = "traffic_signal_failure" } }
    end,
}
CivicOS.ServiceCatalogService = {
    get = function()
        return {
            ok = true,
            data = {
                code = "traffic_signal_failure",
                category = "traffic_signal_failure",
                subcategory = nil,
                defaultDepartment = "dot",
                defaultPriority = "normal",
                duplicate = { windowSeconds = 60, radius = 10 },
            },
        }
    end,
}

local request = dofile("server/services/request_service.lua")
local invalidPriority = request:create(1, {
    serviceCode = "traffic_signal_failure",
    priority = "not-a-priority",
    title = "A valid title",
    description = "A valid description",
    location = { x = 1, y = 2, z = 3 },
})
assert(not invalidPriority.ok and invalidPriority.error.code == "CORE_INVALID_INPUT", "unknown priority must be rejected")

print("input schema guard regression: PASS")

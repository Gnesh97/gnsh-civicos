-- Regression test for the health check preserving the config validator call contract.
-- Run from the resource root with: lua tests/unit/test_health_config.lua

local expectedConfig = {
    Framework = { Provider = "auto", DutyMode = "auto" },
    Locale = "en",
}

_G.CivicOS = {
    Config = expectedConfig,
    Validation = {
        config = function(config)
            assert(config == expectedConfig, "health check must pass the config table to Validation.config")
            return { ok = true, data = config }
        end,
    },
    DatabaseAdapter = {
        health = function() return { ok = true } end,
    },
    Migrations = {
        currentVersion = function() return { ok = true, data = 10 } end,
    },
    Scheduler = { running = true, jobs = {} },
    ProviderCapabilities = {},
    PublicExports = {},
    Bootstrap = { state = "READY" },
    Version = { version = "0.1.0" },
}

dofile("server/services/health_service.lua")

local result = CivicOS.HealthService:check(0, false)
assert(result.ok == true, "health check should return a successful result")
assert(result.data.status == "healthy", "valid config and database should report healthy")
assert(result.data.config.valid == true, "health check should report the config as valid")
assert(next(result.data.config.errors) == nil, "valid config should not report validation errors")

print("Health config validation regression: PASS")

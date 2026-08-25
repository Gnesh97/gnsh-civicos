-- Regression test for restoring a token after a downstream transaction fails.
-- Run from the resource root with: lua tests/unit/test_action_tokens.lua

_G.CivicOS = {
    Result = {
        err = function(code, message)
            return { ok = false, error = { code = code, message = message } }
        end,
    },
    Config = { FieldOperations = { ActionTokenTtlSeconds = 30 } },
}
_G.GetGameTimer = function() return 1000 end

local tokens = dofile("server/security/action_tokens.lua")
local issued = tokens:issue(42, 7, "repair", 2)
assert(issued.ok and type(issued.data.token) == "string", "token should be issued")

local consumed = tokens:consume(42, 7, "repair", issued.data.token, 2)
assert(consumed.ok and consumed.data.entry and consumed.data.token == issued.data.token, "consumption should return rollback state")
assert(not tokens:consume(42, 7, "repair", issued.data.token, 2).ok, "consumed token must not be replayable")

local restored = tokens:restore(consumed.data)
assert(restored.ok, "consumed token should be restorable before expiry")
assert(tokens:consume(42, 7, "repair", issued.data.token, 2).ok, "restored token should be usable again")

print("action token rollback regression: PASS")

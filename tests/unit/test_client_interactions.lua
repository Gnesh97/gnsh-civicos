-- Regression test for target-zone registration failures.
-- Run from the resource root with: lua tests/unit/test_client_interactions.lua

local removed = 0
local nextZone = nil

_G.CivicOS = {
    Target = {
        capabilities = { interactions = true },
        addBoxZone = function()
            return nextZone
        end,
        removeZone = function(id)
            assert(id == "zone-1", "clear should remove the registered target zone")
            removed = removed + 1
        end,
    },
}

local interactions = dofile("client/interactions.lua")
local workorder = { id = 7, version = 1, location = { x = 1, y = 2, z = 3 } }

assert(interactions:register(workorder, "inspect") == nil, "failed target registration should return nil")
assert(#interactions.zones == 0, "failed target registration must not retain a dead zone")

nextZone = "zone-1"
assert(interactions:register(workorder, "repair") == "zone-1", "successful target registration should return zone id")
assert(#interactions.zones == 1, "successful target registration should be tracked")
interactions:clear()
assert(removed == 1 and #interactions.zones == 0, "clear should remove and forget active zones")

print("client interaction registration regression: PASS")

-- Regression test for the QBCore export call contract.
-- Run from the resource root with: lua tests/unit/test_qbcore_player_lookup.lua

local player = {
    PlayerData = {
        citizenid = "citizen-42",
        charinfo = { firstname = "Test", lastname = "Player" },
        job = { name = "unemployed", label = "Unemployed", grade = { level = 0, name = "none" }, onduty = false },
    },
}

local function callbacks()
    return { loaded = {}, unloaded = {}, jobChanged = {}, dutyChanged = {} }
end

_G.CivicOS = {
    FrameworkInterface = {
        new = function(name)
            return { name = name, capabilities = {} }
        end,
        identity = function(source, persistentIdentifier, characterId, displayName, framework, job)
            return {
                source = source,
                persistentIdentifier = persistentIdentifier,
                characterId = characterId,
                displayName = displayName,
                framework = framework,
                job = job,
            }
        end,
    },
    FrameworkShared = {
        callbacks = callbacks,
        capabilities = function(value) return value end,
        dutyMode = function() return "framework" end,
        emit = function() end,
        identity = function(source, data, framework)
            return {
                source = source,
                persistentIdentifier = data.citizenid,
                characterId = data.citizenid,
                displayName = "Test Player",
                framework = framework,
                job = { name = "unemployed", label = "Unemployed", grade = 0, gradeName = "none", onDuty = false },
            }
        end,
        job = function(job)
            return {
                name = job and job.name or "unemployed",
                label = job and job.label or "Unemployed",
                grade = job and job.grade and job.grade.level or 0,
                gradeName = job and job.grade and job.grade.name or "none",
                onDuty = job and job.onduty == true or false,
            }
        end,
    },
}

_G.exports = {
    ["qb-core"] = {
        GetCoreObject = function(...)
            assert(select("#", ...) == 0, "GetCoreObject must be called without an export self argument")
            return {
                Functions = {
                    GetPlayer = function(source)
                        assert(source == 42, "QBCore player source should be normalized to a number")
                        return player
                    end,
                },
            }
        end,
    },
}

local adapter = dofile("server/adapters/framework/qbcore.lua")

assert(adapter.isPlayerLoaded("42"), "QBCore player lookup should accept string sources")
local identity = adapter.getPlayer("42")
assert(identity.persistentIdentifier == "citizen-42", "QBCore identity should use PlayerData.citizenid")

print("QBCore player lookup regression: PASS")

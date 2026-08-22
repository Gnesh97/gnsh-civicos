-- Regression test for mapping QBCore god/admin permissions to CivicOS SYSTEM_ADMIN.
-- Run from the resource root with: lua tests/unit/test_qbcore_admin_role.lua

local player = {
    PlayerData = {
        citizenid = "admin-42",
        charinfo = { firstname = "Admin", lastname = "Player" },
        job = { name = "unemployed", label = "Unemployed", grade = { level = 0, name = "none" }, onduty = false },
    },
}

local function callbacks()
    return { loaded = {}, unloaded = {}, jobChanged = {}, dutyChanged = {} }
end

_G.CivicOS = {
    FrameworkInterface = {
        new = function(name) return { name = name, capabilities = {} } end,
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
                displayName = "Admin Player",
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

local qbResource = {}
function qbResource:GetCoreObject()
    return {
        Functions = {
            GetPlayer = function() return player end,
            HasPermission = function(_, permission)
                return permission == "god"
            end,
        },
    }
end
function qbResource:GetPlayer() return player end

_G.exports = { ["qb-core"] = qbResource }

local adapter = dofile("server/adapters/framework/qbcore.lua")
local identity = adapter.getPlayer(42)

assert(identity.isAdmin == true, "QBCore god permission should mark the identity as admin")

_G.CivicOS.Permissions = { JobRoleMapping = {} }
_G.CivicOS.DepartmentService = { isSupervisor = function() return { ok = true, data = false } end }
dofile("server/security/authorization.lua")

assert(CivicOS.Authorization:roleFor(identity) == "SYSTEM_ADMIN", "framework admin should map to SYSTEM_ADMIN")

print("QBCore admin role regression: PASS")

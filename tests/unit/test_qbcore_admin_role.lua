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

_G.IsPlayerAceAllowed = function(source, permission)
    return source == 99 and permission == "admin"
end

local aceOnlyIdentity = {
    source = 99,
    isAdmin = false,
    job = { name = "unemployed", grade = 0, gradeName = "none" },
}

assert(
    CivicOS.Authorization:roleFor(aceOnlyIdentity) == "SYSTEM_ADMIN",
    "direct FiveM admin ACE should map to SYSTEM_ADMIN even without adapter metadata"
)

_G.IsPlayerAceAllowed = function()
    return false
end
_G.GetPlayerIdentifiers = function()
    return {}
end
_G.IsPrincipalAceAllowed = function()
    return false
end

local revokedIdentity = {
    source = 99,
    isAdmin = true,
    job = { name = "unemployed", grade = 0, gradeName = "none" },
}
CivicOS.Framework = {
    isAdmin = function(source)
        assert(source == 99, "live framework admin lookup should use the player source")
        return false
    end,
}

assert(
    CivicOS.Authorization:roleFor(revokedIdentity) == "CITIZEN",
    "live framework revocation should override stale framework admin metadata"
)

local liveFrameworkIdentity = {
    source = 97,
    isAdmin = false,
    job = { name = "unemployed", grade = 0, gradeName = "none" },
}
CivicOS.Framework.isAdmin = function(source)
    return source == 97
end
assert(
    CivicOS.Authorization:roleFor(liveFrameworkIdentity) == "SYSTEM_ADMIN",
    "a live framework admin decision should map to SYSTEM_ADMIN when ACE checks are false"
)

CivicOS.Framework = nil
local frameworkOnlyIdentity = {
    source = 98,
    isAdmin = true,
    job = { name = "unemployed", grade = 0, gradeName = "none" },
}
assert(
    CivicOS.Authorization:roleFor(frameworkOnlyIdentity) == "SYSTEM_ADMIN",
    "framework admin metadata should remain valid when no live framework resolver exists"
)

_G.GetConvar = function(name, default)
    assert(name == "civicos_global_admin_identifiers", "authorization should read the CivicOS admin convar")
    assert(default == "", "authorization should provide an empty convar fallback")
    return "license:configured-admin"
end
_G.GetPlayerIdentifiers = function(source)
    assert(source == 76 or source == 77, "identifier lookup should use the live player source")
    if source == 76 then return { "license:configured-admin" } end
    return { "license:admin-license", "fivem:admin-account" }
end
_G.IsPrincipalAceAllowed = function(principal, permission)
    return principal == "identifier.license:admin-license" and permission == "god"
end

local identifierAceIdentity = {
    source = 77,
    isAdmin = false,
    job = { name = "unemployed", grade = 0, gradeName = "none" },
}

assert(
    CivicOS.Authorization:roleFor(identifierAceIdentity) == "SYSTEM_ADMIN",
    "identifier-backed FiveM ACE should map to SYSTEM_ADMIN when the player principal is not linked"
)

local convarIdentity = {
    source = 76,
    isAdmin = false,
    job = { name = "unemployed", grade = 0, gradeName = "none" },
}
_G.IsPrincipalAceAllowed = function()
    return false
end
assert(
    CivicOS.Authorization:roleFor(convarIdentity) == "SYSTEM_ADMIN",
    "server convar identifiers should map to SYSTEM_ADMIN without ACE metadata"
)
_G.GetConvar = nil
_G.IsPrincipalAceAllowed = function(principal, permission)
    return principal == "identifier.license:admin-license" and permission == "god"
end

CivicOS.Permissions.Roles = {
    SYSTEM_ADMIN = {
        scope = "global",
        permissions = { "system.config.manage" },
    },
}
CivicOS.EmployeeService = {
    get = function(_, source)
        assert(source == 77, "authorization should resolve the requesting player")
        return { ok = true, data = identifierAceIdentity }
    end,
}

local authorization = CivicOS.Authorization:can(77, "system.config.manage", {})
assert(authorization.ok == true, "identifier-backed admin should pass the diagnostics permission check")
assert(authorization.data.role == "SYSTEM_ADMIN", "diagnostics authorization should retain the system admin role")

print("QBCore admin role regression: PASS")

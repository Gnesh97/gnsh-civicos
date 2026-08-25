-- Single-player QBCore contract smoke test.
-- The multiplayer/reconnect matrix remains a release-gate exercise; this spec
-- verifies the normalized identity, native duty, money, and lifecycle boundary.

local handlers = {}
local player = {
    PlayerData = {
        citizenid = "qb-citizen-42",
        charinfo = { firstname = "QB", lastname = "Technician" },
        job = { name = "publicworks", label = "Public Works", grade = { level = 2, name = "technician" }, onduty = false },
        money = { cash = 150, bank = 800 },
    },
}
player.Functions = {
    GetMoney = function(_, account) return player.PlayerData.money[account] or 0 end,
    AddMoney = function(_, account, amount) player.PlayerData.money[account] = (player.PlayerData.money[account] or 0) + amount; return true end,
    RemoveMoney = function(_, account, amount) player.PlayerData.money[account] = (player.PlayerData.money[account] or 0) - amount; return true end,
    SetJobDuty = function(_, state) player.PlayerData.job.onduty = state == true; return true end,
}

local core = { usable = {}, dutyCalls = 0 }
function core:GetPlayer(source) assert(source == 42, "QBCore GetPlayer must receive the numeric source"); return player end
function core:HasPermission(source, permission) return source == 42 and permission == "god" end
function core:CreateUseableItem(item, callback) self.usable[item] = callback end
local qbResource = {}
function qbResource:GetPlayer(source) return core:GetPlayer(source) end
function qbResource:GetCoreObject() return { Functions = { GetPlayer = function(source) return core:GetPlayer(source) end, HasPermission = function(source, permission) return core:HasPermission(source, permission) end, CreateUseableItem = function(item, callback) return core:CreateUseableItem(item, callback) end } } end

local function callbacks()
    return { loaded = {}, unloaded = {}, jobChanged = {}, dutyChanged = {} }
end
local function job(data)
    local grade = type(data.grade) == "table" and data.grade.level or data.grade
    return { name = data.name or "unemployed", label = data.label or "Unemployed", grade = tonumber(grade) or 0, gradeName = type(data.grade) == "table" and data.grade.name or "none", onDuty = data.onduty == true }
end

_G.CivicOS = {
    FrameworkInterface = {
        new = function(name) return { name = name, capabilities = {} } end,
        identity = function(source, persistentIdentifier, characterId, displayName, framework, normalizedJob)
            return { source = source, persistentIdentifier = persistentIdentifier, characterId = characterId, displayName = displayName, framework = framework, job = normalizedJob }
        end,
    },
    FrameworkShared = {
        callbacks = callbacks,
        dutyMode = function() return "framework" end,
        emit = function(list, value) for _, callback in ipairs(list) do callback(value) end end,
        capabilities = function(value) return value end,
        job = job,
        identity = function(source, data, framework)
            data = type(data) == "table" and data or {}
            return CivicOS.FrameworkInterface.identity(source, data.citizenid, data.citizenid, data.charinfo.firstname .. " " .. data.charinfo.lastname, framework, job(data.job))
        end,
    },
}
_G.exports = { ["qb-core"] = qbResource }
_G.AddEventHandler = function(name, callback)
    handlers[name] = handlers[name] or {}
    handlers[name][#handlers[name] + 1] = callback
end
_G.IsPlayerAceAllowed = function() return false end

local adapter = dofile("server/adapters/framework/qbcore.lua")
local identity = adapter.getPlayer("42")
assert(identity.framework == "qbcore" and identity.persistentIdentifier == "qb-citizen-42", "QBCore identity must be normalized")
assert(identity.job.name == "publicworks" and identity.job.grade == 2, "QBCore job must be normalized")
assert(identity.isAdmin == true, "QBCore god permission must be available at the adapter boundary")
assert(adapter.getMoney(42, "cash") == 150, "QBCore money read must be available")
assert(adapter.setDuty(42, true) == true and adapter.isOnDuty(42), "QBCore native duty must be writable")
assert(adapter.registerUsableItem("civicos_tool", function() end) == true, "QBCore usable item capability must be available")
assert(core.usable.civicos_tool ~= nil, "QBCore usable item callback must be registered")

local loaded, unloaded, jobChanged, dutyChanged = 0, 0, 0, 0
adapter.onPlayerLoaded(function(value) loaded = loaded + 1; assert(value.source == 42) end)
adapter.onPlayerUnloaded(function(source) unloaded = unloaded + 1; assert(source == 42) end)
adapter.onJobChanged(function(value) jobChanged = jobChanged + 1; assert(value.source == 42) end)
adapter.onDutyChanged(function(value) dutyChanged = dutyChanged + 1; assert(value.source == 42) end)
local function fire(name, ...)
    for _, callback in ipairs(handlers[name] or {}) do callback(...) end
end
fire("QBCore:Server:OnPlayerLoaded", 42)
fire("QBCore:Server:OnPlayerUnload", 42)
fire("QBCore:Server:OnJobUpdate", 42, player.PlayerData.job)
assert(loaded == 1 and unloaded == 1 and jobChanged == 1 and dutyChanged == 1, "QBCore lifecycle events must reach CivicOS callbacks")

print("QBCore adapter contract: PASS")

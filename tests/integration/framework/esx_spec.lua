-- Single-player ESX Legacy contract smoke test.
-- The multiplayer/reconnect matrix remains a release-gate exercise; this spec
-- only verifies normalized identity, fallback duty, money, and lifecycle hooks.

local handlers = {}
local xPlayer = {
    identifier = "license:esx-42",
    job = { name = "publicworks", label = "Public Works", grade = 2, grade_name = "technician" },
    accounts = { money = 100, bank = 700 },
}
function xPlayer.getJob() return xPlayer.job end
function xPlayer.getName() return "ESX Technician" end
function xPlayer.getIdentifier() return xPlayer.identifier end
function xPlayer.getAccount(account) return { money = xPlayer.accounts[account] or 0 } end
function xPlayer.addAccountMoney(account, amount) xPlayer.accounts[account] = (xPlayer.accounts[account] or 0) + amount; return true end
function xPlayer.removeAccountMoney(account, amount) xPlayer.accounts[account] = (xPlayer.accounts[account] or 0) - amount; return true end

local esx = {}
function esx.getSharedObject(_) return esx end
function esx.GetPlayerFromId(source) assert(source == 42, "ESX player lookup must receive the numeric source"); return xPlayer end
function esx.RegisterUsableItem(item, callback) esx.usable = esx.usable or {}; esx.usable[item] = callback end

local function callbacks()
    return { loaded = {}, unloaded = {}, jobChanged = {}, dutyChanged = {} }
end

local function normalizedJob(data)
    return {
        name = data.name,
        label = data.label,
        grade = tonumber(data.grade) or 0,
        gradeName = data.grade_name,
        onDuty = false,
    }
end

_G.CivicOS = {
    FrameworkInterface = {
        new = function(name) return { name = name, capabilities = {} } end,
        identity = function(source, persistentIdentifier, characterId, displayName, framework, job)
            return { source = source, persistentIdentifier = persistentIdentifier, characterId = characterId, displayName = displayName, framework = framework, job = job }
        end,
    },
    FrameworkShared = {
        callbacks = callbacks,
        dutyMode = function() return "civicos" end,
        emit = function(list, value) for _, callback in ipairs(list) do callback(value) end end,
        capabilities = function(value) return value end,
        job = normalizedJob,
        identity = function(source, data, framework)
            return CivicOS.FrameworkInterface.identity(source, data.identifier, data.characterId, data.displayName, framework, normalizedJob(data.job))
        end,
    },
}
_G.exports = { es_extended = esx }
_G.AddEventHandler = function(name, callback) handlers[name] = callback end

local adapter = dofile("server/adapters/framework/esx.lua")
local identity = adapter.getPlayer(42)
assert(identity.framework == "esx", "ESX identity must expose the normalized provider name")
assert(identity.persistentIdentifier == "license:esx-42", "ESX identifier must be stable")
assert(identity.job.name == "publicworks" and identity.job.gradeName == "technician", "ESX job must be normalized")
assert(adapter.isPlayerLoaded(42), "ESX loaded check must resolve the player")
assert(adapter.getMoney(42, "money") == 100, "ESX account read must be normalized")
assert(adapter.addMoney(42, "money", 25, "test") == true and adapter.getMoney(42, "money") == 125, "ESX account add must be normalized")
assert(adapter.removeMoney(42, "money", 10, "test") == true and adapter.getMoney(42, "money") == 115, "ESX account remove must be normalized")
assert(adapter.isOnDuty(42) == false, "ESX starts off duty without native duty")
assert(adapter.setDuty(42, true) == true and adapter.isOnDuty(42), "ESX CivicOS duty fallback must be writable")

local usable = function() end
assert(adapter.registerUsableItem("civicos_tool", usable) == true, "ESX usable item capability must be available")
assert(esx.usable.civicos_tool == usable, "ESX usable item callback must be registered")

local loaded, unloaded, jobChanged = 0, 0, 0
adapter.onPlayerLoaded(function(value) loaded = loaded + 1; assert(value.framework == "esx") end)
adapter.onPlayerUnloaded(function(source) unloaded = unloaded + 1; assert(source == 42) end)
adapter.onJobChanged(function(value) jobChanged = jobChanged + 1; assert(value.source == 42) end)
adapter.onDutyChanged(function() end)
handlers["esx:playerLoaded"](42)
_G.source = 42
handlers["playerDropped"]()
handlers["esx:setJob"](42, xPlayer.job)
assert(loaded == 1 and unloaded == 1 and jobChanged == 1, "ESX lifecycle events must reach CivicOS callbacks")

print("ESX adapter contract: PASS")

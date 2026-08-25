-- Single-player Qbox contract smoke test.
-- The multiplayer/reconnect matrix remains a release-gate exercise; this spec
-- only verifies the adapter boundary with a deterministic qbx_core stub.

local handlers = {}
local player = {
    PlayerData = {
        citizenid = "qbox-citizen-42",
        charinfo = { firstname = "Qbox", lastname = "Technician" },
        job = { name = "publicworks", label = "Public Works", grade = { level = 2, name = "technician" }, onduty = false },
        money = { cash = 125, bank = 900 },
    },
}

local qbx = { usable = {}, dutyCalls = 0 }
function qbx:GetPlayer(source)
    assert(source == 42, "qbx GetPlayer must receive the numeric source")
    return player
end
function qbx:SetJobDuty(source, state)
    assert(source == 42, "qbx SetJobDuty must receive the numeric source")
    self.dutyCalls = self.dutyCalls + 1
    player.PlayerData.job.onduty = state == true
    return true
end
function qbx:GetMoney(source, account)
    assert(source == 42, "qbx GetMoney must receive the numeric source")
    return player.PlayerData.money[account]
end
function qbx:AddMoney(source, account, amount)
    player.PlayerData.money[account] = (player.PlayerData.money[account] or 0) + amount
    return true
end
function qbx:RemoveMoney(source, account, amount)
    player.PlayerData.money[account] = (player.PlayerData.money[account] or 0) - amount
    return true
end
function qbx:CreateUseableItem(item, callback)
    self.usable[item] = callback
end

local function callbacks()
    return { loaded = {}, unloaded = {}, jobChanged = {}, dutyChanged = {} }
end

local function job(data)
    data = type(data) == "table" and data or {}
    local grade = type(data.grade) == "table" and data.grade.level or data.grade
    return {
        name = data.name or "unemployed",
        label = data.label or "Unemployed",
        grade = tonumber(grade) or 0,
        gradeName = type(data.grade) == "table" and data.grade.name or "none",
        onDuty = data.onduty == true,
    }
end

_G.CivicOS = {
    FrameworkInterface = {
        new = function(name) return { name = name, capabilities = {} } end,
        identity = function(source, persistentIdentifier, characterId, displayName, framework, normalizedJob)
            return {
                source = source,
                persistentIdentifier = persistentIdentifier,
                characterId = characterId,
                displayName = displayName,
                framework = framework,
                job = normalizedJob,
            }
        end,
    },
    FrameworkShared = {
        callbacks = callbacks,
        dutyMode = function() return "framework" end,
        emit = function(list, value) for _, callback in ipairs(list) do callback(value) end end,
        capabilities = function(value) return value end,
        job = job,
        identity = function(source, data, framework)
            local normalized = type(data) == "table" and data or {}
            return CivicOS.FrameworkInterface.identity(
                source,
                normalized.citizenid,
                normalized.citizenid,
                (normalized.charinfo.firstname .. " " .. normalized.charinfo.lastname),
                framework,
                job(normalized.job)
            )
        end,
    },
}
_G.exports = { qbx_core = qbx }
_G.AddEventHandler = function(name, callback) handlers[name] = callback end

local adapter = dofile("server/adapters/framework/qbox.lua")
local identity = adapter.getPlayer("42")
assert(identity.framework == "qbox", "Qbox identity must expose the normalized provider name")
assert(identity.persistentIdentifier == "qbox-citizen-42", "Qbox citizen identity must be stable")
assert(identity.job.name == "publicworks" and identity.job.grade == 2, "Qbox job must be normalized")
assert(adapter.isPlayerLoaded("42"), "Qbox loaded check must resolve the player")
assert(adapter.getMoney(42, "cash") == 125, "Qbox money read must use the export contract")
assert(adapter.addMoney(42, "cash", 25, "test") == true and adapter.getMoney(42, "cash") == 150, "Qbox money add must be normalized")
assert(adapter.removeMoney(42, "cash", 10, "test") == true and adapter.getMoney(42, "cash") == 140, "Qbox money remove must be normalized")
assert(adapter.setDuty(42, true) == true and adapter.isOnDuty(42), "Qbox native duty must be writable")
assert(qbx.dutyCalls == 1, "Qbox adapter must call SetJobDuty")

local usable = function() end
assert(adapter.registerUsableItem("civicos_tool", usable) == true, "Qbox usable item capability must be available")
assert(qbx.usable.civicos_tool == usable, "Qbox usable item callback must be registered")

local loaded, unloaded, jobChanged, dutyChanged = 0, 0, 0, 0
adapter.onPlayerLoaded(function(value) loaded = loaded + 1; assert(value.framework == "qbox") end)
adapter.onPlayerUnloaded(function(source) unloaded = unloaded + 1; assert(source == 42) end)
adapter.onJobChanged(function(value) jobChanged = jobChanged + 1; assert(value.source == 42) end)
adapter.onDutyChanged(function(value) dutyChanged = dutyChanged + 1; assert(value.source == 42) end)

assert(type(handlers["QBCore:Server:OnPlayerLoaded"]) == "function", "Qbox must use its documented load event")
assert(type(handlers["QBCore:Server:OnPlayerUnload"]) == "function", "Qbox must use its documented unload event")
assert(type(handlers["QBCore:Server:OnJobUpdate"]) == "function", "Qbox must use its documented job event")
assert(type(handlers["QBCore:Server:SetDuty"]) == "function", "Qbox must use its documented duty event")
handlers["QBCore:Server:OnPlayerLoaded"](42)
handlers["QBCore:Server:OnPlayerUnload"](42)
handlers["QBCore:Server:OnJobUpdate"](42, player.PlayerData.job)
handlers["QBCore:Server:SetDuty"](42, true)
assert(loaded == 1 and unloaded == 1 and jobChanged == 1 and dutyChanged == 1, "Qbox lifecycle events must reach CivicOS callbacks")

print("Qbox adapter contract: PASS")

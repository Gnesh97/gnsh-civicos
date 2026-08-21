local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS
local Interface = CivicOS.FrameworkInterface
local Shared = CivicOS.FrameworkShared

local Adapter = Interface.new("esx")
local callbacks = Shared.callbacks()
local ESX
local internalDuty = {}

local function framework()
    if ESX then return ESX end
    if type(exports) == "table" and exports["es_extended"] and type(exports["es_extended"].getSharedObject) == "function" then
        local ok, value = pcall(exports["es_extended"].getSharedObject, exports["es_extended"])
        if ok then ESX = value end
    end
    return ESX
end

local function player(source)
    local current = framework()
    if current and type(current.GetPlayerFromId) == "function" then
        return current.GetPlayerFromId(source)
    end
    return nil
end

local function job(source)
    local current = player(source)
    local native = current and current.getJob and current.getJob() or current and current.job or {}
    local normalized = Shared.job(native)
    normalized.onDuty = internalDuty[source] == true
    return normalized
end

function Adapter.getPlayer(source)
    local current = player(source)
    local nativeJob = current and current.getJob and current.getJob() or current and current.job or {}
    local identity = Shared.identity(source, {
        identifier = current and current.identifier,
        characterId = current and (current.getIdentifier and current.getIdentifier() or current.identifier),
        displayName = current and current.getName and current.getName() or nil,
        job = nativeJob,
    }, "esx")
    identity.job.onDuty = internalDuty[source] == true
    return identity
end

function Adapter.isPlayerLoaded(source)
    return player(source) ~= nil
end

function Adapter.getIdentifier(source)
    local current = player(source)
    return current and current.identifier or nil
end

function Adapter.getCharacterId(source)
    return Adapter.getIdentifier(source)
end

function Adapter.getCharacterName(source)
    return Adapter.getPlayer(source).displayName
end

function Adapter.getJob(source)
    return job(source)
end

function Adapter.getJobName(source)
    return job(source).name
end

function Adapter.getJobGrade(source)
    return job(source).grade
end

function Adapter.getJobGradeName(source)
    return job(source).gradeName
end

function Adapter.isOnDuty(source)
    return internalDuty[source] == true
end

function Adapter.setDuty(source, state)
    internalDuty[source] = state == true
    Shared.emit(callbacks.dutyChanged, Adapter.getPlayer(source))
    return true
end

function Adapter.getMoney(source, account)
    local current = player(source)
    if current and type(current.getAccount) == "function" then
        local value = current.getAccount(account or "money")
        return value and (value.money or 0) or 0
    end
    return 0
end

function Adapter.addMoney(source, account, amount, reason)
    local current = player(source)
    if current and type(current.addAccountMoney) == "function" then
        return current.addAccountMoney(account or "money", amount, reason or "civicos")
    end
    return false
end

function Adapter.removeMoney(source, account, amount, reason)
    local current = player(source)
    if current and type(current.removeAccountMoney) == "function" then
        return current.removeAccountMoney(account or "money", amount, reason or "civicos")
    end
    return false
end

function Adapter.registerUsableItem(itemName, callback)
    local current = framework()
    if current and type(current.RegisterUsableItem) == "function" then
        current.RegisterUsableItem(itemName, callback)
        return true
    end
    return false
end

function Adapter.onPlayerLoaded(callback)
    callbacks.loaded[#callbacks.loaded + 1] = callback
    if type(AddEventHandler) == "function" then
        AddEventHandler("esx:playerLoaded", function(source)
            callback(Adapter.getPlayer(source))
        end)
    end
end

function Adapter.onPlayerUnloaded(callback)
    callbacks.unloaded[#callbacks.unloaded + 1] = callback
    if type(AddEventHandler) == "function" then
        AddEventHandler("playerDropped", function()
            callback(source)
        end)
    end
end

function Adapter.onJobChanged(callback)
    callbacks.jobChanged[#callbacks.jobChanged + 1] = callback
    if type(AddEventHandler) == "function" then
        AddEventHandler("esx:setJob", function(source)
            callback(Adapter.getPlayer(source))
        end)
    end
end

function Adapter.onDutyChanged(callback)
    callbacks.dutyChanged[#callbacks.dutyChanged + 1] = callback
end

function Adapter.getCapabilities()
    return Shared.capabilities({
        nativeDuty = false,
        usableItems = true,
        multipleAccounts = true,
        jobChangeEvents = true,
        dutyChangeEvents = true,
        playerLifecycleEvents = true,
    })
end

Adapter.capabilities = Adapter.getCapabilities()
CivicOS.FrameworkAdapters = CivicOS.FrameworkAdapters or {}
CivicOS.FrameworkAdapters.esx = Adapter
return Adapter

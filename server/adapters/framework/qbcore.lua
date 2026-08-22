local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS
local Interface = CivicOS.FrameworkInterface
local Shared = CivicOS.FrameworkShared

local Adapter = Interface.new("qbcore")
local callbacks = Shared.callbacks()
local QBCore
local internalDuty = {}
local adminPermissionLevels = { "god", "admin" }

local function resource()
    local ok, value = pcall(function()
        return exports["qb-core"]
    end)
    return ok and value or nil
end

local function core()
    if type(GetResourceState) == "function" and GetResourceState("qb-core") ~= "started" then
        QBCore = nil
        return nil
    end
    if QBCore then
        return QBCore
    end
    local qb = resource()
    if qb then
        local ok, value = pcall(function()
            return qb:GetCoreObject()
        end)
        if ok and type(value) == "table" and type(value.Functions) == "table" then
            QBCore = value
        end
    end
    return QBCore
end

local function player(source)
    local normalizedSource = tonumber(source) or source
    local qb = resource()
    if qb then
        local ok, value = pcall(function()
            return qb:GetPlayer(normalizedSource)
        end)
        if ok and value then
            return value
        end
    end
    local framework = core()
    if framework and framework.Functions and type(framework.Functions.GetPlayer) == "function" then
        local ok, value = pcall(framework.Functions.GetPlayer, normalizedSource)
        if ok then
            return value
        end
    end
    return nil
end

local function data(source)
    local current = player(source)
    return current and current.PlayerData or nil, current
end

function Adapter.hasPermission(source, permission)
    local framework = core()
    if framework and framework.Functions and type(framework.Functions.HasPermission) == "function" then
        local ok, allowed = pcall(function()
            return framework.Functions.HasPermission(tonumber(source) or source, permission)
        end)
        if ok and allowed == true then return true end
    end
    if type(IsPlayerAceAllowed) == "function" then
        local ok, allowed = pcall(IsPlayerAceAllowed, tonumber(source) or source, permission)
        if ok and allowed == true then return true end
    end
    return false
end

function Adapter.isAdmin(source)
    for _, permission in ipairs(adminPermissionLevels) do
        if Adapter.hasPermission(source, permission) then return true end
    end
    return false
end

function Adapter.getPlayer(source)
    local playerData = data(source)
    local identity = Shared.identity(source, playerData, "qbcore")
    identity.job.onDuty = Adapter.isOnDuty(source)
    identity.isAdmin = Adapter.isAdmin(source)
    return identity
end

function Adapter.isPlayerLoaded(source)
    return player(source) ~= nil
end

function Adapter.getIdentifier(source)
    local playerData = data(source)
    return playerData and (playerData.citizenid or playerData.license) or nil
end

function Adapter.getCharacterId(source)
    local playerData = data(source)
    return playerData and (playerData.citizenid or playerData.cid) or nil
end

function Adapter.getCharacterName(source)
    return Adapter.getPlayer(source).displayName
end

function Adapter.getJob(source)
    return Adapter.getPlayer(source).job
end

function Adapter.getJobName(source)
    return Adapter.getJob(source).name
end

function Adapter.getJobGrade(source)
    return Adapter.getJob(source).grade
end

function Adapter.getJobGradeName(source)
    return Adapter.getJob(source).gradeName
end

function Adapter.isOnDuty(source)
    if Shared.dutyMode() == "civicos" then
        return internalDuty[source] == true
    end
    local playerData = data(source)
    return Shared.job(playerData and playerData.job).onDuty == true
end

function Adapter.setDuty(source, state)
    if Shared.dutyMode() == "civicos" then
        internalDuty[source] = state == true
        Shared.emit(callbacks.dutyChanged, Adapter.getPlayer(source))
        return true
    end
    local current = player(source)
    if current and current.Functions and type(current.Functions.SetJobDuty) == "function" then
        current.Functions.SetJobDuty(state == true)
        return true
    end
    return false
end

function Adapter.getMoney(source, account)
    local current = player(source)
    if current and current.Functions and type(current.Functions.GetMoney) == "function" then
        return current.Functions.GetMoney(account or "cash") or 0
    end
    return 0
end

function Adapter.addMoney(source, account, amount, reason)
    local current = player(source)
    if current and current.Functions and type(current.Functions.AddMoney) == "function" then
        return current.Functions.AddMoney(account or "cash", amount, reason or "civicos")
    end
    return false
end

function Adapter.removeMoney(source, account, amount, reason)
    local current = player(source)
    if current and current.Functions and type(current.Functions.RemoveMoney) == "function" then
        return current.Functions.RemoveMoney(account or "cash", amount, reason or "civicos")
    end
    return false
end

function Adapter.registerUsableItem(itemName, callback)
    local framework = core()
    if framework and framework.Functions and type(framework.Functions.CreateUseableItem) == "function" then
        framework.Functions.CreateUseableItem(itemName, callback)
        return true
    end
    return false
end

function Adapter.onPlayerLoaded(callback)
    callbacks.loaded[#callbacks.loaded + 1] = callback
    if type(AddEventHandler) == "function" then
        AddEventHandler("QBCore:Server:OnPlayerLoaded", function(source)
            callback(Adapter.getPlayer(source))
        end)
    end
end

function Adapter.onPlayerUnloaded(callback)
    callbacks.unloaded[#callbacks.unloaded + 1] = callback
    if type(AddEventHandler) == "function" then
        AddEventHandler("QBCore:Server:OnPlayerUnload", function(source)
            callback(source)
        end)
    end
end

function Adapter.onJobChanged(callback)
    callbacks.jobChanged[#callbacks.jobChanged + 1] = callback
    if type(AddEventHandler) == "function" then
        AddEventHandler("QBCore:Server:OnJobUpdate", function(source)
            callback(Adapter.getPlayer(source))
        end)
    end
end

function Adapter.onDutyChanged(callback)
    callbacks.dutyChanged[#callbacks.dutyChanged + 1] = callback
    if type(AddEventHandler) == "function" then
        AddEventHandler("QBCore:Server:OnJobUpdate", function(source)
            callback(Adapter.getPlayer(source))
        end)
    end
end

function Adapter.getCapabilities()
    return Shared.capabilities({
        nativeDuty = true,
        usableItems = true,
        multipleAccounts = true,
        jobChangeEvents = true,
        dutyChangeEvents = true,
        playerLifecycleEvents = true,
    })
end

Adapter.capabilities = Adapter.getCapabilities()
CivicOS.FrameworkAdapters = CivicOS.FrameworkAdapters or {}
CivicOS.FrameworkAdapters.qbcore = Adapter
return Adapter

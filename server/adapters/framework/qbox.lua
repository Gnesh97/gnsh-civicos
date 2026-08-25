local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS
local Interface = CivicOS.FrameworkInterface
local Shared = CivicOS.FrameworkShared

local Adapter = Interface.new("qbox")
local callbacks = Shared.callbacks()
local internalDuty = {}

local function resource()
    local ok, value = pcall(function()
        return exports.qbx_core
    end)
    return ok and value or nil
end

local function player(source)
    local qbx = resource()
    if qbx and type(qbx.GetPlayer) == "function" then
        local normalizedSource = tonumber(source) or source
        local ok, value = pcall(function()
            return qbx:GetPlayer(normalizedSource)
        end)
        if ok then
            return value
        end
    end
    return nil
end

local function playerData(source)
    local current = player(source)
    return current and (current.PlayerData or current) or nil, current
end

function Adapter.getPlayer(source)
    local identity = Shared.identity(source, playerData(source), "qbox")
    identity.job.onDuty = Adapter.isOnDuty(source)
    return identity
end

function Adapter.isPlayerLoaded(source)
    return player(source) ~= nil
end

function Adapter.getIdentifier(source)
    local data = playerData(source)
    return data and (data.citizenid or data.license) or nil
end

function Adapter.getCharacterId(source)
    local data = playerData(source)
    return data and (data.citizenid or data.charid) or nil
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
    local currentData = playerData(source)
    return Shared.job(currentData and currentData.job).onDuty == true
end

function Adapter.setDuty(source, state)
    if Shared.dutyMode() == "civicos" then
        internalDuty[source] = state == true
        Shared.emit(callbacks.dutyChanged, Adapter.getPlayer(source))
        return true
    end
    local qbx = resource()
    if qbx and type(qbx.SetJobDuty) == "function" then
        local normalizedSource = tonumber(source) or source
        local ok, result = pcall(function()
            return qbx:SetJobDuty(normalizedSource, state == true)
        end)
        return ok and result ~= false
    end
    local current = player(source)
    if current and current.Functions and type(current.Functions.SetJobDuty) == "function" then
        current.Functions:SetJobDuty(state == true)
        return true
    end
    return false
end

function Adapter.getMoney(source, account)
    local qbx = resource()
    if qbx and type(qbx.GetMoney) == "function" then
        local normalizedSource = tonumber(source) or source
        local ok, value = pcall(function()
            return qbx:GetMoney(normalizedSource, account or "cash")
        end)
        if ok then return value or 0 end
    end
    local current = player(source)
    if current and current.Functions and type(current.Functions.GetMoney) == "function" then
        return current.Functions:GetMoney(account or "cash") or 0
    end
    return 0
end

function Adapter.addMoney(source, account, amount, reason)
    local qbx = resource()
    if qbx and type(qbx.AddMoney) == "function" then
        local normalizedSource = tonumber(source) or source
        local ok, value = pcall(function()
            return qbx:AddMoney(normalizedSource, account or "cash", amount, reason or "civicos")
        end)
        if ok then return value end
    end
    local current = player(source)
    if current and current.Functions and type(current.Functions.AddMoney) == "function" then
        return current.Functions:AddMoney(account or "cash", amount, reason or "civicos")
    end
    return false
end

function Adapter.removeMoney(source, account, amount, reason)
    local qbx = resource()
    if qbx and type(qbx.RemoveMoney) == "function" then
        local normalizedSource = tonumber(source) or source
        local ok, value = pcall(function()
            return qbx:RemoveMoney(normalizedSource, account or "cash", amount, reason or "civicos")
        end)
        if ok then return value end
    end
    local current = player(source)
    if current and current.Functions and type(current.Functions.RemoveMoney) == "function" then
        return current.Functions:RemoveMoney(account or "cash", amount, reason or "civicos")
    end
    return false
end

function Adapter.registerUsableItem(itemName, callback)
    local qbx = resource()
    if qbx and type(qbx.CreateUseableItem) == "function" then
        local ok = pcall(function()
            qbx:CreateUseableItem(itemName, callback)
        end)
        return ok
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
        AddEventHandler("QBCore:Server:SetDuty", function(source)
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
CivicOS.FrameworkAdapters.qbox = Adapter
return Adapter

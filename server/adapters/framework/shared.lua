local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS

local Shared = {}

function Shared.dutyMode()
    return CivicOS.Config and CivicOS.Config.Framework and CivicOS.Config.Framework.DutyMode or "auto"
end

function Shared.job(data)
    data = type(data) == "table" and data or {}
    local grade = data.grade
    if type(grade) == "table" then
        grade = grade.level or grade.value
    end
    return {
        name = data.name or "unemployed",
        label = data.label or data.grade_label or data.name or "Unemployed",
        grade = tonumber(grade) or 0,
        gradeName = data.gradeName or data.grade_name or data.grade_label or "none",
        onDuty = data.onduty == true or data.onDuty == true,
    }
end

function Shared.identity(source, playerData, framework)
    playerData = type(playerData) == "table" and playerData or {}
    local job = Shared.job(playerData.job)
    local persistentIdentifier = playerData.persistentIdentifier
        or playerData.citizenid
        or playerData.identifier
        or string.format("%s:%s", framework, tostring(source))
    local characterId = playerData.characterId or playerData.charid or playerData.citizenid or persistentIdentifier
    local displayName = playerData.displayName or playerData.name
    if not displayName and playerData.charinfo then
        displayName = ((playerData.charinfo.firstname or "") .. " " .. (playerData.charinfo.lastname or ""))
            :gsub("^%s+", ""):gsub("%s+$", "")
    end
    displayName = displayName or "Unknown"
    return CivicOS.FrameworkInterface.identity(source, persistentIdentifier, characterId, displayName, framework, job)
end

function Shared.capabilities(values)
    local capabilities = {
        nativeDuty = false,
        usableItems = false,
        multipleAccounts = false,
        jobChangeEvents = false,
        dutyChangeEvents = false,
        playerLifecycleEvents = false,
    }
    for key, value in pairs(values or {}) do
        capabilities[key] = value == true
    end
    return capabilities
end

local function resourceStarted(name)
    return type(GetResourceState) == "function" and GetResourceState(name) == "started"
end

Shared.resourceStarted = resourceStarted

local function notify(callbacks, payload)
    for _, callback in ipairs(callbacks or {}) do
        pcall(callback, payload)
    end
end

function Shared.callbacks()
    return { loaded = {}, unloaded = {}, jobChanged = {}, dutyChanged = {} }
end

function Shared.emit(callbackList, payload)
    notify(callbackList, payload)
end

CivicOS.FrameworkShared = Shared
return Shared

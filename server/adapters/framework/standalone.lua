local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS
local Interface = CivicOS.FrameworkInterface
local Shared = CivicOS.FrameworkShared

local Adapter = Interface.new("standalone")
local dutyState = {}
local callbacks = Shared.callbacks()

function Adapter.getPlayer(source)
    return Shared.identity(source, {
        identifier = string.format("standalone:%s", tostring(source)),
        characterId = string.format("standalone:%s", tostring(source)),
        displayName = string.format("Player %s", tostring(source)),
        job = { name = "citizen", label = "Citizen", grade = 0, gradeName = "citizen", onduty = dutyState[source] == true },
    }, "standalone")
end

function Adapter.isPlayerLoaded(source)
    return source ~= nil
end

function Adapter.getIdentifier(source)
    return Adapter.getPlayer(source).persistentIdentifier
end

function Adapter.getCharacterId(source)
    return Adapter.getPlayer(source).characterId
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
    return dutyState[source] == true
end

function Adapter.setDuty(source, state)
    dutyState[source] = state == true
    Shared.emit(callbacks.dutyChanged, Adapter.getPlayer(source))
    return true
end

function Adapter.getMoney()
    return 0
end

function Adapter.addMoney()
    return false
end

function Adapter.removeMoney()
    return false
end

function Adapter.registerUsableItem()
    return false
end

function Adapter.onPlayerLoaded(callback)
    callbacks.loaded[#callbacks.loaded + 1] = callback
end

function Adapter.onPlayerUnloaded(callback)
    callbacks.unloaded[#callbacks.unloaded + 1] = callback
end

function Adapter.onJobChanged(callback)
    callbacks.jobChanged[#callbacks.jobChanged + 1] = callback
end

function Adapter.onDutyChanged(callback)
    callbacks.dutyChanged[#callbacks.dutyChanged + 1] = callback
end

function Adapter.getCapabilities()
    return Shared.capabilities({
        nativeDuty = false,
        usableItems = false,
        multipleAccounts = false,
        jobChangeEvents = false,
        dutyChangeEvents = true,
        playerLifecycleEvents = false,
    })
end

Adapter.capabilities = Adapter.getCapabilities()
CivicOS.FrameworkAdapters = CivicOS.FrameworkAdapters or {}
CivicOS.FrameworkAdapters.standalone = Adapter
return Adapter

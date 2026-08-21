local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS

local Interface = {
    contractVersion = 1,
}

function Interface.new(name)
    return {
        name = name,
        capabilities = {},
    }
end

function Interface.validate(adapter)
    local required = {
        "getPlayer",
        "isPlayerLoaded",
        "getIdentifier",
        "getCharacterId",
        "getCharacterName",
        "getJob",
        "getJobName",
        "getJobGrade",
        "getJobGradeName",
        "isOnDuty",
        "setDuty",
        "getMoney",
        "addMoney",
        "removeMoney",
        "registerUsableItem",
        "onPlayerLoaded",
        "onPlayerUnloaded",
        "onJobChanged",
        "onDutyChanged",
        "getCapabilities",
    }
    for _, method in ipairs(required) do
        if type(adapter[method]) ~= "function" then
            return CivicOS.Result.err("ADAPTER_INVALID", "Framework adapter contract is incomplete.", { method = method })
        end
    end
    return CivicOS.Result.ok(true)
end

function Interface.identity(source, persistentIdentifier, characterId, displayName, framework, job)
    return {
        source = source,
        persistentIdentifier = persistentIdentifier,
        characterId = characterId,
        displayName = displayName or "Unknown",
        framework = framework,
        job = job or {
            name = "unemployed",
            label = "Unemployed",
            grade = 0,
            gradeName = "none",
            onDuty = false,
        },
    }
end

CivicOS.FrameworkInterface = Interface
return Interface

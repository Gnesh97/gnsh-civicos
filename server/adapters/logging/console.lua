local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS

local Console = {
    name = "console",
    capabilities = {
        structured = true,
        levels = true,
    },
}

function Console.init(options)
    if CivicOS.Logger and CivicOS.Logger.configure then
        CivicOS.Logger.configure(options)
    end
    return Console
end

function Console.write(level, category, message, context)
    if CivicOS.Logger and type(CivicOS.Logger[level]) == "function" then
        CivicOS.Logger[level](category, message, context)
    end
end

CivicOS.LoggingAdapter = Console
return Console

local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS

local Adapters = {
    Framework = "auto",
    Inventory = "auto",
    Notify = "standalone",
    Target = "auto",
    Evidence = "none",
    Logging = "console",
    Database = "oxmysql",
}

CivicOS.Adapters = Adapters
return Adapters

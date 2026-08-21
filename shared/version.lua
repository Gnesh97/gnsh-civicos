local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS

local Version = {
    resource = "gnsh-civicos",
    version = "0.1.0",
    contractVersion = 1,
    channel = "development",
}

CivicOS.Version = Version
return Version

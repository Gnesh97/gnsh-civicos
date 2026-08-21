local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS

local Features = {
    Requests = true,
    WorkOrders = true,
    Dispatch = true,
    FieldOperations = true,
    Notifications = true,
    Inspections = true,
    Integrations = true,
    Analytics = true,
    DemoSeed = false,
}

CivicOS.Features = Features
return Features

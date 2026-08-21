local context = {
    sourceResource = "custom_resource",
    externalRef = "demo-311-001",
    idempotencyKey = "demo-311-001-create-v1",
}

local created = exports["gnsh-civicos"]:CreateRequest({
    serviceCode = "pothole",
    title = "Road surface damage",
    description = "A deep pothole is blocking the lane.",
    location = { x = 0.0, y = 0.0, z = 0.0 },
}, context)

if created.ok then
    print(("CivicOS request created: %s"):format(created.data.id))
end

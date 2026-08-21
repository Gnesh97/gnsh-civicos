local result = exports["gnsh-civicos"]:CreateRequest({
    serviceCode = "water_leak_report",
    title = "Water main leak",
    description = "Water is pooling near the main valve.",
    location = { x = 10.0, y = 20.0, z = 30.0 },
}, {
    sourceResource = "hydrogrid",
    externalRef = "valve-7",
    idempotencyKey = "valve-7-leak-v1",
})

if result.ok then
    local current = exports["gnsh-civicos"]:GetRequest(result.data.id)
    if current.ok then
        local workorders = exports["gnsh-civicos"]:CreateWorkOrder(current.data.id, current.data.version, "water_leak", nil, {
            sourceResource = "hydrogrid",
            idempotencyKey = "valve-7-workorder-v1",
        })
        print(json.encode(workorders))
    end
end

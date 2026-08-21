local context = {
    sourceResource = "signalgrid",
    externalRef = "controller-42",
    idempotencyKey = "controller-42-offline-v1",
}

local request = exports["gnsh-civicos"]:CreateRequest({
    serviceCode = "traffic_signal_failure",
    title = "Traffic signal failure",
    description = "Controller heartbeat is missing.",
    location = { x = 100.0, y = 200.0, z = 30.0 },
}, context)

if request.ok then
    local current = exports["gnsh-civicos"]:GetRequest(request.data.id)
    if current.ok then
        exports["gnsh-civicos"]:ResolveRequest(current.data.id, current.data.version, "SignalGrid recovered the controller.", {
            sourceResource = context.sourceResource,
            idempotencyKey = context.externalRef .. "-resolve-v1",
        })
    end
end

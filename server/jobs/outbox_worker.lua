local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS

local function deliver(event)
    if CivicOS.OutboxDelivery and type(CivicOS.OutboxDelivery) == "function" then
        return CivicOS.OutboxDelivery(event) ~= false
    end
    if type(TriggerEvent) == "function" then
        TriggerEvent("civicos:outbox:deliver", event)
    end
    return true
end

if CivicOS.Scheduler then
    CivicOS.Scheduler:register("outbox", function()
        local batch = CivicOS.Config and CivicOS.Config.Outbox and CivicOS.Config.Outbox.BatchSize or 50
        local due = CivicOS.OutboxRepository:listDue(batch)
        if not due.ok then return due end
        for _, event in ipairs(due.data) do
            local ok = deliver(event.payload or event)
            if ok then
                CivicOS.OutboxRepository:markDelivered(event.id)
            else
                local maxAttempts = CivicOS.Config and CivicOS.Config.Outbox and CivicOS.Config.Outbox.MaxAttempts or 10
                CivicOS.OutboxRepository:markFailed(event.id, event.attempts, maxAttempts)
            end
        end
        return { ok = true, data = { processed = #due.data } }
    end, 1000)
end

return CivicOS.OutboxWorker or true

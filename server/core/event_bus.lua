local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS

local EventBus = { _handlers = {}, _sequence = 0 }

local function nowIso()
    return os.date("!%Y-%m-%dT%H:%M:%SZ")
end

local function correlationId()
    EventBus._sequence = (EventBus._sequence + 1) % 1000000
    return string.format("evt-%d-%06d", os.time(), EventBus._sequence)
end

function EventBus:subscribe(topic, handler)
    if type(topic) ~= "string" or type(handler) ~= "function" then
        return CivicOS.Result.err("EVENT_INVALID_HANDLER", "Event subscription is invalid.")
    end
    self._handlers[topic] = self._handlers[topic] or {}
    self._handlers[topic][#self._handlers[topic] + 1] = handler
    return { ok = true, data = true }
end

function EventBus:unsubscribe(topic, handler)
    for index, selected in ipairs(self._handlers[topic] or {}) do
        if selected == handler then table.remove(self._handlers[topic], index) break end
    end
    return { ok = true, data = true }
end

function EventBus:emit(topic, data, options)
    options = type(options) == "table" and options or {}
    local envelope = {
        eventName = topic,
        eventVersion = tonumber(options.eventVersion) or 1,
        correlationId = options.correlationId or correlationId(),
        occurredAt = nowIso(),
        data = data or {},
    }
    if options.outbox and CivicOS.OutboxRepository then
        CivicOS.OutboxRepository:create(envelope)
    end
    for _, handler in ipairs(self._handlers[topic] or {}) do
        local ok = pcall(handler, envelope)
        if not ok and CivicOS.Logger then CivicOS.Logger.error("EVENT", "Event handler failed.", { topic = topic }) end
    end
    if type(TriggerEvent) == "function" then TriggerEvent("civicos:event:" .. topic, envelope) end
    return { ok = true, data = envelope }
end

CivicOS.EventBus = EventBus
return EventBus

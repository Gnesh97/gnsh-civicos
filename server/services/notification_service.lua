local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS

local NotificationService = {}

local function errorResult(code, message, details)
    return CivicOS.Result.err(code, message, details)
end

local function safeText(value, field)
    if type(value) ~= "string" or value == "" or #value > 160 then
        return nil, errorResult("NOTIFICATION_INVALID", string.format("%s is invalid.", field))
    end
    return value
end

function NotificationService:create(recipientIdentifier, notificationType, titleKey, bodyKey, payload, source)
    local recipient, recipientError = safeText(recipientIdentifier, "recipientIdentifier")
    if not recipient then return recipientError end
    local kind, kindError = safeText(notificationType, "notificationType")
    if not kind then return kindError end
    local title, titleError = safeText(titleKey, "titleKey")
    if not title then return titleError end
    local body, bodyError = safeText(bodyKey, "bodyKey")
    if not body then return bodyError end
    local created = CivicOS.NotificationRepository:create({
        recipientIdentifier = recipient,
        notificationType = kind,
        titleKey = title,
        bodyKey = body,
        payload = payload,
    })
    if not created.ok then return created end
    if source and CivicOS.Notify then CivicOS.Notify.notify(source, body, "info") end
    return { ok = true, data = { id = created.data, recipientIdentifier = recipient } }
end

function NotificationService:list(source, unreadOnly, page, pageSize)
    local identity = CivicOS.Authorization:identity(source)
    if not identity.ok then return identity end
    local result = CivicOS.NotificationRepository:list(identity.data.persistentIdentifier, unreadOnly == true, page, pageSize)
    if not result.ok then return result end
    local public = {}
    for _, item in ipairs(result.data) do
        public[#public + 1] = {
            id = item.id,
            type = item.notification_type,
            title = item.title_key,
            body = item.body_key,
            payload = item.payload,
            readAt = item.read_at,
            createdAt = item.created_at,
        }
    end
    return { ok = true, data = public }
end

function NotificationService:markRead(source, id)
    local identity = CivicOS.Authorization:identity(source)
    if not identity.ok then return identity end
    local result = CivicOS.NotificationRepository:markRead(id, identity.data.persistentIdentifier)
    if not result.ok then return result end
    return { ok = true, data = { id = id, changed = (result.data.affectedRows or 0) > 0 } }
end

function NotificationService:forRequest(requestId, notificationType, titleKey, bodyKey, payload)
    local request = CivicOS.RequestRepository:findById(requestId)
    if not request.ok then return request end
    local entity = request.data[1]
    if not entity or not entity.requester_identifier then return { ok = true, data = false } end
    return self:create(entity.requester_identifier, notificationType, titleKey, bodyKey, payload)
end

CivicOS.NotificationService = NotificationService
return NotificationService

local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS
local Repository = CivicOS.Repository

local NotificationRepository = {}

function NotificationRepository:create(notification)
    return Repository.db():insert([[INSERT INTO civicos_notifications
        (recipient_identifier, notification_type, title_key, body_key, payload)
        VALUES (?, ?, ?, ?, ?)]], {
        notification.recipientIdentifier, notification.notificationType, notification.titleKey,
        notification.bodyKey, Repository.encode(notification.payload),
    })
end

function NotificationRepository:list(recipientIdentifier, unreadOnly, page, pageSize)
    page = math.max(1, tonumber(page) or 1)
    pageSize = math.min(math.max(1, tonumber(pageSize) or 50), 100)
    local sql = [[SELECT id, recipient_identifier, notification_type, title_key, body_key,
        payload, read_at, created_at FROM civicos_notifications WHERE recipient_identifier = ?]]
    local params = { recipientIdentifier }
    if unreadOnly then sql = sql .. " AND read_at IS NULL" end
    params[#params + 1] = pageSize
    params[#params + 1] = (page - 1) * pageSize
    local result = Repository.db():query(sql .. " ORDER BY created_at DESC LIMIT ? OFFSET ?", params)
    if not result.ok then return result end
    local rows = {}
    for _, row in ipairs(result.data or {}) do
        row.payload = Repository.decode(row.payload)
        rows[#rows + 1] = row
    end
    return { ok = true, data = rows }
end

function NotificationRepository:markRead(id, recipientIdentifier)
    return Repository.db():update(
        "UPDATE civicos_notifications SET read_at = CURRENT_TIMESTAMP(3) WHERE id = ? AND recipient_identifier = ? AND read_at IS NULL",
        { id, recipientIdentifier }
    )
end

CivicOS.NotificationRepository = NotificationRepository
return NotificationRepository

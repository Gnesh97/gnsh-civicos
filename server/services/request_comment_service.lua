local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS

local CommentService = {}

local function errorResult(code, message, details)
    return CivicOS.Result.err(code, message, details)
end

function CommentService:add(source, requestId, body, visibility)
    visibility = visibility or "public"
    if visibility ~= "public" and visibility ~= "internal" then
        return errorResult("CORE_INVALID_INPUT", "Comment visibility is invalid.")
    end
    local request = CivicOS.RequestRepository:findById(requestId)
    if not request.ok then return request end
    local entity = request.data[1]
    if not entity then return errorResult("CORE_NOT_FOUND", "Request not found.") end
    local permission = visibility == "internal" and "request.comment.internal" or "request.comment.own"
    local auth = CivicOS.Authorization:can(source, permission, { ownerIdentifier = entity.requester_identifier, departmentId = entity.department_id })
    if not auth.ok then return auth end
    local validated = CivicOS.Validation.string(body, "body", { required = true, maxLength = CivicOS.Constants.Limits.COMMENT_BODY })
    if not validated.ok then return validated end
    local identifier = auth.data.identity.persistentIdentifier
    local limited = CivicOS.RateLimit:allow(identifier, "request_comment")
    if not limited.ok then return limited end
    local created = CivicOS.RequestRepository:addComment(requestId, identifier, visibility, validated.data)
    if not created.ok then return created end
    CivicOS.RequestRepository:addActivity(requestId, identifier, "comment_added", { visibility = visibility })
    return { ok = true, data = { id = created.data, visibility = visibility } }
end

function CommentService:list(source, requestId, page, pageSize)
    local request = CivicOS.RequestRepository:findById(requestId)
    if not request.ok then return request end
    local entity = request.data[1]
    if not entity then return errorResult("CORE_NOT_FOUND", "Request not found.") end
    local staff = CivicOS.Authorization:can(source, "request.comment.internal", { departmentId = entity.department_id })
    local includeInternal = staff.ok
    if not includeInternal then
        local own = CivicOS.Authorization:can(source, "request.read.own", { ownerIdentifier = entity.requester_identifier })
        if not own.ok then return own end
    end
    local comments = CivicOS.RequestRepository:listComments(requestId, includeInternal, page, pageSize)
    if not comments.ok then return comments end
    local public = {}
    for _, comment in ipairs(comments.data) do
        public[#public + 1] = {
            id = comment.id,
            requestId = comment.request_id,
            visibility = comment.visibility,
            body = comment.body,
            createdAt = comment.created_at,
        }
    end
    return { ok = true, data = public }
end

CivicOS.RequestCommentService = CommentService
return CommentService

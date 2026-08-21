local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS
local Repository = CivicOS.Repository

local RequestRepository = {}

local selectColumns = [[
    id, reference, source, source_resource, external_ref,
    requester_identifier, category, subcategory, title, description,
    priority, status, department_id, location_json, metadata, version,
    created_at, updated_at
]]

function RequestRepository:findById(id)
    return Repository.rows(Repository.db():query("SELECT " .. selectColumns .. " FROM civicos_requests WHERE id = ? LIMIT 1", { id }))
end

function RequestRepository:findByReference(reference)
    return Repository.rows(Repository.db():query("SELECT " .. selectColumns .. " FROM civicos_requests WHERE reference = ? LIMIT 1", { reference }))
end

function RequestRepository:list(filters)
    filters = type(filters) == "table" and filters or {}
    local clauses, params = {}, {}
    if filters.status then
        clauses[#clauses + 1] = "status = ?"
        params[#params + 1] = filters.status
    end
    if filters.departmentId then
        clauses[#clauses + 1] = "department_id = ?"
        params[#params + 1] = filters.departmentId
    end
    local where = #clauses > 0 and (" WHERE " .. table.concat(clauses, " AND ")) or ""
    local page = math.max(1, tonumber(filters.page) or 1)
    local pageSize = math.min(tonumber(filters.pageSize) or 50, 100)
    params[#params + 1] = pageSize
    params[#params + 1] = (page - 1) * pageSize
    local result = Repository.db():query(
        "SELECT " .. selectColumns .. " FROM civicos_requests" .. where .. " ORDER BY created_at DESC LIMIT ? OFFSET ?",
        params
    )
    return Repository.rows(result)
end

function RequestRepository:create(dto)
    local location = Repository.encode(dto.location)
    local metadata = Repository.encode(dto.metadata)
    if not location then
        return Repository.error("CORE_INVALID_INPUT", "Request location could not be encoded.")
    end
    local result = Repository.db():insert([[INSERT INTO civicos_requests
        (reference, source, source_resource, external_ref, requester_identifier,
         category, subcategory, title, description, priority, status, department_id,
         location_json, metadata, version)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1)]], {
        dto.reference, dto.source, dto.sourceResource, dto.externalRef, dto.requesterIdentifier,
        dto.category, dto.subcategory, dto.title, dto.description, dto.priority or "normal",
        dto.status or "submitted", dto.departmentId, location, metadata,
    })
    return result
end

function RequestRepository:updateStatus(id, expectedVersion, status)
    local result = Repository.db():update(
        "UPDATE civicos_requests SET status = ?, version = version + 1 WHERE id = ? AND version = ?",
        { status, id, expectedVersion }
    )
    if not result.ok then
        return result
    end
    if (result.data.affectedRows or 0) == 0 then
        return Repository.error("CORE_VERSION_CONFLICT", "Request version conflict.", { id = id })
    end
    return { ok = true, data = { id = id, version = expectedVersion + 1, status = status } }
end

function RequestRepository:addComment(requestId, authorIdentifier, visibility, body)
    return Repository.db():insert(
        "INSERT INTO civicos_request_comments (request_id, author_identifier, visibility, body) VALUES (?, ?, ?, ?)",
        { requestId, authorIdentifier, visibility or "public", body }
    )
end

CivicOS.RequestRepository = RequestRepository
return RequestRepository

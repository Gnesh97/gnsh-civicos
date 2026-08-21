local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS

local Request = {}

function Request.new(attributes)
    attributes = type(attributes) == "table" and attributes or {}
    return {
        id = attributes.id,
        reference = attributes.reference,
        source = attributes.source,
        category = attributes.category,
        subcategory = attributes.subcategory,
        title = attributes.title,
        description = attributes.description,
        priority = attributes.priority,
        status = attributes.status or CivicOS.Enums.RequestStatus.DRAFT,
        departmentId = attributes.departmentId,
        location = attributes.location,
        metadata = attributes.metadata or {},
        version = attributes.version or 1,
        createdAt = attributes.created_at or attributes.createdAt,
        updatedAt = attributes.updated_at or attributes.updatedAt,
    }
end

function Request.public(entity)
    return {
        id = entity.id,
        reference = entity.reference,
        source = entity.source,
        category = entity.category,
        subcategory = entity.subcategory,
        title = entity.title,
        description = entity.description,
        priority = entity.priority,
        status = entity.status,
        departmentId = entity.department_id or entity.departmentId,
        location = entity.location,
        metadata = entity.metadata or {},
        version = entity.version,
        createdAt = entity.created_at or entity.createdAt,
        updatedAt = entity.updated_at or entity.updatedAt,
    }
end

CivicOS.RequestDomain = Request
return Request

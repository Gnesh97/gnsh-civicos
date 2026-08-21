local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS

local WorkOrder = {}

function WorkOrder.new(attributes)
    attributes = type(attributes) == "table" and attributes or {}
    return {
        id = attributes.id,
        requestId = attributes.request_id or attributes.requestId,
        reference = attributes.reference,
        departmentId = attributes.department_id or attributes.departmentId,
        templateKey = attributes.template_key or attributes.templateKey,
        priority = attributes.priority,
        status = attributes.status or CivicOS.Enums.WorkOrderStatus.CREATED,
        assignedEmployeeId = attributes.assigned_employee_id or attributes.assignedEmployeeId,
        assignedCrewId = attributes.assigned_crew_id or attributes.assignedCrewId,
        location = attributes.location,
        checklist = attributes.checklist,
        metadata = attributes.metadata or {},
        version = attributes.version or 1,
    }
end

function WorkOrder.public(entity)
    return {
        id = entity.id,
        requestId = entity.request_id or entity.requestId,
        reference = entity.reference,
        departmentId = entity.department_id or entity.departmentId,
        templateKey = entity.template_key or entity.templateKey,
        priority = entity.priority,
        status = entity.status,
        assignedEmployeeId = entity.assigned_employee_id or entity.assignedEmployeeId,
        assignedCrewId = entity.assigned_crew_id or entity.assignedCrewId,
        location = entity.location,
        checklist = entity.checklist,
        metadata = entity.metadata or {},
        version = entity.version,
        createdAt = entity.created_at or entity.createdAt,
        updatedAt = entity.updated_at or entity.updatedAt,
    }
end

CivicOS.WorkOrderDomain = WorkOrder
return WorkOrder

local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS

local DTO = {}

function DTO.requestListItem(request)
    return {
        id = request.id,
        reference = request.reference,
        category = request.category,
        subcategory = request.subcategory,
        title = request.title,
        priority = request.priority,
        status = request.status,
        departmentId = request.departmentId or request.department_id,
        location = request.location,
        version = request.version,
        createdAt = request.createdAt or request.created_at,
        updatedAt = request.updatedAt or request.updated_at,
    }
end

function DTO.workOrderListItem(workorder)
    return {
        id = workorder.id,
        requestId = workorder.requestId or workorder.request_id,
        reference = workorder.reference,
        templateKey = workorder.templateKey or workorder.template_key,
        priority = workorder.priority,
        status = workorder.status,
        departmentId = workorder.departmentId or workorder.department_id,
        assignedEmployeeId = workorder.assignedEmployeeId or workorder.assigned_employee_id,
        assignedCrewId = workorder.assignedCrewId or workorder.assigned_crew_id,
        location = workorder.location,
        version = workorder.version,
        createdAt = workorder.createdAt or workorder.created_at,
        updatedAt = workorder.updatedAt or workorder.updated_at,
    }
end

function DTO.employeeAvailability(employee)
    return {
        id = employee.id,
        displayName = employee.display_name or employee.displayName,
        departmentId = employee.department_id or employee.departmentId,
        jobName = employee.job_name or employee.jobName,
        dutyStatus = employee.duty_status or employee.dutyStatus,
        availabilityStatus = employee.availability_status or employee.availabilityStatus,
    }
end

function DTO.citizenRequestDetail(request, comments, activity)
    local result = CivicOS.RequestDomain.public(request)
    result.comments = comments or {}
    result.activity = activity or {}
    return result
end

function DTO.staffRequestDetail(request, comments, activity)
    local result = CivicOS.RequestDomain.public(request)
    result.requesterIdentifier = request.requester_identifier
    result.comments = comments or {}
    result.activity = activity or {}
    return result
end

CivicOS.DTO = DTO
return DTO

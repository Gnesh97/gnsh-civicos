local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS

local WorkOrderService = {}
local referenceCounter = 0

local function errorResult(code, message, details)
    return CivicOS.Result.err(code, message, details)
end

local function reference()
    referenceCounter = (referenceCounter + 1) % 1000000
    return string.format("WO-%s-%06d", os.date("!%Y"), (os.time() + referenceCounter) % 1000000)
end

local function actorIdentifier(auth)
    return auth.data.identity.persistentIdentifier
end

local function crewMemberAuth(source, entity, permission)
    if not entity.assigned_crew_id then return nil end
    local identity = CivicOS.Authorization:identity(source)
    if not identity.ok then return identity end
    local employee = CivicOS.EmployeeRepository:findByIdentifier(identity.data.persistentIdentifier)
    if not employee.ok or not employee.data[1] then return nil end
    local membership = CivicOS.CrewRepository:findMembership(entity.assigned_crew_id, employee.data[1].id)
    if membership.ok and membership.data[1] and membership.data[1].status == "active" then
        local role = CivicOS.Permissions.Roles[identity.data.role]
        if role and CivicOS.Authorization:hasRolePermission(identity.data.role, permission) then
            return { ok = true, data = { identity = identity.data, role = identity.data.role, scope = "crew" } }
        end
    end
    return nil
end

local function publicWorkOrder(entity)
    if type(entity) ~= "table" then return nil end

    local domain = CivicOS.WorkOrderDomain
    if type(domain) == "table" and type(domain.public) == "function" then
        local ok, result = pcall(domain.public, entity)
        if ok and type(result) == "table" then return result end
    end

    -- Keep list responses available while a resource is being hot-reloaded or
    -- when an older manifest has not registered the domain module yet. The DTO
    -- has the exact list projection required by the API boundary.
    local dto = CivicOS.DTO
    if type(dto) == "table" and type(dto.workOrderListItem) == "function" then
        local ok, result = pcall(dto.workOrderListItem, entity)
        if ok and type(result) == "table" then return result end
    end

    return {
        id = entity.id,
        requestId = entity.request_id or entity.requestId,
        reference = entity.reference,
        templateKey = entity.template_key or entity.templateKey,
        priority = entity.priority,
        status = entity.status,
        departmentId = entity.department_id or entity.departmentId,
        assignedEmployeeId = entity.assigned_employee_id or entity.assignedEmployeeId,
        assignedCrewId = entity.assigned_crew_id or entity.assignedCrewId,
        location = entity.location,
        version = entity.version,
        createdAt = entity.created_at or entity.createdAt,
        updatedAt = entity.updated_at or entity.updatedAt,
    }
end

function WorkOrderService:convert(source, requestId, expectedVersion, serviceCode, overrides, context)
    overrides = type(overrides) == "table" and overrides or {}
    local requestResult = CivicOS.RequestRepository:findById(requestId)
    if not requestResult.ok then return requestResult end
    local request = requestResult.data[1]
    if not request then return errorResult("CORE_NOT_FOUND", "Request not found.") end
    local auth
    if source then
        auth = CivicOS.Authorization:can(source, "request.convert", { departmentId = request.department_id })
        if not auth.ok then return auth end
    else
        context = type(context) == "table" and context or {}
        if request.source ~= "integration" or (context.sourceResource and request.source_resource ~= context.sourceResource) then
            return errorResult("AUTH_FORBIDDEN", "Integration cannot convert this request.")
        end
        auth = { ok = true, data = { identity = { persistentIdentifier = context.actorIdentifier or "integration" } } }
    end
    if tonumber(expectedVersion) ~= tonumber(request.version) then return errorResult("CORE_VERSION_CONFLICT", "Request version conflict.") end
    local transition = CivicOS.RequestStateMachine.transition(request, CivicOS.Enums.RequestStatus.CONVERTED, { actorIdentifier = actorIdentifier(auth) })
    if not transition.ok then return transition end
    local catalog = CivicOS.ServiceCatalogService:get(serviceCode or request.category, "staff")
    if not catalog.ok then
        -- Catalog codes are preferred; fall back to matching the request category.
        local matched
        for _, entry in ipairs(CivicOS.ServiceCatalog.list()) do
            if entry.category == request.category and entry.subcategory == request.subcategory then matched = entry.code end
        end
        catalog = matched and CivicOS.ServiceCatalogService:get(matched, "staff") or catalog
    end
    if not catalog.ok then return catalog end
    if type(overrides.workorders) == "table" and #overrides.workorders == 0 then
        return errorResult("WORKORDER_INVALID_INPUT", "At least one work order is required.")
    end
    local template = CivicOS.WorkOrderTemplateService:snapshot(catalog.data.workOrderTemplate)
    if not template.ok then return template end
    local items = overrides.workorders or { { departmentId = request.department_id, templateKey = catalog.data.workOrderTemplate, priority = request.priority } }
    local materialized = {}
    for _, item in ipairs(items) do
        local selectedTemplate = item.templateKey and CivicOS.WorkOrderTemplateService:snapshot(item.templateKey) or template
        if not selectedTemplate.ok then return selectedTemplate end
        materialized[#materialized + 1] = {
            reference = reference(),
            departmentId = item.departmentId or request.department_id,
            templateKey = selectedTemplate.data.key,
            priority = item.priority or request.priority,
            location = request.location,
            checklist = selectedTemplate.data.checklist,
            metadata = { template = selectedTemplate.data, sourceRequest = request.reference },
        }
    end
    local created = CivicOS.WorkOrderRepository:createManyForRequest(requestId, expectedVersion, materialized)
    if not created.ok then return created end
    local convertedRequest = CivicOS.RequestRepository:findById(requestId)
    if not convertedRequest.ok then return convertedRequest end
    local convertedEntity = convertedRequest.data[1]
    if not convertedEntity or convertedEntity.status ~= CivicOS.Enums.RequestStatus.CONVERTED
        or tonumber(convertedEntity.version) ~= tonumber(expectedVersion) + 1 then
        return errorResult("CORE_VERSION_CONFLICT", "Request conversion conflict.", { id = requestId })
    end
    local workorders = CivicOS.WorkOrderRepository:listByRequest(requestId)
    if not workorders.ok then return workorders end
    for _, workorder in ipairs(workorders.data) do
        if workorder.status == CivicOS.Enums.WorkOrderStatus.CREATED then
            local staged = CivicOS.WorkOrderRepository:updateStatus(workorder.id, workorder.version, CivicOS.Enums.WorkOrderStatus.UNASSIGNED)
            if staged.ok then
                workorder.status = CivicOS.Enums.WorkOrderStatus.UNASSIGNED
                workorder.version = workorder.version + 1
            end
        end
    end
    CivicOS.RequestRepository:addActivity(requestId, actorIdentifier(auth), "workorder_created", { count = #materialized })
    return { ok = true, data = workorders.data }
end

function WorkOrderService:syncRequestState(requestId, actorIdentifier, reason)
    local request = CivicOS.RequestRepository:findById(requestId)
    if not request.ok then return request end
    local entity = request.data[1]
    if not entity then return { ok = true, data = false } end
    local children = CivicOS.WorkOrderRepository:listByRequest(requestId)
    if not children.ok then return children end
    if #children.data == 0 then return { ok = true, data = false } end
    local completed, terminal, cancelled = 0, 0, 0
    for _, child in ipairs(children.data) do
        if child.status == "completed" or child.status == "closed" then
            completed = completed + 1
            terminal = terminal + 1
        elseif child.status == "cancelled" or child.status == "failed" then
            cancelled = cancelled + 1
            terminal = terminal + 1
        end
    end
    local target
    if completed == #children.data then
        target = CivicOS.Enums.RequestStatus.RESOLVED
    elseif terminal == #children.data and cancelled == #children.data then
        target = CivicOS.Enums.RequestStatus.CANCELLED
    elseif entity.status == CivicOS.Enums.RequestStatus.CONVERTED then
        target = CivicOS.Enums.RequestStatus.IN_PROGRESS
    end
    if not target or target == entity.status then return { ok = true, data = false } end
    if not CivicOS.RequestStateMachine.can(entity.status, target) then return { ok = true, data = false } end
    local updated = CivicOS.RequestRepository:updateStatus(entity.id, entity.version, target)
    if not updated.ok then return updated end
    if CivicOS.RequestRepository.addActivity then
        CivicOS.RequestRepository:addActivity(entity.id, actorIdentifier, "workorder_sync", {
            status = target,
            reason = reason,
        })
    end
    if CivicOS.NotificationService then
        CivicOS.NotificationService:forRequest(entity.id, "request_status", "civicos.request.status.title", "civicos.request.status.body", {
            status = target,
            requestId = entity.id,
        })
    end
    return { ok = true, data = true }
end

function WorkOrderService:get(source, id)
    local result = CivicOS.WorkOrderRepository:findById(id)
    if not result.ok then return result end
    local entity = result.data[1]
    if not entity then return errorResult("CORE_NOT_FOUND", "Work order not found.") end
    if not source then return { ok = true, data = CivicOS.WorkOrderDomain.public(entity) } end
    local employee = entity.assigned_employee_id and CivicOS.EmployeeRepository:findById(entity.assigned_employee_id)
    local assignedIdentifier = employee and employee.ok and employee.data[1] and employee.data[1].persistent_identifier
    local auth = CivicOS.Authorization:can(source, "workorder.read.assigned", {
        assignedIdentifier = assignedIdentifier,
        departmentId = entity.department_id,
    })
    if not auth.ok then auth = crewMemberAuth(source, entity, "workorder.read.assigned") or auth end
    if not auth.ok then auth = CivicOS.Authorization:can(source, "workorder.read.department", { departmentId = entity.department_id }) end
    if not auth.ok then return auth end
    return { ok = true, data = CivicOS.WorkOrderDomain.public(entity) }
end

function WorkOrderService:list(source, filters)
    filters = type(filters) == "table" and filters or {}
    local identity = CivicOS.Authorization:identity(source)
    if not identity.ok then return identity end
    if identity.data.role == "TECHNICIAN" then
        local employee = CivicOS.EmployeeRepository:findByIdentifier(identity.data.persistentIdentifier)
        if employee.ok and employee.data[1] then filters.employeeId = employee.data[1].id end
        if employee.ok and employee.data[1] and CivicOS.CrewRepository then
            local crews = CivicOS.CrewRepository:list(employee.data[1].department_id, "active")
            if crews.ok then
                local memberships = {}
                for _, item in ipairs(crews.data) do
                    local membership = CivicOS.CrewRepository:findMembership(item.id, employee.data[1].id)
                    if membership.ok and membership.data[1] and membership.data[1].status == "active" then memberships[#memberships + 1] = item.id end
                end
                filters.crewIds = memberships
            end
        end
    elseif identity.data.departmentId and not filters.departmentId then
        filters.departmentId = identity.data.departmentId
    end
    local result = CivicOS.WorkOrderRepository:list(filters)
    if not result.ok then return result end
    local public = {}
    for _, entity in ipairs(result.data or {}) do
        local projected = publicWorkOrder(entity)
        if not projected then return errorResult("API_RESPONSE_INVALID", "Work order response could not be serialized.") end
        public[#public + 1] = projected
    end
    return { ok = true, data = public }
end

function WorkOrderService:transition(source, id, expectedVersion, targetStatus, reason)
    local result = CivicOS.WorkOrderRepository:findById(id)
    if not result.ok then return result end
    local entity = result.data[1]
    if not entity then return errorResult("CORE_NOT_FOUND", "Work order not found.") end
    local employee = entity.assigned_employee_id and CivicOS.EmployeeRepository:findById(entity.assigned_employee_id)
    local assignedIdentifier = employee and employee.ok and employee.data[1] and employee.data[1].persistent_identifier
    local auth = CivicOS.Authorization:can(source, "workorder.update.assigned", {
        assignedIdentifier = assignedIdentifier,
        departmentId = entity.department_id,
    })
    if not auth.ok then auth = crewMemberAuth(source, entity, "workorder.update.assigned") or auth end
    if not auth.ok then auth = CivicOS.Authorization:can(source, "workorder.read.department", { departmentId = entity.department_id }) end
    if not auth.ok then return auth end
    if tonumber(expectedVersion) ~= tonumber(entity.version) then return errorResult("CORE_VERSION_CONFLICT", "Work order version conflict.") end
    if targetStatus == CivicOS.Enums.WorkOrderStatus.COMPLETED and CivicOS.ChecklistService then
        local checklist = CivicOS.ChecklistService:validateCompletion(source, entity)
        if not checklist.ok then return checklist end
    end
    local dependencies = CivicOS.WorkOrderDependencyService and CivicOS.WorkOrderDependencyService:hasUnresolved(id)
    if dependencies and not dependencies.ok then return dependencies end
    local template = CivicOS.WorkOrderTemplateService:get(entity.template_key)
    local inspectionRequired = template.ok and template.data.inspectionRequired == true
    local inspectionPassed = not inspectionRequired
    if inspectionRequired and CivicOS.InspectionService then
        local inspection = CivicOS.InspectionService:isPassed(id)
        if not inspection.ok then return inspection end
        inspectionPassed = inspection.data == true
    end
    local transition = CivicOS.WorkOrderStateMachine.transition(entity, targetStatus, {
        reason = reason,
        dependenciesUnresolved = dependencies and dependencies.ok and dependencies.data or false,
        inspectionRequired = inspectionRequired,
        inspectionPassed = inspectionPassed,
    })
    if not transition.ok then return transition end
    local updated = CivicOS.WorkOrderRepository:updateStatus(id, expectedVersion, targetStatus)
    if not updated.ok then return updated end
    local synced = self:syncRequestState(entity.request_id, auth.data.identity.persistentIdentifier, reason)
    if not synced.ok then return synced end
    if entity.request_id and CivicOS.SlaService then
        if targetStatus == CivicOS.Enums.WorkOrderStatus.EN_ROUTE or targetStatus == CivicOS.Enums.WorkOrderStatus.ON_SCENE then
            CivicOS.SlaService:markMilestone(entity.request_id, "arrival", auth.data.identity.persistentIdentifier)
        elseif targetStatus == CivicOS.Enums.WorkOrderStatus.COMPLETED or targetStatus == CivicOS.Enums.WorkOrderStatus.CLOSED then
            CivicOS.SlaService:markMilestone(entity.request_id, "resolution", auth.data.identity.persistentIdentifier)
        end
    end
    if CivicOS.AuditRepository then
        CivicOS.AuditRepository:append({ actorIdentifier = auth.data.identity.persistentIdentifier, entityType = "workorder", entityId = id, action = "transition", after = { from = entity.status, to = targetStatus, reason = reason } })
    end
    return updated
end

CivicOS.WorkOrderService = WorkOrderService
return WorkOrderService

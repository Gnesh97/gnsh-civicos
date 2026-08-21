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

function WorkOrderService:convert(source, requestId, expectedVersion, serviceCode, overrides)
    overrides = type(overrides) == "table" and overrides or {}
    local requestResult = CivicOS.RequestRepository:findById(requestId)
    if not requestResult.ok then return requestResult end
    local request = requestResult.data[1]
    if not request then return errorResult("CORE_NOT_FOUND", "Request not found.") end
    local auth = CivicOS.Authorization:can(source, "request.convert", { departmentId = request.department_id })
    if not auth.ok then return auth end
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
    return { ok = true, data = true }
end

function WorkOrderService:get(source, id)
    local result = CivicOS.WorkOrderRepository:findById(id)
    if not result.ok then return result end
    local entity = result.data[1]
    if not entity then return errorResult("CORE_NOT_FOUND", "Work order not found.") end
    local employee = entity.assigned_employee_id and CivicOS.EmployeeRepository:findById(entity.assigned_employee_id)
    local assignedIdentifier = employee and employee.ok and employee.data[1] and employee.data[1].persistent_identifier
    local auth = CivicOS.Authorization:can(source, "workorder.read.assigned", {
        assignedIdentifier = assignedIdentifier,
        departmentId = entity.department_id,
    })
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
    elseif identity.data.departmentId and not filters.departmentId then
        filters.departmentId = identity.data.departmentId
    end
    local result = CivicOS.WorkOrderRepository:list(filters)
    if not result.ok then return result end
    local public = {}
    for _, entity in ipairs(result.data) do public[#public + 1] = CivicOS.WorkOrderDomain.public(entity) end
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
    if not auth.ok then auth = CivicOS.Authorization:can(source, "workorder.read.department", { departmentId = entity.department_id }) end
    if not auth.ok then return auth end
    if tonumber(expectedVersion) ~= tonumber(entity.version) then return errorResult("CORE_VERSION_CONFLICT", "Work order version conflict.") end
    local dependencies = CivicOS.WorkOrderDependencyService and CivicOS.WorkOrderDependencyService:hasUnresolved(id)
    if dependencies and not dependencies.ok then return dependencies end
    local template = CivicOS.WorkOrderTemplateService:get(entity.template_key)
    local transition = CivicOS.WorkOrderStateMachine.transition(entity, targetStatus, {
        reason = reason,
        dependenciesUnresolved = dependencies and dependencies.ok and dependencies.data or false,
        inspectionRequired = template.ok and template.data.inspectionRequired,
        inspectionPassed = false,
    })
    if not transition.ok then return transition end
    local updated = CivicOS.WorkOrderRepository:updateStatus(id, expectedVersion, targetStatus)
    if not updated.ok then return updated end
    local synced = self:syncRequestState(entity.request_id, auth.data.identity.persistentIdentifier, reason)
    if not synced.ok then return synced end
    if CivicOS.AuditRepository then
        CivicOS.AuditRepository:append({ actorIdentifier = auth.data.identity.persistentIdentifier, entityType = "workorder", entityId = id, action = "transition", after = { from = entity.status, to = targetStatus, reason = reason } })
    end
    return updated
end

CivicOS.WorkOrderService = WorkOrderService
return WorkOrderService

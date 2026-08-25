local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS

local Api = { handlers = {} }

local function errorResult(code, message, details)
    return CivicOS.Result.err(code, message, details)
end

local function tableValue(value)
    return type(value) == "table" and value or {}
end

local publicActivityTypes = {
    created = true,
    transition = true,
    updated = true,
    comment_added = true,
    workorder_created = true,
    workorder_sync = true,
    sla_met = true,
}

local function callbackTraceback(message)
    local debugLibrary = rawget(_G, "debug")
    if type(debugLibrary) == "table" and type(debugLibrary.traceback) == "function" then
        return debugLibrary.traceback(tostring(message), 2)
    end
    return tostring(message)
end

local function number(value, field)
    local parsed = tonumber(value)
    if not parsed or parsed % 1 ~= 0 or parsed < 1 then
        return nil, errorResult("CORE_INVALID_INPUT", string.format("%s must be a positive integer.", field))
    end
    return parsed
end

local function requestDetail(source, id, staff)
    local rawRequest = CivicOS.RequestRepository:findById(id)
    if not rawRequest.ok then return rawRequest end
    local requestEntity = rawRequest.data[1]
    if not requestEntity then return errorResult("CORE_NOT_FOUND", "Request not found.") end
    local authorized = CivicOS.RequestService:_authorizeRead(source, requestEntity)
    if not authorized.ok then return authorized end
    local comments = CivicOS.RequestCommentService:list(source, id, 1, 100)
    if not comments.ok then return comments end
    local internalAuth = staff and CivicOS.Authorization:can(source, "request.comment.internal", {
        departmentId = requestEntity.department_id,
    }) or { ok = false }
    local canViewInternal = internalAuth.ok
    local activity = CivicOS.RequestRepository:listActivity(id, 1, 100)
    if not activity.ok then return activity end
    local safeActivity = {}
    for _, item in ipairs(activity.data or {}) do
        if canViewInternal or publicActivityTypes[item.activity_type] then
            safeActivity[#safeActivity + 1] = {
                id = item.id,
                requestId = item.request_id,
                activityType = item.activity_type,
                publicData = CivicOS.Repository.decode(item.public_data),
                createdAt = item.created_at,
            }
        end
    end
    local dto = staff and CivicOS.DTO.staffRequestDetail or CivicOS.DTO.citizenRequestDetail
    return { ok = true, data = dto(requestEntity, comments.data, safeActivity) }
end

Api.handlers.bootstrap = function(source)
    local identity = CivicOS.Authorization:identity(source)
    if not identity.ok then return identity end
    local role = CivicOS.Permissions.Roles[identity.data.role] or {}
    local catalog = CivicOS.ServiceCatalogService:list()
    if not catalog.ok then return catalog end
    local visibleCatalog = {}
    for _, entry in ipairs(catalog.data) do
        if identity.data.role ~= "CITIZEN" or entry.citizenEnabled then visibleCatalog[#visibleCatalog + 1] = entry end
    end
    return { ok = true, data = {
        version = CivicOS.Version and CivicOS.Version.version,
        identity = {
            persistentIdentifier = identity.data.persistentIdentifier,
            displayName = identity.data.displayName,
            role = identity.data.role,
            departmentName = identity.data.departmentName,
            departmentId = identity.data.departmentId,
        },
        permissions = role.permissions or {},
        features = CivicOS.Features or {},
        catalog = visibleCatalog,
        providerCapabilities = CivicOS.ProviderCapabilities or {},
    } }
end

Api.handlers["request.list"] = function(source, input)
    input = tableValue(input)
    local result = CivicOS.RequestService:list(source, input)
    if not result.ok then return result end
    return { ok = true, data = CivicOS.Serializers.paginated(result.data, input.page, input.pageSize) }
end

Api.handlers["request.get"] = function(source, input)
    local id, failure = number(tableValue(input).id, "id")
    if not id then return failure end
    local identity = CivicOS.Authorization:identity(source)
    if not identity.ok then return identity end
    return requestDetail(source, id, identity.data.role ~= "CITIZEN")
end

Api.handlers["request.create"] = function(source, input)
    input = tableValue(input)
    local sourceType = input.sourceType or "citizen"
    if sourceType ~= "citizen" then
        local auth = CivicOS.Authorization:can(source, "system.config.manage", {})
        if not auth.ok then return errorResult("AUTH_FORBIDDEN", "Only authorized system callers may create non-citizen requests.") end
    end
    return CivicOS.RequestService:create(source, input, { sourceType = sourceType, sourceResource = "civicos-nui" })
end

Api.handlers["request.patch"] = function(source, input)
    input = tableValue(input)
    local id, failure = number(input.id, "id")
    if not id then return failure end
    return CivicOS.RequestService:patch(source, id, input.expectedVersion, input.patch)
end

Api.handlers["request.transition"] = function(source, input)
    input = tableValue(input)
    local id, failure = number(input.id, "id")
    if not id then return failure end
    return CivicOS.RequestService:transition(source, id, input.expectedVersion, input.targetStatus, input.reason)
end

Api.handlers["request.comment.add"] = function(source, input)
    input = tableValue(input)
    local id, failure = number(input.id, "id")
    if not id then return failure end
    return CivicOS.RequestCommentService:add(source, id, input.body, input.visibility)
end

Api.handlers["request.comment.list"] = function(source, input)
    input = tableValue(input)
    local id, failure = number(input.id, "id")
    if not id then return failure end
    local result = CivicOS.RequestCommentService:list(source, id, input.page, input.pageSize)
    if not result.ok then return result end
    return { ok = true, data = CivicOS.Serializers.paginated(result.data, input.page, input.pageSize) }
end

Api.handlers["workorder.list"] = function(source, input)
    input = tableValue(input)
    local result = CivicOS.WorkOrderService:list(source, input)
    if not result.ok then return result end
    local items = {}
    for _, item in ipairs(result.data) do items[#items + 1] = CivicOS.DTO.workOrderListItem(item) end
    return { ok = true, data = CivicOS.Serializers.paginated(items, input.page, input.pageSize) }
end

Api.handlers["workorder.get"] = function(source, input)
    local id, failure = number(tableValue(input).id, "id")
    if not id then return failure end
    return CivicOS.WorkOrderService:get(source, id)
end

Api.handlers["workorder.convert"] = function(source, input)
    input = tableValue(input)
    local id, failure = number(input.requestId, "requestId")
    if not id then return failure end
    return CivicOS.WorkOrderService:convert(source, id, input.expectedVersion, input.serviceCode, input.overrides)
end

Api.handlers["workorder.assign"] = function(source, input)
    input = tableValue(input)
    local id, failure = number(input.workorderId, "workorderId")
    if not id then return failure end
    local employeeId, employeeFailure = number(input.employeeId, "employeeId")
    if not employeeId then return employeeFailure end
    return CivicOS.DispatchService:assign(source, id, input.expectedVersion, employeeId, input.reason)
end

Api.handlers["workorder.selfAssign"] = function(source, input)
    input = tableValue(input)
    local id, failure = number(input.workorderId, "workorderId")
    if not id then return failure end
    return CivicOS.DispatchService:selfAssign(source, id, input.expectedVersion)
end

Api.handlers["workorder.transition"] = function(source, input)
    input = tableValue(input)
    local id, failure = number(input.workorderId, "workorderId")
    if not id then return failure end
    return CivicOS.WorkOrderService:transition(source, id, input.expectedVersion, input.targetStatus, input.reason)
end

Api.handlers["checklist.get"] = function(source, input)
    local id, failure = number(tableValue(input).workorderId, "workorderId")
    if not id then return failure end
    return CivicOS.ChecklistService:get(source, id)
end

Api.handlers["checklist.update"] = function(source, input)
    input = tableValue(input)
    local id, failure = number(input.workorderId, "workorderId")
    if not id then return failure end
    return CivicOS.ChecklistService:update(source, id, input.expectedVersion, input.key, input.value)
end

Api.handlers["field.actions"] = function(source, input)
    local id, failure = number(tableValue(input).workorderId, "workorderId")
    if not id then return failure end
    return CivicOS.FieldService:actions(source, id)
end

Api.handlers["field.start"] = function(source, input)
    input = tableValue(input)
    local id, failure = number(input.workorderId, "workorderId")
    if not id then return failure end
    return CivicOS.FieldService:startAction(source, id, input.expectedVersion, input.actionKey)
end

Api.handlers["field.complete"] = function(source, input)
    input = tableValue(input)
    local id, failure = number(input.workorderId, "workorderId")
    if not id then return failure end
    return CivicOS.FieldService:completeAction(source, id, input.token, input.actionKey, input.expectedVersion, input.result)
end

Api.handlers["notification.list"] = function(source, input)
    input = tableValue(input)
    local result = CivicOS.NotificationService:list(source, input.unreadOnly, input.page, input.pageSize)
    if not result.ok then return result end
    return { ok = true, data = CivicOS.Serializers.paginated(result.data, input.page, input.pageSize) }
end

Api.handlers["notification.read"] = function(source, input)
    local id, failure = number(tableValue(input).id, "id")
    if not id then return failure end
    return CivicOS.NotificationService:markRead(source, id)
end

Api.handlers["sla.list"] = function(source, input)
    local id, failure = number(tableValue(input).requestId, "requestId")
    if not id then return failure end
    local result = CivicOS.SlaService:list(source, id)
    if not result.ok then return result end
    local events = {}
    for _, event in ipairs(result.data) do
        events[#events + 1] = {
            id = event.id,
            milestone = event.milestone,
            status = event.status,
            dueAt = event.due_at,
            warningAt = event.warning_at,
            metAt = event.met_at,
            breachedAt = event.breached_at,
            pausedAt = event.paused_at,
            accumulatedPauseSeconds = event.accumulated_pause_seconds,
            exempt = event.exempt == 1 or event.exempt == true,
        }
    end
    return { ok = true, data = events }
end

Api.handlers["sla.pause"] = function(source, input)
    local id, failure = number(tableValue(input).id, "id")
    if not id then return failure end
    return CivicOS.SlaService:pause(source, id)
end

Api.handlers["sla.resume"] = function(source, input)
    local id, failure = number(tableValue(input).id, "id")
    if not id then return failure end
    return CivicOS.SlaService:resume(source, id)
end

Api.handlers["sla.exempt"] = function(source, input)
    local id, failure = number(tableValue(input).id, "id")
    if not id then return failure end
    return CivicOS.SlaService:exempt(source, id)
end

Api.handlers["escalation.list"] = function(source)
    local result = CivicOS.EscalationService:list(source)
    if not result.ok then return result end
    local items = {}
    for _, item in ipairs(result.data) do
        items[#items + 1] = {
            id = item.id,
            entityType = item.entity_type,
            entityId = item.entity_id,
            severity = item.severity,
            reason = item.reason,
            status = item.status,
            acknowledgedBy = item.acknowledged_by,
            acknowledgedAt = item.acknowledged_at,
            metadata = CivicOS.Repository.decode(item.metadata),
            createdAt = item.created_at,
        }
    end
    return { ok = true, data = items }
end

Api.handlers["escalation.acknowledge"] = function(source, input)
    local id, failure = number(tableValue(input).id, "id")
    if not id then return failure end
    return CivicOS.EscalationService:acknowledge(source, id)
end

Api.handlers["inspection.get"] = function(source, input)
    local id, failure = number(tableValue(input).id, "id")
    if not id then return failure end
    return CivicOS.InspectionService:get(source, id)
end

Api.handlers["inspection.latest"] = function(source, input)
    local id, failure = number(tableValue(input).workorderId, "workorderId")
    if not id then return failure end
    return CivicOS.InspectionService:latest(source, id)
end

Api.handlers["inspection.create"] = function(source, input)
    input = tableValue(input)
    local id, failure = number(input.workorderId, "workorderId")
    if not id then return failure end
    return CivicOS.InspectionService:create(source, id, input.expectedVersion, input.inspectorIdentifier)
end

Api.handlers["inspection.pass"] = function(source, input)
    input = tableValue(input)
    local id, failure = number(input.id, "id")
    if not id then return failure end
    return CivicOS.InspectionService:pass(source, id, input.notes, input.metadata)
end

Api.handlers["inspection.fail"] = function(source, input)
    input = tableValue(input)
    local id, failure = number(input.id, "id")
    if not id then return failure end
    return CivicOS.InspectionService:fail(source, id, input.notes, input.metadata)
end

Api.handlers["inspection.rework"] = function(source, input)
    local id, failure = number(tableValue(input).id, "id")
    if not id then return failure end
    return CivicOS.InspectionService:rework(source, id, tableValue(input).notes)
end

Api.handlers["evidence.add"] = function(source, input)
    input = tableValue(input)
    local id, failure = number(input.entityId, "entityId")
    if not id then return failure end
    return CivicOS.EvidenceService:add(source, input.entityType, id, input.evidenceType, input.uri, input.metadata)
end

Api.handlers["evidence.list"] = function(source, input)
    input = tableValue(input)
    local id, failure = number(input.entityId, "entityId")
    if not id then return failure end
    return CivicOS.EvidenceService:list(source, input.entityType, id)
end

Api.handlers["evidence.remove"] = function(source, input)
    local id, failure = number(tableValue(input).id, "id")
    if not id then return failure end
    return CivicOS.EvidenceService:remove(source, id)
end

Api.handlers["activity.request"] = function(source, input)
    input = tableValue(input)
    local id, failure = number(input.requestId, "requestId")
    if not id then return failure end
    local result = CivicOS.ActivityService:request(source, id, input.page, input.pageSize)
    if not result.ok then return result end
    return { ok = true, data = CivicOS.Serializers.paginated(result.data, input.page, input.pageSize) }
end

Api.handlers["activity.workorder"] = function(source, input)
    input = tableValue(input)
    local id, failure = number(input.workorderId, "workorderId")
    if not id then return failure end
    local result = CivicOS.ActivityService:workorder(source, id, input.page, input.pageSize)
    if not result.ok then return result end
    return { ok = true, data = CivicOS.Serializers.paginated(result.data, input.page, input.pageSize) }
end

Api.handlers["audit.list"] = function(source, input)
    input = tableValue(input)
    local id, failure = number(input.entityId, "entityId")
    if not id then return failure end
    local result = CivicOS.AuditService:list(source, input.entityType, id, input.page, input.pageSize)
    if not result.ok then return result end
    return { ok = true, data = CivicOS.Serializers.paginated(result.data, input.page, input.pageSize) }
end

Api.handlers["crew.list"] = function(source, input)
    local result = CivicOS.CrewService:list(source, tableValue(input).departmentId)
    if not result.ok then return result end
    local crews = {}
    for _, crew in ipairs(result.data) do
        crews[#crews + 1] = {
            id = crew.id,
            reference = crew.reference,
            name = crew.name,
            departmentId = crew.department_id,
            status = crew.status,
            leaderEmployeeId = crew.leader_employee_id,
            createdAt = crew.created_at,
        }
    end
    return { ok = true, data = crews }
end

Api.handlers["crew.members"] = function(source, input)
    local id, failure = number(tableValue(input).crewId, "crewId")
    if not id then return failure end
    return CivicOS.CrewService:members(source, id)
end

Api.handlers["crew.create"] = function(source, input)
    input = tableValue(input)
    return CivicOS.CrewService:create(source, input.name, input.departmentId, input.metadata)
end

Api.handlers["crew.join"] = function(source, input)
    local id, failure = number(tableValue(input).crewId, "crewId")
    if not id then return failure end
    return CivicOS.CrewService:join(source, id)
end

Api.handlers["crew.leave"] = function(source, input)
    local id, failure = number(tableValue(input).crewId, "crewId")
    if not id then return failure end
    return CivicOS.CrewService:leave(source, id)
end

Api.handlers["crew.transfer"] = function(source, input)
    input = tableValue(input)
    local crewId, crewFailure = number(input.crewId, "crewId")
    if not crewId then return crewFailure end
    local employeeId, employeeFailure = number(input.employeeId, "employeeId")
    if not employeeId then return employeeFailure end
    return CivicOS.CrewService:transfer(source, crewId, employeeId)
end

Api.handlers["crew.disband"] = function(source, input)
    local id, failure = number(tableValue(input).crewId, "crewId")
    if not id then return failure end
    return CivicOS.CrewService:disband(source, id)
end

Api.handlers["crew.assign"] = function(source, input)
    input = tableValue(input)
    local workorderId, workorderFailure = number(input.workorderId, "workorderId")
    if not workorderId then return workorderFailure end
    local crewId, crewFailure = number(input.crewId, "crewId")
    if not crewId then return crewFailure end
    return CivicOS.CrewService:assignWorkorder(source, workorderId, input.expectedVersion, crewId, input.reason)
end

Api.handlers["contribution.list"] = function(source, input)
    local id, failure = number(tableValue(input).workorderId, "workorderId")
    if not id then return failure end
    local result = CivicOS.ContributionService:list(source, id)
    if not result.ok then return result end
    local items = {}
    for _, item in ipairs(result.data) do
        items[#items + 1] = {
            id = item.id,
            employeeId = item.employee_id,
            type = item.contribution_type,
            actionKey = item.action_key,
            durationSeconds = item.duration_seconds,
            metadata = item.metadata,
            createdAt = item.created_at,
        }
    end
    return { ok = true, data = items }
end

Api.handlers["incident.get"] = function(source, input)
    local id, failure = number(tableValue(input).requestId, "requestId")
    if not id then return failure end
    return CivicOS.IncidentService:get(source, id)
end

Api.handlers["analytics.dashboard"] = function(source, input)
    input = tableValue(input)
    return CivicOS.AnalyticsService:dashboard(source, input.startDate, input.endDate)
end

Api.handlers["health"] = function(source)
    return CivicOS.HealthService:check(source, false)
end

function Api.dispatch(source, operation, input)
    if type(operation) ~= "string" or operation == "" then return errorResult("CORE_INVALID_INPUT", "API operation is required.") end
    local handler = Api.handlers[operation]
    if not handler then return errorResult("API_OPERATION_NOT_FOUND", "API operation is not available.") end
    local identity = CivicOS.Authorization:identity(source)
    if not identity.ok then return identity end
    local limited = CivicOS.RateLimit:allow(identity.data.persistentIdentifier, "generic_callback")
    if not limited.ok then return limited end
    local ok, result = xpcall(function()
        return handler(source, input)
    end, callbackTraceback)
    if not ok then
        if CivicOS.Logger then
            CivicOS.Logger.error("API", "Callback handler failed.", { operation = operation, error = result })
        end
        return errorResult("API_HANDLER_FAILED", "The requested operation could not be completed.")
    end
    local safeResult = CivicOS.Serializers.jsonSafe(CivicOS.Serializers.safeError(result))
    if type(safeResult) ~= "table" then
        return errorResult("API_RESPONSE_INVALID", "The API response could not be serialized.")
    end
    return safeResult
end

if type(RegisterNetEvent) == "function" and type(AddEventHandler) == "function" then
    RegisterNetEvent("civicos:server:api:call", function(requestId, operation, input)
        local target = source
        local result = Api.dispatch(target, operation, input)
        if type(TriggerClientEvent) == "function" then
            TriggerClientEvent("civicos:client:api:result", target, requestId, result)
        end
    end)
end

CivicOS.Api = Api
return Api

local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS

local InspectionService = {}

local function errorResult(code, message, details)
    return CivicOS.Result.err(code, message, details)
end

local function workorder(id)
    local result = CivicOS.WorkOrderRepository:findById(id)
    if not result.ok then return result end
    if not result.data[1] then return errorResult("CORE_NOT_FOUND", "Work order not found.") end
    return { ok = true, data = result.data[1] }
end

local function authorize(source, entity)
    return CivicOS.Authorization:can(source, "field.inspection.execute", { departmentId = entity.department_id })
end

function InspectionService:create(source, workorderId, expectedVersion, inspectorIdentifier)
    local entityResult = workorder(workorderId)
    if not entityResult.ok then return entityResult end
    local entity = entityResult.data
    local template = CivicOS.WorkOrderTemplateService:get(entity.template_key)
    if not template.ok then return template end
    if not template.data.inspectionRequired then return errorResult("INSPECTION_NOT_REQUIRED", "This work order does not require inspection.") end
    if entity.status ~= CivicOS.Enums.WorkOrderStatus.WORKING then
        return errorResult("INSPECTION_INVALID_STATE", "Inspection can only start from a working work order.")
    end
    local auth = authorize(source, entity)
    if not auth.ok then return auth end
    if tonumber(expectedVersion) ~= tonumber(entity.version) then return errorResult("CORE_VERSION_CONFLICT", "Work order version conflict.") end
    local latest = CivicOS.InspectionRepository:findLatest(workorderId)
    if not latest.ok then return latest end
    if latest.data[1] and latest.data[1].status ~= "closed" and latest.data[1].status ~= "failed" then
        return errorResult("INSPECTION_ALREADY_OPEN", "An inspection is already open for this work order.")
    end
    local inspector = inspectorIdentifier or auth.data.identity.persistentIdentifier
    local created = CivicOS.InspectionRepository:create(workorderId, inspector, { templateKey = entity.template_key })
    if not created.ok then return created end
    local updated = CivicOS.WorkOrderRepository:updateStatus(workorderId, expectedVersion, CivicOS.Enums.WorkOrderStatus.PENDING_INSPECTION)
    if not updated.ok then return updated end
    return { ok = true, data = { inspectionId = created.data, workorderId = workorderId, status = "pending", version = updated.data.version } }
end

function InspectionService:isPassed(workorderId)
    local latest = CivicOS.InspectionRepository:findLatest(workorderId)
    if not latest.ok then return latest end
    return { ok = true, data = latest.data[1] and latest.data[1].status == "passed" }
end

function InspectionService:get(source, id)
    local inspection = CivicOS.InspectionRepository:findById(id)
    if not inspection.ok then return inspection end
    local item = inspection.data[1]
    if not item then return errorResult("CORE_NOT_FOUND", "Inspection not found.") end
    local entityResult = workorder(item.workorder_id)
    if not entityResult.ok then return entityResult end
    local auth = authorize(source, entityResult.data)
    if not auth.ok then return auth end
    return { ok = true, data = {
        id = item.id,
        workorderId = item.workorder_id,
        inspectorIdentifier = item.inspector_identifier,
        status = item.status,
        notes = item.notes,
        metadata = item.metadata,
        createdAt = item.created_at,
        updatedAt = item.updated_at,
    } }
end

function InspectionService:pass(source, id, notes, metadata)
    local current = CivicOS.InspectionRepository:findById(id)
    if not current.ok then return current end
    local item = current.data[1]
    if not item then return errorResult("CORE_NOT_FOUND", "Inspection not found.") end
    local entityResult = workorder(item.workorder_id)
    if not entityResult.ok then return entityResult end
    local auth = authorize(source, entityResult.data)
    if not auth.ok then return auth end
    local transition = CivicOS.InspectionStateMachine.transition(item, "passed")
    if not transition.ok then return transition end
    local checklist = CivicOS.ChecklistService and CivicOS.ChecklistService:validateValues(entityResult.data)
    if not checklist or not checklist.ok then return checklist or errorResult("CHECKLIST_UNAVAILABLE", "Checklist service is unavailable.") end
    local template = CivicOS.WorkOrderTemplateService:get(entityResult.data.template_key)
    if not template.ok then return template end
    for _, requiredType in ipairs(template.data.requiredEvidence or {}) do
        local evidence = CivicOS.EvidenceService:list(source, "workorder", item.workorder_id)
        if not evidence.ok then return evidence end
        local found = false
        for _, entry in ipairs(evidence.data) do if entry.type == requiredType then found = true break end end
        if not found then return errorResult("INSPECTION_EVIDENCE_REQUIRED", "Required inspection evidence is missing.", { evidenceType = requiredType }) end
    end
    local passed = CivicOS.InspectionRepository:update(id, item.status, "passed", notes, metadata)
    if not passed.ok then return passed end
    if CivicOS.AuditService then CivicOS.AuditService:record(source, { entityType = "inspection", entityId = id, action = "passed", after = { notes = notes } }) end
    return passed
end

function InspectionService:fail(source, id, notes, metadata)
    local current = CivicOS.InspectionRepository:findById(id)
    if not current.ok then return current end
    local item = current.data[1]
    if not item then return errorResult("CORE_NOT_FOUND", "Inspection not found.") end
    local entityResult = workorder(item.workorder_id)
    if not entityResult.ok then return entityResult end
    local auth = authorize(source, entityResult.data)
    if not auth.ok then return auth end
    local transition = CivicOS.InspectionStateMachine.transition(item, "failed")
    if not transition.ok then return transition end
    local updated = CivicOS.InspectionRepository:update(id, item.status, "failed", notes, metadata)
    if updated.ok and CivicOS.AuditService then CivicOS.AuditService:record(source, { entityType = "inspection", entityId = id, action = "failed", after = { notes = notes } }) end
    return updated
end

function InspectionService:rework(source, id, notes)
    local current = CivicOS.InspectionRepository:findById(id)
    if not current.ok then return current end
    local item = current.data[1]
    if not item then return errorResult("CORE_NOT_FOUND", "Inspection not found.") end
    local entityResult = workorder(item.workorder_id)
    if not entityResult.ok then return entityResult end
    local auth = authorize(source, entityResult.data)
    if not auth.ok then return auth end
    local transition = CivicOS.InspectionStateMachine.transition(item, "rework_required")
    if not transition.ok then return transition end
    local updated = CivicOS.InspectionRepository:update(id, item.status, "rework_required", notes, item.metadata)
    if not updated.ok then return updated end
    if entityResult.data.status == CivicOS.Enums.WorkOrderStatus.PENDING_INSPECTION then
        CivicOS.WorkOrderRepository:updateStatus(entityResult.data.id, entityResult.data.version, CivicOS.Enums.WorkOrderStatus.REWORK_REQUIRED)
    end
    if CivicOS.AuditService then CivicOS.AuditService:record(source, { entityType = "inspection", entityId = id, action = "rework_required", after = { notes = notes } }) end
    return updated
end

if type(RegisterNetEvent) == "function" and type(AddEventHandler) == "function" then
    RegisterNetEvent("civicos:server:inspection:create", function(workorderId, expectedVersion, inspectorIdentifier)
        local result = InspectionService:create(source, workorderId, expectedVersion, inspectorIdentifier)
        if type(TriggerClientEvent) == "function" then TriggerClientEvent("civicos:client:inspection:result", source, result) end
    end)
end

CivicOS.InspectionService = InspectionService
return InspectionService

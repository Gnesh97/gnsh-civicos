local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS

local RecoveryService = { _started = false }

local orphanableStatuses = {
    assigned = true,
    acknowledged = true,
    declined = true,
    reassigned = true,
    en_route = true,
    on_scene = true,
    working = true,
    blocked = true,
    on_hold = true,
    pending_inspection = true,
    rework_required = true,
}

local function errorResult(code, message, details)
    return CivicOS.Result.err(code, message, details)
end

function RecoveryService:run()
    local batch = CivicOS.Config and CivicOS.Config.Recovery and CivicOS.Config.Recovery.MaxRecoveryBatch or 500
    if not CivicOS.WorkOrderRepository then
        return errorResult("RECOVERY_UNAVAILABLE", "Work order repository is not registered.")
    end
    local activeRequests = CivicOS.RequestRepository and CivicOS.RequestRepository:listActive(batch)
    if activeRequests and not activeRequests.ok then return activeRequests end
    local active = CivicOS.WorkOrderRepository:listActive(batch)
    if not active.ok then return active end
    local normalized, releasedEmployees, releasedCrews = 0, 0, 0
    for _, workorder in ipairs(active.data) do
        if workorder.assigned_employee_id and CivicOS.EmployeeRepository then
            local employee = CivicOS.EmployeeRepository:findById(workorder.assigned_employee_id)
            if not employee.ok then return employee end
            if not employee.data[1] then
                local released = CivicOS.WorkOrderRepository:releaseAssignment(workorder.id, workorder.version, "recovery_missing_employee")
                if released.ok then releasedEmployees = releasedEmployees + 1 end
            end
        end
        if workorder.assigned_crew_id and CivicOS.CrewRepository then
            local crew = CivicOS.CrewRepository:findById(workorder.assigned_crew_id)
            if not crew.ok then return crew end
            if not crew.data[1] or crew.data[1].status ~= "active" then
                local released = CivicOS.WorkOrderRepository:releaseCrewAssignment(workorder.id, workorder.version, "recovery_missing_crew")
                if released.ok then releasedCrews = releasedCrews + 1 end
            end
        end
        local hasAssignment = workorder.assigned_employee_id ~= nil or workorder.assigned_crew_id ~= nil
        if not hasAssignment and orphanableStatuses[workorder.status]
            and CivicOS.WorkOrderRepository.normalizeUnassigned then
            local normalizedResult = CivicOS.WorkOrderRepository:normalizeUnassigned(
                workorder.id, workorder.version, "recovery_orphaned_state"
            )
            if normalizedResult.ok then normalized = normalized + 1 end
        end
    end
    if CivicOS.SlaService then
        local sla = CivicOS.SlaService:processDue()
        if sla and not sla.ok then return sla end
    end
    local summary = {
        requests = activeRequests and #activeRequests.data or 0,
        active = #active.data,
        normalized = normalized,
        releasedEmployees = releasedEmployees,
        releasedCrews = releasedCrews,
    }
    if CivicOS.AuditService then
        CivicOS.AuditService:record(nil, { entityType = "system", action = "recovery", after = summary })
    end
    return { ok = true, data = summary }
end

function RecoveryService:start()
    if self._started then return { ok = true, data = true } end
    self._started = true
    return self:run()
end

CivicOS.RecoveryService = RecoveryService
return RecoveryService

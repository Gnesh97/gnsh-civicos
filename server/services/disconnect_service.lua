local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS

local DisconnectService = { _started = false, _sessions = {}, _pending = {} }

local function errorResult(code, message, details)
    return CivicOS.Result.err(code, message, details)
end

local function delayed(seconds, callback)
    if type(SetTimeout) == "function" then
        SetTimeout(seconds * 1000, callback)
    elseif type(CreateThread) == "function" then
        CreateThread(function() Wait(seconds * 1000); callback() end)
    end
end

function DisconnectService:releaseSoloAssignments(session)
    if not session or not session.persistentIdentifier then
        return errorResult("RECOVERY_INVALID_SESSION", "Disconnect session is invalid.")
    end
    local employee = CivicOS.EmployeeRepository:findByIdentifier(session.persistentIdentifier)
    if not employee.ok or not employee.data[1] then return employee end
    local pageSize, maxRows = 100, 500
    local configured = CivicOS.Config and CivicOS.Config.Recovery and CivicOS.Config.Recovery.MaxRecoveryBatch
    maxRows = math.min(math.max(1, tonumber(configured) or maxRows), 1000)
    local released, scanned, afterId = 0, 0, 0
    while scanned < maxRows do
        local workorders
        if CivicOS.WorkOrderRepository.listByEmployee then
            workorders = CivicOS.WorkOrderRepository:listByEmployee(
                employee.data[1].id, afterId, math.min(pageSize, maxRows - scanned)
            )
        else
            workorders = CivicOS.WorkOrderRepository:list({
                employeeId = employee.data[1].id,
                page = 1,
                pageSize = math.min(pageSize, maxRows - scanned),
            })
        end
        if not workorders.ok then return workorders end
        if #workorders.data == 0 then break end
        for _, workorder in ipairs(workorders.data) do
            scanned = scanned + 1
            afterId = math.max(afterId, tonumber(workorder.id) or afterId)
            if not workorder.assigned_crew_id and workorder.status ~= "closed" and workorder.status ~= "cancelled" then
                local result = CivicOS.WorkOrderRepository:releaseAssignment(workorder.id, workorder.version, "disconnect_timeout")
                if result.ok then released = released + 1 end
            end
        end
        if #workorders.data < pageSize then break end
    end
    return { ok = true, data = { released = released, scanned = scanned } }
end

function DisconnectService:onLoaded(identity)
    if not identity or not identity.source or not identity.persistentIdentifier then return end
    local source = tonumber(identity.source) or identity.source
    local previous = self._sessions[source]
    local pending = self._pending[identity.persistentIdentifier]
    local reconnecting = (previous and previous.persistentIdentifier == identity.persistentIdentifier) or pending ~= nil

    -- A reconnect can receive a different FiveM source slot.  Cancel the
    -- identifier-scoped grace callback before installing the new session so a
    -- stale timeout cannot release the restored assignment.
    if pending then
        self._pending[identity.persistentIdentifier] = nil
        if self._sessions[pending.source] == pending then
            self._sessions[pending.source] = nil
        end
    end

    local session = {
        source = source,
        persistentIdentifier = identity.persistentIdentifier,
        job = identity.job,
    }
    self._sessions[source] = session
    local employee = CivicOS.EmployeeRepository:findByIdentifier(session.persistentIdentifier)
    if employee.ok and employee.data[1] then
        local availability = session.job and session.job.onDuty and "available" or "offline"
        CivicOS.EmployeeRepository:updateAvailability(employee.data[1].id, availability)
        if CivicOS.CrewRepository and CivicOS.CrewRepository.restoreMemberStatus then
            CivicOS.CrewRepository:restoreMemberStatus(employee.data[1].id)
        end
        local workorders = CivicOS.WorkOrderRepository:list({ employeeId = employee.data[1].id, page = 1, pageSize = 100 })
        if reconnecting and workorders.ok and CivicOS.NotificationService then
            for _, workorder in ipairs(workorders.data) do
                CivicOS.NotificationService:create(session.persistentIdentifier, "reconnect", "notify.reconnect.title", "notify.reconnect.body", { workorderId = workorder.id }, source)
            end
        end
    end
end

function DisconnectService:onUnloaded(sourceOrIdentity)
    local source = type(sourceOrIdentity) == "table" and sourceOrIdentity.source or tonumber(sourceOrIdentity)
    source = tonumber(source) or source
    local session = source and self._sessions[source]
    if not session then return end
    self._sessions[source] = nil
    self._pending[session.persistentIdentifier] = session
    local employee = session.persistentIdentifier and CivicOS.EmployeeRepository:findByIdentifier(session.persistentIdentifier)
    if employee and employee.ok and employee.data[1] then
        CivicOS.EmployeeRepository:updateAvailability(employee.data[1].id, "offline")
    end
    local grace = CivicOS.Config and CivicOS.Config.Recovery and CivicOS.Config.Recovery.DisconnectGraceSeconds or 300
    delayed(grace, function()
        if self._pending[session.persistentIdentifier] ~= session then return end
        self._pending[session.persistentIdentifier] = nil
        self:releaseSoloAssignments(session)
    end)
end

function DisconnectService:start()
    if self._started or not CivicOS.Framework then return end
    self._started = true
    CivicOS.Framework.onPlayerLoaded(function(identity) self:onLoaded(identity) end)
    CivicOS.Framework.onPlayerUnloaded(function(source) self:onUnloaded(source) end)
end

CivicOS.DisconnectService = DisconnectService
return DisconnectService

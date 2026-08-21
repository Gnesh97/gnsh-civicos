local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS

local StateMachine = {
    transitions = {
        pending = { assigned = true, passed = true, failed = true, rework_required = true },
        assigned = { passed = true, failed = true, rework_required = true },
        failed = { rework_required = true },
        rework_required = { assigned = true, passed = true, failed = true },
        passed = { closed = true },
        closed = {},
    },
}

function StateMachine.can(fromStatus, toStatus)
    return StateMachine.transitions[fromStatus] and StateMachine.transitions[fromStatus][toStatus] == true
end

function StateMachine.transition(entity, target)
    if not entity or not StateMachine.can(entity.status, target) then
        return CivicOS.Result.err("INSPECTION_INVALID_STATE", "Inspection transition is not allowed.", {
            from = entity and entity.status,
            to = target,
        })
    end
    return { ok = true, data = { from = entity.status, to = target } }
end

CivicOS.InspectionStateMachine = StateMachine
return StateMachine

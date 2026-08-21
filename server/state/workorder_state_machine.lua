local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS

local StateMachine = {
    transitions = {
        created = { unassigned = true },
        unassigned = { assigned = true, cancelled = true },
        assigned = { acknowledged = true, declined = true, reassigned = true, cancelled = true },
        acknowledged = { en_route = true, on_hold = true, reassigned = true },
        en_route = { on_scene = true, on_hold = true, reassigned = true },
        on_scene = { working = true, blocked = true, on_hold = true },
        working = { pending_inspection = true, completed = true, blocked = true, failed = true },
        pending_inspection = { completed = true, rework_required = true },
        rework_required = { working = true },
        completed = { closed = true },
        blocked = { working = true, on_hold = true, cancelled = true },
        declined = { reassigned = true, cancelled = true },
        reassigned = { acknowledged = true, cancelled = true },
        on_hold = { acknowledged = true, en_route = true, working = true, cancelled = true },
        failed = { working = true, cancelled = true },
        closed = {},
        cancelled = {},
    },
}

function StateMachine.can(fromStatus, toStatus)
    return StateMachine.transitions[fromStatus] and StateMachine.transitions[fromStatus][toStatus] == true
end

function StateMachine.transition(entity, toStatus, context)
    if not entity or not StateMachine.can(entity.status, toStatus) then
        return CivicOS.Result.err("WORKORDER_INVALID_STATE", "Work order transition is not allowed.", {
            from = entity and entity.status,
            to = toStatus,
        })
    end
    if toStatus == "completed" and context and context.inspectionRequired and not context.inspectionPassed then
        return CivicOS.Result.err("WORKORDER_INSPECTION_REQUIRED", "Inspection must pass before completion.")
    end
    if toStatus == "working" and context and context.dependenciesUnresolved then
        return CivicOS.Result.err("WORKORDER_DEPENDENCY_BLOCKED", "A dependency is not resolved.")
    end
    return { ok = true, data = { from = entity.status, to = toStatus, reason = context and context.reason } }
end

CivicOS.WorkOrderStateMachine = StateMachine
return StateMachine

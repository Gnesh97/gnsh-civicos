local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS

local StateMachine = {
    transitions = {
        draft = { submitted = true },
        submitted = { triaged = true, cancelled = true },
        triaged = { accepted = true, rejected = true, duplicate = true, on_hold = true },
        accepted = { converted = true, on_hold = true, cancelled = true },
        converted = { in_progress = true },
        in_progress = { resolved = true, on_hold = true, waiting_external = true },
        resolved = { closed = true, reopened = true },
        reopened = { triaged = true, in_progress = true },
        on_hold = { triaged = true, accepted = true, in_progress = true, cancelled = true },
        waiting_external = { in_progress = true, resolved = true, cancelled = true },
        rejected = {},
        duplicate = {},
        closed = {},
        cancelled = {},
    },
}

function StateMachine.can(fromStatus, toStatus)
    return StateMachine.transitions[fromStatus] and StateMachine.transitions[fromStatus][toStatus] == true
end

function StateMachine.transition(entity, toStatus, context)
    context = type(context) == "table" and context or {}
    if not entity or not StateMachine.can(entity.status, toStatus) then
        return CivicOS.Result.err("REQUEST_INVALID_STATE", "Request transition is not allowed.", {
            from = entity and entity.status,
            to = toStatus,
        })
    end
    return {
        ok = true,
        data = {
            from = entity.status,
            to = toStatus,
            actorIdentifier = context.actorIdentifier,
            reason = context.reason,
            occurredAt = context.occurredAt,
        },
    }
end

CivicOS.RequestStateMachine = StateMachine
return StateMachine

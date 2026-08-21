local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS
local Repository = CivicOS.Repository

local ContributionRepository = {}

function ContributionRepository:create(contribution)
    return Repository.db():query([[INSERT INTO civicos_contributions
        (workorder_id, employee_id, contribution_type, action_key, duration_seconds, metadata)
        VALUES (?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE duration_seconds = VALUES(duration_seconds), metadata = VALUES(metadata)]], {
        contribution.workorderId, contribution.employeeId, contribution.contributionType,
        contribution.actionKey, contribution.durationSeconds or 0, Repository.encode(contribution.metadata),
    })
end

function ContributionRepository:listByWorkorder(workorderId)
    local result = Repository.db():query([[SELECT id, workorder_id, employee_id, contribution_type,
        action_key, duration_seconds, metadata, created_at FROM civicos_contributions
        WHERE workorder_id = ? ORDER BY created_at ASC]], { workorderId })
    if not result.ok then return result end
    for _, row in ipairs(result.data or {}) do row.metadata = Repository.decode(row.metadata) end
    return { ok = true, data = result.data or {} }
end

CivicOS.ContributionRepository = ContributionRepository
return ContributionRepository

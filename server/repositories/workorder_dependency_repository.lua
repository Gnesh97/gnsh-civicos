local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS
local Repository = CivicOS.Repository

local DependencyRepository = {}

function DependencyRepository:create(workorderId, dependsOnId, dependencyType)
    return Repository.db():insert([[INSERT INTO civicos_workorder_dependencies
        (workorder_id, depends_on_workorder_id, dependency_type) VALUES (?, ?, ?)]], {
        workorderId, dependsOnId, dependencyType or "blocks",
    })
end

function DependencyRepository:remove(workorderId, dependsOnId)
    return Repository.db():update(
        "DELETE FROM civicos_workorder_dependencies WHERE workorder_id = ? AND depends_on_workorder_id = ?",
        { workorderId, dependsOnId }
    )
end

function DependencyRepository:list(workorderId)
    return Repository.db():query([[SELECT id, workorder_id, depends_on_workorder_id,
        dependency_type, created_at FROM civicos_workorder_dependencies WHERE workorder_id = ?]], { workorderId })
end

function DependencyRepository:listAll()
    return Repository.db():query([[SELECT id, workorder_id, depends_on_workorder_id,
        dependency_type, created_at FROM civicos_workorder_dependencies]])
end

CivicOS.WorkOrderDependencyRepository = DependencyRepository
return DependencyRepository

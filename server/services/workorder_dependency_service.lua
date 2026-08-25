local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS

local DependencyService = {}

local function errorResult(code, message, details)
    return CivicOS.Result.err(code, message, details)
end

local function graph(edges)
    local result = {}
    for _, edge in ipairs(edges or {}) do
        result[edge.workorder_id] = result[edge.workorder_id] or {}
        result[edge.workorder_id][#result[edge.workorder_id] + 1] = edge.depends_on_workorder_id
    end
    return result
end

local function reachable(edges, start, target, visited)
    if start == target then return true end
    visited[start] = true
    for _, nextId in ipairs(edges[start] or {}) do
        if not visited[nextId] and reachable(edges, nextId, target, visited) then return true end
    end
    return false
end

function DependencyService:create(source, workorderId, dependsOnId)
    local workorder = CivicOS.WorkOrderRepository:findById(workorderId)
    if not workorder.ok then return workorder end
    local entity = workorder.data[1]
    if not entity then return errorResult("CORE_NOT_FOUND", "Work order not found.") end
    local auth = CivicOS.Authorization:can(source, "workorder.dependency.manage", { departmentId = entity and entity.department_id })
    if not auth.ok then return auth end
    if workorderId == dependsOnId then return errorResult("WORKORDER_DEPENDENCY_CYCLE", "A work order cannot depend on itself.") end
    local all = CivicOS.WorkOrderDependencyRepository:listAll()
    if not all.ok then return all end
    local edges = graph(all.data)
    edges[workorderId] = edges[workorderId] or {}
    edges[workorderId][#edges[workorderId] + 1] = dependsOnId
    if reachable(edges, dependsOnId, workorderId, {}) then
        return errorResult("WORKORDER_DEPENDENCY_CYCLE", "Dependency would create a cycle.")
    end
    return CivicOS.WorkOrderDependencyRepository:create(workorderId, dependsOnId, "blocks")
end

function DependencyService:remove(source, workorderId, dependsOnId)
    local workorder = CivicOS.WorkOrderRepository:findById(workorderId)
    if not workorder.ok then return workorder end
    local entity = workorder.data[1]
    if not entity then return errorResult("CORE_NOT_FOUND", "Work order not found.") end
    local auth = CivicOS.Authorization:can(source, "workorder.dependency.manage", {
        departmentId = entity.department_id,
    })
    if not auth.ok then return auth end
    return CivicOS.WorkOrderDependencyRepository:remove(workorderId, dependsOnId)
end

function DependencyService:list(workorderId)
    return CivicOS.WorkOrderDependencyRepository:list(workorderId)
end

function DependencyService:hasUnresolved(workorderId)
    local dependencies = self:list(workorderId)
    if not dependencies.ok then return dependencies end
    for _, edge in ipairs(dependencies.data) do
        local workorder = CivicOS.WorkOrderRepository:findById(edge.depends_on_workorder_id)
        if workorder.ok and workorder.data[1] and workorder.data[1].status ~= "completed" and workorder.data[1].status ~= "closed" then
            return { ok = true, data = true }
        end
    end
    return { ok = true, data = false }
end

CivicOS.WorkOrderDependencyService = DependencyService
return DependencyService

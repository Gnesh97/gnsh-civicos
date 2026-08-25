-- Regression coverage for dependency removal department authorization.
-- Run from the resource root with: lua tests/unit/test_dependency_scope.lua

local function errorResult(code, message)
    return { ok = false, error = { code = code, message = message } }
end

local capturedResource
local missing = false

_G.CivicOS = {
    Result = { err = errorResult },
    WorkOrderRepository = {
        findById = function(_, id)
            if missing then return { ok = true, data = {} } end
            return { ok = true, data = { { id = id, department_id = 9 } } }
        end,
    },
    Authorization = {
        can = function(_, source, permission, resource)
            assert(source == 10 and permission == "workorder.dependency.manage", "dependency permission is incorrect")
            capturedResource = resource
            return { ok = true, data = { identity = { persistentIdentifier = "license:dispatcher" }, scope = "department" } }
        end,
    },
    WorkOrderDependencyRepository = {
        remove = function(_, workorderId, dependsOnId)
            assert(workorderId == 7 and dependsOnId == 8, "dependency removal arguments are incorrect")
            return { ok = true, data = { affectedRows = 1 } }
        end,
    },
}

local dependency = dofile("server/services/workorder_dependency_service.lua")
local result = dependency:remove(10, 7, 8)
assert(result.ok, "a department-scoped dependency removal should succeed")
assert(capturedResource.departmentId == 9, "dependency removal must authorize the work order department")

missing = true
local missingResult = dependency:remove(10, 7, 8)
assert(not missingResult.ok and missingResult.error.code == "CORE_NOT_FOUND", "missing work order must be rejected")

print("dependency authorization scope regression: PASS")

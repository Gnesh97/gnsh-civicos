-- Regression coverage for evidence mutation authorization.
-- Read access must never substitute for field.evidence.attach.

local function errorResult(code, message, details)
    return { ok = false, error = { code = code, message = message, details = details or {} } }
end

local stored = false
local attachAttempts = 0

_G.CivicOS = {
    Result = { err = errorResult },
    Config = { Evidence = { MaxUriLength = 2048, AllowedDomains = {} } },
    Validation = {
        metadata = function(_, value)
            return { ok = true, data = value }
        end,
    },
    WorkOrderRepository = {
        findById = function()
            return { ok = true, data = { { id = 7, department_id = 4, assigned_employee_id = 22 } } }
        end,
    },
    EmployeeRepository = {
        findById = function()
            return { ok = true, data = { { persistent_identifier = "license:technician" } } }
        end,
    },
    Authorization = {
        can = function(_, _, permission)
            if permission == "field.evidence.attach" then
                attachAttempts = attachAttempts + 1
                return errorResult("AUTH_FORBIDDEN", "Evidence attachment is not allowed.")
            end
            if permission == "workorder.read.department" then
                return { ok = true, data = { identity = { persistentIdentifier = "license:dispatcher" } } }
            end
            return errorResult("AUTH_FORBIDDEN", "Unexpected permission.")
        end,
    },
    Evidence = {
        name = "none",
        store = function()
            stored = true
            return { ok = true, data = { uri = "https://example.test/evidence" } }
        end,
    },
    EvidenceRepository = {
        create = function()
            return { ok = true, data = 1 }
        end,
    },
}

local evidence = dofile("server/services/evidence_service.lua")
local result = evidence:add(10, "workorder", 7, "photo", "https://example.test/photo", {})
assert(not result.ok and result.error.code == "AUTH_FORBIDDEN", "read permission must not grant evidence mutation")
assert(attachAttempts == 1 and not stored, "evidence provider must not run after authorization denial")

print("evidence mutation scope regression: PASS")

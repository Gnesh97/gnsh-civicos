-- Regression coverage for citizen request-detail activity filtering.
-- Internal activity must never be returned to an own-request citizen reader.

local capturedActivity

local function errorResult(code, message, details)
    return { ok = false, error = { code = code, message = message, details = details or {} } }
end

_G.CivicOS = {
    Result = { err = errorResult },
    RequestRepository = {
        findById = function()
            return { ok = true, data = { { id = 7, requester_identifier = "license:citizen", department_id = 4 } } }
        end,
        listActivity = function()
            return {
                ok = true,
                data = {
                    { id = 1, request_id = 7, activity_type = "created", public_data = "public", created_at = "now" },
                    { id = 2, request_id = 7, activity_type = "internal_note", public_data = "secret", created_at = "now" },
                },
            }
        end,
    },
    Authorization = {
        identity = function()
            return { ok = true, data = { role = "CITIZEN" } }
        end,
        can = function(_, _, permission)
            if permission == "request.read.own" then return { ok = true, data = {} } end
            if permission == "request.comment.internal" then return errorResult("AUTH_FORBIDDEN", "not staff") end
            return errorResult("AUTH_FORBIDDEN", "unexpected permission")
        end,
    },
    RequestService = {
        _authorizeRead = function()
            return { ok = true, data = {} }
        end,
    },
    RequestCommentService = {
        list = function()
            return { ok = true, data = {} }
        end,
    },
    Repository = {
        decode = function(_, value) return value end,
    },
    DTO = {
        citizenRequestDetail = function(_, _, activity)
            capturedActivity = activity
            return { activity = activity }
        end,
        staffRequestDetail = function() error("staff DTO must not be selected") end,
    },
}

local api = dofile("server/api/callbacks.lua")
local result = api.handlers["request.get"](1, { id = 7 })
assert(result.ok, "citizen request detail should succeed")
assert(#capturedActivity == 1 and capturedActivity[1].activityType == "created", "internal activity must be filtered from citizen detail")

print("request detail scope regression: PASS")

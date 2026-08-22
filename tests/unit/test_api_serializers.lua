-- Regression test for API responses crossing the FiveM JSON boundary.
-- Run from the resource root with: lua tests/unit/test_api_serializers.lua

_G.CivicOS = {
    Result = {
        err = function(code, message, details)
            return { ok = false, error = { code = code, message = message, details = details or {} } }
        end,
    },
}

dofile("server/api/serializers.lua")

local cyclic = {
    ok = true,
    data = {
        catalog = {
            { code = "pothole", label = "service.pothole" },
        },
        providerCapabilities = {
            available = true,
            callback = function() end,
        },
    },
}
cyclic.data.self = cyclic.data

local safe = CivicOS.Serializers.jsonSafe(cyclic)
assert(safe.ok == true, "result envelope must survive serialization")
assert(safe.data.catalog[1].code == "pothole", "array data must survive serialization")
assert(safe.data.providerCapabilities.available == true, "scalar capability must survive serialization")
assert(safe.data.providerCapabilities.callback == nil, "functions must be omitted")
assert(safe.data.self == nil, "cyclic references must be omitted")

local deep = {}
local cursor = deep
for _ = 1, 40 do
    cursor.child = {}
    cursor = cursor.child
end
local bounded = CivicOS.Serializers.jsonSafe(deep)
local depth = 0
cursor = bounded
while type(cursor) == "table" and cursor.child do
    depth = depth + 1
    cursor = cursor.child
end
assert(depth < 40, "deep tables must be bounded before reaching FiveM JSON")

print("API serializer regression: PASS (functions, cycles, and depth are safe)")

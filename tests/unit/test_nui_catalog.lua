-- Regression test for the shared catalog fallback sent when the panel opens.
-- Run from the resource root with: lua tests/unit/test_nui_catalog.lua

_G.CivicOS = {}
dofile("config/service_catalog.lua")

local sent = {}
local command
_G.SendNUIMessage = function(message) sent[#sent + 1] = message end
_G.RegisterCommand = function(_, callback) command = callback end

dofile("client/nui.lua")
assert(type(command) == "function", "CivicOS command must be registered")
command()

local catalog = sent[#sent] and sent[#sent].payload and sent[#sent].payload.catalog
assert(type(catalog) == "table" and #catalog == 8, "open message must include shared service catalog")
assert(catalog[1].code and catalog[1].label, "catalog fallback entries must expose code and label")

print("NUI catalog fallback regression: PASS (" .. #catalog .. " services)")

local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS

local Departments = {
    dot = {
        name = "dot",
        label = "Department of Transportation",
        active = true,
        jobs = { qbcore = { "dot", "publicworks" }, qbox = { "dot", "publicworks" }, esx = { "dot", "publicworks" } },
        supervisorGrades = { 3, 4, 5 },
        allowedCategories = { "traffic_infrastructure", "road_maintenance", "public_property" },
    },
    publicworks = {
        name = "publicworks",
        label = "Public Works",
        active = true,
        jobs = { qbcore = { "publicworks" }, qbox = { "publicworks" }, esx = { "publicworks" } },
        supervisorGrades = { 3, 4, 5 },
        allowedCategories = { "traffic_infrastructure", "road_maintenance", "public_property" },
    },
    sanitation = {
        name = "sanitation",
        label = "Sanitation",
        active = true,
        jobs = { qbcore = { "sanitation", "garbage" }, qbox = { "sanitation", "garbage" }, esx = { "sanitation", "garbage" } },
        supervisorGrades = { 3, 4, 5 },
        allowedCategories = { "sanitation", "public_property" },
    },
    water = {
        name = "water",
        label = "Water Services",
        active = true,
        jobs = { qbcore = { "water" }, qbox = { "water" }, esx = { "water" } },
        supervisorGrades = { 3, 4, 5 },
        allowedCategories = { "water_infrastructure", "public_property" },
    },
}

function Departments.get(name)
    return Departments[name]
end

function Departments.list()
    local result = {}
    for _, department in pairs(Departments) do
        if type(department) == "table" and department.name then
            result[#result + 1] = department
        end
    end
    table.sort(result, function(left, right) return left.name < right.name end)
    return result
end

CivicOS.Departments = Departments
return Departments

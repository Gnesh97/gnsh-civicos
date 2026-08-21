local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS
local Repository = CivicOS.Repository

local DepartmentRepository = {}

function DepartmentRepository:findByName(name)
    return Repository.rows(Repository.db():query(
        "SELECT id, name, label, active, metadata, created_at, updated_at FROM civicos_departments WHERE name = ? LIMIT 1",
        { name }
    ))
end

function DepartmentRepository:list(activeOnly)
    local suffix = activeOnly == false and "" or " WHERE active = 1"
    return Repository.rows(Repository.db():query(
        "SELECT id, name, label, active, metadata, created_at, updated_at FROM civicos_departments" .. suffix .. " ORDER BY name ASC"
    ))
end

function DepartmentRepository:upsert(department)
    return Repository.db():query([[INSERT INTO civicos_departments (name, label, active, metadata)
        VALUES (?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE label = VALUES(label), active = VALUES(active), metadata = VALUES(metadata)]], {
        department.name, department.label, department.active == false and 0 or 1, Repository.encode(department.metadata),
    })
end

CivicOS.DepartmentRepository = DepartmentRepository
return DepartmentRepository

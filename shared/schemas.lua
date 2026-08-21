local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS

local Schemas = {
    RequestCreate = {
        title = { type = "string", required = true, maxLength = 120 },
        description = { type = "string", required = true, maxLength = 4000 },
        category = { type = "string", required = true, maxLength = 80 },
        subcategory = { type = "string", required = false, maxLength = 80 },
        priority = { type = "enum", required = false, enum = "Priority" },
        location = { type = "vector", required = true },
        metadata = { type = "table", required = false },
    },

    Transition = {
        entityId = { type = "positive_integer", required = true },
        expectedVersion = { type = "positive_integer", required = true },
        targetStatus = { type = "string", required = true, maxLength = 64 },
        reason = { type = "string", required = false, maxLength = 500 },
    },

    Pagination = {
        page = { type = "positive_integer", required = false },
        pageSize = { type = "positive_integer", required = false },
    },
}

CivicOS.Schemas = Schemas
return Schemas

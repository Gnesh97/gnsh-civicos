fx_version "cerulean"
game "gta5"
lua54 "yes"

author "Gnesh97"
description "CivicOS municipal operations core"
version "0.1.0"

shared_scripts {
    "shared/version.lua",
    "shared/constants.lua",
    "shared/enums.lua",
    "shared/errors.lua",
    "shared/schemas.lua",
    "shared/locale.lua",
    "config/config.lua",
    "config/features.lua",
    "config/adapters.lua",
    "config/permissions.lua",
}

server_scripts {
    "server/core/result.lua",
    "server/core/logger.lua",
    "server/adapters/database/interface.lua",
    "server/adapters/database/oxmysql.lua",
    "server/adapters/logging/console.lua",
    "server/security/validation.lua",
    "server/container.lua",
    "server/core/migrations.lua",
    "server/core/cache.lua",
    "server/repositories/_base.lua",
    "server/repositories/request_repository.lua",
    "server/repositories/workorder_repository.lua",
    "server/repositories/employee_repository.lua",
    "server/repositories/department_repository.lua",
    "server/repositories/audit_repository.lua",
    "server/bootstrap.lua",
}

client_scripts {
    "client/bootstrap.lua",
}

ui_page "web/dist/index.html"

files {
    "locales/en.json",
    "locales/tr.json",
    "web/dist/index.html",
}

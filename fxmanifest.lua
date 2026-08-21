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
    "config/departments.lua",
    "config/service_catalog.lua",
}

server_scripts {
    "server/core/result.lua",
    "server/core/logger.lua",
    "server/adapters/framework/interface.lua",
    "server/adapters/framework/shared.lua",
    "server/adapters/framework/standalone.lua",
    "server/adapters/framework/qbcore.lua",
    "server/adapters/framework/qbox.lua",
    "server/adapters/framework/esx.lua",
    "server/adapters/framework/registry.lua",
    "server/adapters/database/interface.lua",
    "server/adapters/database/oxmysql.lua",
    "server/adapters/logging/console.lua",
    "server/adapters/inventory/interface.lua",
    "server/adapters/inventory/none.lua",
    "server/adapters/inventory/ox_inventory.lua",
    "server/adapters/notify/interface.lua",
    "server/adapters/notify/standalone.lua",
    "server/adapters/provider_registry.lua",
    "server/security/validation.lua",
    "server/security/authorization.lua",
    "server/security/rate_limit.lua",
    "server/security/action_tokens.lua",
    "server/security/exploit_guard.lua",
    "server/container.lua",
    "server/core/migrations.lua",
    "server/core/cache.lua",
    "server/core/identity.lua",
    "server/services/department_service.lua",
    "server/services/employee_service.lua",
    "server/domain/service_catalog.lua",
    "server/domain/request.lua",
    "server/state/request_state_machine.lua",
    "server/services/service_catalog_service.lua",
    "server/services/request_service.lua",
    "server/services/request_comment_service.lua",
    "server/services/workorder_template_service.lua",
    "server/services/workorder_service.lua",
    "server/services/dispatch_service.lua",
    "server/services/workorder_dependency_service.lua",
    "server/services/inventory_service.lua",
    "server/services/checklist_service.lua",
    "server/services/field_service.lua",
    "server/api/dto.lua",
    "server/api/serializers.lua",
    "server/repositories/_base.lua",
    "server/repositories/request_repository.lua",
    "server/repositories/workorder_repository.lua",
    "server/repositories/employee_repository.lua",
    "server/repositories/department_repository.lua",
    "server/repositories/audit_repository.lua",
    "server/repositories/assignment_repository.lua",
    "server/repositories/workorder_dependency_repository.lua",
    "server/bootstrap.lua",
}

client_scripts {
    "client/adapters/target/interface.lua",
    "client/adapters/target/none.lua",
    "client/adapters/target/ox_target.lua",
    "client/adapters/target/registry.lua",
    "client/field_actions.lua",
    "client/routes.lua",
    "client/interactions.lua",
    "client/markers.lua",
    "client/bootstrap.lua",
}

ui_page "web/dist/index.html"

files {
    "locales/en.json",
    "locales/tr.json",
    "web/dist/index.html",
}

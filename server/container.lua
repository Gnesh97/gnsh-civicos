local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS

local Container = {
    _definitions = {},
    _instances = {},
    _ready = false,
}

function Container.register(name, definition)
    assert(type(name) == "string" and name ~= "", "Container service name is required")
    assert(Container._definitions[name] == nil, string.format("Container service already registered: %s", name))
    assert(type(definition) == "function" or type(definition) == "table", string.format("Invalid service: %s", name))
    Container._definitions[name] = definition
end

function Container.resolve(name)
    if Container._instances[name] ~= nil then
        return Container._instances[name]
    end
    if not Container._ready and Container._definitions[name] == nil then
        error(string.format("Container service is not registered before READY: %s", tostring(name)))
    end
    local definition = Container._definitions[name]
    if definition == nil then
        error(string.format("Container service not found: %s", tostring(name)))
    end
    local instance = type(definition) == "function" and definition(Container) or definition
    Container._instances[name] = instance
    return instance
end

function Container.markReady()
    Container._ready = true
end

function Container.isReady()
    return Container._ready
end

function Container.reset()
    Container._instances = {}
    Container._ready = false
end

CivicOS.Container = Container
return Container

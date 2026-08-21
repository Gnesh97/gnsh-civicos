local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS

local Locale = {
    _catalogues = {},
    _locale = "en",
    _fallback = "en",
}

local function decode(contents)
    if type(contents) ~= "string" or contents == "" or type(json) ~= "table" or type(json.decode) ~= "function" then
        return nil
    end
    local ok, value = pcall(json.decode, contents)
    return ok and type(value) == "table" and value or nil
end

local function readLocale(locale)
    if type(LoadResourceFile) ~= "function" then
        return {}
    end
    local resource = type(GetCurrentResourceName) == "function" and GetCurrentResourceName() or "gnsh-civicos"
    return decode(LoadResourceFile(resource, string.format("locales/%s.json", locale))) or {}
end

local function lookup(catalogue, key)
    local current = catalogue
    for part in string.gmatch(key, "[^.]+") do
        if type(current) ~= "table" then
            return nil
        end
        current = current[part]
    end
    return type(current) == "string" and current or nil
end

function Locale.init(locale, fallback)
    Locale._locale = type(locale) == "string" and locale or "en"
    Locale._fallback = type(fallback) == "string" and fallback or "en"
    Locale._catalogues[Locale._locale] = Locale._catalogues[Locale._locale] or readLocale(Locale._locale)
    Locale._catalogues[Locale._fallback] = Locale._catalogues[Locale._fallback] or readLocale(Locale._fallback)
    return Locale
end

function Locale.set(locale)
    return Locale.init(locale, Locale._fallback)
end

function Locale.t(key, fallback)
    local value = lookup(Locale._catalogues[Locale._locale] or {}, key)
        or lookup(Locale._catalogues[Locale._fallback] or {}, key)
        or fallback
        or key
    return value
end

function Locale.catalogue(locale)
    return Locale._catalogues[locale or Locale._locale] or {}
end

CivicOS.Locale = Locale
return Locale

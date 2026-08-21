# Framework Adapter Contract

CivicOS core/service/domain kodu framework-native player object'i kullanmaz.
`server/adapters/framework/` altında ayrı QBCore, Qbox, ESX Legacy ve standalone
adapter'ları normalize edilmiş aynı contract'ı uygular.

## Provider seçimi

```lua
Config.Framework = {
    Provider = "auto", -- auto | qbcore | qbox | esx | standalone
    DutyMode = "auto"   -- auto | framework | civicos
}
```

- Production için explicit provider önerilir.
- `auto`, çalışan resource'ları tespit eder.
- `qb-core` ve `qbx_core` birlikte çalışıyorsa ambiguity'de startup fail olur.
- Resource bulunamıyorsa açık `ADAPTER_UNAVAILABLE` sonucu döner.
- Hiçbir framework yoksa yalnızca `standalone` fallback seçilir.

## Normalize edilmiş contract

Her adapter şu metodları sağlar: `getPlayer`, `isPlayerLoaded`,
`getIdentifier`, `getCharacterId`, `getCharacterName`, `getJob`,
`getJobName`, `getJobGrade`, `getJobGradeName`, `isOnDuty`, `setDuty`,
`getMoney`, `addMoney`, `removeMoney`, `registerUsableItem`, lifecycle callback'leri
ve `getCapabilities`.

Identity payload:

```lua
{
    source = 31,
    persistentIdentifier = "private-internal-id",
    characterId = "character-id",
    displayName = "John Doe",
    framework = "qbox",
    job = {
        name = "publicworks",
        label = "Public Works",
        grade = 2,
        gradeName = "technician",
        onDuty = true
    }
}
```

`persistentIdentifier` yalnızca server-side identity ve persistence için
kullanılır; public DTO'larda raw license/citizen identifier bulunmaz.

## Duty parity

- QBCore/Qbox native duty adapter tarafından okunur ve güncellenir.
- ESX native duty yoksa adapter internal CivicOS duty state tutar.
- `auto`, güvenilir native duty varsa framework'ü; yoksa CivicOS state'ini seçer.
- Core feature'ları framework adına değil capability object'ine göre davranır.

## Provider fallback'leri

- Inventory: `ox_inventory` veya `none`.
- Notify: standalone client event fallback.
- Target: `ox_target` veya marker/drawtext no-op fallback.

Optional provider yoksa core import/startup syntax hatası vermez. Explicit olarak
seçilen provider yoksa startup actionable error üretir.

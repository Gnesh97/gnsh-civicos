# CivicOS API & Error Conventions

Bu sözleşme callback, export, internal event ve public integration API'lerinin
isimlendirme ve response biçimini freeze eder. Public API değişiklikleri semver
kurallarına tabidir.

## Result envelope

Başarılı çağrı:

```lua
{
    ok = true,
    data = {...}
}
```

Başarısız çağrı:

```lua
{
    ok = false,
    error = {
        code = "DOMAIN_REASON",
        message = "Safe fallback/localized message",
        details = {}
    }
}
```

`server/core/result.lua` her iki envelope'u üretir. `details` yalnızca client'ın
işlem yapmasına yarayan safe primitive alanları içerebilir; stack trace, debug
payload, secret, token, password veya raw provider error gönderilmez.

Error code formatı `DOMAIN_REASON`'dır. Örnekler: `AUTH_FORBIDDEN`,
`REQUEST_DUPLICATE`, `WORKORDER_INVALID_STATE`, `CORE_VERSION_CONFLICT`.

## Naming

- Public exports: `civicos:<Verb><Noun>`; örnek `civicos:CreateRequest`,
  `civicos:GetRequest`.
- Internal events: lowercase dotted topic; örnek `request.created`,
  `workorder.assignment.changed`.
- Client/server net events: `civicos:server:<verb>` ve
  `civicos:client:<verb>` namespace'lerinde olmalı.
- IDs internal numeric/UUID olabilir; public reference ayrı ve tahmin edilmesi
  zor olmalıdır (`311-YYYY-XXXXXX`).

## Input and output

1. Her sınırda schema validation, string length, enum, coordinate sanity,
   entity existence ve rate limit uygulanır.
2. Client'a DB entity değil permission-scoped DTO gönderilir.
3. Request/work-order mutation'ları `expectedVersion` kabul eder ve conflict'te
   `CORE_VERSION_CONFLICT` döner.
4. Public integration mutation'ları idempotency key kabul eder.
5. Pagination `page`, `pageSize`, `total` ve bounded result payload kullanır;
   default/max değerler `shared/constants.lua` içinden gelir.
6. Persistent timestamps UTC'dir; local timezone yalnızca UI'da uygulanır.

## Events and delivery

Domain event payload'ları `eventName`, `eventVersion`, `correlationId`,
`occurredAt` ve permission-safe `data` alanlarını taşır. Event handler'lar
duplicate delivery'ye dayanıklı olmalıdır. Third-party delivery transactional
outbox üzerinden at-least-once semantiğiyle yapılır.

## Semver and compatibility

- Additive field/event değişikliği minor sürüm olabilir.
- Mevcut field anlamını değiştiren veya kaldıran değişiklik major sürüm ister.
- Breaking değişiklikten önce ADR, migration ve API dokümanı güncellenir.
- Unknown request fields reject veya açıkça ignore edilir; sessiz type coercion
  yapılmaz.

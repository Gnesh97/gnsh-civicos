# CivicOS Coding Rules

## Lifecycle values

- Request and Work Order states, priority, duty, availability, inspection and
  SLA values must come from `shared/enums.lua`.
- Magic string lifecycle assignments are forbidden. A state change must pass
  through the domain state machine and its transition guard.
- Consumers must not mutate the tables returned by `shared/enums.lua` or
  `shared/constants.lua`; treat them as frozen contract data.

## Boundaries

- Core/service/domain code is framework-blind. QBCore, Qbox and ESX details stay
  in adapters and capability providers.
- SQL belongs only in repositories/database adapters.
- Client input is untrusted. Every server action validates identity, permission,
  scope, state, version and business preconditions.
- UI code presents data and emits intent; it never owns business state.

## Contract changes

- Add public contract changes to an ADR and update API documentation.
- Add new config or locale keys to validation and both EN/TR locale sets.
- Keep persistent timestamps in UTC and expose permission-scoped DTOs only.

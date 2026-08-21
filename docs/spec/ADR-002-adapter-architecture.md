# ADR-002: Adapter-First Framework and Provider Architecture

- **Status:** Accepted
- **Date:** 2026-08-22
- **Scope:** QBCore, Qbox, ESX Legacy, standalone, inventory, notify and target

## Context

CivicOS must provide feature parity across QBCore, Qbox and ESX Legacy without
coupling domain services to native player objects or provider APIs. Standalone
fallbacks are required for development and provider-minimal deployments.

## Decision

Framework and provider details are isolated behind normalized adapters and
capability contracts. Core receives normalized identity, job, duty, money and
inventory operations. QBCore and Qbox have separate public adapters; ESX duty
falls back to CivicOS state when native duty is absent. `Provider = auto` fails
fast on ambiguous detection; production may select an explicit provider.

## Consequences

- Domain behavior is framework-blind and parity can be tested per adapter.
- Adapter code has more files and contract tests.
- A missing optional provider yields a declared fallback or actionable startup
  failure, never a silent behavior change.

## Rejected alternatives

- `if Config.Framework == ...` branches inside services: leaks framework details.
- Aliasing Qbox to QBCore: native lifecycle and capability differences are lost.
- Best-effort framework support: violates v1 parity.

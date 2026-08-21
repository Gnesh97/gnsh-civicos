# CivicOS Installation

## Requirements

- FiveM server with Lua 5.4 support;
- `oxmysql` started before this resource;
- one supported framework (`qb-core`, `qbx_core`, `es_extended`) or no
  framework for standalone mode;
- a database user allowed to create/alter CivicOS tables.

## Fresh install

1. Copy `gnsh-civicos` into the server's resources directory.
2. Ensure `oxmysql` is started first.
3. Add `ensure gnsh-civicos` after the framework and database resources.
4. Set `Config.Framework.Provider` to `auto`, `qbcore`, `qbox`, `esx`, or
   `standalone`.
5. Select inventory, notify, target, and evidence providers in
   `config/adapters.lua`.
6. Restart the server and inspect the console for the `CivicOS ready` message.

When `Config.Database.MigrationOnStart` is true, CivicOS creates and advances
`civicos_schema_version` automatically. Never edit an applied migration; add a
new numbered SQL file and register it in `server/core/migrations.lua`.

## Optional providers

The `none` adapters are safe fallbacks. Install and configure `ox_inventory`,
`ox_target`, or a custom provider only after the core boots in fallback mode.
Custom provider contracts are documented in the corresponding adapter
interfaces under `server/adapters`.

## First boot checklist

- confirm the selected framework/provider in the startup log;
- confirm migrations 001–010 are applied;
- use `/civicos_health` and `/civicos_diagnostics` to inspect dependencies;
- use `/civicos_seed` only in a disposable/demo environment;
- open the NUI and verify bootstrap, request list, and request creation;
- configure retention and recovery values before production traffic.

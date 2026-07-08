<!--
SPDX-License-Identifier: CC-BY-SA-4.0
Copyright (c) Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
-->

# awap_backend (Elixir/Phoenix)

An alternate backend written in Elixir/Phoenix, with its own event store, a
worker pool, Moodle sync, and a `CoreBridge` GenServer intended to drive the
Rust core.

## Status: NON-CANONICAL

Per `docs/adr/0001-backend-consolidation.md`, the **Rust core**
(`components/core/`) is the canonical backend. This Elixir backend duplicates
the event-store and anonymization responsibilities, and its `CoreBridge`
expects the Rust core to speak line-delimited JSON over stdin/stdout — a
`--mode port` protocol that `components/core/src/main.rs` (HTTP/GraphQL only)
does not implement. The two do not currently connect.

The code is real (46 tests written, not yet run). Its genuinely unique pieces
(Moodle sync, worker orchestration) are candidates to return later as separate
services that call the core over its HTTP/GraphQL API.

## Build & test

```bash
cd components/backend
mix deps.get
mix test
```

Requires a BEAM/Elixir toolchain.

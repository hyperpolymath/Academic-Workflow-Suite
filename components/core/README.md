<!--
SPDX-License-Identifier: CC-BY-SA-4.0
Copyright (c) Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
-->

# aws-core

The Rust application core and the **canonical backend** for the suite (see
`docs/adr/0001-backend-consolidation.md`).

## What's here

- `components/core/src/security.rs` — the privacy-critical piece: `SecurityService` computes a
  SHA3-256 anonymized student ID and runs a regex PII detector/redactor
  (email, phone, postcode, URL, student-ID). The plaintext `original` is
  `skip_serializing`, so it never crosses a serialization boundary.
- `components/core/src/events.rs` — LMDB-backed event-sourcing store (immutable audit log).
- `components/core/src/graphql.rs`, `components/core/src/api/` — async-graphql schema and Actix REST endpoints.
- `components/core/src/feedback.rs`, `components/core/src/tma.rs` — TMA model and feedback context. Note: DOCX
  ingestion in `components/core/src/tma.rs` currently returns placeholder text (not yet real).
- `components/core/src/main.rs` — starts the Actix HTTP/GraphQL server on a TCP port.
- `components/core/src/ipc.rs` — IPC helpers (see the ADR for the backend-protocol decision).

## Build & test

```bash
cd components/core
cargo test
```

`cargo test` includes the anonymization leak-canary tests in `components/core/src/security.rs`
(`test_serialized_result_never_contains_plaintext`,
`test_convenience_fallback_never_embeds_raw_id`).

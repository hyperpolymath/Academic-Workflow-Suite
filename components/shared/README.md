<!--
SPDX-License-Identifier: CC-BY-SA-4.0
Copyright (c) Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
-->

# academic-shared

Cross-cutting Rust library shared by the other Rust components.

## What's here

- `components/shared/src/crypto.rs` — hashing/crypto helpers (BLAKE3, SHA3-256/512, HMAC-SHA3,
  Argon2id, and PQ primitives). Note: the `proven` (Idris2) integration is
  commented out; the crate builds without it.
- `components/shared/src/sanitization.rs` — input sanitization helpers.
- `components/shared/src/validation.rs` — validation utilities.
- `components/shared/src/logging.rs`, `components/shared/src/time.rs`, `components/shared/src/errors.rs`, `components/shared/src/testing.rs` — logging setup, time
  helpers, shared error types, and test utilities.

## Build & test

```bash
cd components/shared
cargo test
```

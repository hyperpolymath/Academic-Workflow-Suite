<!--
SPDX-License-Identifier: CC-BY-SA-4.0
Copyright (c) Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
-->

# aws-cli

The command-line interface to Academic Workflow Suite, built with `clap`. It
talks to the Rust core over HTTP.

## What's here

- `cli/src/main.rs` — entry point and argument parsing.
- `cli/src/commands/` — one module per subcommand.
- `cli/src/api_client.rs` — HTTP client to `aws-core`.
- `cli/src/interactive.rs` — interactive mode.
- `cli/src/models.rs`, `cli/src/output.rs`, `cli/src/config.rs` — data types, output formatting, config.

## Status

The most complete component: **71 passing tests** (unit, contract, e2e,
property, security).

## Build & test

```bash
cd cli
cargo test
cargo run -- --help
```

# Test & Benchmark Requirements

## Current State
- Unit tests: ~12 test files found (1 Rust integration, 2 Elixir, 3 ReScript, plus test support files)
- Integration tests: 1 (ai-jail test_isolation.rs)
- E2E tests: NONE
- Benchmarks: 8 files exist (crypto_bench.rs, validation_bench.rs, ai_benchmarks.rs, core_benchmarks.rs, plus baselines)
- panic-attack scan: NEVER RUN

## What's Missing
### Point-to-Point (P2P)
#### CLI (Rust — 14 source files)
- api_client.rs — no tests
- commands/batch.rs — no tests
- commands/config_cmd.rs — no tests
- commands/doctor.rs — no tests
- commands/feedback.rs — no tests
- commands/init.rs — no tests
- commands/login.rs — no tests
- commands/mark.rs — no tests
- commands/start.rs — no tests
- commands/status.rs — no tests
- commands/stop.rs — no tests
- commands/sync.rs — no tests
- commands/update.rs — no tests
- config.rs — no tests
- interactive.rs — no tests
- models.rs — no tests
- output.rs — no tests

#### AI Jail (Rust — 4 source files)
- inference.rs — no dedicated tests
- model.rs — no dedicated tests
- protocol.rs — no dedicated tests
- test_isolation.rs — 1 test file, coverage unclear

#### Backend (Elixir — 30+ source files)
- Only 2 test files: tma_test.exs and tma_controller_test.exs
- Missing tests for all other modules, controllers, channels

#### Office Add-in (ReScript — 10 files)
- 3 test files exist (BackendClient_test.res, OfficeAPI_test.res, Types_test.res)
- Coverage vs total module count unknown

#### Shared (Rust — testing.rs + others)
- testing.rs exists but other shared modules lack tests

### End-to-End (E2E)
- Full marking workflow: create assignment -> submit -> mark -> feedback
- CLI login -> configure -> start session -> mark -> sync workflow
- AI jail: submit assignment -> AI detection -> report
- Office add-in: open document -> connect -> mark -> save
- Backend API: full CRUD for TMA lifecycle

### Aspect Tests
- [ ] Security (AI jail isolation, auth bypass in backend, CSRF in web UI)
- [ ] Performance (batch marking throughput, AI inference latency)
- [ ] Concurrency (multiple markers on same assignment, concurrent API calls)
- [ ] Error handling (network failures, timeout handling, invalid submissions)
- [ ] Accessibility (Office add-in UI accessibility)

### Build & Execution
- [ ] cargo build (cli/) — not verified
- [ ] cargo build (ai-jail/) — not verified
- [ ] mix compile (backend/) — not verified
- [ ] ReScript build (office-addin/) — not verified
- [ ] Docker compose build — not verified
- [ ] CLI --help works — not verified
- [ ] Self-diagnostic (doctor command exists but untested)

### Benchmarks Needed
- Crypto operations benchmark (bench file exists — verify it runs)
- Validation benchmark (bench file exists — verify it runs)
- AI inference latency and throughput
- Batch marking performance at scale (50, 100, 500 submissions)
- Backend response times under concurrent load

### Self-Tests
- [ ] panic-attack assail on own repo
- [ ] doctor command self-test
- [ ] Docker compose health checks

## Priority
- **HIGH** — Multi-component system (CLI + AI Jail + Backend + Office Add-in + Shared) with 59 Rust files, 30 Elixir files, 10 ReScript files. The CLI has 14+ command modules with ZERO tests. The backend has 30+ modules with only 2 test files. This is a user-facing academic tool where correctness directly affects students.

## FAKE-FUZZ ALERT

- `tests/fuzz/placeholder.txt` is a scorecard placeholder inherited from rsr-template-repo — it does NOT provide real fuzz testing
- Replace with an actual fuzz harness (see rsr-template-repo/tests/fuzz/README.adoc) or remove the file
- Priority: P2 — creates false impression of fuzz coverage

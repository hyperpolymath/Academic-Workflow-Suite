<!--
SPDX-License-Identifier: CC-BY-SA-4.0
Copyright (c) Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
-->
<!-- TOPOLOGY.md — Project architecture map and completion dashboard -->
<!-- Last updated: 2026-02-19 -->

# Academic Workflow Suite — Project Topology

## System Architecture

```
                        ┌─────────────────────────────────────────┐
                        │              TUTORS / CLIENTS           │
                        │        (Microsoft Word Interface)        │
                        └───────────────────┬─────────────────────┘
                                            │
                                            ▼
                        ┌─────────────────────────────────────────┐
                        │          PRESENTATION LAYER             │
                        │    (Office Add-in - AffineScript/React)     │
                        │  ┌───────────┐  ┌───────────────────┐  │
                        │  │  Task Pane│  │  Office.js        │  │
                        │  │  UI       │  │  Integration      │  │
                        │  └─────┬─────┘  └────────┬──────────┘  │
                        └────────│─────────────────│──────────────┘
                                 │ HTTPS/TLS 1.3   │
                                 ▼ (localhost)     ▼
                        ┌─────────────────────────────────────────┐
                        │          APPLICATION LAYER (RUST)       │
                        │                                         │
                        │  ┌───────────┐  ┌───────────────────┐  │
                        │  │  REST API │  │  Anonymization    │  │
                        │  │  (Actix)  │  │  Engine (SHA3)    │  │
                        │  └─────┬─────┘  └────────┬──────────┘  │
                        │        │                 │              │
                        │  ┌─────▼─────┐  ┌────────▼──────────┐  │
                        │  │ Persistence│  │  Business Logic  │  │
                        │  │ (LMDB)    │  │  (Event Sourcing) │  │
                        │  └─────┬─────┘  └────────┬──────────┘  │
                        └────────│─────────────────│──────────────┘
                                 │                 │
                                 ▼ Unix Socket     ▼
                        ┌─────────────────────────────────────────┐
                        │          AI ISOLATION LAYER             │
                        │    (Sandboxed Container - gVisor)       │
                        │  ┌───────────┐  ┌───────────────────┐  │
                        │  │  AI Model │  │  ONNX Runtime     │  │
                        │  │  (Local)  │  │  (Isolated)       │  │
                        │  └───────────┘  └───────────────────┘  │
                        └───────────────────┬─────────────────────┘
                                            │
                                            ▼
                        ┌─────────────────────────────────────────┐
                        │          BACKEND SERVICES               │
                        │  (Rubric Repo, Update Server - Optional) │
                        └─────────────────────────────────────────┘
```

## Completion Dashboard

This dashboard tracks demonstrable reality, and is kept consistent with the
canonical `.machine_readable/6a2/STATE.a2ml` (42%, CRG grade D). An earlier
version claimed ~80% with nearly everything "100% verified"; that was false and
contradicted STATE and the CRG audit. Corrected 2026-07-02.

```
COMPONENT                          STATUS              NOTES
─────────────────────────────────  ──────────────────  ─────────────────────────────────
PRESENTATION LAYER
  Office Add-in (AffineScript)          ██████░░░░  ~60%   Real Office.js/Word bindings; 39
                                                       assertions written, unrun vs Word
APPLICATION LAYER (RUST)
  Actix REST API                    ████████░░  ~80%   Real GraphQL/REST server
  Anonymization (SHA3-256) + PII    █████████░  ~90%   Real + tested; plaintext no longer
                                                       serialised; leak-canary tests added
  Event Sourcing (LMDB)             ████████░░  ~85%   Real store + tests
  DOCX ingestion                    ██░░░░░░░░  ~15%   tma.rs parse returns placeholder text
  Business Logic                    ██████░░░░  ~60%   Real, tested in isolation

AI ISOLATION LAYER
  AI Jail (Candle/Mistral-7B)       ███░░░░░░░  ~30%   Inference skeleton real; scoring is
                                                       placeholder; hard-requires CUDA (no
                                                       CPU fallback) — BLOCKED
  Local AI Models                   ██░░░░░░░░  ~20%   Blocked on the CUDA/model issue above

INTEGRATIONS
  Proven Library (Idris2)           ░░░░░░░░░░   0%    Aspirational: zero Idris files, dep
                                                       commented out (not "45 modules active")
  Moodle LMS Integration            ░░░░░░░░░░   0%    Planned for v0.2.0
  Elixir backend (Phoenix)          ████░░░░░░  ~40%   Real code; 46 tests written, unrun;
                                                       see ADR 0001 (backend consolidation)

REPO INFRASTRUCTURE
  Containerfiles (Docker/Podman)    ███████░░░  ~70%   Exist; not demonstrated end-to-end
  Justfile                          █████████░  ~90%   Standard build automation
  Rust test suite                   ████████░░  ~80%   ~230 assertions passing (core/shared/cli)
  Office/backend test suites        ███░░░░░░░  ~30%   Written, not yet executed

─────────────────────────────────────────────────────────────────────────────
OVERALL:                            ████░░░░░░  ~42%   Alpha (CRG grade D) — components real
                                                       but not yet an integrated pipeline
```

## Key Dependencies

```
Office Add-in ───► Core Engine (Rust) ───► AI Jail (Isolated)
                        │                     │
                        ▼                     ▼
                  Event Store (LMDB)      ONNX Runtime
                        │                     │
                        └──────────┬──────────┘
                                   ▼
                                COMPLETE
```

## Update Protocol

This file is maintained by both humans and AI agents. When updating:

1. **After completing a component**: Change its bar and percentage
2. **After adding a component**: Add a new row in the appropriate section
3. **After architectural changes**: Update the ASCII diagram
4. **Date**: Update the `Last updated` comment at the top of this file

Progress bars use: `█` (filled) and `░` (empty), 10 characters wide.
Percentages: 0%, 10%, 20%, ... 100% (in 10% increments).

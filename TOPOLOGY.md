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
                        │    (Office Add-in - ReScript/React)     │
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

```
COMPONENT                          STATUS              NOTES
─────────────────────────────────  ──────────────────  ─────────────────────────────────
PRESENTATION LAYER
  Office Add-in (ReScript)          ██████████ 100%    v0.1.0 stable release
  Office.js Integration             ██████████ 100%    Word manipulation verified

APPLICATION LAYER (RUST)
  Actix REST API                    ██████████ 100%    Core endpoints active
  Anonymization Engine (SHA3)       ██████████ 100%    Privacy guarantees validated
  Event Sourcing (LMDB)             ██████████ 100%    Immutable audit log stable
  Business Logic                    ████████░░  80%    Scaling for large cohorts

AI ISOLATION LAYER
  AI Jail (gVisor/Firecracker)      ██████████ 100%    Network isolation verified
  ONNX Runtime Integration          ██████████ 100%    Local inference stable
  Local AI Models                   ██████░░░░  60%    Fine-tuning for feedback style

INTEGRATIONS
  Proven Library (Idris2)           ██████████ 100%    45 verified modules active
  Moodle LMS Integration            ░░░░░░░░░░   0%    Planned for v0.2.0
  Batch Processing                  ████████░░  80%    Refining overnight triggers

REPO INFRASTRUCTURE
  Containerfiles (Docker/Podman)    ██████████ 100%    Reproducible builds
  Justfile                          ██████████ 100%    Standard build automation
  Test Suite (Rust/AffineScript)        ██████████ 100%    High coverage (Unit/E2E)

─────────────────────────────────────────────────────────────────────────────
OVERALL:                            ████████░░  ~80%   v0.1.0 Beta Release
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

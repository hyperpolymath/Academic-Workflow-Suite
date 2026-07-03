<!--
SPDX-License-Identifier: CC-BY-SA-4.0
Copyright (c) Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
-->

# components/

The building blocks of Academic Workflow Suite. Each subdirectory is an
independent component with its own build.

| Directory | Language | What it is | Status |
|---|---|---|---|
| `core/` | Rust | Actix REST/GraphQL server, LMDB event store, SHA3-256 anonymization + PII detection | real, tested |
| `shared/` | Rust | Cross-cutting library: crypto, validation, sanitization, logging, time | real, tested |
| `ai-jail/` | Rust | Local LLM inference skeleton (Candle/Mistral-7B) | CUDA-blocked; scoring placeholder |
| `office-addin/` | ReScript | Microsoft Word Office.js add-in (task pane, ribbon) | real bindings, unrun vs Word |
| `backend/` | Elixir/Phoenix | Alternate backend (`awap_backend`) | non-canonical — see `docs/adr/0001-backend-consolidation.md` |

See the repository `TOPOLOGY.md` for the completion dashboard and the honest
per-component status, and `.machine_readable/6a2/STATE.a2ml` for the canonical
project state.

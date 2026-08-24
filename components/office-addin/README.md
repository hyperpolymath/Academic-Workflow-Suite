<!--
SPDX-License-Identifier: CC-BY-SA-4.0
Copyright (c) Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
-->

# office-addin

The Microsoft Word Office add-in (task pane + ribbon), written in **AffineScript**
against Office.js. This is how an Associate Lecturer interacts with the suite
from inside Word.

## What's here

- `components/office-addin/src/OfficeAPI.res` — real Office.js/Word bindings: insert comment, read/write
  the student-ID custom property, extract document text.
- `components/office-addin/src/BackendClient.res` — HTTP client to the Rust core.
- `components/office-addin/src/TaskPane.res`, `components/office-addin/src/RibbonCommands.res`, `components/office-addin/src/AWAPAddin.res` — UI and command wiring.
- `components/office-addin/src/Types.res` — shared types.

## Status

The bindings are real and there are 39 test assertions, but they have **not
been run against Word** yet. See the repository `TOPOLOGY.md`.

## Build & test

Uses Deno (per the estate language policy). See `deno.json` at the repo root
for the `test:office-addin` task.

# RCC-OS — Resonant Cognitive Core Operating System

RCC-OS is an experimental, local-first AI operating substrate that evolves the architecture of
[ResonantOS/2.0.0-alpha](https://github.com/ResonantOS/2.0.0-alpha) toward a hardware-adaptive
cognitive operating system.

The project's central hypothesis:

> A lightweight, always-local cognitive model can provide sufficient intent recognition,
> routing, memory retrieval, tool selection, and basic planning to serve as the cognitive
> control plane of an AI operating environment across low-resource hardware, while larger
> local and remote models dynamically *extend* — never replace — that baseline intelligence.

## Why a fork

ResonantOS/2.0.0-alpha deliberately scopes its public Alpha runtime to a Chrome MV3 extension
plus an authenticated local Node.js bridge. Desktop shells (Tauri, Electron, native CEF),
terminal, and Audio2TOL are explicitly outside the Alpha surface.

RCC-OS reuses ResonantOS's existing architectural primitives — Provider Fabric, Living Archive,
Agent Control, capability/security boundary — and adds three new architectural layers:

1. **Resonant Core** — a deterministic substrate that can exist independently of Chrome.
2. **Cognitive Core** — a small, always-on local model (initially a ternary/1.58-bit SLM).
3. **Model Fabric** — a unified router over local and remote intelligence.

The browser extension remains a supported client. The historical desktop shells become
reference implementations of additional clients around the same Core.

## Repository layout

```text
baseline/                 Snapshot of ResonantOS/2.0.0-alpha @ dev (this commit)
docs/                     RCC-OS vision, architecture, milestones, research notes
src/                      RCC-OS native code (Rust + minimal Node)
clients/                  Future browser, desktop, and CLI clients
experiments/              Isolated research branches (ternary runtime, model router, etc.)
scripts/                  Local verification and development scripts
```

`baseline/` is a read-only reference snapshot, retained to make upstream divergence obvious
and to anchor benchmarks. Day-to-day work happens in `src/`, `clients/`, `experiments/`,
and `docs/`.

## Milestones

| Stage | Title | Goal |
| --- | --- | --- |
| 0 | Lab scaffold | Fork, document, snapshot, governance, CI |
| 1 | Local inference | Add tiny ternary SLM behind the existing Node bridge |
| 2 | Cognitive router | Tiny model becomes the first-stage intent/router before cloud calls |
| 3 | Core/client separation | Move `baseline/browser-first/host` logic into `src/core` |
| 4 | Desktop shell restored | Tauri-style client around the new Core |
| 5 | Hardware profiler | Adaptive model selection by detected hardware |

Each milestone is independently benchmarkable. Reverting a stage must not require reverting
later stages.

## Relationship to ResonantOS

- Upstream: `ResonantOS/2.0.0-alpha` @ `dev`.
- Fork license: MIT (matches upstream).
- Provenance: this repo is an experimental derivative. Upstream attribution is preserved
  in `baseline/LICENSE.txt` and the top-level `LICENSE` file.

Results that mature in RCC-OS may be proposed upstream as PRs; conversely the lab tracks
upstream `dev` and pulls compatible changes.

## Status

This repository is a research lab. Nothing here is a product, a release, or a public
promise. Expect incomplete documentation, broken windows, and rough edges.
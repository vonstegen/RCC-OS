# RCC-OS Vision

This document captures the architectural vision behind the
**Resonant Cognitive Core Operating System (RCC-OS)** lab. It is the
starting point for design decisions in this repository and is the
context that every other document in `docs/` is expected to honor.

The vision was developed by reviewing the public ResonantOS/2.0.0-alpha
repository on its `dev` branch as of August 2026. See
[`baseline/`](https://github.com/vonstegen/RCC-OS/tree/main/baseline) for
the snapshot used as the reference architecture.

## The hypothesis

> A lightweight, always-local cognitive model can provide sufficient
> intent recognition, routing, memory retrieval, tool selection, and
> basic planning to serve as the cognitive control plane of an AI
> operating environment across low-resource hardware. Larger local and
> remote models dynamically *extend* — never define — the intelligence
> of the system.

Concretely:

```text
                  RESONANTOS (product, upstream)
                          │
                  ResonantOS/2.0.0-alpha (dev)
                          │
                          ▼
                  RCC-OS (this repository, lab)
                          │
            ┌─────────────┼─────────────┐
            ▼             ▼             ▼
       Resonant Core  Cognitive    Model Fabric
       (deterministic) Core
            │           (SLM)
            │             │
            ▼             ▼
       Capability     Intent · Routing
       Engine         Planning · Memory
            │             │
            └──────┬──────┘
                   ▼
              Clients
       Browser  Desktop  CLI  ...
```

The product **ResonantOS** remains the user-facing artifact. The
research lab **RCC-OS** investigates whether the architecture can
become a true cognitive operating substrate rather than a browser
shell over an LLM API.

## Why now

ResonantOS has already done three structurally important things:

1. It separated the **UI** from the **privileged host** via an
   authenticated local bridge. That is a real architectural boundary,
   not a marketing claim.
2. It defined a **Provider Fabric** that is intentionally model-agnostic.
3. It introduced **Living Archive** as governed, audited persistent
   memory rather than letting AI freely rewrite trusted context.

Those three pieces are exactly the foundation an AI operating system
needs. They are missing only:

- a **native Core** that can exist independently of any single client,
- a **local cognitive control layer** to provide baseline intelligence
  without requiring a network or a frontier model,
- **hardware-adaptive model selection** so the system runs from old
  laptops up to workstations with NPUs.

That is the work the lab exists to investigate.

## Why ternary (initially)

BitNet b1.58 demonstrated that transformer weights can be represented
using the three values `{-1, 0, +1}`, with competitive model quality
at equivalent scale and substantial CPU efficiency advantages. The
`bitnet.cpp` runtime and the 2B4T technical report from Microsoft make
this testable today.

RCC-OS does not lock itself to ternary weights. The Cognitive Core is
defined as an interface; the initial implementation uses whatever
low-bit, CPU-efficient local model is currently the most defensible
choice. Ternary is the starting point because it best solves the
"always-on minimum intelligence" problem across the widest range of
hardware.

## What does not change

Several principles from the upstream ResonantOS architecture should
carry forward unchanged:

- The **AI is never the permission system**. The deterministic Core
  decides every privileged action; the AI only proposes structured
  capability requests.
- **Capability tokens** remain scoped per route. The Cognitive Core
  does not gain blanket execution authority.
- **Living Archive** stays governed. The local AI cannot arbitrarily
  rewrite trusted memory.
- **Provider credentials** stay inside the Core, never in the browser
  page or add-on.
- **Sensitive autonomous actions** — wallet operations, payments,
  transfers, credential entry, public submission — stay human-only.

These become *more* important once a local model is always running.

## What is new

The lab introduces five architectural layers above the existing
ResonantOS primitives:

```text
┌──────────────────────────────────────────────────────────┐
│ 5. Experience                                            │
│    Browser extension · Desktop shell · CLI · future UIs  │
├──────────────────────────────────────────────────────────┤
│ 4. Augmentation                                          │
│    Agents · Apps · Add-ons · Workflows                   │
├──────────────────────────────────────────────────────────┤
│ 3. Intelligence                                          │
│    Cognitive Core · Local LLMs · Cloud LLMs              │
├──────────────────────────────────────────────────────────┤
│ 2. Cognitive Infrastructure                              │
│    Living Archive · Context · Model Fabric               │
├──────────────────────────────────────────────────────────┤
│ 1. Resonant Core                                         │
│    Capability engine · Security · IPC · Host OS          │
└──────────────────────────────────────────────────────────┘
```

Layer 1 does **not** require AI. The computer remains deterministic.
Layer 3 makes the system intelligent. The lab's first experiments
test whether Layer 3 can be filled by a tiny, always-local model.

## Staged experiments

The lab runs experiments in stages. Each stage must be independently
benchmarkable. Reverting a stage must not require reverting later
stages.

| Stage | Title | What changes |
| --- | --- | --- |
| 1 | Local inference | A tiny SLM is installed and accessible from the existing Node bridge |
| 2 | Cognitive router | The SLM becomes the first-stage intent/router before any cloud call |
| 3 | Core/client separation | `baseline/browser-first/host` becomes `src/core`; bridge is no longer the architectural center |
| 4 | Desktop shell | A native client around the new Core, reusing lessons from the historical Tauri/Electron work |
| 5 | Hardware profiler | Adaptive model selection by detected hardware |

The biggest mistake would be to attempt all five simultaneously. Each
stage ends with a measurable result, positive or negative, that
informs whether the next stage begins.

## Out of scope (for now)

- Shipping a ResonantOS distribution.
- Replacing ResonantOS's current Node bridge wholesale.
- Reintroducing the deleted Tauri/Electron/native-CEF code unchanged.
- Training a new ResonantOS-specific foundation model. The lab
  experiments with available open ternary SLMs first.
- Mobile or edge device packaging. Browser-first remains the
  broadest-deployment target.

## License

This repository is MIT licensed, matching upstream ResonantOS. See
[`LICENSE`](LICENSE) for the full text and the upstream attribution
preserved in [`baseline/LICENSE.txt`](baseline/LICENSE.txt).
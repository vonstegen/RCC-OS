# Milestones

The lab runs experiments in stages. Each stage ends with a measurable
result. The next stage begins only after the previous stage's result
is recorded.

## Stage 0 — Lab scaffold (current)

Goal: establish a clean derivative repository of
ResonantOS/2.0.0-alpha with the vision, architecture, governance, and
CI baseline.

Deliverables:

- [x] README and vision documents.
- [x] Architecture document.
- [x] Milestones document (this file).
- [x] Snapshot of upstream `dev` in `baseline/`.
- [x] `.gitignore`, `LICENSE`, `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`,
      `SECURITY.md`.
- [ ] CI workflow that runs the upstream deterministic verification
      suite against `baseline/` so we can detect divergence early.
- [ ] Initial decisions recorded in `docs/decisions/`.

## Stage 1 — Local inference

Goal: prove that a tiny SLM can run on the existing Node bridge
without destabilizing the upstream ResonantOS runtime.

Deliverables:

- [ ] Add a local-model service backed by a defensible runtime
      (initially `bitnet.cpp`).
- [ ] Expose it behind a capability-scoped bridge route.
- [ ] Record throughput, RAM, and CPU measurements on a reference
      machine.
- [ ] Document the integration points with the upstream Node bridge.

Decision gate: continue to Stage 2 only if the local model can run
reliably below 4 GB RAM on a CPU-only machine and produces structured
output that the bridge can validate.

## Stage 2 — Cognitive router

Goal: make the tiny local model the first-stage intent/router before
any cloud call.

Deliverables:

- [ ] A new bridge route that accepts user intent, runs the local
      model, returns a typed capability request.
- [ ] The deterministic Core validates the request and either
      executes locally, escalates to a stronger model, or returns a
      missing-capability error.
- [ ] A benchmark comparing routing accuracy and cloud-call reduction
      versus the current ResonantOS provider-routing path.

Decision gate: continue to Stage 3 only if the local router achieves
non-trivial routing accuracy (a target threshold will be set before
the stage begins) and demonstrably reduces cloud calls for common
tasks.

## Stage 3 — Core/client separation

Goal: make the Core addressable by clients other than Chrome.

Deliverables:

- [ ] A new `src/core` module that exposes the same capability
      surface as the current Node bridge.
- [ ] The Chrome extension becomes a thin client talking to the Core
      through the existing authenticated bridge protocol.
- [ ] A minimal CLI client that issues a single capability request
      end-to-end.

Decision gate: continue to Stage 4 only if the CLI client can perform
at least one meaningful task (e.g. read a file, summarize it, write a
result) without the Chrome extension loaded.

## Stage 4 — Desktop shell

Goal: bring back a native desktop client around the new Core.

Deliverables:

- [ ] A Tauri-style shell that loads a web UI and talks to the Core.
- [ ] macOS `.app` and `.dmg` builds.
- [ ] Windows `.msi` and `.exe` builds.
- [ ] Linux package builds.

Decision gate: continue to Stage 5 only if both macOS and Windows
installers build successfully on the reference CI and pass a
one-click smoke test.

## Stage 5 — Hardware profiler

Goal: detect the host hardware and choose the model tier adaptively.

Deliverables:

- [ ] A hardware-profiler service that reports architecture, CPU,
      RAM, GPU/NPU, disk, and OS.
- [ ] A model-tier selector that maps the profile to a recommended
      Cognitive Core model and provider set.
- [ ] End-to-end benchmarks across at least three reference
      machines: low-RAM, mid-range, and accelerated.

## Out of milestone scope

- Building a ResonantOS distribution.
- Training a new foundation model.
- Mobile packaging.
- Replacing the upstream Node bridge with a wholesale rewrite.

## Working assumptions

These are stated explicitly so they can be falsified early:

- The local SLM is honest about uncertainty. It returns structured
  fields, not free-form prose, for routing decisions.
- The deterministic Core never blocks on the local model for more
  than a bounded budget. If the model times out, the Core falls
  back to a safe default.
- Capability policy is written before the model is integrated, not
  after.
- All measurements are reproducible from a fresh checkout.
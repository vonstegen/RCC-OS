# ADR-0001: Resonant Core is implemented in Rust

- Status: Proposed
- Date: 2026-08-12
- Deciders: RCC-OS maintainers
- Stage: 0 (lab scaffold)
- Related: [`docs/VISION.md`](../VISION.md), [`docs/ARCHITECTURE.md`](../ARCHITECTURE.md), [`docs/MILESTONES.md`](../MILESTONES.md)

## Context

The vision requires a deterministic Resonant Core that:

- mediates every privileged action;
- holds provider credentials, secrets, and bridge tokens;
- enforces capability policy;
- can be addressed by clients other than Chrome;
- does not depend on any AI component to make security decisions.

Today the closest thing the lab has to a Core is the Node.js bridge
shipped with `baseline/browser-first/host/`. That code works, but it
lives inside a directory whose own README frames it as an
"authenticated local bridge for the Chrome MV3 extension." It is not
positioned as a substrate for additional clients.

Three language options are realistic:

- **Rust.** Strong static typing, memory safety without garbage
  collection pauses, mature ecosystem for cryptography, IPC, async,
  and embedding Tauri/WebView. Existing `baseline/src-tauri/`
  history shows the team has done real work in this direction.
- **Go.** Mature concurrency model and a small standard library;
  widely used for local daemons. Less expressive around
  zero-copy/FFI than Rust.
- **TypeScript on Node.** Already in use; minimum disruption.
  However, dependency on V8 and npm supply chain at the privilege
  boundary is a meaningful security cost, and the upstream review
  identified multiple confirmed critical/high issues in the Node
  bridge (engineer-runner shell injection, `verify:alpha` argv
  regression, tokenless proxy exemptions, `bridgeTargetOverride`
  redirect, addon-iframe permissive CSP).

## Decision

The new Resonant Core is implemented in **Rust**.

The existing Node bridge remains a transitional implementation
referenced by `baseline/` and is exercised by `pr-checks` /
`upstream-deterministic` workflows until Stage 3 replaces the
relevant code paths.

## Consequences

Positive:

- Memory-safety without runtime cost at the privilege boundary.
- Static typing makes capability/permission policy reviewable
  rather than inferred.
- Reuses the historical Tauri `src-tauri/` work as reference, not
  restoration.
- Cleaner FFI surface for embedding a `bitnet.cpp`-style runtime
  in Stage 1.

Negative / tradeoffs:

- New contributors must know Rust or be willing to learn it.
- Stage 3 takes longer than a Node.js port of the same surface.
- Two language runtimes (Rust Core + TypeScript clients) must be
  coordinated.

Mitigations:

- Stage 0 keeps the upstream Node bridge verifiable in CI, so the
  lab has a working system to reference throughout the rewrite.
- A short `docs/HOWTO-build-core.md` will be added in Stage 1 with
  a minimal `cargo build` walkthrough.
- The Core's IPC contract is language-agnostic; clients can
  continue to be TypeScript.

## Alternatives considered

- **Go.** Acceptable. Rejected because the lab already has
  meaningful Rust history in `baseline/src-tauri/`, and Rust's
  expressiveness around capability-based resource types is a
  better fit for the privilege boundary.
- **TypeScript only.** Rejected for the reasons above. The lab will
  not, however, abandon TypeScript for the client experience.

## Supersedes

None.

## Superseded by

None.

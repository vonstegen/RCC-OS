# Reference: ResonantOS/2.0.0-alpha snapshot

This directory is a read-only snapshot of
[ResonantOS/2.0.0-alpha](https://github.com/ResonantOS/2.0.0-alpha) at
the `dev` branch as committed on the date this lab was initialized.

It exists so the lab always has the upstream reference architecture
at hand, and so divergence between the lab and upstream is obvious.

## What lives here

- All upstream source code, unmodified.
- All upstream documentation.
- The upstream `LICENSE.txt`.
- The upstream `package.json` and lockfile.

## What does not live here

- Any lab work. New code, new docs, and new experiments live in
  `../src/`, `../clients/`, `../experiments/`, and `../docs/`.

## How to update the snapshot

The snapshot is intentionally frozen for the initial commit. To pull
newer upstream changes, see
[`CONTRIBUTING.md`](../CONTRIBUTING.md#working-with-upstream).

## Why a snapshot rather than a submodule

A submodule would track upstream commits transparently, but would
also mean every lab commit that touches the snapshot hash requires a
network round trip. The lab is offline-friendly by design. A frozen
in-tree snapshot is more honest about what was reviewed when.

## Provenance

See the upstream `LICENSE.txt` in this directory for copyright and
license terms of the snapshot contents. The lab's top-level `LICENSE`
file preserves attribution.
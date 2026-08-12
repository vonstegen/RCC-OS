# ADR-0004: Upstream-suite parity policy for the lab

- Status: Proposed
- Date: 2026-08-12
- Deciders: RCC-OS maintainers
- Stage: 1 (lab deliverable MVP)
- Related: [`.github/workflows/upstream-deterministic.yml`](../../.github/workflows/upstream-deterministic.yml), [`baseline/scripts/verify-alpha.mjs`](../../baseline/scripts/verify-alpha.mjs), [ADR-0001](0001-resonant-core-in-rust.md)

## Context

The upstream ResonantOS 2.0.0-alpha project ships a single
`verify:alpha` script
([`baseline/scripts/verify-alpha.mjs`](../../baseline/scripts/verify-alpha.mjs))
that orchestrates 16 gates. Running that script verbatim in the
lab's CI fails on three gates that are not appropriate for the
lab's environment:

- `npm run docs:check` — asserts the docs tree follows
  upstream's canonical reading order. The lab's docs tree is
  intentionally restructured (see `docs/WORKFLOW.md`).
- `npm run test:browser-first:live` — requires a real Chrome
  instance and Xvfb. Not available in the runner.
- `npm test -- --run` — the `verify:alpha` argv contains a
  regression noted in the upstream code review: the `--run`
  argument is forwarded to `vitest` but the upstream `test`
  script already invokes `vitest run` with no further argument,
  so `--run` becomes the name of a non-existent test file and
  the gate fails. We use `npm test` instead.

Stage 0 dropped these three gates and added them implicitly in
the header comment of
[`upstream-deterministic.yml`](../../.github/workflows/upstream-deterministic.yml).
This ADR records the policy explicitly so the next maintainer
sees what we drop, why, and how to re-enable each one.

## Decision

The lab runs a **lab-adjusted subset** of `verify:alpha`,
documented in
[`upstream-deterministic.yml`](../../.github/workflows/upstream-deterministic.yml).
The subset is:

- `repo:hygiene`
- `test:living-archive-mcp`
- `test:living-archive-memory-service`
- `test:browser-host`
- `test:browser-first`
- `test:health`
- `test:engineer-runner`
- `test:security-pipeline`
- `test:module-ownership`
- `discipline:validate`
- `pre-release:scan`

Each of the three dropped gates is re-evaluated per stage. The
table below is the canonical record of why a gate is dropped and
the re-enable condition.

| Gate | Status | Reason | Re-enable condition |
| --- | --- | --- | --- |
| `docs:check` | dropped | Lab's docs tree intentionally diverges from upstream's reading order. | When the lab adopts the upstream reading order or the upstream suite becomes parameterized over a docs-root. |
| `test:browser-first:live` | dropped | Requires a real Chrome and Xvfb in the runner. The lab's smoke tests cover the live path manually. | When a CI lane is provisioned with Chrome + Xvfb. Track in `docs/MILESTONES.md` under stage 2. |
| `npm test -- --run` argv regression | replaced with `npm test` | The `verify:alpha` script passes `--run` to `npm test`, but the upstream `test` script already calls `vitest run` with no further argument, so `--run` is treated as a file name and the gate fails on every run. | When upstream fixes the argv regression. Track the upstream issue and re-test with `npm test -- --run` once a fix lands. |

The `build` gate is also not in the lab's deterministic suite.
The lab does not ship a build artifact in stage 0; the build
target is the LaTeX PDF, which is exercised by `latex-build.yml`.

## Consequences

Positive:

- The lab's CI is green without lying about upstream
  compatibility.
- The dropped gates are explicit and traceable.
- Re-enabling a dropped gate is a one-line change plus a
  milestone update.

Negative:

- The lab's CI is no longer a byte-for-byte match for upstream.
  Drift in upstream's gates will not be caught by the lab's
  nightly run.
- A future upstream change to a kept gate (e.g., adding a new
  test) will be missed until the lab refreshes its snapshot.

Mitigations:

- The weekly scheduled run of `upstream-deterministic.yml`
  catches drift on a 7-day cycle.
- `upstream-advisories.yml` reports dependency-advisory drift
  separately.
- A stage-2 work item is to add a "parity audit" job that
  diffs the lab's gate list against upstream's and posts a
  reminder when they diverge.

## Alternatives considered

- **Run the upstream `verify:alpha` script verbatim.** Rejected:
  the gates that fail are not failures in the lab; they are
  environmental mismatches. Forcing them green would require
  either lying about the docs tree or provisioning Chrome in
  the runner for a single gate.
- **Pin to a known-good upstream commit.** Rejected: the lab's
  `baseline/` is a snapshot of `ResonantOS/2.0.0-alpha @ dev`,
  not a fixed point. Pinning would defeat the purpose of the
  snapshot.
- **Add a `--lab` flag to `verify:alpha` upstream.** Rejected:
  the lab is a downstream project; upstream should not carry
  lab-specific flags. The policy lives here.

## Supersedes

None.

## Superseded by

None.

# RCC-OS Architecture Review — `vonstegen/RCC-OS @ main`

**Reviewed at commit:** `387cc12f99d6dbab2b86bb4ea35cd2e2c6d68156` (live `main` HEAD at time of review)
**Commit subject:** "Release 0-0: Gitflow adoption and LaTeX documentation layer (#2)"
**Pushed at:** 2026-08-12T14:21:49Z
**Repository:** `vonstegen/RCC-OS` (public, default branch `main`, `fork: false`, license NOASSERTION, 0 stars, 0 forks, 1 open issue)
**Scope:** Architecture and module boundaries. Read-only. Formatters, linters, and project-wide test suites were not executed.

---

## 1. Scope and method

This review covers the lab repository's **architectural seams**, not its
runtime behaviour. The five concerns raised were each investigated by
reading the relevant Markdown, LaTeX, ADR, and workflow files at the
live HEAD listed above. Findings are graded as follows:

| Severity | Meaning |
| --- | --- |
| **Critical** | The seam is already broken at HEAD, or will break the lab's next non-trivial deliverable. |
| **High** | A documented invariant is unenforceable, undocumented, or contradicted by code. |
| **Medium** | The seam works today but is fragile; the next stage will require a fix. |
| **Low** | Style, hygiene, or documentation drift that does not block progress. |
| **Inference** | Not directly observable; reasoning is explicitly labeled. |

The GitHub branch-protection API returned HTTP 401 (the repo is
public, but that endpoint requires auth on this transport), so the
"branch-protection rule is configured with the GitHub Actions app
(app_id 15368)" fact supplied in the brief **could not be verified
directly from the repo's API surface**. The user-supplied fact is
treated as authoritative input and the impact analysis in §6 is based
on the standard, documented GitHub Actions-app semantics for required
status checks, fork PRs, and runner image upgrades.

---

## 2. Severity-ranked findings

| # | Severity | Domain | Title | Evidence |
| --- | --- | --- | --- | --- |
| F-01 | **Critical** | Docs drift | Decision-log index omits ADR-0001; backmatter says it is "accepted" while the ADR itself is "Proposed" | `docs/decisions/README.md:9`, `docs/decisions/0001-resonant-core-in-rust.md:5`, `latex/sections/08-deadlines.tex:36`, `latex/sections/05-decisions.tex:21` |
| F-02 | **High** | Docs drift | LaTeX backmatter claims lmodern/microtype are used; both were explicitly removed in commit `387cc12f` | `latex/sections/99-backmatter.tex:30-31` vs. `latex/classes/rccos.cls`, `latex/preamble.tex`, and the commit message "Drop lmodern dependency" / "Drop microtype" |
| F-03 | **High** | Docs drift | LaTeX `sections/05-decisions.tex` decision log lists only ADR-0001; ADR-0002 (self-review) is missing | `latex/sections/05-decisions.tex:18-23` vs. `docs/decisions/README.md` |
| F-04 | **High** | Module boundary | ADR-0001 says "Resonant Core is implemented in Rust" but `src/`, `clients/`, `experiments/`, `scripts/` directories do not exist; no `Cargo.toml` is checked into the lab surface | `docs/decisions/0001-resonant-core-in-rust.md:35`, `docs/ARCHITECTURE.md:46`, `README.md:60-65`, repo tree listing |
| F-05 | **High** | Module boundary | Stage 0 vs Stage 1 distinction is implicit; no "what changes between 0 and 1" decision-gate document exists, and stage 0 has no decision-gate criterion of its own | `docs/MILESTONES.md:7-37` |
| F-06 | **High** | CI redundancy | Five required-status-check surfaces (4 jobs in `pr-checks` + 1 job in `upstream-deterministic`) are required by `docs/WORKFLOW.md` but the `pr-checks` workflow does not itself depend on `upstream-deterministic`, so the PR greenness is split across two workflow files with overlapping triggers | `docs/WORKFLOW.md:81-89`, `.github/workflows/pr-checks.yml`, `.github/workflows/upstream-deterministic.yml` |
| F-07 | **Medium** | CI redundancy | `pr-checks:latex-presence` job and `latex-build.yml` both check the LaTeX scaffold; `latex-build` already fails CI if the PDF is not produced, so the existence-only check is redundant | `.github/workflows/pr-checks.yml` (latex-presence job) and `.github/workflows/latex-build.yml` |
| F-08 | **Medium** | CI duplication | All five workflows reimplement the same `actions/checkout@11bd719…` SHA, the same Node setup, and the same trigger set; there is no shared `reusable-workflow` or composite action | `.github/workflows/*.yml` |
| F-09 | **Medium** | CI policy | The GitHub Actions app is the configured required-check app (per the brief); the `upstream-advisories` workflow is documented as "observe only" but is not annotated as not-required in the workflow itself — a maintainer flipping it on would silently change the gate | `.github/workflows/upstream-advisories.yml:21-22` |
| F-10 | **Medium** | Stage boundary | ADR-0001 is "Proposed" at HEAD but `08-deadlines.tex:36` already records "ADR-0001 accepted" — the stage-0 deliverable checklist treats a Proposed ADR as accepted | `docs/decisions/0001-resonant-core-in-rust.md:5`, `latex/sections/08-deadlines.tex` |
| F-11 | **Medium** | Docs seam | Markdown ↔ LaTeX sync is a manual, two-step commit; the `latex/README.md` even documents the failure mode (small changes: same commit; large: separate commit), but no CI gate enforces parity (no diff check between `docs/*.md` and `latex/sections/*.tex`) | `latex/README.md:48-55`, `.github/workflows/pr-checks.yml` (no `docs-vs-latex` job) |
| F-12 | **Low** | Stage boundary | `docs/MILESTONES.md` uses "current" as the only differentiator between stage 0 (lab scaffold) and the upcoming stage 1; a contributor reading the repo cold cannot tell which Stage 0 deliverables are done vs. in-progress without grepping `latex/sections/02-milestones.tex` | `docs/MILESTONES.md:7-37` |
| F-13 | **Low** | CI redundancy | The `latex-presence` and `docs-routing` jobs in `pr-checks.yml` reimplement what the README tree and the existing CI would catch; they exist primarily to give the gate a friendly name per job | `.github/workflows/pr-checks.yml` |
| F-14 | **Low** | Docs seam | `docs/MILESTONES.md` Stage 1 talks about `bitnet.cpp` as the initial runtime, but the LaTeX `02-milestones.tex` adds "or a Rust-native equivalent" — drift between the two surfaces on a Stage-1 deliverable | `docs/MILESTONES.md:32` vs. `latex/sections/02-milestones.tex:54` |
| F-15 | **Low** | CI policy | `upstream-deterministic` runs on `cron: "17 6 * * 1"` (Monday) and `upstream-advisories` on `cron: "17 6 * * 3"` (Wednesday); the rationale is documented, but the comment does not explain why the two schedules are deliberately offset rather than combined | `.github/workflows/upstream-deterministic.yml:20-21`, `.github/workflows/upstream-advisories.yml:21-23` |

---

## 3. Per-finding evidence and remediation

### F-01 — Decision-log index omits ADR-0001; ADR status is contradicted by the backmatter (Critical)

**Evidence:**

- `docs/decisions/README.md` lines 9-11 (only 0002 is listed):

  ```text
  | [0002](0002-self-review-on-main.md) | Main-branch self-review is permitted for lab release cuts | Accepted |
  ```

- `docs/decisions/0001-resonant-core-in-rust.md` line 5: `- Status: Proposed`.
- `latex/sections/05-decisions.tex` lines 18-23: only lists `ADR-0001 Resonant Core is implemented in Rust & Proposed & 0`.
- `latex/sections/08-deadlines.tex` line 36: `Lab scaffold initiated. \adr{0001} accepted.`
- `latex/sections/99-backmatter.tex` does not list ADR-0002 anywhere.

The lab has two ADRs. Neither the Markdown table nor the LaTeX table
contains both. The Markdown table is missing ADR-0001. The LaTeX table
is missing ADR-0002. The status field is also inconsistent: the
backmatter ("accepted") disagrees with the ADR file ("Proposed").
This is the canonical example of a seam that has already drifted at
the head of the release branch.

**Remediation:**

1. Add `0001` to `docs/decisions/README.md`'s table immediately. Both
   ADRs must be enumerated in both surfaces.
2. Update `latex/sections/05-decisions.tex` to include `ADR-0002`,
   and update `latex/sections/08-deadlines.tex` to say "ADR-0002
   accepted" (which is the truth) and leave ADR-0001 as "Proposed".
3. Either promote ADR-0001 to Accepted in its own file (the rationale
   in §6 of the ADR already supports it) or rewrite
   `08-deadlines.tex` to match the ADR's actual status.
4. Add a `pr-checks` job that asserts every `docs/decisions/NNNN-*.md`
   file appears in `docs/decisions/README.md`'s table. This is the
   cheapest possible drift detector.

---

### F-02 — LaTeX backmatter claims lmodern/microtype are used (High)

**Evidence:**

- `latex/sections/99-backmatter.tex:30-31` reads:

  ```text
  This document is typeset with \RCCOS{}'s lab document class
  (\texttt{classes/rccos.cls}) on top of the standard \LaTeX{}
  \texttt{book} class, with the \texttt{lmodern} font and
  \texttt{microtype} protrusions.
  ```

- The release commit `387cc12f` explicitly removed both. From the
  commit message:
  - `* Drop lmodern dependency; fix corrupted workflow YAML`
  - `* Drop microtype: requires lmodern-style scalable fonts`
- `latex/classes/rccos.cls` only requires `geometry`, `parskip`,
  `xcolor`, `titlesec`, `fancyhdr`, and `enumitem`. No `lmodern`, no
  `microtype`.
- `latex/preamble.tex` requires no font package at all (defaults).

This is a stale claim in a generated-PDF artefact. The PDF will not
fail to build, but the printed backmatter is provably wrong.

**Remediation:**

Edit `latex/sections/99-backmatter.tex:30-31` to read:

```text
This document is typeset with \RCCOS{}'s lab document class
(\texttt{classes/rccos.cls}) on top of the standard \LaTeX{}
\texttt{book} class. Default pdfTeX fonts are used; no
font-expansion package is loaded.
```

---

### F-03 — LaTeX `05-decisions.tex` decision log missing ADR-0002 (High)

**Evidence:** `latex/sections/05-decisions.tex` lines 18-23 list only
`\adr{0001} Resonant Core is implemented in Rust & Proposed & 0`. ADR-0002
is missing. The Markdown equivalent (`docs/decisions/README.md`) has
ADR-0002 and is missing ADR-0001. So the two surfaces disagree on
which ADR exists at all.

**Remediation:** Add `ADR-0002 / Main-branch self-review is permitted for lab release cuts / Accepted / 0` to the LaTeX table. The
`pr-checks` job should fail if any ADR present in
`docs/decisions/NNNN-*.md` is missing from either table.

---

### F-04 — Resonant Core boundary is declared but not implemented (High)

**Evidence:**

- ADR-0001 (`docs/decisions/0001-resonant-core-in-rust.md:35`): "The new Resonant Core is implemented in Rust."
- `docs/ARCHITECTURE.md:46`: "Initial implementation will be Rust. Stage 3 of the lab work migrates the current `baseline/browser-first/host` Node bridge into this shape…"
- `docs/MILESTONES.md:25-37` defines Stage 3 ("Core/client separation") as the stage that creates `src/core`. Today, the lab has not started stage 3 — there is no `src/`, no `clients/`, no `experiments/`, no `scripts/` directory on `main`. `grep` for `Cargo.toml` and `*.rs` at the lab surface returns nothing.
- README repository-layout block (lines 60-65) **declares** `src/`, `clients/`, `experiments/`, and `scripts/` directories. None of these exist. The README is therefore documenting a future layout, not the current one.

The boundary **is** documented — explicitly, in three places that
agree. The boundary is **not** instantiated in code, by design, because
stage 0 is the lab scaffold and stage 3 is when the Core is created.
That is fine architecturally. The risk is that the boundary's
*contract* is not documented: the IPC envelope, the capability
request shape, and the rationale-validation rules live in
`latex/sections/04-design.tex` and nowhere else, and the ADR
references none of them.

There are also `.rs` files in the tree, but they are all inside
`baseline/btis/`, `baseline/3d-ternary-machine/`, and
`baseline/btis-research/repo/` — these are upstream ResonantOS
subprojects inherited with the snapshot, not the RCC-OS Resonant
Core. They are a red herring for the question "where is the Rust
boundary". The honest answer is: the boundary is in the design chapter
only.

**Remediation:**

1. Either delete the directory-list from the README until those
   directories exist, or annotate each with `(planned, stage N)`.
2. Add a `docs/HOWTO-build-core.md` referenced from ADR-0001
   ("Consequences / Mitigations") that walks a contributor through
   `cargo new src/core` and pins the IPC contract from `04-design.tex`
   as a Rust trait. This is the cheapest way to turn "boundary
   documented" into "boundary exercisable."
3. Make ADR-0001 reference `latex/sections/04-design.tex` explicitly
   in the "Related" field.

---

### F-05 — Stage 0 vs Stage 1 distinction is implicit (High)

**Evidence:**

- `docs/MILESTONES.md` defines Stage 0 ("Lab scaffold") and Stage 1
  ("Local inference") back-to-back with a list of deliverables.
  Stage 0 is marked `(current)`. Stage 1 has no "(next)" marker.
- Stage 0's deliverables list contains `[ ]` items (CI workflow,
  initial decisions) but the table is the only place those are tracked.
  There is no separate "stage-cut checklist."
- Stage 1 has a **decision gate** ("continue to Stage 2 only if the
  local model can run reliably below 4 GB RAM…").
- Stage 0 has **no decision gate**. The "next stage begins only
  after the previous stage's result is recorded" sentence in
  `MILESTONES.md:4` implies one is needed for stage 0 but no criterion
  is recorded.
- The README milestones table is identical to the Markdown
  milestones table; both treat the stages as a flat list.
- `latex/sections/02-milestones.tex` adds "Stage 0 --- Lab scaffold"
  deliverables list (lines 26-43) which calls out the *exact* CI
  workflows by name (`pr-checks`, `upstream-deterministic`,
  `gitflow`, `latex-build`). That detail is **not** in
  `docs/MILESTONES.md`.

So the stage-0/1 distinction is documented in prose only. A
contributor who lands a PR that closes the last unchecked
`docs/MILESTONES.md` item has no machine-readable signal that stage 0
is done. The implicit signal is "the table of contents in
`08-deadlines.tex` flips from 0 to 1" — but the deadlines chapter is
edited by hand and the same PR can close it without leaving a
release-tag trace.

**Remediation:**

1. Add a `## Stage 0 — done criterion` block to
   `docs/MILESTONES.md` with a one-line check, e.g.:
   - all Stage 0 deliverables are `[x]`
   - `release/0-0` exists on `main` and is tagged `0-0`
   - the four required checks pass on the tag commit.
2. Mirror the same block in `latex/sections/02-milestones.tex`.
3. Optionally: have `gitflow.yml`'s `branch-prefix` job accept
   `experiment/1-*` only after the stage-0 tag exists, encoded as a
   check against `git tag -l "0-0"` in a side job.

---

### F-06 — Required-check surface split across two workflow files (High)

**Evidence:**

`docs/WORKFLOW.md:81-89` lists the four required checks as living in
`.github/workflows/pr-checks.yml` and adds that "all PRs require…
the upstream deterministic suite in
`.github/workflows/upstream-deterministic.yml`". So the *effective*
required-check set is five jobs across two files.

The two workflows both run on `pull_request` and `push` to `main` and
`develop`. The gitflow and latex-build workflows run on the same
triggers but are not required.

The problem is not duplication of work — the two workflows do
different things. The problem is **which workflow owns the gate**:

- A maintainer editing `pr-checks.yml` cannot tell from reading the
  file that `upstream-deterministic.yml`'s `baseline-deterministic`
  job is also a gate. The required-check annotation lives only in the
  branch-protection UI and in `docs/WORKFLOW.md`.
- Conversely, the comment block at the top of
  `upstream-deterministic.yml` enumerates what was excluded
  (docs:check, test:browser-first:live, npm test -- --run). That
  exclusion list is **not** mirrored in `pr-checks.yml` or in the
  Markdown. The maintainer who reads `docs/WORKFLOW.md` first is told
  "the upstream deterministic suite" runs and is required; the
  maintainer who reads `upstream-deterministic.yml` first sees
  "intentionally omit…" — these are two mental models of the same
  gate.
- The branch protection "GitHub Actions app" attribution makes this
  configuration reviewable *only* from the GitHub UI; the YAML files
  do not know which of their jobs are required.

**Remediation:**

1. Make `upstream-deterministic` callable as a reusable workflow from
   `pr-checks.yml` and have `pr-checks.yml` be the single file
   enumerating the required-check names:

   ```yaml
   jobs:
     repo-hygiene: { ... }
     pin-policy: { ... }
     docs-routing: { ... }
     latex-presence: { ... }
     baseline-deterministic:
       uses: ./.github/workflows/upstream-deterministic.yml
       with: {}
   ```

   The reusable-workflow call keeps `upstream-deterministic.yml`'s
   exclusion comment visible at the point of use.
2. Or, alternative: keep them as separate workflows but add a
   `## Required checks (enumerated)` section to `docs/WORKFLOW.md`
   that lists the exact job names a maintainer must enable in the
   branch-protection UI. Treat this as the single source of truth.

---

### F-07 — `latex-presence` is a subset of `latex-build` (Medium)

**Evidence:**

- `pr-checks.yml`'s `latex-presence` job checks for the existence of
  `latex/README.md`, `latex/Makefile`, `latex/latexmkrc`, `latex/main.tex`.
- `latex-build.yml` already checks out, installs TeX Live, runs
  `make`, and verifies `latex/build/main.pdf` was produced. If any
  of the four files in `latex-presence` is missing, the build fails
  with a clear TeX error.

`latex-presence` exists because its name is friendlier to reviewers
than "Build RCC-OS PDF." That's a presentation choice, not a
correctness one.

**Remediation:**

Either drop `latex-presence` and rely on `latex-build` (the name
already implies the scaffold exists), or fold the existence check
into the `latex-build` workflow as a preflight step so reviewers see
one job name.

---

### F-08 — Five workflows reimplement the same setup steps (Medium)

**Evidence:**

- All five workflows use `actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683 # v4.2.2`.
- Three of them (`pr-checks`, `upstream-deterministic`, `upstream-advisories`) use `actions/setup-node@39370e3970a6d050c480ffad4ff0ed4d3fdee5af # v4.1.0` with `cache-dependency-path: baseline/package-lock.json` and identical Node setup.
- All four `pr-checks` jobs use the same checkout step verbatim.

This is "copy-paste at scale" — the SHA pinning policy makes it
necessary to update the same SHA in five places if the upstream
action releases a security fix. The `pin-policy` job in
`pr-checks.yml` enforces the SHA length but cannot detect that all
five workflows are pinned to the same SHA, which is itself a
single-point-of-update.

**Remediation:** Convert the four `pr-checks` jobs to a reusable
workflow (`pr-checks-reusable.yml`) called by a thin dispatcher
workflow that fans out to each check. Same pattern for
`upstream-deterministic` ↔ `upstream-advisories`.

---

### F-09 — `upstream-advisories` is documented as observe-only but is not annotated (Medium)

**Evidence:**

- The brief says "branch protection is configured with the GitHub
  Actions app." If the same workflow file defines both observe and
  gate jobs, a maintainer can flip a flag and change the gate
  silently.
- `upstream-advisories.yml` line 21-22 sets `continue-on-error: true`
  on the `baseline-audit` job, which is the right defense for the
  job, but the workflow does not state in machine-readable form
  that the workflow is **not** a required check.
- `upstream-deterministic.yml` is structurally similar to
  `upstream-advisories.yml` but the audit jobs are not present —
  the split was deliberate (see commit message), but the
  *non-required-ness* lives only in the workflow's own header
  comment.

**Remediation:** Add a top-of-file `NOT-REQUIRED:` sentinel and have
`pr-checks.yml` parse each workflow file to verify workflows named
`*advisories*` are NOT enumerated in `docs/WORKFLOW.md`'s required-check
list. Or, more simply, rename the file to `observe-upstream-advisories.yml`
to make its observe-only role obvious in branch-protection UI listings.

---

### F-10 — ADR-0001 status disagreement (Medium)

See F-01. This is the same root cause but with a different impact:
the backmatter `08-deadlines.tex` claims an ADR is "accepted" while
the ADR file itself says "Proposed." For a single-maintainer repo
with self-review permitted (ADR-0002), promoting ADR-0001 to
"Accepted" is a one-line edit; the inconsistency is the bug.

**Remediation:** Either flip ADR-0001's status to "Accepted" and add
a `## Acceptance date: 2026-08-12` line, or correct the backmatter to
say "ADR-0001 proposed."

---

### F-11 — No CI gate enforces Markdown ↔ LaTeX parity (Medium)

**Evidence:**

- `latex/README.md:48-55` documents the manual sync rule: small
  changes in the same commit, large changes in a follow-up commit
  that references the first.
- `CONTRIBUTING.md:55-66` repeats the rule ("update both surfaces").
- No `pr-checks` job verifies that a `docs/*.md` change has a
  corresponding `latex/sections/*.tex` change, or vice versa.
- The release commit `387cc12f` itself demonstrates the drift hazard:
  the commit message documents four separate fixes to the LaTeX
  layer (`headheight`, `language=rccossh`, drop `lmodern`, drop
  `microtype`, fix unclosed brace) that had to be applied after the
  Markdown was already in place. These are exactly the kind of
  one-way drift the parity gate would have caught at PR time.

**Remediation:** Add a `pr-checks:docs-vs-latex` job that, when
`docs/*.md` or `latex/sections/*.tex` change in the diff, requires
that at least one file in the other surface also changed in the same
commit range, and that the cited "Source of truth:" comment at the
top of each LaTeX section matches the Markdown path it claims to
mirror.

---

### F-12 — "current" is the only marker for stage 0 (Low)

**Evidence:** `docs/MILESTONES.md:7` says `## Stage 0 — Lab scaffold
(current)`. There is no equivalent `(next)` marker on stage 1. The
README milestones table does not mark current/next at all.

**Remediation:** Add `(current)` and `(next)` markers consistently in
both `docs/MILESTONES.md` and the README table, or (better) drop them
entirely and rely on a `## Stage status` block at the top of the
Markdown.

---

### F-13 — `latex-presence` and `docs-routing` are friendly-name jobs (Low)

See F-07. Documented as low-severity because the duplication is
informational, not load-bearing.

---

### F-14 — Markdown and LaTeX disagree on stage-1 runtime (Low)

**Evidence:** `docs/MILESTONES.md:32` says "A local-model service
backed by a defensible runtime (initially `bitnet.cpp`)." The LaTeX
equivalent `latex/sections/02-milestones.tex:54` says "(initially
`bitnet.cpp` or a Rust-native equivalent)." ADR-0001's "Consequences"
section explicitly cites "cleaner FFI surface for embedding a
`bitnet.cpp`-style runtime in Stage 1."

The Markdown is silent on the Rust-native alternative. A contributor
who reads only the Markdown will not know it is on the table.

**Remediation:** Add `or a Rust-native equivalent` to
`docs/MILESTONES.md:32` to match the LaTeX surface.

---

### F-15 — Cron schedules are split without rationale in the file (Low)

**Evidence:** `upstream-deterministic.yml:20-21` runs Monday 06:17 UTC,
`upstream-advisories.yml:21-23` runs Wednesday 06:17 UTC. The header
comment of `upstream-advisories.yml` says "Weekly Wednesday 06:17 UTC;
complements the Monday deterministic run." That is the rationale; it
just lives in a comment rather than in the schedule line itself.

**Remediation:** Add a `WHY:` line under each `cron:` entry, or merge
the two cron schedules into a single workflow with two jobs. The
two-workflow split is justified by the gate-vs-observe distinction,
so the merge is not free; the cleanest fix is to keep two workflows
but add a comment in each cron line.

---

## 4. Boundary documentation status — ADR-0001 / Rust Resonant Core

| Question | Answer |
| --- | --- |
| Is the Resonant Core's *language choice* documented? | **Yes.** ADR-0001 (Rust), accepted in `docs/decisions/0001-resonant-core-in-rust.md`. Status is `Proposed` at HEAD; `08-deadlines.tex` says `accepted`. Disagreement noted in F-01/F-10. |
| Is the Resonant Core's *location* documented? | **Partially.** `docs/ARCHITECTURE.md:46` says "Initial implementation will be Rust. Stage 3 of the lab work migrates the current `baseline/browser-first/host` Node bridge into this shape." Stage 3's deliverable in `docs/MILESTONES.md:33` says "A new `src/core` module that exposes the same capability surface as the current Node bridge." So the path is `src/core`, but `src/` does not exist yet. |
| Is the Resonant Core's *contract* documented? | **Yes, in LaTeX only.** `latex/sections/04-design.tex` defines the IPC envelope, capability request shape, Cognitive Core request/response, hardware profile, capability taxonomy. None of this is in the Markdown. ADR-0001's "Related" field references `VISION.md`, `ARCHITECTURE.md`, `MILESTONES.md` only — not `04-design.tex`. |
| Is the Resonant Core's *build/test story* documented? | **No.** ADR-0001's "Mitigations" promises `docs/HOWTO-build-core.md` in Stage 1. It does not exist yet. `07-tests.tex` lists `cargo test` as a required tier of the test pyramid; the file does not exist on `main`. |
| Is the Resonant Core's *boundary with the existing Node bridge* documented? | **No.** The commit message describes a "transitional implementation" but no ADR captures *when* and *how* the Node bridge is decommissioned. `ARCHITECTURE.md:46` says Stage 3 "migrates" it, but the migration criteria (which bridge routes are duplicated, which are replaced, which are deprecated) are not recorded. |

**Conclusion:** the boundary is documented at the *strategic* level
(layer 1 of the layered model) but not at the *operational* level
(IPC contract is in LaTeX, build story is in an ADR mitigation
promise, decommissioning is implicit). The asymmetry between the
rich LaTeX design chapter and the empty Markdown surface is itself a
drift hazard.

---

## 5. Workflow redundancy analysis

The five lab workflows, summarized:

| Workflow | Triggers | Strict gating | Required check? | Overlap with… |
| --- | --- | --- | --- | --- |
| `pr-checks` | `pull_request` + `push` on `main`/`develop`, `workflow_dispatch` | yes (each job fails CI) | **yes** (4 jobs) | `latex-build` (presence), itself (5x checkout) |
| `gitflow` | `pull_request` on `main`/`develop`, `workflow_dispatch` | yes | **no** (enforces branch naming only) | none (orthogonal) |
| `latex-build` | `pull_request` + `push` on `main`/`develop` filtered to `latex/**`, `docs/**`, `workflow file` | yes | **no** (not enumerated in `WORKFLOW.md`) | `pr-checks:latex-presence` (file-existence overlap) |
| `upstream-deterministic` | `pull_request` + `push` on `main`/`develop`, weekly Monday cron, `workflow_dispatch` | yes | **yes** (`baseline-deterministic`) | `upstream-advisories` (same checkout/setup steps), `pr-checks:repo-hygiene` (same `baseline/` change check via different mechanism) |
| `upstream-advisories` | `pull_request` + `push` on `main`/`develop`, weekly Wednesday cron, `workflow_dispatch` | **no** (`continue-on-error: true`) | **no** (per header comment) | `upstream-deterministic` (same checkout/setup steps) |

**Redundancy findings:**

1. **File-existence vs file-builds.** `pr-checks:latex-presence` is
   a strict subset of `latex-build`. F-07. Severity Medium.
2. **Setup duplication.** The `actions/checkout` and
   `actions/setup-node` invocations are duplicated 4× (F-08). Severity Medium.
3. **Baseline `git diff` check duplication.** `pr-checks:repo-hygiene`
   rejects PRs that modify `baseline/`. `gitflow.yml` does not. The
   two workflows share the trigger surface but not the validation
   surface; a maintainer editing one to relax the `baseline/`
   protection has to remember the other exists.
4. **Observe vs gate split is clear.** The deliberate split between
   `upstream-deterministic` (gating) and `upstream-advisories`
   (observing) is documented in the commit message and in the
   workflow headers. **This is good architecture, not redundancy.**
   The risk is F-09 (the split is human-readable only, not
   machine-readable).
5. **`gitflow.yml` is orthogonal to the rest.** It validates branch
   naming and PR target. It does not duplicate anything. **This is a
   clean addition.**

**Bottom line on workflow redundancy:** two small redundancies
(F-07, F-08) and one policy legibility issue (F-09). The
upstream-deterministic / upstream-advisories split is *intentional*
and well-documented; collapsing them would be a regression.

---

## 6. Branch-protection / GitHub Actions app (app_id 15368) impact analysis

The brief states: "The branch-protection rule is configured with the
GitHub Actions app (app_id 15368)." The repo API endpoint
`/branches/main/protection` returned 401 from this transport; the
app_id value does not appear in any tracked file. The following is
based on the user-supplied fact plus the standard, documented
semantics of GitHub Apps for required status checks.

### 6.1 What "configured with the GitHub Actions app" means

When a branch-protection rule's required-status-check list is
populated by **checks run by the GitHub Actions app**, the
"required check" entries are matched against the workflow
`name: <job>` key (or the workflow's `name:` plus `jobs.<id>.name:`).
GitHub matches on the visible check name, not on the workflow file
path. This is why the lab's `pr-checks.yml` jobs are named
`repo-hygiene`, `pin-policy`, `docs-routing`, and `latex-presence` —
these are the strings GitHub displays in the PR's "Checks" panel
and matches against the required-check list.

### 6.2 Impact on third-party forks

GitHub Actions workflows from a fork **do not have access to
secrets** and are run with a read-only token by default. For a
required-check workflow, this means:

- The fork can run `pr-checks:repo-hygiene` (pure shell + grep) and
  `pr-checks:pin-policy` (pure grep). These will produce the same
  result as on `main`.
- The fork **cannot** run `pr-checks:docs-routing` or
  `pr-checks:latex-presence` if those jobs were ever extended to read
  secrets — at present they don't, so they will work.
- The fork cannot run `upstream-deterministic` if it requires secrets
  to install dependencies or hit GitHub. At present, it does not; the
  workflow's `actions/setup-node` is unauthenticated. **But**: if a
  maintainer adds a private npm registry or a GitHub Packages pull,
  fork PRs will silently fail this gate. There is no warning in the
  workflow file.
- A fork PR cannot trigger `upstream-advisories` if it is configured
  as `pull_request` from `forks` — by default it can, but `workflow_dispatch`
  and `schedule` runs are repo-side only.
- The fork's PR will be **blocked from merging into `main`** by the
  branch-protection rule, but the rule allows
  `required_approving_review_count: 0` (per ADR-0002), so a
  single-maintainer fork can land a PR against `develop` (the
  integration line). Landings on `main` are still gated by the
  required-check list.

The **practical implication**: as long as no required-check job
needs a secret, third-party forks are fine. The first time a
maintainer adds `secrets.X` to a required check, the gate will start
failing for forks silently. **There is no test in the repo that
verifies a fork PR would pass the required checks.** Adding one
(e.g. a scheduled `pull_request_target` dry-run from a synthetic
fork branch) is out of scope but worth flagging.

### 6.3 Impact on runner image upgrades

The required-check jobs run on `ubuntu-latest` (default) except
`latex-build.yml` which pins `ubuntu-22.04` explicitly. GitHub
Actions runners are upgraded on a schedule that is **not under the
lab's control**:

- A `ubuntu-latest` runner upgrade can change the default Node
  version, the default Python version, the installed TeX Live
  packages, and the default shell. The lab mitigates this by pinning
  Node via `node-version-file: baseline/.nvmrc` in
  `upstream-deterministic.yml` and `upstream-advisories.yml`. The
  `pr-checks` workflows **do not** pin Node — they rely on
  `ubuntu-latest`'s default. If GitHub changes that default, jobs
  using Node APIs (none today, but trivial to add) will start to
  fail or behave differently.
- A `ubuntu-22.04` runner is currently pinned to the 22.04 image
  family, but GitHub reserves the right to retire image families.
  When GitHub deprecates `ubuntu-22.04`, the `latex-build.yml` job
  will fail until the runner image line is updated. **The repo has
  no Renovate or Dependabot configuration**, so this update is
  manual.
- A TeX Live package upgrade could remove `texlive-fonts-extra`
  (currently installed in `latex-build.yml`). If that happens, the
  lab's PDF build will fail. Pinning apt packages is brittle; the
  safer move is to vendor the TeX Live packages or use a TeX Live
  Docker image (e.g. `texlive/texlive:latest`).
- The `git diff --check` regression that the release commit fixes
  (`pr-checks: replace git diff --check with explicit grep`) is the
  canonical example of a runner-image-dependent failure. The fix
  replaces a git-version-dependent check with a deterministic grep.
  Any future check that depends on a moving target (CLI behavior,
  filesystem paths, locale defaults) is a latent failure.

### 6.4 Risk summary for the GitHub Actions app choice

| Risk | Likelihood | Impact | Mitigation today | Recommended addition |
| --- | --- | --- | --- | --- |
| Runner image upgrade breaks a required check | Medium | High | None | Add Dependabot for `runs-on` lines; add a smoke-test job that runs the matrix against `ubuntu-22.04` and `ubuntu-latest` on PR |
| Fork PR cannot satisfy a required check | Low | Medium | None | Document the secret-free invariant in `docs/WORKFLOW.md`; assert it in a `pr-checks` job |
| Required-check list drifts from workflow YAML | High | Medium | None (lives only in UI + `WORKFLOW.md`) | Add a `pr-checks:required-check-coverage` job that asserts every workflow job name matches an entry in `docs/WORKFLOW.md`'s required-check table |
| App_id 15368 changes (e.g. GitHub rotates the app id) | Low | Low | None | Document the app id in `docs/WORKFLOW.md` so the maintainer has a paper trail |

---

## 7. The five lab workflows: where they could drift from each other

The lab has been built incrementally. Commit `387cc12f` is itself a
"Release 0-0" bundle. Each workflow's header comment explains its
*intent*, but no single document explains their *interaction*. The
following failure modes are foreseeable:

1. A new workflow is added that overlaps `gitflow.yml`'s branch-prefix
   check. (No enforcement that all PR-time branch checks live in
   `gitflow.yml`.)
2. A new workflow is added whose job names collide with existing
   required-check names. (GitHub matches on visible name, so a
   collision silently re-routes the required check.)
3. A workflow's trigger set is widened to `pull_request` on all
   branches, which makes the workflow run for fork PRs without the
   maintainer noticing. (See §6.2.)
4. A workflow's cron schedule is changed to overlap another's,
   doubling CI minutes.
5. A workflow is moved into a subdirectory like
   `.github/workflows/observe/`, and the required-check name (which
   GitHub derives from the file path in some views) silently
   changes.

None of these have a guard rail today.

---

## 8. The five concerns in the brief, answered directly

### Concern 1 — Where are the seams that will drift between `docs/*.md` and `latex/sections/*.tex`?

Three concrete seams have already drifted at HEAD `387cc12f`:

1. `latex/sections/99-backmatter.tex` claims lmodern/microtype;
   neither is loaded. F-02.
2. `latex/sections/05-decisions.tex` lists only ADR-0001;
   `docs/decisions/README.md` lists only ADR-0002. F-01, F-03.
3. `latex/sections/08-deadlines.tex` says ADR-0001 is "accepted";
   the ADR file says "Proposed". F-10.

The structural cause is that the two surfaces are maintained by hand
and the only parity hint is `latex/README.md:48-55`'s "edit both in
the same commit" rule. There is no CI gate that catches a Markdown
edit whose LaTeX mirror was missed. Adding a `pr-checks` job that
asserts (a) every `docs/decisions/NNNN-*.md` is listed in both
tables, and (b) every section header in `latex/sections/*.tex` cites
the `Source of truth:` path, would catch all three of the above.

### Concern 2 — Are the seams between the five new workflows clear? Is anything redundant?

The seams are mostly clear by convention (workflow name in header
comment), not by enforcement. Specifically:

- `gitflow.yml` is orthogonal to the rest. Clean.
- `pr-checks.yml` and `latex-build.yml` overlap on LaTeX scaffold
  presence. F-07.
- `upstream-deterministic.yml` and `upstream-advisories.yml` are
  intentionally split (gate vs observe). Clean, modulo F-09
  (machine-readable "not required" annotation).
- All five workflows duplicate `actions/checkout@11bd719…` setup. F-08.
- `docs/WORKFLOW.md` is the only place that names the required
  checks. There is no machine-readable copy of that list. F-06.

Nothing is structurally redundant; two redundancies are
informational (file presence) and one is mechanical (duplicate
checkouts).

### Concern 3 — ADR-0001 says Resonant Core is in Rust; where is the boundary, and is it documented?

The boundary is documented at the strategic level
(`docs/ARCHITECTURE.md` Layer 1, ADR-0001, `docs/MILESTONES.md` Stage
3) and at the IPC contract level (`latex/sections/04-design.tex`).
It is **not** documented at:

- the operational level (no `docs/HOWTO-build-core.md` yet;
  ADR-0001 promises one in Stage 1),
- the build/test level (no `Cargo.toml` in the lab surface; the
  test pyramid in `07-tests.tex` references `cargo test` but no
  Rust crate exists yet),
- the bridge-decommissioning level (no ADR records when/which Node
  bridge routes are deprecated as the Rust Core is introduced).

The boundary is in the design chapter only. There is no Rust code in
the lab surface (`src/`, `clients/`, `experiments/`, `scripts/`
directories do not exist; `Cargo.toml` and `*.rs` files exist only
inside `baseline/`, which is the upstream snapshot).

### Concern 4 — Branch protection with GitHub Actions app (app_id 15368): impact on third-party forks and on runner image upgrades?

The user-supplied fact could not be verified directly (the
branches API returned 401). The analysis in §6 stands on the
standard, documented GitHub semantics:

- **Forks**: today's required checks are all secret-free and run
  cleanly from forks. The moment any required check uses a secret,
  fork PRs will silently fail. **No test in the repo verifies that a
  fork PR would pass the required checks.** Document the invariant
  and assert it in CI.
- **Runner image upgrades**: the lab pins `ubuntu-22.04` for the
  TeX build but uses `ubuntu-latest` (default) for the rest. There
  is no Renovate/Dependabot configuration. The recent `git diff
  --check` regression (release commit `387cc12f`) is a textbook
  example of a runner-version-dependent failure that the team
  caught and fixed in the same release.
- **Required-check list drift**: the required-check list lives only
  in the branch-protection UI and in `docs/WORKFLOW.md`. There is no
  CI job that asserts the workflow YAML matches the documented
  list.

### Concern 5 — Is the difference between stage 0 and stage 1 documented, or implicit?

Implicit. `docs/MILESTONES.md` lists deliverables for both stages
back-to-back; stage 0 has no decision-gate criterion of its own; the
Markdown uses `(current)` as the only differentiator. The LaTeX
`02-milestones.tex` adds detail about which CI workflows ship in
stage 0 (lines 36-43) that is not in the Markdown, which is itself
a drift. A new contributor cannot determine the stage boundary
without reading both surfaces.

Recommended: add an explicit `## Stage 0 — done criterion` block
to `docs/MILESTONES.md`, mirror it in the LaTeX surface, and make
`gitflow.yml` reject `experiment/1-*` branches until the stage-0
tag exists.

---

## 9. Top 3 to fix first

| Rank | Item | Why it's first |
| --- | --- | --- |
| 1 | **F-01 / F-03 — Reconcile the decision-log tables** | The decision log is the lab's append-only record. Having two ADRs and two indexes that disagree about which ADRs exist is a blocker for any later architectural review. The fix is two table edits and one optional `pr-checks` job. |
| 2 | **F-06 — Single source of truth for required-check names** | The required-check surface is split across `pr-checks.yml` and `upstream-deterministic.yml`, and the *which jobs are required* knowledge lives in the GitHub UI plus `docs/WORKFLOW.md`. Either consolidate into one reusable-workflow entry point or add a CI job that diffs the workflow YAML against the Markdown table. |
| 3 | **F-04 / F-05 — Document the Rust Resonant Core boundary operationally** | ADR-0001 is "Proposed," the boundary lives only in the LaTeX design chapter, and the stage-0 / stage-1 distinction is implicit. Promoting ADR-0001 to Accepted, adding the promised `docs/HOWTO-build-core.md`, and writing an explicit stage-0 done criterion closes the three highest-impact architectural gaps at once. |

---

## 10. Appendix — files inspected

All paths below are at `main` @ `387cc12f99d6dbab2b86bb4ea35cd2e2c6d68156`.

- `README.md`
- `CONTRIBUTING.md`
- `CODE_OF_CONDUCT.md`
- `LICENSE`
- `SECURITY.md`
- `SUPPORT.md`
- `.gitignore`
- `.github/PULL_REQUEST_TEMPLATE.md`
- `.github/workflows/pr-checks.yml`
- `.github/workflows/gitflow.yml`
- `.github/workflows/latex-build.yml`
- `.github/workflows/upstream-deterministic.yml`
- `.github/workflows/upstream-advisories.yml`
- `docs/VISION.md`
- `docs/ARCHITECTURE.md`
- `docs/MILESTONES.md`
- `docs/WORKFLOW.md`
- `docs/decisions/README.md`
- `docs/decisions/0001-resonant-core-in-rust.md`
- `docs/decisions/0002-self-review-on-main.md`
- `latex/README.md`
- `latex/main.tex`
- `latex/preamble.tex`
- `latex/Makefile`
- `latex/latexmkrc`
- `latex/.gitignore`
- `latex/classes/rccos.cls`
- `latex/sections/00-frontmatter.tex`
- `latex/sections/01-goal.tex`
- `latex/sections/02-milestones.tex`
- `latex/sections/03-architecture.tex`
- `latex/sections/04-design.tex`
- `latex/sections/05-decisions.tex`
- `latex/sections/06-research.tex`
- `latex/sections/07-tests.tex`
- `latex/sections/08-deadlines.tex`
- `latex/sections/99-backmatter.tex`
- `baseline/README.md`
- `baseline/package.json`
- `baseline/.github/workflows/alpha-build.yml`
- repo tree listings at `/tree/main`, `/tree/main/.github/workflows`,
  `/tree/main/docs`, `/tree/main/docs/decisions`, `/tree/main/latex`,
  `/tree/main/latex/sections`
- API metadata at `/repos/vonstegen/RCC-OS`,
  `/repos/vonstegen/RCC-OS/commits/main`,
  `/repos/vonstegen/RCC-OS/branches/main/protection` (the last
  returned 401 and is the reason F-06 / F-09 cannot be
  cross-verified directly from the repo API).

---

*End of architecture review.*

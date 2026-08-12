# RCC-OS build/CI review @ 387cc12f

**Category:** discovery
**Saved:** 2026-08-12T14:25:23.027Z
**Machine:** VIGIL
**Importance:** high

# RCC-OS Build, CI, and Reproducibility Review

**Repo:** `github.com/vonstegen/RCC-OS`
**Branch:** `main`
**SHA reviewed:** `387cc12f99d6dbab2b86bb4ea35cd2e2c6d68156`
**Commit message:** `Release 0-0: Gitflow adoption and LaTeX documentation layer (#2)`
**Commit date:** 2026-08-12T13:02:16Z
**Reviewer:** BuildReview-2
**Scope:** Build, CI, and reproducibility — latex-build, bridge bind surface, dependency manifests, action pin policy, auto-retrigger hygiene.

---

## Executive Summary

The Stage 0 lab scaffold is sound in build fundamentals but carries seven distinct concerns. Two are blockers for external distribution of the LaTeX PDF (the colophon still claims dropped packages, and the default Computer Modern measurably degrades typeset quality vs the dropped `lmodern`). One is a real correctness gap in dependency management (the dual-tree `playwright` install). The bridge listener correctly sanitizes `0.0.0.0` for URL derivation but still binds every interface when the env var is set (developer footgun, not CI). The pin policy and its self-policing are correctly implemented; all 11 action refs are 40-char SHAs; no under-pinning. The `chore: re-trigger pr-checks` was a one-time mitigation for a YAML parse error that the same release fixed; no systemic instability.

---

## Severity-Ranked Findings

| # | Severity | Finding | Domain |
|---|----------|---------|--------|
| 1 | HIGH | Colophon in `99-backmatter.tex` still advertises `lmodern` + `microtype` after both packages were dropped from `preamble.tex` | LaTeX |
| 2 | HIGH | `playwright@1.59.1` is declared as `devDependencies` in `baseline/package.json` AND as `dependencies` in `baseline/addons/resonant-browser-host/package.json`; both trees install it. No version drift, but duplicated ~250MB browser bundle in CI | Dependencies |
| 3 | MEDIUM | Bridge `startBridgeServer()` binds `bindHost` literally; when `RESONANTOS_BRIDGE_HOST=0.0.0.0` is set, the listener opens on every interface. URL derivation is partially sanitized (`dashboardProxyHostname` and `clientReachableHost` map 0.0.0.0→127.0.0.1) but `getBridgePublicUrl()` is NOT. No CI or committed script sets the env var; developer footgun only | Bridge |
| 4 | MEDIUM | Default pdfTeX Computer Modern (with `T1` encoding, no font package) yields measurably worse typeset than dropped `lmodern` (x-height, weight, hinting). Acceptable for internal archival; not for external reviewers expecting typeset quality | LaTeX |
| 5 | LOW | `chore: re-trigger pr-checks` no-op commit was a one-time mitigation for a YAML parse error that the same release fixed. Healthy once, unhealthy as a habit | CI |
| 6 | LOW | No root `package.json` or root `package-lock.json`. Naive `npm install` at root is a no-op (npm refuses without manifest). PR template's `make verify (or npm run verify:alpha --prefix baseline)` covers the case but the root README does not call it out | Dependencies |
| 7 | LOW | `latex-presence` job is not listed in ADR-0002's "four required status checks" (`repo-hygiene`, `baseline-deterministic`, `pin-policy`, `docs-routing`). LaTeX build is not gating on `main` unless branch protection is updated to include `latex-presence` and `latex-build` | CI |

---

## Finding 1 — HIGH: Stale colophon advertises dropped LaTeX packages

**File:** `latex/sections/99-backmatter.tex` (Colophon section, ~line 39):
```latex
This document is typeset with \RCCOS{}'s lab document class
(\texttt{classes/rccos.cls}) on top of the standard \LaTeX{}
\texttt{book} class, with the \texttt{lmodern} font and
\texttt{microtype} protrusions. ...
```

**Cross-reference:** `latex/preamble.tex` (raw) contains NEITHER `\usepackage{lmodern}` NOR `\usepackage{microtype}`. The release 0-0 commit message states "Drop lmodern dependency" and "Drop microtype: requires lmodern-style scalable fonts". The colophon contradicts the source.

**Remediation:** Delete the lmodern/microtype references from the colophon to match reality, OR re-add `\usepackage{lmodern}` to preamble (it's available in the already-installed `texlive-fonts-recommended`).

---

## Finding 2 — HIGH: `playwright` is declared as both devDependencies and dependencies across two trees

**Files:**
- `baseline/package.json` (devDependencies line 32): `"playwright": "^1.59.1"`
- `baseline/addons/resonant-browser-host/package.json` (dependencies line 15): `"playwright": "^1.59.1"`
- `baseline/package-lock.json` line 3747: `"version": "1.59.1", ..., "dev": true`
- `baseline/addons/resonant-browser-host/package-lock.json` line 18: `"version": "1.59.1"` (no dev marker)

No version drift (both pin 1.59.1) but: CI runs `npm ci` in both trees, downloading the same ~250MB Playwright bundle twice. Risk of future drift between the two `^1.59.1` ranges; lockfile masks this today.

**Remediation:** Pick one home. The addon is the only tree that runs Playwright at runtime (browser host service). Remove from `baseline/devDependencies` if no baseline test directly imports it.

---

## Finding 3 — MEDIUM: Bridge listener binds 0.0.0.0 literally when env var is set

**File:** `baseline/browser-first/host/bridge-server.mjs`
- Line 901-903: `getBridgeHost()` reads `RESONANTOS_BRIDGE_HOST` (default `127.0.0.1`).
- Line 1186, 1270: `const bindHost = host ?? getBridgeHost();`
- Line 1244, 1290, 1302: `server.listen(port, bindHost);` (HTTP and HTTPS listeners).

URL derivation is partially sanitized:
- Line 164-168 (`dashboardProxyHostname`): `0.0.0.0`/`::` → `127.0.0.1` for upstream dashboard proxy.
- `addon-delegation-service.mjs` `clientReachableHost()`: same translation for client-facing URL.
- BUT `getBridgePublicUrl()` (line 917-925): does NOT sanitize `0.0.0.0`. The generated `bridge-config.generated.js` would contain `http://0.0.0.0:47773/` if the user exports the env var without setting `RESONANTOS_BRIDGE_PUBLIC_URL`.

**CI scripts:** Grep across `.github/**/*.yml` and `baseline/scripts/**`: zero matches for `RESONANTOS_BRIDGE_HOST` or `0.0.0.0` outside the `bridge-server.mjs` source. The `dev` script uses `vite --host 127.0.0.1`. `run-bridge-minimal.mjs` does not export the var. Conclusion: developer-environment risk only.

**Remediation:**
- Hard-fail at startup if `RESONANTOS_BRIDGE_HOST` is `0.0.0.0`/`::` AND `RESONANTOS_BRIDGE_PUBLIC_URL` is unset.
- Sanitize `0.0.0.0`/`::` in `getBridgePublicUrl()` for symmetry with `dashboardProxyHostname()`.
- Document LAN-exposure risk in `SECURITY.md`.

---

## Finding 4 — MEDIUM: Default pdfTeX Computer Modern is a measurable typeset regression

With `T1` encoding and no font package, pdfTeX falls back to EC fonts. With `texlive-fonts-recommended` (installed by `latex-build.yml`), the CM-Super Type 1 outlines are used so the PDF is valid, but the metric quality is the same as plain EC: x-height ≈ 0.45em, weight ≈ 380, no protrusion or expansion.

By contrast, `lmodern` provides Latin Modern: slightly taller x-height, optical sizes, properly hinted Type 1.

For 11pt A4 software-architecture PDFs, the EC vs Latin Modern difference is visible but not dramatic. Acceptable for internal distribution, not for academic submission. Compounds with Finding 1 (colophon claims lmodern, so reviewers who trust the colophon will misjudge what they see).

**Remediation:**
- **(Best)** Re-add `\usepackage{lmodern}` — already covered by `texlive-fonts-recommended` in `latex-build.yml`.
- **(Acceptable)** Keep CM; rewrite colophon to say so.
- **(Avoid)** `kpfonts`/`newpxtext` — larger visual character change.

---

## Finding 5 — LOW: chore: re-trigger pr-checks was a one-time mitigation

Release 0-0 commit message: "Drop lmodern dependency; fix corrupted workflow YAML" → "pr-checks: quote YAML key with embedded colon" (fixed parse error) → "chore: re-trigger pr-checks" (empty commit to force fresh run with corrected YAML).

This is acceptable when the YAML fix cannot itself trigger a re-run (parse-time failure leaves no jobs). Unhealthy if used as a habit to paper over flakiness.

**Recommendations:**
- Add workflow `concurrency` groups to `pr-checks.yml` and `latex-build.yml` (cancel-in-progress on force-push).
- Document the pattern in `docs/WORKFLOW.md` so future maintainers do not reach for it reflexively.

---

## Finding 6 — LOW: No root package.json or package-lock.json

- Repo root: no `package.json` (raw URL HTTP 404).
- Repo root: no `package-lock.json` (raw URL HTTP 404).
- `.gitignore` does NOT ignore a root `package-lock.json` — so if one existed, it would be tracked.
- `baseline/package.json` (3404 bytes) and `baseline/package-lock.json` (171308 bytes) ARE committed.

`npm install` at root: no-op (npm errors with ENOENT). PR template's `--prefix baseline` covers the case.

**No version conflicts across trees.** Both pin `playwright@1.59.1`. Only cross-tree concern is Finding 2.

**Remediation:** Add a one-line note in root `README.md` (Repository layout) clarifying that all npm commands need `--prefix baseline` or to be run from inside `baseline/`.

---

## Finding 7 — LOW: latex-presence and latex-build are not required status checks on main

`docs/decisions/0002-self-review-on-main.md` line 26: "all four required checks (`repo-hygiene`, `baseline-deterministic`, `pin-policy`, `docs-routing`) must pass before any merge into `main`."

`pr-checks.yml` defines 4 jobs: `repo-hygiene`, `pin-policy`, `docs-routing`, `latex-presence`. Three match ADR-0002; `latex-presence` does not. `baseline-deterministic` lives in a different workflow. `latex-build` (the artifact-building job in `latex-build.yml`) is NOT in ADR-0002's list and NOT a required check.

Risk: a PR that breaks LaTeX (e.g., the brace-mangling sed from release 0-0) triggers `latex-build.yml` via path filter, fails it, but does NOT block merge into `main`. `latex-presence` continues to pass (it only checks file presence).

**Remediation:**
- Add `latex-build` job to required status checks on `main`. Drop `latex-presence` (redundant with `latex-build`).
- OR explicitly carve out ADR-0003 stating the PDF is advisory.

---

## Action Pin Policy Audit

**All `uses: ...@<SHA>` in `.github/workflows/` (5 files, 11 references):**

| Workflow | Action | Length |
|----------|--------|--------|
| gitflow.yml | actions/checkout | 40 |
| upstream-deterministic.yml | actions/checkout | 40 |
| upstream-deterministic.yml | actions/setup-node | 40 |
| upstream-advisories.yml | actions/checkout | 40 |
| upstream-advisories.yml | actions/setup-node | 40 |
| latex-build.yml | actions/checkout | 40 |
| latex-build.yml | actions/upload-artifact | 40 |
| pr-checks.yml (repo-hygiene) | actions/checkout | 40 |
| pr-checks.yml (pin-policy) | actions/checkout | 40 |
| pr-checks.yml (docs-routing) | actions/checkout | 40 |
| pr-checks.yml (latex-presence) | actions/checkout | 40 |

**11 references. All 40 chars. Zero short pins.**

**Self-policing:** YES. `pr-checks.yml` has no `paths:` filter; runs on all PRs/pushes to main/develop. Edits to `.github/workflows/pr-checks.yml` itself trigger the `pin-policy` job which greps `.github/workflows` for `uses: ...@[0-9a-f]{1,39}([^0-9a-f]|$)` and fails on any short pin.

**Regex trace:** The pattern requires a non-hex character immediately after the 1-39 hex run. For a 40-char SHA like `11bd71901bbe5b1630ceea73d27597364c9af683` followed by ` # v4.2.2`, every position within the 40-char run is followed by another hex char, so the regex cannot match (it tries 1-39 hex then a non-hex terminator, but every such terminator candidate is itself hex until the trailing space — which is beyond the 40-char run, so unreachable). 40-char pins pass cleanly.

**Caveat:** The regex would NOT flag non-hex `uses:` refs like `foo/bar@main` (a tag ref would not match `[0-9a-f]{1,39}` at all). Tighten to positively require `@[0-9a-f]{40}([^0-9a-f]|$)` and fail on any other form.

---

## Build Hygiene Cross-Cuts

- `latex-build.yml` installs `texlive-latex-base`, `texlive-latex-extra`, `texlive-latex-recommended`, `texlive-fonts-recommended`, `texlive-fonts-extra`, `texlive-science`, `texlive-publishers`, `texlive-bibtex-extra`. Enough for everything in `preamble.tex` EXCEPT dropped `lmodern` (which IS in `texlive-fonts-recommended` — re-adding it requires no install change).
- `latex/Makefile` exports `TEXINPUTS` (line 22) so pdflatex finds `classes/`, `sections/`, `refs/`. Fix for prior `rccos.cls not found` error.
- `latex/latexmkrc`: `$max_repeat = 5`, `$bibtex_use = 2`, `$biber = 'biber %O %S'`, `$out_dir = 'build'`. Deterministic given fixed inputs.
- `latex-build.yml` verifies `build/main.pdf` is non-empty and uploads with 14-day retention. NO content smoke check (e.g., `pdftotext build/main.pdf - | head -5` to confirm first chapter renders). A successful build that produces a PDF with all body text as blank rectangles (missing font) would still upload.

**Defense-in-depth:** Add a `pdftotext` smoke check after the Build step.

---

## Top 3 to Fix First

**Build (LaTeX/PDF):**
1. Update colophon in `latex/sections/99-backmatter.tex` to match dropped packages (Finding 1). Cheapest, no install changes.
2. Decide on `lmodern`: re-add it OR accept regression and document it. Colophon and source must agree (Findings 1, 4).
3. Add `pdftotext` smoke check to `latex-build.yml` so font failures don't upload as "successful" artifacts.

**CI (workflows and policy):**
1. Add `latex-build` job to required status checks on `main`, OR carve out ADR-0003 stating PDF is advisory (Finding 7).
2. Tighten pin-policy regex to positively require `@[0-9a-f]{40}` rather than only failing on `<40`. Catches tag/branch refs that slip past current heuristic.
3. Add `concurrency:` groups to `pr-checks.yml` and `latex-build.yml` to avoid stale-run races on force-push.

**Reproducibility (manifests, dependencies, bridge surface):**
1. Resolve dual-tree `playwright` install (Finding 2). Move OUT of `baseline/devDependencies` if no baseline test directly imports it.
2. Hard-fail in `startBridgeServer()` when `RESONANTOS_BRIDGE_HOST=0.0.0.0`/`::` AND `RESONANTOS_BRIDGE_PUBLIC_URL` is unset. Sanitize `0.0.0.0`/`::` in `getBridgePublicUrl()` (Finding 3).
3. Document LAN-bridge surface in `SECURITY.md` and add one-line note in root `README.md` clarifying `npm install` at root is unsupported (Findings 3, 6).

---

*Saved via pi-infra with Guardian oversight. Context pulled from Aether and Local Memory.*
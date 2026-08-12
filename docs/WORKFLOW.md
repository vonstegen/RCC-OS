# WORKFLOW

RCC-OS uses a **lab-flavored Gitflow** branching model. It keeps the
release semantics of classic Gitflow (`main` vs. integration line,
release branches, hotfixes) but renames the topic branches so they
align with the staged-experiment structure recorded in
[`docs/MILESTONES.md`](MILESTONES.md).

## Long-lived branches

| Branch | Purpose | Protection |
| --- | --- | --- |
| `main` | Always-releasable line. Receives merges only from `release/*` and `hotfix/*`. | Strict required checks, no force pushes, no deletions, linear history, 1 review. |
| `develop` | Integration line. Receives merges from `feature/*` and `experiment/*`. | Same required checks, no force pushes, linear history, 1 review. |

`main` and `develop` are **never** force-pushed or rewritten.

## Topic branch types

| Prefix | Branches from | Merges into | Use |
| --- | --- | --- | --- |
| `feature/<name>` | `develop` | `develop` | Internal work that doesn't drive a milestone directly (docs refactors, refactors, non-stage plumbing). |
| `experiment/<stage>-<short-name>` | `develop` | `develop` | Work that advances a specific lab stage. `<stage>` is the milestone number (0, 1, 2, 3, 4, 5). Example: `experiment/1-ternary-runtime`. |
| `release/<version>` | `develop` | `main` and `develop` | Cuts a stage snapshot. Used to lock the docs baseline, freeze new features, and apply final fixes before promotion. |
| `hotfix/<name>` | `main` | `main` and `develop` | Critical fix on the release line. Must be followed by a back-merge into `develop`. |
| `upstream-sync/<date>` | `develop` | `develop` | Refreshes `baseline/` from `ResonantOS/2.0.0-alpha` @ `dev`. See [`CONTRIBUTING.md`](CONTRIBUTING.md#working-with-upstream). |

## Commit graph at a glance

```text
*---*---*---*---*---*---*  main  (protected, releasable)
 \           ^    \
  \         /      \* hotfix/x  → main
   \       /        \
    \     /          *---*  develop  (protected, integration)
     \   /
      \ /
       *---*---*---*---*  feature/y, experiment/n-z, upstream-sync/...
```

## Stage cut procedure

1. From `develop`, create `release/<stage>-<version>`.
2. Lock the LaTeX docs baseline (`make docs-lock`).
3. Run the full verification suite.
4. Open a PR `release/<stage>-<version>` → `main`. Required checks
   must pass and at least one review is required.
5. After merge, back-merge `main` into `develop` so the integration
   line carries the release commit.
6. Tag the merge commit on `main` with `<stage>-<version>`.

## Hotfix procedure

1. From `main`, create `hotfix/<short-name>`.
2. Apply the fix. Add a regression test.
3. Open a PR `hotfix/<short-name>` → `main`. Required checks must
   pass.
4. After merge, immediately back-merge `main` into `develop`.
5. Tag the merge commit on `main` with `hotfix-<short-name>`.

## PR rules

- A PR to `main` may originate only from `release/*` or `hotfix/*`.
- A PR to `develop` may originate only from `feature/*`,
  `experiment/*`, or `upstream-sync/*`.
- All PRs require the four status checks defined in
  [`.github/workflows/pr-checks.yml`](../.github/workflows/pr-checks.yml)
  and the upstream deterministic suite in
  [`.github/workflows/upstream-deterministic.yml`](../.github/workflows/upstream-deterministic.yml).
- Squash-merge is the default. Merge commits are permitted only on
  `release/*` and `hotfix/*` PRs to preserve the topology described
  above.

## Local cheat sheet

```bash
# Start work
git fetch origin
git switch develop
git pull --ff-only
git switch -c experiment/1-ternary-runtime

# After review
git push -u origin experiment/1-ternary-runtime
# Open PR → develop

# Cut a stage release
git switch develop
git pull --ff-only
git switch -c release/1-0
# Lock docs, run verification, open PR → main

# Hotfix on main
git switch main
git pull --ff-only
git switch -c hotfix/lockfile-pin
# Fix, test, open PR → main
# Then back-merge main into develop
```

## Why lab-flavored

Classic Gitflow already separates release from integration. The lab
extends the topic branch prefixes so:

- a branch name encodes the milestone it advances
  (`experiment/1-ternary-runtime`),
- the documentation layer can be linked to the same names without
  ambiguity, and
- the CI history makes it trivial to answer "which branches
  contributed to stage N?".

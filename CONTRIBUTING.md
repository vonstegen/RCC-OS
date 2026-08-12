# Contributing to RCC-OS

RCC-OS is an experimental research lab derived from
[ResonantOS/2.0.0-alpha](https://github.com/ResonantOS/2.0.0-alpha).
Contributions should respect both the spirit of the upstream project
and the staged-experiment structure of this lab.

## Branching

The lab uses **lab-flavored Gitflow**. Read
[`docs/WORKFLOW.md`](docs/WORKFLOW.md) before opening a PR. In
particular:

- The integration line is `develop`. Default target for new work.
- The release line is `main`. Receives only `release/*` and `hotfix/*`.
- Topic branches are `feature/<name>`, `experiment/<stage>-<name>`,
  `release/<version>`, `hotfix/<name>`, or `upstream-sync/<date>`.
- Squash-merge is the default.

## Working with upstream

`baseline/` is a read-only snapshot of
`ResonantOS/2.0.0-alpha` @ `dev`. It is committed into the repo so
the lab always has a reference architecture at hand.

To pull new upstream changes, branch from `develop`:

```bash
git fetch upstream
git switch develop
git pull --ff-only
git switch -c upstream-sync-YYYY-MM-DD upstream/dev
# Refresh baseline/, then open a PR upstream-sync-YYYY-MM-DD → develop
```

The `pr-checks` workflow will reject any PR that modifies files
inside `baseline/` directly. Refresh the snapshot on a dedicated
upstream-sync branch instead.

## Commit messages

- Imperative mood. "Add cognitive router", not "Added".
- First line ≤ 72 characters.
- Body explains why, not what.
- Reference the relevant milestone when the change advances one.

## Documentation layer

The lab maintains **two parallel documentation surfaces**:

- [`docs/`](docs/) — short, living Markdown kept in the repo and
  rendered by GitHub.
- [`latex/`](latex/) — typeset LaTeX for archival PDFs (goal,
  milestones, research, decisions, design, architecture, tests).

When you add a new decision, design, milestone, or research note,
update **both** surfaces. The `pr-checks` workflow verifies the
Markdown; the `latex-build` workflow builds the PDF tree.

See [`latex/README.md`](latex/README.md) for the LaTeX layout and
build commands.

## Code review expectations

- Stage-gate deliverables are checked before the next stage begins.
- Performance claims must include the hardware, the dataset, and
  the measurement script.
- New capability surfaces must come with policy before any code
  that uses them.
- No commit may weaken the existing ResonantOS security boundary
  without an explicit decision recorded in
  [`docs/decisions/`](docs/decisions/).
- `baseline/` is read-only.

## Reporting issues

Use GitHub issues. Label the issue with the relevant stage and
component. Do not include secrets, generated bridge credentials, or
unredacted diagnostics in public issues.

## License

By contributing, you agree that your contributions are licensed
under the MIT license that covers this repository.
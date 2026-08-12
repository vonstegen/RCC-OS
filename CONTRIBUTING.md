# Contributing to RCC-OS

RCC-OS is an experimental research lab derived from
[ResonantOS/2.0.0-alpha](https://github.com/ResonantOS/2.0.0-alpha).
Contributions should respect both the spirit of the upstream project
and the staged-experiment structure of this lab.

## Branching

- The default branch is `main`. It reflects the current best state
  of the lab.
- All work happens on topic branches named after the experiment or
  change.
- Work on staged experiments happens under `experiments/<topic>`.
- Pull requests target `main`.

## Working with upstream

`baseline/` is a read-only snapshot of
`ResonantOS/2.0.0-alpha` @ `dev`. It is committed into the repo so
the lab always has a reference architecture at hand.

To pull new upstream changes:

```bash
git remote add upstream https://github.com/ResonantOS/2.0.0-alpha.git
git fetch upstream dev
git checkout -b upstream-sync-YYYY-MM-DD upstream/dev
# compare baseline/ against upstream/dev and resolve conflicts
```

Do **not** modify files inside `baseline/` directly. Any experiment
that needs to start from upstream code should copy the relevant file
into `src/`, `clients/`, or `experiments/` first and develop there.

## Commit messages

- Imperative mood. "Add cognitive router", not "Added".
- First line ≤ 72 characters.
- Body explains why, not what.
- Reference the relevant milestone when the change advances one.

## Code review expectations

- Stage-gate deliverables are checked before the next stage begins.
- Performance claims must include the hardware, the dataset, and
  the measurement script.
- New capability surfaces must come with policy before any code
  that uses them.
- No commit may weaken the existing ResonantOS security boundary
  without an explicit decision recorded in `docs/decisions/`.

## Reporting issues

Use GitHub issues. Label the issue with the relevant stage and
component. Do not include secrets, generated bridge credentials, or
unredacted diagnostics in public issues.

## License

By contributing, you agree that your contributions are licensed
under the MIT license that covers this repository.
# ADR-0002: Main-branch self-review is permitted for lab release cuts

- Status: Accepted
- Date: 2026-08-12
- Deciders: RCC-OS maintainers
- Stage: 0 (lab scaffold)
- Related: [`docs/WORKFLOW.md`](../WORKFLOW.md), [`docs/VISION.md`](../VISION.md)

## Context

The lab is a single-maintainer research project. The branch
protection on `main` requires one approving review before merge.
GitHub's API does not allow a PR author to approve their own PR.

Without a relaxation, the only way to land a stage cut is to either
recruit a second reviewer or to bypass `main` entirely (which
defeats the Gitflow model).

The status-check requirement remains non-negotiable: all four
required checks (`repo-hygiene`, `baseline-deterministic`,
`pin-policy`, `docs-routing`) must pass before any merge into
`main`.

## Decision

For the duration of stage 0 (lab scaffold), the
`required_approving_review_count` on `main` is **0** while
`required_status_checks.strict` remains `true`. The first stage cut
(`release/0-0`) is allowed to merge on green status checks alone.

When the lab gains a second maintainer, the rule is restored to
`required_approving_review_count: 1` immediately, with no further
vote required.

## Consequences

Positive:

- Unblocks stage 0 release cuts.
- Status checks remain the hard gate.
- Single point of failure removed for the lab.

Negative:

- Until a second maintainer joins, every merge into `main` is
  effectively self-approved.
- The audit trail is the commit log plus the workflow runs.

Mitigations:

- Every release cut uses a `release/<version>` branch and a PR
  target. The PR is the audit record.
- Every release cut is tagged on `main`.
- Every release cut is back-merged into `develop`.

## Alternatives considered

- **Keep `required_approving_review_count: 1`.** Rejected because
  it blocks the lab entirely.
- **Add a bot reviewer.** Possible but out of scope for stage 0.
- **Use CODEOWNERS with no required owner.** Same effect as
  removing the rule; rejected for clarity.

## Supersedes

None.

## Superseded by

None.

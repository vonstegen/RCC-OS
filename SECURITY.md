# Security

## Reporting

Please report security issues privately through GitHub's private
vulnerability reporting on this repository, or by contacting the
project maintainers directly. Do not file public issues for
suspected vulnerabilities.

## What this lab guarantees

RCC-OS inherits ResonantOS's existing security boundary and is
explicit about it:

- The **deterministic Core** is the only authority for capability
  decisions. The local SLM and any other AI components cannot
  execute privileged actions directly.
- **Capability tokens** are scoped per route and never persisted in
  generated extension configuration.
- **Living Archive** is governed; AI components cannot arbitrarily
  rewrite trusted memory.
- **Provider credentials** stay inside the Core, never in the
  browser page or add-on.
- **Sensitive autonomous actions** (wallet, payment, transfer,
  credential entry, public submission) are human-only by policy.

## What the lab explicitly does not guarantee yet

- The lab is experimental. The capability surface may change
  between releases.
- New stages add new code paths and may temporarily introduce
  regressions.
- Performance claims have not yet been independently reproduced.

## Dependencies

All third-party dependencies must come from `package.json`,
`Cargo.toml`, or committed lockfiles. Do not introduce ad-hoc
binary downloads without an explicit decision recorded in
`docs/decisions/`.

## Secrets

Never commit secrets. Generated bridge credentials belong in the
user state root (`~/ResonantOS_User` by default) and must remain
outside the repository.

## Acknowledgements

This policy is based on the upstream ResonantOS `SECURITY.md`,
preserved verbatim in `baseline/SECURITY.md`.
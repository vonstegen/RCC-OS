# ADR-0005: Bridge loopback exemption and LAN startup guard

- Status: Proposed
- Date: 2026-08-12
- Deciders: RCC-OS maintainers
- Stage: 1 (lab deliverable MVP)
- Related: [`baseline/browser-first/host/bridge-server.mjs`](../../baseline/browser-first/host/bridge-server.mjs), [`baseline/browser-first/host/README.md`](../../baseline/browser-first/host/README.md), [`docs/reviews/2026-08-12-security-review-387cc12f.md`](../reviews/2026-08-12-security-review-387cc12f.md) (findings S2, S5, S18), [`docs/reviews/2026-08-12-bridge-policy-upstream.md`](../reviews/2026-08-12-bridge-policy-upstream.md) (proposed upstream fix)

## Context

The bridge server sits between the Chrome extension origin and the
local Node.js addon. The extension loads addon SPAs inside an
`<iframe src="...">` that points at the bridge; the iframe cannot
set custom request headers, so the bridge cannot require the
`X-ResonantOS-Bridge-Token` header on iframe-targeted paths. The
bridge's `getBridgeOpenProxyPrefixes()` returns a list of path
prefixes that are exempt from the token check.

The stage-0 policy in `baseline/browser-first/host/bridge-server.mjs`
is:

- Default bind is `127.0.0.1` (loopback). The full set of
  dashboard mirror paths (`/hermes-dashboard`, `/auth`, `/api`,
  `/assets`, `/fonts-terminal`, `/dashboard-plugins`,
  `/favicon.ico`) is exempt from the token check.
- Operators who bind to `0.0.0.0` (LAN / Tailscale) get no
  startup-time warning. The IP allowlist
  (`RESONANTOS_BRIDGE_ALLOWED_IPS`) is opt-in. With no allowlist
  set, `clientIpAllowed()` returns `true` for every connection.

The stage-0 policy has three concrete defects (security review
findings S2, S5, S18):

1. **S2 — too many paths exempt on loopback.** `/auth`, `/api`,
   `/assets`, `/fonts-terminal`, `/dashboard-plugins`,
   `/favicon.ico` are not needed as `<iframe src>` targets. They
   are reachable from extension code that already sets the
   bridge-token header (the addon-iframe srcdoc preamble
   rewrites `fetch` and `XMLHttpRequest` to inject it).
   Exempting them on loopback means a same-origin request from
   a script injected via the addon iframe (S6) reaches them
   without the token, widening the impact of any other
   vulnerability.
2. **S5 — bind to non-loopback has no startup guard.** Binding
   to `0.0.0.0` silently turns the bridge into a LAN-reachable
   service. With no IP allowlist set, the IP-gate is
   pass-through.
3. **S18 — `clientIpAllowed` returns `true` on empty allowlist.**
   Documented behaviour, but it means the operator's only
   safety belt is the bridge token, and the bridge token is
   bypassed for the open paths.

The fix is a code change to `baseline/browser-first/host/bridge-server.mjs`
(`getBridgeOpenProxyPrefixes` + `startBridgeServer`). The
[`docs/reviews/2026-08-12-bridge-policy-upstream.md`](../reviews/2026-08-12-bridge-policy-upstream.md)
note proposes the exact upstream patch.

The lab's contribution is the **policy decision and the static
check**; the code change is staged for an `upstream-sync/*`
branch that refreshes the baseline/ snapshot. The static
check is the lab's drift detector: it asserts that the
baseline/ file conforms to the policy in this ADR. When
upstream merges the fix, the static check goes green.

## Decision

The lab adopts the following **two-tier policy** as the
authoritative interpretation of S2/S5/S18:

### Tier 1: loopback bind (`127.0.0.1`, `localhost`, `::1`, `[::1]`)

- The only open-path exemption is **`/hermes-dashboard`**.
  All other mirror paths require the bridge token, even on
  loopback.
- `clientIpAllowed()` continues to return `true` on the empty
  allowlist (loopback trust is the documented behaviour).
- A startup banner is printed to `stdout`:

  ```
  [bridge] bound to 127.0.0.1:<port>; token=on; ip-allowlist=off; open-prefixes=[/hermes-dashboard]
  ```

### Tier 2: non-loopback bind (any other host, including `0.0.0.0` and LAN IPs)

- The server **refuses to start** unless
  `RESONANTOS_BRIDGE_ALLOWED_IPS` is set to a non-empty
  comma-separated CIDR list. The check is in
  `startBridgeServer`, before `server.listen()`.
- The exemption for `/hermes-dashboard` is **revoked** on
  non-loopback binds. Every path requires the bridge token.
- A startup banner is printed:

  ```
  [bridge] bound to 0.0.0.0:<port>; token=on; ip-allowlist=<N>cidrs; open-prefixes=[]
  ```

- The error thrown on refuse-to-start is:

  ```
  [bridge] refuse to start: bind host <host> is non-loopback but
  RESONANTOS_BRIDGE_ALLOWED_IPS is not set. Refusing to expose
  the bridge to the LAN without an explicit IP allowlist.
  ```

### Override

- An explicit env var
  `RESONANTOS_BRIDGE_ALLOW_LAN_WITHOUT_CIDRS=1` is honoured to
  allow the legacy behaviour (LAN bind, no allowlist). The
  override is logged at `warn` level. The override is **not**
  documented in the README; it exists for the lab's smoke
  tests and for operators who explicitly want the unsafe
  behaviour. Production runs do not set it.

### Lab-side drift detector

A new static check is added to
[`.github/workflows/pr-checks.yml`](../../.github/workflows/pr-checks.yml)
("Verify bridge policy conformance" job). The check
inspects `baseline/browser-first/host/bridge-server.mjs` and
asserts:

- `getBridgeOpenProxyPrefixes` returns `["/hermes-dashboard"]`
  on loopback (default) and `[]` on non-loopback.
- `startBridgeServer` throws on a non-loopback bind with
  empty `allowedCidrs` unless the override env var is set.

The check runs on every PR; it is the lab's way of catching
upstream drift relative to the policy in this ADR.

## Consequences

Positive:

- The policy is recorded; the next maintainer (or upstream)
  sees the rationale without re-deriving it from the security
  review.
- The static check catches baseline/ drift automatically.
- The lab's smoke tests can opt into the override env var
  without weakening the policy.

Negative:

- The code change is upstream's responsibility. Until upstream
  merges, the lab's baseline/ file is non-compliant. The
  static check is the only enforcement; the lab does not
  block the non-compliant file from being merged.
- A future upstream change that adds additional open-path
  exemptions will not be caught unless the static check is
  updated.

## Alternatives considered

- **Edit baseline/ directly in this PR.** Rejected: the lab's
  `pr-checks.yml` "Disallow changes inside baseline/" gate
  enforces that baseline/ is only updated via
  `upstream-sync/*` branches. The lab's policy is to keep
  baseline/ as a clean snapshot of upstream.
- **Add the code change in an `upstream-sync/*` branch
  without an ADR.** Rejected: the policy decision is the
  lab's contribution; the code change is upstream's. Mixing
  them obscures the separation.

## Supersedes

None.

## Superseded by

None.

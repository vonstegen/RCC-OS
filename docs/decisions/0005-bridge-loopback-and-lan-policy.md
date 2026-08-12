# ADR-0005: Bridge loopback exemption and LAN startup guard

- Status: Proposed
- Date: 2026-08-12
- Deciders: RCC-OS maintainers
- Stage: 1 (lab deliverable MVP)
- Related: [`baseline/browser-first/host/bridge-server.mjs`](../../baseline/browser-first/host/bridge-server.mjs), [`baseline/browser-first/host/README.md`](../../baseline/browser-first/host/README.md), [`docs/reviews/2026-08-12-security-review-387cc12f.md`](../reviews/2026-08-12-security-review-387cc12f.md) (findings S2, S5, S16, S18)

## Context

The bridge server sits between the Chrome extension origin and the
local Node.js addon. The extension loads addon SPAs inside an
`<iframe src="...">` that points at the bridge; the iframe cannot
set custom request headers, so the bridge cannot require the
`X-ResonantOS-Bridge-Token` header on iframe-targeted paths. The
bridge's `getBridgeOpenProxyPrefixes()` returns a list of path
prefixes that are exempt from the token check.

The stage-0 policy is:

- Default bind is `127.0.0.1` (loopback). The full set of
  dashboard mirror paths (`/hermes-dashboard`, `/auth`, `/api`,
  `/assets`, `/fonts-terminal`, `/dashboard-plugins`,
  `/favicon.ico`) is exempt from the token check.
- Operators who bind to `0.0.0.0` (LAN / Tailscale) get no
  startup-time warning. The IP allowlist
  (`RESONANTOS_BRIDGE_ALLOWED_IPS`) is opt-in. With no allowlist
  set, `clientIpAllowed()` returns `true` for every connection,
  and the open-path exemption is still granted (because
  `allowedCidrs.length > 0` evaluates to `false`, so the
  exemption is gated only on `isLoopbackBridgeHost(host)`, which
  is `false` for `0.0.0.0` — wait, that means on `0.0.0.0` the
  exemption is NOT granted; the token check is enforced. The
  documented concern is the opposite case: the operator binds
  to a specific LAN IP, sets no allowlist, and every request
  from the LAN gets in.).

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
   pass-through. With an IP allowlist set, the loopback
   exemption is granted to all mirror paths even on the LAN
   bind, because the gate is `isLoopbackBridgeHost(host) ||
   allowedCidrs.length > 0`.
3. **S18 — `clientIpAllowed` returns `true` on empty allowlist.**
   Documented behaviour, but it means the operator's only
   safety belt is the bridge token, and the bridge token is
   bypassed for the open paths.

## Decision

The bridge implements a **two-tier policy**:

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
  The `isLoopbackBridgeHost(host) || allowedCidrs.length > 0`
  branch is replaced with `isLoopbackBridgeHost(host) && host
  === getBridgeHost()`. The `allowedCidrs.length > 0` branch
  is dropped.
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

- An explicit env var `RESONANTOS_BRIDGE_ALLOW_LAN_WITHOUT_CIDRS=1`
  is honoured to allow the legacy behaviour (LAN bind, no
  allowlist). The override is logged at `warn` level. The
  override is **not** documented in the README; it exists for
  the lab's smoke tests and for operators who explicitly want
  the unsafe behaviour. Production runs do not set it.

### Code change locations

- `getBridgeOpenProxyPrefixes` (lines 963-970): change the
  gating condition.
- `startBridgeServer` (lines 1173-1247): add the refuse-to-start
  guard before `server.listen()`; add the startup banner after
  `listening` resolves.

## Consequences

Positive:

- The loopback default is no longer an open proxy for `/api`,
  `/auth`, `/assets`, `/fonts-terminal`, `/dashboard-plugins`,
  `/favicon.ico`. A successful S6 (CSP relaxation) exploit
  loses its ability to read the same paths unauthenticated.
- A misconfigured LAN bind fails closed instead of silently
  exposing the bridge.
- The startup banner makes the security posture visible to
  every operator on every start.

Negative:

- Addon bundles that fetch `/api` or `/assets` from a
  cross-origin context without setting the bridge-token header
  will break. The addon-iframe srcdoc preamble already injects
  the token via the `fetch` / `XMLHttpRequest` override
  (`addon-iframe.js:137-184`); the breakage mode is for
  bundles that bypass the preamble (e.g., direct `<img
  src="/assets/...">` from the addon). Mitigation: such
  assets should be moved under `/hermes-dashboard/assets` and
  served from the iframe-prefixed path; tracked as a follow-up
  in `docs/MILESTONES.md`.
- The override flag adds a way to disable the new safety. The
  lab's smoke tests use it; production does not. It is logged
  at `warn` so audit logs catch misuse.

## Alternatives considered

- **Keep all seven prefixes exempt on loopback.** Rejected: the
  exemption is only needed for `<iframe src>` targets, and
  only `/hermes-dashboard` is one. The other six are reachable
  from extension code that sets the bridge-token header.
- **Drop the loopback exemption entirely; require the bridge
  token on every path including `/hermes-dashboard`.** Rejected:
  the iframe cannot set custom request headers, so the
  iframe-target path must be exempt when the iframe has no
  other auth channel. The only auth channel the iframe has
  today is the `Sec-Fetch-Dest: iframe` header plus the
  bridge's IP gate. With loopback trust (Tier 1), that is
  sufficient. With a LAN bind (Tier 2), the IP allowlist is
  the only protection, which is why we revoke the exemption
  there.
- **Warn but do not refuse on LAN bind.** Rejected: a warning
  the operator can ignore is a warning the operator will
  ignore. Refuse-to-start is the only way to guarantee
  fail-closed.
- **Add a CIDR parser that supports IPv6.** Out of scope for
  this decision. Tracked separately as S16.

## Supersedes

None.

## Superseded by

None.

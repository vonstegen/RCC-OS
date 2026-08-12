# Bridge loopback exemption and LAN startup guard — proposed upstream patch

- Date: 2026-08-12
- Related: [ADR-0005](../decisions/0005-bridge-loopback-and-lan-policy.md),
  [Security review 2026-08-12](2026-08-12-security-review-387cc12f.md) (findings S2, S5, S18)
- Target: `ResonantOS/2.0.0-alpha` `baseline/browser-first/host/bridge-server.mjs`

## Summary

The stage-0 bridge in
`baseline/browser-first/host/bridge-server.mjs` has two
configuration defects that the lab's security review flagged
as **High** (S2) and **Medium** (S5). The lab's
[ADR-0005](../decisions/0005-bridge-loopback-and-lan-policy.md)
records the policy. This note is the **proposed patch** to
land in the upstream ResonantOS repository.

## Defect 1 — S2: too many paths exempt on loopback

### Current behaviour

`getBridgeOpenProxyPrefixes()` (lines 963-970 of the stage-0
file) returns the full `DASHBOARD_PROXY_MIRROR_PATHS` list
(seven paths: `/hermes-dashboard`, `/auth`, `/api`,
`/assets`, `/fonts-terminal`, `/dashboard-plugins`,
`/favicon.ico`) whenever the bind host is loopback OR
`allowedCidrs.length > 0`. The handler consumes the list and
exempts each prefix from the `X-ResonantOS-Bridge-Token`
check.

### Why this is wrong

Only `/hermes-dashboard` is used as an `<iframe src>`. The
other six paths are reachable from extension code (the
addon-iframe srcdoc preamble rewrites `fetch` and
`XMLHttpRequest` to inject the bridge token
[`addon-iframe.js:137-184`](../../baseline/browser-first/resonantos-side-panel-extension/src/addon-iframe.js))
so they should be token-gated. Exempting them widens the
impact of any other vulnerability (e.g. S6 — the meta-CSP
relaxation) by allowing an attacker to read the same paths
unauthenticated.

### Proposed change

```diff
--- a/baseline/browser-first/host/bridge-server.mjs
+++ b/baseline/browser-first/host/bridge-server.mjs
@@ -963,9 +963,13 @@ export function getBridgeOpenProxyPrefixes({ host = getBridgeHost(), allowedCidrs
   const configured = parseAllowedList(process.env.RESONANTOS_BRIDGE_OPEN_PROXY_PREFIXES);
   if (configured.length > 0) return configured;
-  if (isLoopbackBridgeHost(host) || allowedCidrs.length > 0) {
-    return DASHBOARD_PROXY_MIRROR_PATHS.map((entry) => entry.bridge);
-  }
-  return [];
+  // Loopback: only the iframe src target (/hermes-dashboard) is
+  // exempt. The other mirror paths are reachable from extension
+  // code that sets the bridge-token header. See ADR-0005.
+  if (isLoopbackBridgeHost(host)) {
+    return ["/hermes-dashboard"];
+  }
+  return [];
 }
```

## Defect 2 — S5: bind to non-loopback has no startup guard

### Current behaviour

`RESONANTOS_BRIDGE_HOST` defaults to `127.0.0.1`; the
file's comment (lines 17-24) advertises `0.0.0.0` to expose
to LAN/Tailscale without any "must set X" requirement.
There is no startup-time check. With `0.0.0.0` and no IP
allowlist set, every connection passes the IP-gate and
hits the bridge directly.

### Proposed change

Add a refuse-to-start guard to `startBridgeServer` before
`server.listen()`. Allow an override for the lab's smoke
tests.

```diff
--- a/baseline/browser-first/host/bridge-server.mjs
+++ b/baseline/browser-first/host/bridge-server.mjs
@@ -1185,6 +1185,23 @@ export async function startBridgeServer({
   openPathPrefixes,
 }) {
   const bindHost = host ?? getBridgeHost();
+  // ADR-0005: refuse to start on a non-loopback bind without
+  // an explicit IP allowlist. Override via
+  // RESONANTOS_BRIDGE_ALLOW_LAN_WITHOUT_CIDRS=1 for smoke tests.
+  if (!isLoopbackBridgeHost(bindHost) && allowedCidrs.length === 0) {
+    const override = String(process.env.RESONANTOS_BRIDGE_ALLOW_LAN_WITHOUT_CIDRS ?? "").trim() === "1";
+    if (!override) {
+      const error = new Error(
+        `[bridge] refuse to start: bind host ${bindHost} is non-loopback but RESONANTOS_BRIDGE_ALLOWED_IPS is not set. ` +
+          `Refusing to expose the bridge to the LAN without an explicit IP allowlist. ` +
+          `Set RESONANTOS_BRIDGE_ALLOWED_IPS to a comma-separated CIDR list, or set ` +
+          `RESONANTOS_BRIDGE_ALLOW_LAN_WITHOUT_CIDRS=1 to override (not recommended).`,
+      );
+      error.code = "BRIDGE_REFUSE_LAN_NO_CIDRS";
+      throw error;
+    }
+    console.warn(
+      `[bridge] WARNING: bound to non-loopback host ${bindHost} with no IP allowlist. ` +
+        `RESONANTOS_BRIDGE_ALLOW_LAN_WITHOUT_CIDRS=1 override is in effect.`,
+    );
+  }
   const effectiveOpenPathPrefixes = openPathPrefixes ?? getBridgeOpenProxyPrefixes({ host: bindHost, allowedCidrs });
```

And add a startup banner after `listening` resolves:

```diff
@@ -1256,6 +1273,12 @@
     const onListening = () => {
       server.off("error", onError);
+      const address = server.address();
+      const actualHost = typeof address === "object" && address ? address.address : bindHost;
+      const actualPort = typeof address === "object" && address ? address.port : port;
+      const allowlistStatus = allowedCidrs.length === 0 ? "off" : `${allowedCidrs.length}cidrs`;
+      console.log(
+        `[bridge] bound to ${actualHost}:${actualPort}; token=${bridgeToken ? "on" : "off"}; ` +
+          `ip-allowlist=${allowlistStatus}; open-prefixes=[${effectiveOpenPathPrefixes.join(",")}]`,
+      );
       resolve();
     };
```

## Defect 3 — S18: empty allowlist is pass-through

The current `clientIpAllowed()` returns `true` when
`allowedCidrs` is empty. This is documented behaviour and
matches the lab's `getBridgeAllowedCidrs` helper. It is
**acceptable on loopback** (Tier 1) because the loopback
bind is the trust boundary. It is **not acceptable on a
non-loopback bind** without an explicit allowlist, which
is why Defect 2's refuse-to-start guard exists.

No code change is required for S18; the refuse-to-start
guard in Defect 2 makes the pass-through unreachable from
the LAN.

## Tests to add upstream

In `baseline/browser-first/test/bridge-server.test.mjs`:

1. `getBridgeOpenProxyPrefixes` returns `["/hermes-dashboard"]`
   on loopback with no env override.
2. `getBridgeOpenProxyPrefixes` returns `[]` on non-loopback
   with no env override.
3. `getBridgeOpenProxyPrefixes` honours the
   `RESONANTOS_BRIDGE_OPEN_PROXY_PREFIXES` env var on any
   bind host.
4. `startBridgeServer` refuses to start on a non-loopback
   bind with empty `allowedCidrs` and no override env var
   (`error.code === "BRIDGE_REFUSE_LAN_NO_CIDRS"`).
5. `startBridgeServer` honours
   `RESONANTOS_BRIDGE_ALLOW_LAN_WITHOUT_CIDRS=1` to override.
6. A loopback bridge returns 401 for `/api`, `/auth`,
   `/assets`, `/fonts-terminal`, `/dashboard-plugins`,
   `/favicon.ico` without the bridge token; returns non-401
   for `/hermes-dashboard` without the token; returns
   non-401 for the others with the token.

In `baseline/browser-first/test/dashboard-proxy.test.mjs`:

7. Update the existing
   "proxy: allows iframe src dashboard mirror paths on
   loopback by default" test to assert that only
   `/hermes-dashboard` is open and that `/assets` now
   requires the token.

## README update

`baseline/browser-first/host/README.md` "Security Contract"
section should be updated to document the policy and the
override. See
[ADR-0005](../decisions/0005-bridge-loopback-and-lan-policy.md)
for the prose.

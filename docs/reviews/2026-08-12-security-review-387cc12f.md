# Security Review — vonstegen/RCC-OS @ main

Scope, commit SHA, and method follow. Findings are severity-ranked; each has file/line evidence and a concrete remediation. The "top 3 to fix first" callout for this domain closes the report.

> Note on path layout. The task brief names the bridge as `addons/resonant-browser-host` and `host/bridge-server.mjs`, but on `main` the bridge lives under **`baseline/browser-first/host/`** (the lab tracks a snapshot of ResonantOS/2.0.0-alpha under `baseline/`, which is read-only on the lab side). This review uses the actual paths and points back to the baseline tree where appropriate. The single-maintainer policy is documented in `docs/decisions/0002-self-review-on-main.md` (ADR-0002).

## 1. Scope and Commit SHA Reviewed

- Repo: github.com/vonstegen/RCC-OS
- Ref: `main` @ `387cc12f99d6dbab2b86bb4ea35cd2e2c6d68156`
- Branch prefix model (per `docs/WORKFLOW.md`): lab-flavored Gitflow — `main`, `develop`, `feature/*`, `experiment/<stage>-*`, `release/*`, `hotfix/*`, `upstream-sync/<date>`.
- Files reviewed: top-level `.gitignore`, `SECURITY.md`, `.github/workflows/{pr-checks,gitflow,latex-build,upstream-advisories,upstream-deterministic}.yml`; baseline workflows `baseline/.github/workflows/{alpha-build,project-issue-sync,security,agent-control-live}.yml`; baseline security pipeline `baseline/.github/security-pipeline/checks.yml` and `baseline/scripts/security-pipeline/{run-check.mjs,checks/*.mjs,checks/lib/*.mjs}`; baseline bridge `baseline/browser-first/host/{bridge-server,run-bridge-minimal,bridge-capability-tokens,bridge-tls,browser-first-self-test-service,browser-first-host-utils,addon-delegation-host-service,addon-delegation-service}.mjs`; extension `baseline/browser-first/resonantos-side-panel-extension/manifest.json` and selected `src/lib/{bridge-client,addon-iframe,addon-capability-review,content-field-safety}.js` and `src/content.js`; browser-host addon `baseline/addons/resonant-browser-host/{src/browser-host.mjs,src/lib/path-contains.mjs,test/*.test.mjs,package.json,README.md}`; `baseline/INSTALL.md`, `baseline/AGENTS.md`, `baseline/pre-release-scan.sh`.

## 2. Severity-Ranked Findings

| # | Severity | Domain | Finding | Evidence (file:line) |
|---|---|---|---|---|
| S1 | **High** | Secret handling | `pr-checks.yml` "Block generated credentials" step uses `git ls-files` to detect committed secrets, but `.gitignore` (lines 15–21) excludes `bridge-config.generated.js`, `*.generated.js`, `BridgeTLS/`, `.env`, `.env.local`, `.env.*.local`. Tracked-file listing therefore cannot surface those names — the check is effectively a no-op for the patterns it targets unless a contributor uses `git add -f`. | `.gitignore:15-21`, `.github/workflows/pr-checks.yml:37-42` |
| S2 | **High** | Bridge server | `RESONANTOS_BRIDGE_OPEN_PROXY_PREFIXES` defaults to **all** dashboard proxy mirror prefixes when bound to loopback or when `RESONANTOS_BRIDGE_ALLOWED_IPS` is set. Combined with `getBridgeOpenProxyPrefixes()` returning the full list whenever the host is `127.0.0.1`/`localhost`/`::1`/`[::1]` or any CIDR allowlist is present, every iframe-rendered addon SPA path becomes exempt from the bridge-token check. The mitigation (IP allowlist) is opt-in — the default has empty `allowedCidrs`, so on loopback the token is bypassed for `/hermes-dashboard`, `/auth`, `/api`, `/assets`, `/fonts-terminal`, `/dashboard-plugins`, `/favicon.ico` with **no** network gating when `RESONANTOS_BRIDGE_HOST` defaults to `127.0.0.1`. | `bridge-server.mjs:1009-1017`, `bridge-server.mjs:1037-1112` |
| S3 | **High** | Bridge server / capability bootstrap | The bootstrap-token check uses `constantTimeEqual` against `request.headers[bridgeCapabilityBootstrapHeader]`, but `bootstrapToken` is written to `bridge-config.generated.js` in plaintext (`bridgeToken` + `capabilityBootstrapToken` together, lines 985–1000). The generated file lives at `path.join(extensionRoot, "src", "bridge-config.generated.js")` — readable by every script in the chrome-extension origin. Any code injection in the extension (XSS via content script → extension page) exposes both tokens. The README (`baseline/browser-first/host/README.md` "Security Contract") and the file's own comment claim raw route capability tokens are not written; the bootstrap token is not a route capability but is functionally the master key that mints all of them. | `bridge-server.mjs:972-1001`, `bridge-capability-tokens.mjs:31-44`, `bridge-server.mjs:1024-1032` |
| S4 | **Medium** | Bridge server | `bridge-server.mjs` writeBridgeConfig writes the bridge-token to `bridge-config.generated.js` with mode `0o600`, but the file's location is `extensionRoot/src/bridge-config.generated.js` (i.e., inside the chrome-extension source tree). The 0600 only protects against other OS users on a single-user workstation. Anyone with shell access on the bridge host can read it; in many Tailscale/LAN deployments the bridge host is the operator's only workstation and this is fine, but it is **not** a defense against anyone who can read `~/ResonantOS_User` paths. Worth a security note in the README. | `bridge-server.mjs:980-999` |
| S5 | **Medium** | Bridge server | `RESONANTOS_BRIDGE_HOST` defaults to `127.0.0.1` and the comment in the file (lines 17–24) advertises `0.0.0.0` to expose to LAN/Tailscale. There is no startup-time warning when the operator picks `0.0.0.0`; the only protections are opt-in `RESONANTOS_BRIDGE_ALLOWED_IPS` (CIDR allowlist, default empty) and `RESONANTOS_BRIDGE_ALLOWED_ORIGINS` (default echoes `extensionOrigin` only). With `0.0.0.0` and no allowlists set, every route except the iframe-proxy exempt paths is bridge-token-protected (good), but the iframe-proxy exempt paths are open to the entire LAN/Tailscale with no token AND no IP allowlist because both checks are off. | `bridge-server.mjs:17-24`, `bridge-server.mjs:1009-1017`, `bridge-server.mjs:1138-1147` |
| S6 | **Medium** | Browser host | The addon-iframe srcdoc path injects a `<meta http-equiv="Content-Security-Policy">` (`addon-iframe.js:107-118`) that **broadens** the inherited MV3 CSP to `'unsafe-inline' 'unsafe-eval'` and `script-src`/`connect-src` includes the bridge origin. This is necessary for the addon to function inside an MV3 iframe, but it means the addon SPA (loaded from a non-extension origin via the bridge proxy) effectively runs with `unsafe-eval` inside the extension page's secure context. If the bridge proxy ever serves content from a host that is not under operator control (e.g. operator binds `0.0.0.0` and a LAN attacker serves a poisoned upstream), that attacker gets script execution in the user's chrome-extension:// origin. | `addon-iframe.js:107-118`, `addon-iframe.js:118-186` |
| S7 | **Medium** | Browser host | The injected srcdoc preamble also overrides `window.fetch` and `window.XMLHttpRequest` (lines 137–184) to silently add the bridge token and rewrite same-origin paths. A web page's content script cannot read these globals back, but any third-party JS executed inside the addon iframe inherits the override and can therefore make authenticated requests to the bridge proxy on behalf of the extension, regardless of the addon SPA's own auth model. The injected `<base href="…">` (line 109) plus the meta CSP further relax what URLs resolve relative to. | `addon-iframe.js:107-186` |
| S8 | **Medium** | Browser host | `addon-iframe.js` "src mode" deliberately drops `sandbox=` (line 281) so cross-origin addon bundles can load, on the rationale that sandboxing blocks subresources. Comment acknowledges that the upstream SPA "is a trusted same-host SPA"; an operator who proxies an addon over a hostile host now has unsandboxed script execution inside the extension page's origin with full DOM access. This is the documented design trade-off but it materially increases the impact of S5/S6. | `addon-iframe.js:276-290` |
| S9 | **Medium** | IPC boundary | `background.js:287-291` enforces `sender.id === chrome.runtime.id` on incoming messages — good. But content scripts (`content.js:96-113`, `control-overlay.js:106-108`, `main-workspace-action-controller.js:107-111`) accept `chrome.runtime.sendMessage(...)` with arbitrary payloads, including the full `pageSnapshot()` from content.js (lines 158–209) which embeds `innerText` of up to 12000 chars across shadow roots, all form fields with `name`/`id`/`action`/`method`, and link/control/iframe listings. The sanitization in `content.js:67-89` redacts obvious credential shapes and the structured walker skips keys matching a credential-name regex, but it does not redact arbitrary values that look like API keys in non-canonicalized fields. A page that intentionally constructs fake-looking key material can still leak through to the side panel and (via the Augmentor pipeline) to the bridge. | `content.js:67-89`, `content.js:158-209` |
| S10 | **Medium** | IPC boundary | `addon-delegation-service.mjs:resolveDelegationPath` (lines 453–459) rejects paths whose resolved form does not start with `${root}${path.sep}`. The check uses lexical containment: a path that escapes the root via a hard-link, junction, or symlink at the OS level (Windows `mklink /J` or POSIX symlink inside `Delegations/`) would still pass the lexical test and then be opened by `readFile`. The browser-host addon (`path-contains.mjs`) addresses this with `realpathSync` for screenshot containment, but the bridge's path validator does not. | `addon-delegation-service.mjs:453-459`, `path-contains.mjs:24-104` |
| S11 | **Medium** | Dependency security | No Renovate or Dependabot configuration is present anywhere in the tree (verified: zero matches for `renovate*` / `dependabot*` / `.github/dependabot.yml`). The `baseline/` lockfile (`baseline/package-lock.json`, 4765 lines, lockfileVersion 3) pins exact versions, but upstream CVEs are only surfaced by the `npm audit` step that was moved out of the deterministic gate (`upstream-deterministic.yml` no longer audits, `upstream-advisories.yml` runs the audit but is `continue-on-error: true` and not a required status check). The current SHA-pinned commit message explicitly says three high-severity CVEs in transitive deps (`nanoid`, `postcss`, `undici`) are now reported but not gating. | `upstream-deterministic.yml:23-46`, `upstream-advisories.yml:18-31`, commit message in `387cc12` |
| S12 | **Low** | CI | All five top-level workflows pin `uses:` to full 40-char SHAs (verified `actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683`, `actions/setup-node@39370e3970a6d050c480ffad4ff0ed4d3fdee5af`, `actions/upload-artifact@50769540e7f5e21e526ee35c689e35e0d6874`), and `pr-checks.yml:80-95` enforces 40-char SHA policy via regex. `baseline/` workflows are also pinned but to an **older** SHA (`actions/checkout@34e114876b0b11c390a56381ad16ebd13914f8d5`, `actions/setup-node@49933ea5288caeca8642d1e84afbd3f7d6820020`, `actions/upload-artifact@ea165f8d65b6e75b540449e92b4886f43607fa02`), suggesting two divergent pinning cadences. `baseline/` is a snapshot but its workflows still execute under `baseline/` CI; their older pins are worth a periodic re-verify. | `pr-checks.yml:25,84,100,117`, `alpha-build.yml:24,29,62`, `security.yml:36,40`, `project-issue-sync.yml:31,37`, `agent-control-live.yml:55,57,76` |
| S13 | **Low** | CI | `pull_request` events with `branches: [main, develop]` are configured on `pr-checks.yml`, `gitflow.yml`, `latex-build.yml`, `upstream-advisories.yml`, and `upstream-deterministic.yml`. By GitHub default, **PRs from forks DO trigger `pull_request` workflows** but with **read-only tokens and no secrets**, which is the safer default. The workflows themselves all set `permissions: contents: read` at the top level (good). No `pull_request_target` is used in any of the five top-level workflows (verified by grep). `pull_request_target` IS used in `baseline/.github/workflows/project-issue-sync.yml` (line 10), but it scopes to `issues` events only and gates everything on `secrets.PROJECT_SYNC_TOKEN` being configured (lines 39-44, 64-67). | `pr-checks.yml:13-19`, `gitflow.yml:13-19`, `latex-build.yml:9-17`, `upstream-advisories.yml:10-22`, `upstream-deterministic.yml:14-27`, `project-issue-sync.yml:10-22,39-67` |
| S14 | **Low** | CI | `workflow_dispatch` is exposed on all five top-level workflows and on `baseline/.github/workflows/{alpha-build,security,project-issue-sync,agent-control-live}.yml`. Anyone with `workflow_dispatch` permission on `main` can trigger them manually. The single-maintainer model (ADR-0002) makes this moot today, but as soon as a second collaborator is added, this becomes an attacker-controlled code path if the collaborator's PAT is compromised. Workflows do not assert an "actor is maintainer" gate before running. | `pr-checks.yml:18`, `gitflow.yml:18`, `latex-build.yml:15`, `upstream-advisories.yml:21`, `upstream-deterministic.yml:26`, `alpha-build.yml:11-19`, `security.yml:23-27`, `project-issue-sync.yml:21-22`, `agent-control-live.yml:34-44` |
| S15 | **Low** | CI / secret handling | `upstream-advisories.yml:38-44` calls `npm ci` against `baseline/package-lock.json` and `baseline/addons/resonant-browser-host/package-lock.json` and then `npm audit --json || true`. The job is gated only by `permissions: contents: read`; it does not write anywhere. Note: the lockfiles are committed at the snapshot point, so a transitive CVE landing upstream after the snapshot date will not be visible until a refresh. | `upstream-advisories.yml:33-65` |
| S16 | **Low** | Bridge server | `bridge-server.mjs:clientIpAllowed` (line 64) silently strips the `::ffff:` IPv6-mapped prefix from `remoteAddress` and then validates against IPv4-only CIDRs. There is no IPv6 support at all (the CIDR parser rejects anything but dotted-quad). If an operator binds `::` (IPv6 any) the IPv4 allowlist will silently fail-OPEN because every request's stripped address won't match the configured IPv4 CIDRs. The mitigation is that the default bind is `127.0.0.1`, but the docs do not call this out. | `bridge-server.mjs:46-79`, `bridge-server.mjs:1009-1017` |
| S17 | **Low** | Browser host | `bridge-server.mjs:createDashboardProxyUpgradeHandler` (lines 326-481) implements WebSocket upgrade by manually parsing the upstream response, re-injecting `Connection: Upgrade`/`Upgrade: websocket` headers, and piping bytes both directions. This is hand-rolled and well-commented, but it has no size limit, no origin check beyond IP, and the iframe path exemption from bridge-token auth applies to the WebSocket upgrade as well. The `openPathPrefixes.some(...)` exemption (line 343) means a WebSocket to `/hermes-dashboard/...` is accepted with no bridge token and no IP allowlist when bound to loopback. | `bridge-server.mjs:340-481`, `bridge-server.mjs:1009-1017` |
| S18 | **Low** | Bridge server | `bridge-server.mjs:clientIpAllowed` returns `true` when `allowedCidrs` is empty (line 64). This is the documented behavior but it means the **only** auth on the loopback default is the bridge token, which is bypassed for iframe-proxy paths (see S2). On LAN/Tailscale deployments, the operator must remember to set `RESONANTOS_BRIDGE_ALLOWED_IPS` — there is no startup assertion or warning. | `bridge-server.mjs:64-68`, `bridge-server.mjs:1009-1017` |
| S19 | **Informational** | Bridge server | `bridge-server.mjs:createAddonProxyHandler` strips hop-by-hop headers (lines 196-211) and forwards all others, including any `Cookie:` the extension sets. The dashboard SPA uses its own session cookie; if the extension sets a cookie on the bridge origin, that cookie is forwarded upstream. The bridge is on a different port from the dashboard, but they share the IP; if both run on `127.0.0.1`, the cookies are scoped per-port so there is no collision. This is a behavior note, not an active defect. | `bridge-server.mjs:175-211` |
| S20 | **Informational** | Browser host | `browser-host.mjs:assertSafeHttpUrl` (lines 56-66) refuses non-http/https schemes. `captureEvidence` (lines 207-220) uses `path-contains.mjs` to keep screenshots inside `artifactsDir` — correctly defends against `..`, absolute paths, and symlink escapes (covered by `test/path-contains.test.mjs`). No findings here; documenting as positive control. | `browser-host.mjs:56-66`, `browser-host.mjs:207-220`, `path-contains.mjs:24-104`, `path-contains.test.mjs` |
| S21 | **Informational** | Secret handling | The current tree contains no tracked secrets. Search for high-entropy key shapes (`sk-…`, `ghp_…`, `AKIA…`, JWTs) returns only the test fixture in `baseline/src/core/compute-fabric.test.ts:351` (`"sk-EXAMPLEEXAMPLEEXAMPLE"`, deliberately non-real), `baseline/scripts/security-pipeline/checks/runtime-hardening-registry.test.mjs:75-90` (test fixtures with placeholder names like `"secret-anthropic"`), and INSTALL/README placeholders. No real credentials are committed. | tree-wide grep |
| S22 | **Informational** | Bridge server | Capability token validation (`bridge-server.mjs:scopedCapabilityTokenPayload`, lines 1037-1059) limits the request to 80 capabilities and validates the `^[a-z0-9][a-z0-9-]{0,80}$` shape. Good defense against DoS via giant capability lists and against typos. | `bridge-server.mjs:1037-1059` |

## 3. Per-Finding Evidence and Remediation

### S1 — `pr-checks.yml` "Block generated credentials" is a no-op for the names it targets

Evidence:
- `.gitignore:15-21` excludes `ResonantOS_User/`, `BridgeTLS/`, `*.generated.js`, `bridge-config.generated.js`, `.env`, `.env.local`, `.env.*.local`.
- `.github/workflows/pr-checks.yml:37-42` runs `git ls-files | grep -E '(bridge-config\.generated\.js|\.env($|\.)|BridgeTLS/ResonantOS_User/)'`.
- `git ls-files` does not list ignored files; `git add` without `-f` will silently drop them.

Remediation:
- Replace `git ls-files` with `git ls-files --others --exclude-standard --directory` to catch files staged but ignored, **or** add `git check-ignore` on the diff for the same patterns, **or** add a real secret scanner (e.g. `gitleaks` or `trufflehog`) as a `block`-policy step. The current check only catches the case where someone runs `git add -f bridge-config.generated.js`.

### S2 — Loopback default opens iframe proxy paths to bridge-token bypass

Evidence:
- `bridge-server.mjs:1009-1017` (`getBridgeOpenProxyPrefixes`) returns `DASHBOARD_PROXY_MIRROR_PATHS.map(...)` whenever host is loopback **or** `allowedCidrs.length > 0`.
- `bridge-server.mjs:1037-1112` (`createBridgeRequestHandler` + `dashboardProxyHandler`) consumes that list and exempts each prefix from the bridge-token check.
- `bridge-server.mjs:64-68` (`clientIpAllowed`) returns `true` when `allowedCidrs` is empty (default).
- The combined effect on the documented default (`127.0.0.1`, no CIDRs set) is that `/hermes-dashboard/*`, `/auth/*`, `/api/*`, `/assets/*`, `/fonts-terminal/*`, `/dashboard-plugins/*`, `/favicon.ico` are reachable without the bridge token AND without IP allowlisting.

Remediation:
- On loopback with no IP allowlist, exempt only `/hermes-dashboard/*` (the iframe `src`) and **not** the others, since they are not needed as `<iframe src>` targets and are reachable from extension code that can set headers.
- When `RESONANTOS_BRIDGE_HOST != loopback`, refuse to start unless `RESONANTOS_BRIDGE_ALLOWED_IPS` is set and non-empty (startup-time guard, fail closed).
- Add a startup log line that prints the active bind host, the open prefixes, and whether the IP allowlist is configured — so misconfigurations are visible.

### S3 — Capability-bootstrap token in plaintext on disk is a master-key leak surface

Evidence:
- `bridge-server.mjs:972-1001` writes `{ bridgeUrl, httpsBridgeUrl, bridgeToken, capabilityBootstrapToken }` to `bridge-config.generated.js` with mode `0o600`.
- `bridge-capability-tokens.mjs:31-44` documents that raw route capability tokens are NOT written; the bootstrap token is the credential that mints them.
- `bridge-server.mjs:1024-1032` (`isAuthorizedCapabilityBootstrapRequest`) shows the bootstrap token authorizes `/api/capability-tokens`, which returns the entire capability allowlist.
- Any code path that can read chrome-extension origin files (i.e., any extension JS, including content scripts that have moved into the extension's own page) reads the bootstrap token.

Remediation:
- Treat the bootstrap token as a session secret: derive it from a per-startup value (random 256 bits) and keep it in the bridge process only. Issue short-lived capability tokens (e.g. 1-hour JWT-style) signed by the bridge key, so a leak window is bounded.
- Or, rotate the bootstrap token on every `/api/capability-tokens` POST (one-shot use), forcing the extension to re-request.
- Or, move the bootstrap handshake to a localhost-only IPC channel rather than a file.

### S4 — `bridge-config.generated.js` 0600 mode is misnamed

Evidence:
- `bridge-server.mjs:980-999` writes to `path.join(extensionRoot, "src", "bridge-config.generated.js")` with `mode: 0o600`.

Remediation:
- Document in `baseline/browser-first/host/README.md` and `baseline/INSTALL.md` that the 0600 protects only against other OS users, not against anyone with shell access on the workstation. State the threat model plainly: "If your workstation account is compromised, the bridge token and bootstrap token are exposed."
- Consider writing to a path outside the chrome-extension source tree (e.g. `~/.config/resonantos/bridge-config.json`) and exposing it to the extension via `chrome.runtime.getURL("…")` plus a side-load manifest entry — but this conflicts with the existing `chrome.runtime.getURL(GENERATED_CONFIG_PATH)` pattern at `bridge-client.js:158-160`. A reasonable compromise is a one-line README warning.

### S5 — Bind-to-LAN has no startup guard

Evidence:
- `bridge-server.mjs:17-24` documents the bind options without any "must set X" requirement.
- `bridge-server.mjs:1009-1017` exposes all iframe-proxy paths to LAN/Tailscale with no IP allowlist when `allowedCidrs` is empty.

Remediation:
- Add a `startBridgeServer` precondition: if `bindHost` is `0.0.0.0` / `::` / a non-loopback IP and `effectiveAllowedCidrs.length === 0`, throw on startup. Same for `openPathPrefixes` exemption: refuse to grant exemptions on non-loopback binds.
- Add a startup log line: `[bridge] bound to <host>:<port>; token=on; ip-allowlist=<count-of-CIDRs>; open-prefixes=<count-of-prefixes>`.

### S6 — Meta-CSP relaxation in addon iframe

Evidence:
- `addon-iframe.js:107-118` injects a meta CSP that includes `'unsafe-inline'` and `'unsafe-eval'` for the addon origin.

Remediation:
- Replace `'unsafe-eval'` with a SHA-256 nonce if any addon SPA actually requires it (Hermes dashboard's React build with Vite typically does). For addons that don't need it, omit `'unsafe-eval'`.
- Restrict `connect-src` to the bridge origin only — current value is already restricted, but `default-src 'self'` plus narrow `script-src`/`img-src`/`connect-src` would be tighter.
- Consider stripping the meta-CSP injection if the iframe is loaded in `src` mode (where the upstream's own CSP applies); the relaxation is only needed in `srcdoc` mode (the comment at lines 254-261 acknowledges this distinction).

### S7 — `fetch`/`XHR` override inside srcdoc adds auth header without caller intent

Evidence:
- `addon-iframe.js:137-184` overrides `window.fetch` and `window.XMLHttpRequest` inside the addon iframe. The override always adds the bridge token (when present in the preamble's `BRIDGE_TOKEN`).

Remediation:
- Document this in the addon-iframe JSDoc — that any JS in the addon iframe, including any user-content rendered into it, will silently authenticate to the bridge as the extension.
- Restrict the override's effect to same-origin (already done in spirit via the `chrome-extension://` re-write), but add a comment that cross-origin fetches from the addon iframe are NOT proxied (they go to the addon SPA's own backend, which is intentional).

### S8 — `src` mode drops the sandbox

Evidence:
- `addon-iframe.js:276-290` (`// In src mode, no sandbox`). The comment acknowledges that the upstream is treated as a "trusted same-host SPA", but on the bridge side that trust is implicit and depends on `RESONANTOS_BRIDGE_HOST` and the addon host's URL.

Remediation:
- Document the trust boundary clearly: "Operators must only proxy addon hosts they control."
- Consider adding `sandbox="allow-scripts allow-same-origin allow-forms"` and accepting the subresource load failures for cross-origin addon bundles, until a path is found to load them through the proxy without breaking Chrome's frame-src.

### S9 — Content-script page snapshots may carry secrets through to the Augmentor

Evidence:
- `content.js:67-89` (`_rcSanitizeText`, `_rcSanitizeStructured`) redacts obvious key shapes and credential-named fields.
- `content.js:158-209` (`pageSnapshot`) emits 12000 chars of innerText, all forms, all link hrefs, all control refs.
- The redaction uses regex, so novel key shapes (e.g. a credential in a long opaque URL fragment or a custom field name) are missed.

Remediation:
- Move the redaction to a server-side post-processor on the bridge (where the snapshot is forwarded to the model). The current client-side redaction is a first line of defense only.
- Add a per-snapshot hash of redacted field names so a regression in the regex set is detectable.
- Consider stripping `<input type="password">` value fields entirely rather than relying on regex.

### S10 — `resolveDelegationPath` does not check realpath

Evidence:
- `addon-delegation-service.mjs:453-459`: `resolved.startsWith(\`${root}${path.sep}\`)` and `endsWith(".md")`. No `realpathSync` call.

Remediation:
- Adopt the same `pathContains` primitive used by the browser-host addon (`baseline/addons/resonant-browser-host/src/lib/path-contains.mjs`) for the delegation path check. It already handles symlink resolution, `..` chains, and absolute-outside cases.
- Alternatively, refuse to operate on symlinks at all (`lstatSync(...).isSymbolicLink()` → throw).

### S11 — No Renovate/Dependabot; CVE advisories are observed-only

Evidence:
- Tree-wide grep for `renovate*`, `dependabot*`, `.github/dependabot.yml` → 0 matches.
- `upstream-deterministic.yml` does not run `npm audit`.
- `upstream-advisories.yml:42-44` runs `npm audit --json || true` and is `continue-on-error: true`.
- The merge commit message for `387cc12` explicitly states: "Three high-severity CVEs in the baseline's transitive deps (nanoid, postcss, undici) are now reported but not gating."

Remediation:
- Add `.github/dependabot.yml` for `npm` and `github-actions`. Dependabot for GitHub Actions will catch S12.
- Add a Renovate config (more flexible than Dependabot for npm monorepos).
- Add a `block`-policy step in `upstream-deterministic.yml` that fails on `npm audit --audit-level=high` for new advisories since the last baseline refresh.

### S12 — Baseline workflows use older action SHAs than the lab workflows

Evidence:
- Lab: `actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683` (v4.2.2), `actions/setup-node@39370e3970a6d050c480ffad4ff0ed4d3fdee5af` (v4.1.0), `actions/upload-artifact@50769540e7f4bd5e21e526ee35c689e35e0d6874` (v4.4.0).
- Baseline: `actions/checkout@34e114876b0b11c390a56381ad16ebd13914f8d5` (v4 unannotated), `actions/setup-node@49933ea5288caeca8642d1e84afbd3f7d6820020` (v4 unannotated), `actions/upload-artifact@ea165f8d65b6e75b540449e92b4886f43607fa02` (v4 unannotated).

Remediation:
- During the next `upstream-sync/*` refresh, bump baseline action SHAs to match the lab's, or open a `hotfix/baseline-action-pin-bump` against `develop` to update them in place.
- Add Dependabot for `github-actions` (see S11) so this gap closes automatically.

### S13 — `pull_request_target` in baseline project-issue-sync

Evidence:
- `baseline/.github/workflows/project-issue-sync.yml:10-22` uses `pull_request_target` with `issues:` triggers. All write steps are gated on `secrets.PROJECT_SYNC_TOKEN != ''` and on `gh project item-list` succeeding. The workflow uses `persist-credentials: false` on checkout (line 33).

Remediation:
- None for the current setup (gating is correct). Document the pattern in `baseline/SECURITY.md` so future contributors know to gate write paths behind a secret check.
- Consider moving the project sync off `pull_request_target` entirely (use the `contents: read` workflow with a manual `workflow_dispatch` step instead), since `pull_request_target` historically is the most common workflow-injection vector.

### S14 — `workflow_dispatch` exposure under single-maintainer model

Evidence:
- All five top-level workflows and the baseline workflows expose `workflow_dispatch:` with no actor check.

Remediation:
- ADR-0002 already commits to restoring `required_approving_review_count = 1` when a second maintainer joins. Add a parallel ADR commit: when that happens, add an `actor in ${{ vars.MAINTAINERS }}` gate to every workflow that exposes `workflow_dispatch`.
- For now, document in `SECURITY.md` that workflow_dispatch is a single-maintainer trust point.

### S15 — `upstream-advisories.yml` reports only

Evidence:
- `upstream-advisories.yml:18-31` is `continue-on-error: true` and never gates the workflow.

Remediation:
- After Dependabot/auto-bumps are in place, this workflow's value drops. Keep it for the historical record but make it explicit that it is non-gating.

### S16 — IPv6 fallback silently opens CIDR allowlist

Evidence:
- `bridge-server.mjs:46-79` only parses IPv4. If the bind is `::` and the operator set IPv4-only CIDRs, every IPv6 request's stripped address won't match → the loopback-only bind still works (the kernel routes IPv4-mapped IPv6 to the IPv4 handler) but the LAN bind is unprotected.

Remediation:
- Reject `RESONANTOS_BRIDGE_HOST = ::` (or any IPv6 literal) until the CIDR parser supports v6. Add a startup assertion.
- Add an IPv6 parser (the codebase already has the pattern in `ipToBigInt`; generalize to 128-bit).

### S17 — WebSocket upgrade exemption is the same as HTTP iframe-proxy exemption

Evidence:
- `bridge-server.mjs:340-481` uses the same `openPathPrefixes` and the same `clientIpAllowed` short-circuit as the HTTP handler. No additional defense is layered.

Remediation:
- WebSocket upgrades should additionally require the bridge token OR an Origin header that matches the extension's chrome-extension:// origin. Browsers can't add headers to WS, but they DO send `Origin:` reliably.

### S18 — Default IP allowlist behavior is permissive

Evidence:
- `bridge-server.mjs:64-68`.

Remediation:
- Document in `baseline/browser-first/host/README.md`: "Default bind `127.0.0.1` is loopback-only; if you switch to LAN/Tailscale, you MUST set `RESONANTOS_BRIDGE_ALLOWED_IPS` to a non-empty CIDR list, otherwise the iframe-proxy paths are open to the entire LAN."

### S19 — Cookie forwarding to upstream

Evidence:
- `bridge-server.mjs:175-211` forwards all non-hop-by-hop headers.

Remediation:
- Strip `Cookie:` and `Set-Cookie:` from the proxy response as well as the request, unless the upstream is a localhost Hermes dashboard (which uses its own session cookie). Add a comment to that effect.

### S20 — Browser-host addon path containment is correct

Evidence:
- `browser-host.mjs:207-220` calls `assertContained` before any FS write. Tests cover `..` chains, absolute paths, and symlink escapes.

Remediation:
- None. Use the same primitive for S10.

### S21 — No tracked secrets

Evidence:
- Tree-wide grep for high-entropy key shapes returns only test fixtures.

Remediation:
- Continue scanning in CI (currently absent — see S1, S11).

### S22 — Capability token request shape is bounded

Evidence:
- `bridge-server.mjs:1037-1059`.

Remediation:
- None. Good defense.

## 4. Top 3 to Fix First (security domain)

1. **S1 — `pr-checks.yml` "Block generated credentials" is a no-op.** Replace `git ls-files` with `git ls-files --others --exclude-standard` (or add a real secret scanner step) so a developer who runs `git add -f bridge-config.generated.js` or `.env` is blocked at PR time. Today this is the only secret-related gate on PRs to `main`/`develop` and it doesn't fire.
2. **S2/S5 — Loopback default opens iframe-proxy paths to bridge-token bypass.** On LAN/Tailscale binds, refuse to start unless `RESONANTOS_BRIDGE_ALLOWED_IPS` is set; on loopback, narrow the open-prefix exemption to `/hermes-dashboard/*` only. This closes the highest-impact network exposure in the bridge today.
3. **S3 — Capability-bootstrap token is a plaintext master key.** Rotate the bootstrap token to short-lived (e.g. one-shot, or 1-hour JWT-style signed by the bridge key) so a leak is bounded. Today anyone who reads `bridge-config.generated.js` (or any extension code that runs in the chrome-extension origin) holds the credential that mints every route capability.

---

### One-paragraph chat summary

This is a small, deliberately scoped fork with disciplined hygiene: action refs are pinned to 40-char SHAs in the lab layer (with a 40-char SHA policy enforcement step in `pr-checks.yml`), no real secrets are tracked in the tree, and the bridge uses constant-time token comparison, scoped capability tokens that are minted only at runtime via a separate bootstrap secret, and an IP-allowlist + open-prefix scheme that defends the JSON route surface well. The bridge's main weaknesses are (a) the `pr-checks.yml` "Block generated credentials" step is effectively a no-op because every name it greps for is `.gitignore`-excluded, so `git ls-files` never returns them; (b) the loopback default exempts all seven iframe-proxy mirror paths (`/hermes-dashboard`, `/auth`, `/api`, `/assets`, `/fonts-terminal`, `/dashboard-plugins`, `/favicon.ico`) from the bridge-token check with no IP allowlist enforcement, and the same exemption is inherited when binding to `0.0.0.0`; (c) the capability-bootstrap token that mints every route capability is written in plaintext to `bridge-config.generated.js` alongside the bridge token, making any extension-script-origin code a master-key reader; and (d) there is no Renovate or Dependabot config, so the upstream `npm audit` advisories (`nanoid`/`postcss`/`undici` high-severity CVEs explicitly mentioned in the latest commit message) are reported in an `observe`-only weekly workflow with `continue-on-error: true` and never gate the merge. The browser host's `addon-iframe.js` adds a third class of concern: it injects a meta-CSP that loosens the MV3 CSP to include `'unsafe-eval'` for the addon origin, overrides `window.fetch`/`XMLHttpRequest` inside the addon iframe to silently add the bridge token, and intentionally drops `sandbox=` in `src` mode — a documented trade-off that materially raises the impact of any addon proxy misconfiguration. Recommended top-3 fixes: make the secret-scanner step real (S1), narrow the loopback open-prefix exemption and add a startup guard against `0.0.0.0`/`::` binds without `RESONANTOS_BRIDGE_ALLOWED_IPS` (S2/S5), and rotate/shorten the capability-bootstrap token so the master key has a bounded leak window (S3).

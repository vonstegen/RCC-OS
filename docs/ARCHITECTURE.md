# Architecture

This document describes the target architecture for RCC-OS as it
should look at the end of the staged experiments described in
[`docs/VISION.md`](VISION.md). It is intentionally aspirational; the
current implementation is at stage 0 (lab scaffold).

## Layered model

```text
┌──────────────────────────────────────────────────────────┐
│ 5. Experience                                            │
│    Browser extension · Desktop shell · CLI · future UIs  │
├──────────────────────────────────────────────────────────┤
│ 4. Augmentation                                          │
│    Agents · Apps · Add-ons · Workflows                   │
├──────────────────────────────────────────────────────────┤
│ 3. Intelligence                                          │
│    Cognitive Core · Local LLMs · Cloud LLMs              │
├──────────────────────────────────────────────────────────┤
│ 2. Cognitive Infrastructure                              │
│    Living Archive · Context · Model Fabric               │
├──────────────────────────────────────────────────────────┤
│ 1. Resonant Core                                         │
│    Capability engine · Security · IPC · Host OS          │
└──────────────────────────────────────────────────────────┘
```

Layer 1 is deterministic software. Layer 3 makes the system
intelligent. Layers 2 and 4 are policy and orchestration glue.

## Resonant Core (Layer 1)

The Core is the single substrate that all clients (browser, desktop,
CLI, future UIs) speak to. It is the architectural center of the
system, not the browser.

```text
resonant-core/
├── capabilities/    policy + capability tokens + enforcement
├── security/        identity, secrets, audit
├── ipc/             authenticated transports (loopback HTTP, sockets)
├── host/            filesystem, processes, devices, notifications
├── agents/          Agent Control planners + next-action engine
└── api/             stable surface exposed to clients
```

Responsibilities:

- Enforce every capability decision through deterministic code.
- Maintain the local user state root (`~/ResonantOS_User` by default).
- Audit every privileged action.
- Hold provider credentials, secrets, and bridge tokens.
- Never depend on any AI component to make a security decision.

Initial implementation will be Rust. Stage 3 of the lab work migrates
the current `baseline/browser-first/host` Node bridge into this shape,
not by deleting it but by giving it a stable boundary and a
non-Chrome entry point.

## Cognitive Infrastructure (Layer 2)

```text
cognitive-infra/
├── living-archive/   governed persistent memory
├── context/          working context assembly
└── model-fabric/     unified router over local and remote intelligence
```

- **Living Archive** inherits from the upstream ResonantOS
  `Living Archive` concept (intake, snapshots, review, verification,
  promotion, restore) and remains governed: the AI cannot unilaterally
  rewrite trusted memory.
- **Context** assembles the structured inputs the Cognitive Core sees
  on every interaction.
- **Model Fabric** is the unified router. It treats every model —
  local tiny, local large, cloud frontier, corporate private — as
  a provider with measured properties:

  ```text
  latency
  cost
  privacy
  capability
  memory footprint
  availability
  ```

## Intelligence (Layer 3)

```text
intelligence/
├── cognitive-core/   always-on small local model (the AI BIOS)
├── local-llms/       larger local specialists (optional)
└── remote-llms/      cloud / corporate / federated models (optional)
```

The **Cognitive Core** is the smallest model that can reliably serve
as the cognitive control plane. It does not need to be the most
capable model on the machine.

Its job is narrowly defined:

- classify user intent;
- choose a capability;
- choose a model tier;
- rank memory candidates;
- plan simple tasks;
- interpret results;
- decide when to escalate.

Concretely, the Core handles structured requests like:

```json
{
  "task": "route",
  "input": "Open the budget spreadsheet and summarize it",
  "available_capabilities": ["filesystem.read", "spreadsheet.inspect"],
  "available_models": ["core-local", "local-7b", "cloud-gpt"],
  "context_summary": "..."
}
```

and returns:

```json
{
  "intent": "summarize_document",
  "capabilities": ["filesystem.read", "spreadsheet.inspect"],
  "model_tier": "local",
  "memory_queries": ["budget-2026", "spreadsheet:budget"]
}
```

The deterministic Core then validates and executes.

## Augmentation (Layer 4)

```text
augmentation/
├── agents/       long-running autonomous workflows
├── apps/         scoped applications
├── add-ons/      third-party extensions
└── workflows/    user-defined multi-step flows
```

This is where the existing ResonantOS Agent Control surface moves
when the Core becomes client-independent. The current approval-boundary
keywords (wallet, sign, payment, publish, credential, etc.) become a
typed capability taxonomy rather than a free-text classifier.

## Experience (Layer 5)

```text
clients/
├── browser-extension/    Chrome MV3 (carried over from baseline)
├── desktop/              Tauri or native shell (new in stage 4)
├── cli/                  terminal-oriented client
└── mobile/               future
```

The browser extension is the broadest-deployment client and the
first one the lab will validate end-to-end.

## What is intentionally absent

- No "AI decides whether the action is safe" path. The Core always
  decides.
- No implicit trust between Cognitive Core and capability layer. The
  Core is treated as a user-facing intelligence, not a privileged
  process.
- No AI-managed secrets. Secrets live in the Core and are only
  released to specific capability requests, never to a prompt.

## Open architectural questions

These are research questions the lab expects to investigate and
resolve in `docs/decisions/`:

1. How should the Cognitive Core be trained? ResonantOS-specific
   fine-tuning of an existing ternary SLM vs. an off-the-shelf SLM?
2. How is hardware discovery structured — Rust trait, JSON contract,
   both?
3. Where does IPC terminate? Loopback HTTP is the ResonantOS default;
   is that the right long-term transport?
4. What is the upgrade story for the Cognitive Core model without
   breaking capability contracts?

See [`docs/decisions/`](decisions/) for current working answers.
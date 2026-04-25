# opencode-plugins-termux expansion plan

## Scope
- Build a curated next-batch plugin roadmap for `/data/data/com.termux/files/home/develop/opencode-plugins-termux`.
- Prioritize **source-build maintenance** over release-only packaging.
- Prefer plugins that fit the current Termux-first `file://` registration model.
- Exclude plugins already effectively covered as **built-in / old core-integrated plugins**.

## Hard filters
- Exclude built-in/old core-integrated plugins from new maintenance work:
  - `opencode-anthropic-auth`
- Soft-exclude / defer likely core-covered auth lanes unless future evidence shows a clear external-maintenance need:
  - `opencode-copilot-auth`
  - `@gitlab/opencode-gitlab-auth`
- Exclude archived repos from near-term batches unless they are uniquely valuable.
- Exclude release-only candidates with no credible source-build path.

## Current maintained baseline
- `code-yeongyu/oh-my-opencode`
- `gustavodiasdev/opencode-qwencode-auth`
- `foxswat/opencode-qwen-auth`

## Selection rubric
- **Signal**: stars, ecosystem references, official/awesome listing, activity
- **Buildability**: clear source repo, TypeScript/JS build path, likely `bun`/`npm` compatibility
- **Termux fit**: file-plugin friendliness, low native/runtime burden, low GUI/container dependency
- **Maintenance cost**: overlap with existing plugins, churn risk, auth fragility, upstream health

## Batch table

| Batch | Repo | Purpose | Signal | Source-build outlook | Termux risk | Recommendation | Notes |
|---|---|---|---|---|---|---|---|
| S0 | `ghoulr/opencode-websearch-cited` | Cited web search tool | medium-high | strong | low | integrate first | Packaging canary: focused, useful, pure TS/Bun build |
| B1 | `frap129/opencode-rules` | Rule injection engine | medium | strong | low | integrate early | High operator value and simple `tsc` build |
| B1 | `Octane0411/opencode-plugin-openspec` | OpenSpec planning/spec agent | medium | strong | low | integrated | Bun build proved clean on local Termux packaging flow |
| B3 | `NoeFabris/opencode-antigravity-auth` | Antigravity/Google auth provider | very high | strong | medium | integrate after low-risk lane | Highest-signal auth plugin in search; clear ecosystem demand |
| B3 | `jenslys/opencode-gemini-auth` | Gemini auth provider | high | strong | low-medium | integrate after low-risk lane | Popular, active, direct auth fit |
| B3 | `numman-ali/opencode-openai-codex-auth` | OpenAI Codex/ChatGPT OAuth | high | strong | medium | integrate after low-risk lane | Strong stars and direct provider value |
| B4 | `andyvandaric/opencode-ag-auth` | Hardened antigravity auth fork | medium-high | likely | medium | watchlist / maybe replace | Overlaps with B3 antigravity lane; evaluate only after baseline provider lands |
| B4 | `TVD-00/opencode-qwen-cli-auth` | Alternative Qwen CLI auth | low-medium | likely | low-medium | watchlist | Useful fallback if current Qwen plugins stagnate |
| B4 | `Tarquinen/opencode-auth-provider` | Shared auth/provider runtime | medium | likely | medium-high | watchlist | Strategic abstraction, but not obviously a direct end-user plugin |
| B4 | `joshuadavidthomas/opencode-agent-memory` | Persistent agent memory | medium | strong | medium | later watchlist | Stateful/persistent behavior raises maintenance cost vs simple utilities |
| B4 | `joshuadavidthomas/opencode-agent-skills` | Dynamic skills loader | medium | strong | medium | later watchlist | Behavior-shaping plugin; stage after simpler utility lane |
| B2 | `vbgate/opencode-mystatus` | Multi-provider quota/status checker | medium-high | likely | low-medium | integrated | Bundled successfully from source; includes command payload |
| B2 | `joshuadavidthomas/opencode-handoff` | Focused handoff prompt generator | medium | medium | medium | integrated | Bundled successfully from TS source for Termux packaging |
| B2 | `ramarivera/opencode-model-announcer` | Inject current model name into context | medium | likely | low | integrated | Lightweight bundled build succeeded cleanly |
| B1 | `boxpositron/envsitter-guard` | Prevent `.env*` secret leaks | medium | likely | low | integrate early | Strong safety value and low platform burden |
| B4 | `kdcokenny/opencode-notify` | Native notifications | medium | likely | medium-high | defer | Practical but Termux notification behavior is more fragile than pure JS plugins |
| B1 | `lgladysz/opencode-ignore` | Ignore pattern enforcement | low-medium | likely | low | integrate early | Small/cheap plugin with safety value |
| B4 | `slkiser/opencode-quota` | Quota tracking / toasts | medium | unknown-likely | medium | later watchlist | Useful but less urgent than simpler utilities |
| B1 | `JosXa/opencode-snippets` | Hashtag-based prompt snippets | low-medium | likely | low | integrate early | Small utility with low platform friction |
| B2 | `nick-vi/type-inject` | Type context injection | medium | likely | medium | watchlist | Good TS-focused utility, but repo fit should be checked against your real workloads |
| B2 | `JRedeker/opencode-morph-fast-apply` | Fast edit/apply workflow | medium | likely | medium | watchlist | Pure TS but depends on external Morph API |
| B2 | `@simonwjackson/opencode-direnv` | Direnv environment loader | low-medium | likely | medium | watchlist | Useful in nix/direnv-heavy setups but depends on local direnv presence |
| B3 | `@knikolov/opencode-plugin-simple-memory` | Simple git-backed memory | low-medium | medium | medium | watchlist | Lighter than vector-memory plugins, but still introduces state/persistence concerns |
| B4 | `malhashemi/opencode-sessions` | Session management | medium | unknown | medium-high | defer | Could overlap with OMO/session tooling |
| B4 | `kdcokenny/opencode-worktree` | Git worktree orchestration | medium-high | likely | medium-high | defer | Useful but terminal/worktree orchestration increases maintenance burden |
| B4 | `zenobi-us/opencode-background` | Background processing | medium | unknown | high | defer | Process-management complexity on Termux |
| B4 | `kdcokenny/opencode-background-agents` | Async background agents | medium | unknown | high | defer | Overlaps with OMO orchestration direction |
| B4 | `IgorWarzocha/Opencode-Google-AI-Search-Plugin` | Google AI Search tool | medium | unknown | medium-high | defer | Web/tooling value but less core than auth/skills |
| B4 | `Tarquinen/opencode-dynamic-context-pruning` | Context pruning optimization | medium | unknown | medium | defer | Potentially useful later after baseline ecosystem grows |
| B4 | `simonwjackson/opencode-direnv` | Direnv integration | low-medium | unknown-likely | medium | defer | Nice environment helper, but less urgent than memory/safety tools |
| B4 | `athal7/opencode-devcontainers` | Devcontainer integration | low-medium | unknown | very high | defer | Weak fit for Termux-first maintenance |
| B4 | `mailshieldai/opencode-canvas` | Interactive canvas/tmux UI | low-medium | unknown | high | defer | UI/tmux-heavy, lower priority than auth and pure tooling |
| B4 | `IgorWarzocha/Opencode-Roadmap` | Planning helper | low-medium | unknown | medium | defer | Lower operator value than memory/skills/ignore |
| B4 | `shekohex/opencode-pty` | PTY/session management | medium-high | likely | high | defer | Powerful but PTY/runtime edges make it a poor first Termux package |
| B4 | `tickernelz/opencode-mem` | Persistent memory alternative | medium | unknown | medium-high | defer | Competes with stronger `agent-memory` candidate |
| B4 | `smartfrog/opencode-froggy` | Hooks/agents/tool bundle | medium | unknown | high | defer | Feature overlap and likely maintenance sprawl |
| Skip | `malhashemi/opencode-skills` | Archived skills plugin | medium-high | likely | medium | skip | Archived; replaced by stronger active skills candidates |
| Skip | `shekohex/opencode-google-antigravity-auth` | Archived antigravity fork | medium | likely | medium | skip | Archived and superseded by stronger antigravity candidates |
| Skip | `theblazehen/opencode-antigravity-multi-auth` | Archived antigravity multi-auth fork | low-medium | likely | medium | skip | Archived overlap |
| Skip | `activadee/opencode-auth-sync` | Auth secret sync | low | likely | high | skip | Archived and CI/secrets-heavy |
| Skip | `sting8k/opencode-codex-plugin` | Codex proxy bridge | low | weak | high | skip | Archived; Python proxy burden |

## Batch sequencing
0. **Starter batch: packaging-first utility canary**
   - Goal: land one low-risk, source-buildable, immediately useful plugin to validate the packaging lane.
   - Status: complete with **S0a** `opencode-websearch-cited`.
1. **Batch 1: low-risk utility/safety lane**
   - Goal: land stateless or near-stateless JS/TS plugins with high operator value.
   - Status: active/mostly landed with `opencode-rules`, `envsitter-guard`, `opencode-snippets`, and `opencode-plugin-openspec`.
2. **Batch 2: medium-risk utility lane**
   - Goal: add useful but slightly more behavior-shaping or integration-heavy utilities.
   - Status: core lane landed with `opencode-mystatus`, `opencode-handoff`, `opencode-model-announcer`, and `opencode-plugin-openspec`; `type-inject`, `opencode-morph-fast-apply`, and `opencode-direnv` remain optional follow-ons.
3. **Batch 3: provider/auth expansion**
   - Goal: widen useful provider coverage with the strongest, most demanded source-buildable auth plugins.
   - Sequence internally as **B3a** `opencode-antigravity-auth`, **B3b** `opencode-gemini-auth`, **B3c** `opencode-openai-codex-auth`.
4. **Batch 4: stateful/deferred watchlist**
   - Goal: keep higher-maintenance or more stateful plugins behind the simpler utility and auth lanes.

## Immediate recommendation
- Start with **Starter batch S0** first, then move into **Batch 1**.
- First implementation target should be `ghoulr/opencode-websearch-cited` because it combines operator value, source-build simplicity, and low Termux-specific risk.
- Current integrated-from-source set now also includes `opencode-rules`, `envsitter-guard`, `opencode-snippets`, and `opencode-plugin-openspec` with successful local deb + pacman builds.
- Suggested **next round after this**: `opencode-direnv` or `type-inject`, then `opencode-morph-fast-apply` if you want more workflow tooling before the auth lane.
- After Batch 3 lands, choose **either** `NoeFabris/opencode-antigravity-auth` **or** `andyvandaric/opencode-ag-auth` as the long-term antigravity lane; do not maintain both unless there is a clear user-segment split.
- Treat `agent-memory` and `agent-skills` as later, stateful follow-ups rather than early utility wins.

## Packaging hardening checkpoint (insert before further expansion)

Before adding another plugin batch, run a hardening pass across current plugins:

1. **Audit install surfaces**
   - Distinguish between:
     - plugin entry only
     - `command/` payloads
     - `skill/` or `skills/`
     - `bin` / CLI entrypoints
     - package-specific assets (`schema/`, bundled templates, etc.)
2. **Stop shipping whole repos by default**
   - Current source-first staging often preserves far more than npm package `files` would publish.
   - Move toward manifest-driven staging (`package.json files` + explicitly required extras).
3. **Make runtime self-contained where needed**
   - `tsc`-only plugins with runtime deps are at risk of packaging JS without the needed dependency closure.
   - Prefer bundling where possible, or explicitly vendor the runtime dependency tree.
4. **Do not create `/usr/bin` shims blindly**
   - In Termux, CLI wrappers belong under `$PREFIX/bin` (`/data/data/com.termux/files/usr/bin`), not `/usr/bin`.
   - Some npm `bin` entrypoints assume optional platform packages or npm-managed dependency installation.
   - Example: `oh-my-opencode` bin expects platform binary packages; `opencode-qwen-auth` CLI expects dependencies like `prompts`.
   - A package-side bin shim should only be generated after the CLI is proven self-contained in the packaged layout.
5. **Only after hardening**, continue with the next candidate lane (`direnv`, `type-inject`, `morph-fast-apply`).

Current state:

- `oh-my-opencode` hardening has moved from shell-embedded full-file rewrites to an adaptive
  build-time patcher with explicit patch summary lines.
- The patcher successfully applied all required patches against a clean `v3.11.0` source clone.
- The approach is safer than before, but still path-sensitive across major upstream restructures.

## Risks
- Auth plugins are high-value but can break due to upstream OAuth/API changes.
- Some utility plugins may overlap with OMO functionality and create maintenance duplication.
- Termux notification/process-heavy plugins may need per-device behavior checks.

## Notable exclusions from planning
- Built-in/core-integrated old plugins are intentionally excluded from new maintenance work.
- Generic ecosystem resources (`awesome-opencode`, docs/gists) are references, not packaging targets.

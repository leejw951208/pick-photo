# Plan Review

Review the implementation plan before editing code or product documents.

Treat plan review as Codex internal self-review unless the user explicitly requires human approval. After an internal `Approved` review, ask the user to confirm before implementation only for high-impact work: security-sensitive changes, public API or exported interface changes, data/schema changes, package metadata or dependency changes, runtime/config/deployment changes, filesystem/command/network exposure, unresolved product decisions, destructive file operations, or when the user requested confirmation.

If `AGENTS.md` has a stricter confirmation rule, follow `AGENTS.md`.

## Review Criteria

- The plan satisfies the requested outcome with the smallest reviewable change.
- The plan aligns with `PRD.md` product intent, requirements, scope, and open decisions when present.
- The plan is based on verified repository facts, not assumptions.
- The plan preserves existing language, runtime, package manager, module, source layout, app-shape, security, and compatibility patterns.
- The plan identifies connected product behavior, UI, APIs, contracts, exported interfaces, data, config, docs, and tests.
- The plan preserves independent project boundaries unless an explicit contract change coordinates them.
- The plan uses only verified validation commands.
- Security-sensitive work includes `security.md` checks.
- Language/runtime-sensitive work includes `language-runtime.md` checks.
- Human-facing plan and review docs outside `.agents/` are in Korean.
- No unrelated refactor is included.

## Pick Photo-Specific Checks

- Selected faces remain the only generation targets.
- Original-photo direct face selection remains the primary face review interaction when changing face selection UX.
- Fresh Clarity changes remain visual-only unless the plan explicitly covers product, API, AI, database, or privacy behavior.
- Privacy, retention, deletion, logging, and consent promises are not invented while those policies remain open.
- `selected_faces` schema compatibility is addressed before relying on PostgreSQL persistence for multi-face selected generation.

## Decision

Return exactly one decision:

- `Approved`: Implementation may begin after any required user confirmation.
- `Needs revision`: Revise the plan before implementation.
- `Blocked`: Record the blocker and do not implement.

## Output

Include:

- Decision
- Reasons
- Required revisions or blockers
- Approved implementation scope, if approved

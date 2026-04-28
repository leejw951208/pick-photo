# Plan Review

Review the implementation plan before editing code.

Treat plan review as Codex internal self-review unless the user explicitly requires human approval. After an internal `Approved` review for substantial work, ask the user to confirm before implementation.

## Review Criteria

- The plan satisfies the requested outcome with the smallest reviewable change.
- The plan aligns with existing `PRD.md` product intent, requirements, scope, and open decisions when present.
- The plan is based on verified repository facts, not assumptions.
- The plan preserves existing language, runtime, package manager, module, source layout, app-shape, security, and compatibility patterns.
- The plan identifies connected product behavior, APIs, exported interfaces, data, config, docs, and test impacts.
- The plan uses only verified validation commands.
- Security-sensitive work includes `security.md` checks.
- Language/runtime-sensitive work includes `language-runtime.md` checks.
- Human-facing plan and review docs outside `.agents/` are in Korean.
- No unrelated refactor is included.

## Decision

Return exactly one decision:

- `Approved`: Implementation may begin after user confirmation.
- `Needs revision`: Revise the plan before implementation.
- `Blocked`: Record the blocker and do not implement.

## Output

Include:

- Decision
- Reasons
- Required revisions or blockers
- Approved implementation scope, if approved

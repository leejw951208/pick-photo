# Feature Progress Tracking

Use this reference for substantial feature work, multi-requirement changes, user-flow changes, API/CLI behavior changes, or work with several deliverables.

For a small single-feature change, use one compact line with status and validation. For work with no feature dimension, state that feature progress tracking is not applicable.

## Status Values

Use only these status values:

- `Not started`: The feature is in scope, but no implementation work has begun.
- `In progress`: Implementation or validation work has started.
- `Blocked`: Work cannot continue without a decision, dependency, access, missing information, failing prerequisite, or unresolved technical issue.
- `Complete`: Implementation review and required validation are complete for this feature.

## Progress Values

Progress values are optional. Prefer status, blocker, and validation evidence over percentages. If progress helps summarize multi-feature work, use these evidence-based values:

- `0%`: Not started.
- `50%`: Implementation has started, but behavior is incomplete or unreviewed.
- `75%`: Implementation is complete, but review or validation remains.
- `100%`: Implementation review and validation are complete.

Do not use decorative percentages. For `Blocked`, the blocker and next action matter more than the percentage.

## Where To Track

Use the existing documentation layout first:

- For `docs/superpowers/plans/**` work, keep feature progress in the relevant Korean plan or review section.
- For `docs/superpowers/specs/**` work, map progress to the matching plan when implementation begins.
- For contract changes, include requirement-to-validation mapping in the Korean plan or review note and update the relevant `docs/contracts/**` file.
- Use `docs/features/<feature-slug>/progress.md` only when no existing repo-local documentation location fits and a fallback feature directory is created.

Use a short list or this table shape, whichever is clearer. Include `Progress` only when it adds useful signal.

```markdown
## Feature Progress

| Feature ID | Feature / behavior | Status | Requirements | Validation / tests | Blocker / next action |
| --- | --- | --- | --- | --- | --- |
| F-001 | <feature or behavior> | Not started | FR-001, AC-001 | <test command, test name, or manual check> | <none or blocker> |
```

## Mapping Rules

- Every in-scope feature must map to at least one PRD requirement, acceptance criterion, open decision, or explicit user-requested requirement.
- Every `Complete` feature must map to validation evidence: an automated command, test name, or manual validation step.
- Follow `06-testing.md` for verified validation command rules; when no verified test command exists, record manual validation steps for each completed feature.
- If a feature cannot be mapped to a requirement or user request, pause and clarify scope before implementing it.
- Do not mark a feature `Complete` while it has unresolved blockers, missing validation, or unreviewed plan divergence.

## Update Points

Update feature progress at practical checkpoints:

- in the implementation plan for substantial multi-feature work
- in the existing `docs/superpowers/plans/**` document when that is the relevant plan location
- in `docs/features/<feature-slug>/progress.md` only when a fallback feature document directory exists
- when a feature becomes blocked or scope changes
- after implementation review or validation when status changes
- in the final Korean change summary when feature tracking was used

# Feature Progress Tracking

Use this reference for substantial feature work, multi-requirement changes, user-flow changes, API/CLI behavior changes, or work with several deliverables.

For a very small single-feature change, keep the tracking compact. For work with no feature dimension, state that feature progress tracking is not applicable.

## Status Values

Use only these status values:

- `Not started`: The feature is in scope, but no implementation work has begun.
- `In progress`: Implementation or validation work has started.
- `Blocked`: Work cannot continue without a decision, dependency, access, missing information, failing prerequisite, or unresolved technical issue.
- `Complete`: Implementation review and required validation are complete for this feature.

## Progress Values

Use evidence-based progress values. Do not use decorative percentages.

- `0%`: Not started.
- `25%`: Scope is understood, affected files are identified, and the implementation path is planned.
- `50%`: Implementation has started, but behavior is incomplete or unreviewed.
- `75%`: Implementation is complete, but review or validation remains.
- `100%`: Implementation review and validation are complete.

`Blocked` may use the most accurate current percentage, but the blocker and next action must be recorded.

## Required Section

For substantial feature work, keep a `Feature Progress` section in the implementation plan, review notes, or change summary.

Use this table shape unless a shorter equivalent is clearer:

```markdown
## Feature Progress

| Feature ID | Feature / behavior | Status | Progress | Requirements | Validation / tests | Blocker / next action |
| --- | --- | --- | --- | --- | --- | --- |
| F-001 | <feature or behavior> | Not started | 0% | FR-001, AC-001 | <test command, test name, or manual check> | <none or blocker> |
```

## Mapping Rules

- Every in-scope feature must map to at least one PRD requirement, acceptance criterion, open decision, or explicit user-requested requirement.
- Every `Complete` feature must map to validation evidence: an automated command, test name, or manual validation step.
- If no verified test command exists, write `No verified test command found` and record manual validation steps for each completed feature.
- If a feature cannot be mapped to a requirement or user request, pause and clarify scope before implementing it.
- Do not mark a feature `Complete` while it has unresolved blockers, missing validation, or unreviewed plan divergence.

## Update Points

Update feature progress:

- after the implementation plan is drafted
- when work starts on a feature
- when a feature becomes blocked
- when implementation for a feature is complete
- after implementation review
- after validation
- before the final response

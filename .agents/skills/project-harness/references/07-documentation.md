# Documentation

Review documentation after testing or after documentation-only changes.

## Documentation Impact

Check whether repo-local docs need updates when the change affects:

- product intent, requirements, scope, users, use cases, or open decisions
- user-visible behavior
- setup or run instructions
- package scripts or validation commands
- public APIs, exported interfaces, CLI usage, or integration contracts
- environment variables or configuration
- deployment or operations
- schema, migration, seed, or fixture workflow
- security-sensitive behavior or boundaries

## Rules

- Write `.agents/**` operational guidance in English.
- Write human-facing documents outside `.agents/` in Korean, including PRDs, product docs, feature docs, implementation plans, feature progress tracking, review docs, change summaries, and commit messages.
- Preserve the existing repo-local documentation layout before using fallback layouts.
- Current repo-local documentation layout:
  - `PRD.md`: root-level Korean product baseline.
  - `README.md`: root local setup and validation overview.
  - `apps/*/README.md`: app-specific run, env, and validation notes.
  - `database/README.md` and `database/seeds/README.md`: database schema and seed guidance.
  - `docs/contracts/**`: API, AI service, data model, and privacy contracts.
  - `docs/superpowers/specs/**`: design and system specifications.
  - `docs/superpowers/plans/**`: implementation plans and progress-oriented plans.
  - `docs/superpowers/mockups/**`: visual mockup artifacts and index notes.
- Use `docs/features/<feature-slug>/` only when no existing repo-local documentation location fits the work.
- Keep root `PRD.md` separate from feature folders.
- Format commit messages as `<commit type>: <Korean message>` on `main` or `dev`; use `[<branch>]<commit type>: <Korean message>` on any other branch.
- During harness generation, do not create, modify, overwrite, rewrite, or delete `AGENTS.md` or `PRD.md`.
- For future separate PRD tasks, write `PRD.md` in Korean and keep it product-only.
- Do not document unverified tools, services, commands, frameworks, languages, runtimes, or deployment paths as facts.
- If a decision remains open, write `Decision needed` or `To be defined`.
- Do not create broad docs when a small update to existing docs is enough.

## Fallback Feature Documentation Layout

Use existing repo conventions first. When none fit, use only the files needed for the work:

```text
docs/features/<feature-slug>/
|-- spec.md
|-- plan.md
|-- tasks.md
|-- progress.md
|-- review.md
`-- contracts/
```

- `PRD.md`: root-level product baseline for product intent, scope, and completion criteria.
- `spec.md`: feature-specific user scenarios, requirements, acceptance criteria, edge cases, assumptions, and success criteria.
- `plan.md`: implementation approach, impacted files, repo evidence, validation, documentation impact, rollback or containment, and open decisions.
- `tasks.md`: actionable checklist with stable task IDs such as `T001`; use `[P]` only for parallel-safe tasks, user-story labels such as `[US1]` when applicable, and exact file paths when tasks change files.
- `progress.md`: feature status, requirement-to-validation mapping, blockers, and next actions.
- `review.md`: implementation review findings, fixes applied, residual risks, and validation readiness.
- `contracts/`: create only for API, CLI, event, webhook, import/export, or external integration contracts.

## Output

State whether documentation needs a Korean update. If no update is needed, state why.

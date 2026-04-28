# Documentation

Review documentation after testing.

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

- Write `AGENTS.md` and `.agents/**` operational guidance in English.
- Write human-facing documents outside `.agents/` in Korean, including PRDs, product docs, feature docs, implementation plans, review docs, change summaries, and commit messages.
- Format commit messages as `<commit type>: <Korean message>` on `main` or `dev`; use `[<branch>]<commit type>: <Korean message>` on any other branch.
- During harness generation, do not create, modify, overwrite, rewrite, or delete `PRD.md`.
- For future separate PRD tasks, write `PRD.md` in Korean.
- Do not document unverified tools, services, commands, frameworks, languages, runtimes, or deployment paths as facts.
- If a decision remains open, write `Decision needed` or `To be defined`.
- Do not create broad docs when a small update to existing docs is enough.

## Output

State whether documentation needs a Korean update. If not, state why no update is needed.

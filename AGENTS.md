# Project Harness

## Repository Facts

- Repository root: `/Users/leejinwoo/mine/pick-photo`.
- Repository state at harness creation: no repository-local source files, product docs, project metadata, lockfiles, toolchain config, env examples, Docker files, CI workflows, or VCS metadata were present.
- Product reference: `PRD.md` is the product intent and requirements baseline for future work.
- Canonical local harness path: `.agents/skills/project-harness/SKILL.md`.
- System design document: `docs/superpowers/specs/2026-04-28-pick-photo-system-design.md`.
- Implementation plan documents: `docs/superpowers/plans/2026-04-28-pick-photo-master.md`, `docs/superpowers/plans/2026-04-28-pick-photo-flutter-app.md`, `docs/superpowers/plans/2026-04-28-pick-photo-nestjs-server.md`, `docs/superpowers/plans/2026-04-28-pick-photo-python-ai-server.md`, and `docs/superpowers/plans/2026-04-28-pick-photo-database.md`.
- Languages and runtimes: Decision needed. No repository-local project files currently verify Flutter/Dart, Node.js/NestJS, Python, PostgreSQL tooling, package managers, framework versions, test runners, linters, formatters, or build tools.
- App shape: Decision needed. The intended shape is a multi-project system, but no repository-local app folders or entrypoints exist yet.
- Verified validation commands: No verified test command found.

## Product Reference

- Read `PRD.md` before all product or engineering work.
- Treat `PRD.md` as the baseline for product intent, users, requirements, scope, and open product decisions.
- Do not treat unresolved PRD decisions as verified repository facts.
- When implementation creates or changes product behavior, API behavior, data models, configuration, security boundaries, setup steps, or validation commands, update `PRD.md` and this file as needed.

## Project Decisions To Define

- Decision needed: repository initialization policy, branch strategy, CI policy, and code ownership boundaries.
- Decision needed: exact independent project folder names for the Flutter app, NestJS server, Python AI server, database assets, infrastructure, and shared documentation.
- Decision needed: package managers and runtime versions for Dart/Flutter, Node.js/NestJS, Python, and PostgreSQL tooling.
- Decision needed: NestJS API contract, authentication policy, upload policy, job orchestration, storage strategy, data retention policy, and error model.
- Decision needed: Python AI service model stack, face detection/selection pipeline, ID photo generation pipeline, model artifact storage, inference hardware expectations, and service interface.
- Decision needed: PostgreSQL schema, migration tool, ORM or query layer, transaction policy, and seed/fixture workflow.
- Decision needed: local development, testing, build, lint, formatting, e2e, Docker, deployment, observability, and operations commands.
- Decision needed: privacy, consent, personal data handling, image retention, deletion, logging redaction, and compliance requirements for uploaded photos and generated ID photos.

## Always-On Rules

- Stay inside the repository root. Do not read, write, modify, summarize, merge, or clean up files outside this repository.
- Read `AGENTS.md` and `PRD.md` before all work.
- Follow verified repository-local language, runtime, package manager, module, source layout, app-shape, error handling, configuration, and test patterns once they exist.
- Do not assume a framework, ORM, test runner, build tool, formatter, deployment target, cloud, database, external service, or command unless verified inside the repository or explicitly requested for a new implementation plan.
- Keep the three intended application areas independent unless a future approved plan defines a shared contract: Flutter client, NestJS application server, and Python AI service.
- Keep changes small and reviewable. Do not perform unrelated refactors.
- For substantial work, use `.agents/skills/project-harness/SKILL.md` before implementation.
- Do not implement substantial changes before product thinking, implementation planning, and plan review are complete.
- Treat plan review as Codex internal self-review unless the user explicitly requires human approval.
- After an internal `Approved` plan review for substantial work, ask the user to confirm before implementation.
- Do not proceed from plan review to implementation unless the plan review result is `Approved`.
- If implementation must materially diverge from the approved plan, stop and get user confirmation before continuing.
- Keep implementation plans aligned with `PRD.md`; if the plan conflicts with `PRD.md`, update the plan or record the decision before implementing.
- Do not invent product requirements that are absent from `PRD.md`, repository evidence, or explicit user direction.
- Preserve authentication, authorization, validation, security boundaries, type safety, runtime safety, error handling, and tests.
- Treat uploaded photos, detected faces, generated ID photos, embeddings, metadata, logs, and model outputs as personal or sensitive data unless a future policy states otherwise.
- Use only verified repository commands for testing or validation. If none are verified, report `No verified test command found`.
- Do not treat commands listed in `Project decisions to define` as verified while they are unresolved, stale, conflicting, missing, `Decision needed`, or `To be defined`.
- When changing product behavior, user-facing behavior, APIs, configuration behavior, workflows, requirements, or scope, check whether `PRD.md` must be updated.

## Skill Entrypoint

Use `.agents/skills/project-harness/SKILL.md` for substantial product or engineering work. Use `PRD.md` as the product baseline.

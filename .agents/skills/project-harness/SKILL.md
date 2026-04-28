---
name: project-harness
description: Use this skill for substantial product or engineering work in this repository, including product thinking, PRD alignment when PRD.md exists, architecture decisions, implementation planning, plan review, plan-based execution, implementation review, testing, documentation updates, and security-sensitive changes. Use it before changing product behavior, runtime behavior, APIs, exported interfaces, module boundaries, package metadata, configuration, environment variables, filesystem access, command execution, network exposure, authentication, authorization, data storage, or external integrations. Always read AGENTS.md first and PRD.md when it exists. It preserves verified repository facts and keeps language, runtime, framework, build, test, and deployment rules conditional on evidence found inside this repository.
---

# Project Harness

## Required Context

Read `AGENTS.md` first for all work. Read `PRD.md` when it exists. Treat `Repository facts` as verified local evidence. Treat an existing `PRD.md` as product intent, scope, requirements, and open-decision context.

Stay inside the repository root. Do not read, write, or modify files outside this repository.

Write `.agents/**` skill files and `AGENTS.md` in English. Write human-facing documents outside `.agents/` in Korean, including PRDs, product docs, feature docs, implementation plans, review docs, change summaries, and commit messages. Format commit messages as `<commit type>: <Korean message>` on `main` or `dev`; use `[<branch>]<commit type>: <Korean message>` on any other branch.

## Workflow

For substantial work, follow this sequence:

1. Read `AGENTS.md`.
2. Read `PRD.md`, if present.
3. Read `references/01-product-thinking.md`.
4. Read `references/02-implementation-planning.md`.
5. Read `references/03-plan-review.md`.
6. Do not implement unless plan review is `Approved`.
7. Ask the user to confirm the approved plan before implementation.
8. Read `references/04-plan-execution.md` and implement from the approved plan.
9. Read `references/05-implementation-review.md`.
10. Read `references/06-testing.md`.
11. Read `references/07-documentation.md`.
12. Read `references/language-runtime.md` when touching language, runtime, compiler/interpreter, package metadata, build, module, dependency, public interface, CLI, API, config, or app-shape behavior.
13. Read `references/security.md` as soon as work touches authentication, authorization, secrets, env/config, filesystem access, command execution, network exposure, external APIs, payment, personal data, token/session/cookie handling, upload/download, sensitive logging, CORS, server-side execution boundaries, webhooks, or background jobs.

Small work must still read `AGENTS.md` first and `PRD.md` when present, then only the references needed for the change.

## Stop Conditions

- If plan review is `Needs revision`, update the plan before implementation.
- If plan review is `Blocked`, record the blocker and do not implement.
- If the implementation plan conflicts with existing `PRD.md`, update the plan or record the decision before implementing.
- If implementation must materially diverge from the approved plan, stop and update the plan before continuing.
- Do not report testing complete before implementation review and verified validation are complete.
- If no verified test command exists, report `No verified test command found` and provide manual validation steps.

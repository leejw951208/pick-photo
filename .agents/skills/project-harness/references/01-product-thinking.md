# Product Thinking

Use this step before planning or implementing substantial work.

## Define The Change

- State the user-visible or operator-visible outcome.
- Identify affected users, workflows, UI, APIs, CLI behavior, library consumers, jobs, integrations, or configuration.
- Separate required behavior from optional improvements.
- Name the smallest useful change that satisfies the request.

## Align With PRD

- Read `PRD.md` before deciding product behavior.
- Use verified product facts, requirements, scope, and open decisions from `PRD.md`.
- Do not invent users, business rules, product goals, or features that are absent from `PRD.md` and repository evidence.
- If `PRD.md` conflicts with repository evidence, prefer repository evidence and record the conflict as `Decision needed`.

## Identify Risk

- Mark security-sensitive work early and read `security.md`.
- Mark language/runtime or compatibility-sensitive work and read `language-runtime.md`.
- Check whether the change touches public APIs, exported interfaces, request/response contracts, CLI behavior, configuration behavior, data shape, package metadata, module boundaries, generated types, or user data.

## Output

Produce a short product note:

- Goal
- Non-goals
- PRD alignment
- Verified repository context
- Risks and security-sensitive areas
- Open decisions

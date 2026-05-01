# Product Thinking

Use this reference before planning or implementing substantial product, UI, API, data, workflow, or configuration work.

## Product Baseline

- Read `PRD.md` when it exists.
- Treat `PRD.md` as the source for product intent, users, requirements, acceptance criteria, non-goals, assumptions, risks, and open product questions.
- Keep `PRD.md` product-only; technical details belong in contracts, implementation plans, review notes, or harness guidance.
- Do not create or modify `PRD.md` unless the user explicitly asks for a separate PRD task.
- Do not treat unresolved PRD questions as verified repository facts.

## Pick Photo Product Facts

- The core flow is photo upload, face detection, face selection, ID-photo style generation, result review, failure recovery, and restart with a new photo.
- Results must be generated only for selected faces.
- Users must understand which faces are selected before generation.
- Face and photo data are sensitive personal data.
- The app must make upload, detection, generation, completion, failure, and retry states understandable.
- One-photo-per-flow is the current product assumption.
- Official country-specific ID-photo compliance, account-based long-term storage, payment, and editing tools are outside the current PRD scope unless a new product decision changes them.

## Current Experience Anchors

- Face review should prioritize original-photo direct face selection, with zoom/pan assistance for dense or small faces and a bottom selection summary instead of using a lower face list as the primary selection control.
- The selected UI direction is Fresh Clarity: bright mint/blue, clearer status hierarchy, confidence-building chips and banners, and stronger result/failure states.
- Fresh Clarity is a visual direction only; it must not imply new retention, deletion, API, AI, database, or policy behavior.

## Define The Change

- State the user-visible or operator-visible outcome.
- Identify affected users, workflows, UI, APIs, contracts, background work, integrations, or configuration.
- Separate required behavior from optional polish.
- Name the smallest useful change that satisfies the request.
- Map new behavior to a PRD requirement, acceptance criterion, open decision, repository fact, or explicit user request.

## Identify Risk

- Mark security-sensitive work early and read `security.md`.
- Mark language/runtime or compatibility-sensitive work and read `language-runtime.md`.
- Check whether the change touches public APIs, request/response contracts, generated/client types, database schema, configuration behavior, sensitive data, or user-facing policy language.
- If a PRD decision is unresolved, record `Decision needed` instead of filling the gap with product promises.

## Output

For human-facing notes outside `.agents/`, write in Korean and include:

- Goal
- Non-goals
- PRD alignment
- Verified repository context
- Security-sensitive areas
- Open decisions

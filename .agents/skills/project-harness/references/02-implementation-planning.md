# Implementation Planning

Create a plan before substantial implementation.

## Plan From Evidence

- Read the files directly involved in the change.
- Use existing language, runtime, module, source layout, naming, error handling, validation, testing, and documentation patterns.
- Keep language, runtime, framework, app-shape, build, test, deployment, and cloud rules conditional on verified repository evidence.
- Prefer existing dependencies and local helpers over new abstractions or packages.
- Keep the plan aligned with existing `PRD.md` when present.
- Write implementation plans in Korean when they are outside `.agents/`.

## Plan Contents

Include:

- Scope and non-scope
- Existing PRD requirements or open decisions involved, if any
- Files or modules likely to change
- Product behavior, API, CLI, configuration, data, type/interface, package metadata, or schema impacts
- Feature progress tracking when the work has distinct features, requirements, user flows, API/CLI behaviors, or multi-step deliverables
- Security-sensitive impacts and required `security.md` checks
- Language/runtime impacts and required `language-runtime.md` checks
- Test and validation commands verified from repository files
- Documentation impact and whether a separate Korean product-doc update is needed
- Rollback or containment notes for risky changes

## Output

Write a concise implementation plan that can be reviewed before code changes. When feature progress tracking applies, include a `Feature Progress` section using `08-feature-progress.md`.

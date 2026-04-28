# Implementation Planning

Create a plan before substantial implementation.

## Plan From Evidence

- Read the files directly involved in the change.
- Use existing language, runtime, module, source layout, naming, error handling, validation, testing, and documentation patterns.
- Keep language, runtime, framework, app-shape, build, test, deployment, and cloud rules conditional on verified repository evidence.
- Prefer existing dependencies and local helpers over new abstractions or packages.
- Keep the plan aligned with `PRD.md`.

## Plan Contents

Include:

- Scope and non-scope
- PRD requirements or open decisions involved
- Files or modules likely to change
- Product behavior, API, CLI, configuration, data, type/interface, package metadata, or schema impacts
- Security-sensitive impacts and required `security.md` checks
- Language/runtime impacts and required `language-runtime.md` checks
- Test and validation commands verified from repository files
- Documentation and PRD impact
- Rollback or containment notes for risky changes

## Output

Write a concise implementation plan that can be reviewed before code changes.

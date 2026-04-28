# Testing

Run validation only with commands verified in `AGENTS.md`, project metadata, README, repo-local docs, or CI.

Do not treat commands listed in `AGENTS.md` `Project decisions to define` as verified while they are unresolved, stale, conflicting, missing, `Decision needed`, or `To be defined`.

## Test Selection

- Prefer the narrowest verified command that covers the change.
- Broaden validation when touching shared behavior, product behavior, API contracts, exported interfaces, schemas, package metadata, build output, module boundaries, auth, filesystem access, command execution, network exposure, or external integrations.
- Do not invent test commands.

## If No Command Is Verified

Write:

`No verified test command found`

Then provide manual validation steps based on the changed behavior.

## Before Reporting Completion

- Confirm implementation review is complete.
- Confirm every completed in-scope feature has an automated validation command, test name, or explicit manual validation step recorded.
- Report commands run and results.
- Report commands not run and why.
- Include manual checks for behavior that automated tests do not cover.

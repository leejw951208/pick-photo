# Testing

Run validation only with commands verified in `AGENTS.md`, project metadata, README, repo-local docs, or CI.

Do not treat commands listed as unresolved, stale, conflicting, missing, `Decision needed`, or `To be defined` as verified.

## Verified Commands

AI server:

```bash
cd apps/ai && .venv/bin/python -m pytest -q
```

Backend:

```bash
cd apps/backend && npm run prisma:generate
cd apps/backend && npm test
cd apps/backend && npm run test:e2e
cd apps/backend && npm run build
```

Flutter mobile:

```bash
cd apps/mobile && mise x flutter@3.22.1-stable -- flutter test
cd apps/mobile && mise x flutter@3.22.1-stable -- dart format lib test
```

Docker local runtime:

```bash
docker compose config
docker compose build
docker compose up -d
docker compose ps
docker compose exec -T postgres psql -U pick_photo -d pick_photo -c "select count(*) as tables from information_schema.tables where table_schema = 'public';"
```

## Test Selection

- Prefer the narrowest verified command that covers the change.
- Use Flutter tests and Dart format for Flutter UI or photo-flow changes.
- Use backend unit/e2e/build commands for NestJS API, DTO, repository, Prisma, Swagger, storage, AI adapter, or contract changes.
- Use AI pytest for FastAPI, local AI, fake AI, schemas, storage, and image-generation changes.
- Use Docker validation when Compose service wiring, env vars, ports, shared storage, PostgreSQL startup, or cross-service runtime behavior changes.
- Broaden validation when touching shared behavior, product behavior, API contracts, schemas, package metadata, build output, module boundaries, auth, filesystem access, command execution, network exposure, or external integrations.
- Do not invent test commands.

## Manual Checks

When automated tests do not cover the behavior, record manual checks for:

- Mobile layout and text fit across relevant viewport/device sizes.
- Direct face selection, zoom/pan, selected/excluded labels, and selection summary behavior.
- Upload, detection, generation, result, failure, and restart state transitions.
- Privacy-facing language, especially any retention or deletion claims.
- Cross-service behavior that cannot be exercised by the available local command set.

## If No Command Is Verified

Write:

`No verified test command found`

Then provide manual validation steps based on the changed behavior.

## Before Reporting Completion

- Confirm implementation review is complete.
- When feature progress tracking applies, confirm the completion rules in `08-feature-progress.md` are satisfied.
- Report commands run and results.
- Report commands not run and why.
- Include manual checks for behavior that automated tests do not cover.

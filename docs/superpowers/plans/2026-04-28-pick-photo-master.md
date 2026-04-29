# Pick Photo Master Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

## 진행 현황 (2026-04-28)

- 완료: 계약 문서, PostgreSQL 초기 스키마, Python AI fake 서버, NestJS API/Swagger/fake 워크플로, Flutter 업로드/얼굴 선택/생성 요청 흐름, `apps/mobile`, `apps/backend`, `apps/ai` 폴더 구조 정리.
- 완료: NestJS 백엔드 업로드 로컬 저장, `DATABASE_URL` 기반 Prisma 7 PostgreSQL 저장소 어댑터, `AI_SERVICE_BASE_URL` 기반 Python AI 서버 HTTP 어댑터 연결.
- 완료: Python AI 서버 기본 동작을 OpenCV/Pillow 로컬 이미지 처리로 전환하고, fake 모드는 `PICK_PHOTO_AI_MODE=fake`로 유지.
- 완료: Docker Compose로 PostgreSQL, Python AI 서버, NestJS 백엔드를 함께 실행하는 로컬 통합 환경 구성.
- 다음 예정: 생성 결과 이미지 제공/다운로드, 모바일 결과 이미지 미리보기와 저장 UX, 개인정보 동의/보관/삭제 실행, 운영 문서와 반복 가능한 migration runner.
- 참고: `PRD.md`는 서비스 정의 문서이므로 진행 상태와 기술 구현 내용은 이 계획 문서와 계약 문서에만 기록한다.

**Goal:** Establish the multi-project Pick Photo foundation and connect the first upload-to-result workflow through explicit contracts.

**Architecture:** Keep the Flutter app, NestJS server, Python AI server, and PostgreSQL assets in independent folders. Cross-project behavior is coordinated through documented contracts in `docs/contracts` rather than shared code.

**Tech Stack:** Flutter 3.22.1 / Dart 3.4.1, NestJS 11 with npm, Prisma 7 PostgreSQL driver adapter, Python 3.12 / FastAPI, and PostgreSQL SQL migrations. Verified versions and validation commands are recorded in `AGENTS.md`.

---

## Plan Notes

- Current repository state: contract documents, database assets, Flutter app, NestJS server, and Python AI server exist.
- Verified validation commands are recorded in `AGENTS.md`.
- Git is initialized and connected to `https://github.com/leejw951208/pick-photo.git` on `main`.
- The first foundation pass, the local OpenCV/Pillow AI slice, Docker Compose local runtime, and Docker-based local PostgreSQL init validation are complete. Remaining work is result image serving/download, mobile result preview/save UX, production model selection, retention/deletion execution, operations documentation, and a production-grade migration workflow.
- Execute subsystem plans in this order unless a blocker appears:
  1. `docs/superpowers/plans/2026-04-28-pick-photo-database.md`
  2. `docs/superpowers/plans/2026-04-28-pick-photo-python-ai-server.md`
  3. `docs/superpowers/plans/2026-04-28-pick-photo-nestjs-server.md`
  4. `docs/superpowers/plans/2026-04-28-pick-photo-flutter-app.md`

## Feature Progress

| Feature ID | Feature / behavior | Status | Progress | Requirements | Validation / tests | Blocker / next action |
| --- | --- | --- | --- | --- | --- | --- |
| F-001 | 계약 문서와 프로젝트 구조 기반 | Complete | 100% | PRD 전체 첫 구현 범위 | `find docs/contracts -maxdepth 1 -type f \| sort` | none |
| F-002 | PostgreSQL 초기 데이터 모델과 SQL migration | Complete | 100% | NFR-006, workflow status requirements | `database/migrations/001_initial_schema.sql` 검토 | none |
| F-003 | Python AI HTTP 계약과 fake fallback | Complete | 100% | FR-002, FR-007 | `cd apps/ai && .venv/bin/python -m pytest -q` | none |
| F-004 | NestJS public API, upload storage, AI/Prisma DB adapters | Complete | 100% | FR-001, FR-002, FR-005, FR-006, FR-007, FR-008, FR-009, FR-010 | `cd apps/backend && npm run prisma:generate`; `cd apps/backend && npm test`; `cd apps/backend && npm run test:e2e`; `cd apps/backend && npm run build` | none |
| F-005 | Flutter upload, face review, single/all generation request, result URL list | Complete | 100% | FR-001, FR-003, FR-004, FR-005, FR-006, FR-009, FR-010, FR-012, NFR-007 | `cd apps/mobile && mise x flutter@3.22.1-stable -- flutter test`; `cd apps/mobile && mise x flutter@3.22.1-stable -- dart format lib test` | none |
| F-006 | OpenCV/Pillow 기반 로컬 얼굴 감지와 413x531 JPEG 생성 | Complete | 100% | FR-002, FR-003, FR-004, FR-007, FR-008, NFR-001, NFR-002, NFR-006 | `cd apps/ai && .venv/bin/python -m pytest -q` | none |
| F-007 | 생성 결과 이미지 제공/다운로드 API | Not started | 0% | FR-011, AC-007 | No verified test command yet | 다음 구현 대상 |
| F-008 | 모바일 실제 이미지 미리보기와 저장 UX | Not started | 0% | FR-011, AC-007, NFR-007 | No verified test command yet | F-007 이후 진행 |
| F-009 | 개인정보 동의, 보관, 삭제 UX와 cleanup 실행 | Blocked | 25% | FR-013, AC-011, NFR-006 | No verified test command yet | 보관 기간, 삭제 방식, 사용자 안내 문구 결정 필요 |
| F-010 | Docker 기반 로컬 PostgreSQL 초기 스키마 검증 | Complete | 100% | database operations decision | `docker compose exec -T postgres psql -U pick_photo -d pick_photo -c "select count(*) as tables from information_schema.tables where table_schema = 'public';"` | none |
| F-011 | Android build 검증 | Blocked | 25% | NFR-007 | No verified test command found | Java 21 / Gradle 7.6.3 호환성 경고 해소 필요 |
| F-012 | Docker Compose 기반 backend/AI/PostgreSQL 통합 실행 | Complete | 100% | 명시적 사용자 요청 | `docker compose config`; `docker compose build`; `docker compose up -d`; `docker compose ps` | none |

## File Structure

- Exists: `docs/contracts/api.md` for Flutter-to-NestJS contracts.
- Exists: `docs/contracts/ai-service.md` for NestJS-to-Python AI contracts.
- Exists: `docs/contracts/data-model.md` for entity and status definitions.
- Exists: `docs/contracts/privacy.md` for sensitive photo handling rules.
- Exists: `apps/mobile/` through the Flutter plan.
- Exists: `apps/backend/` through the NestJS plan.
- Exists: `apps/ai/` through the Python AI plan.
- Exists: `database/` through the database plan.
- Updated: `AGENTS.md` records verified commands, app shape, adapters, and remaining decisions.

### Task 1: Create Contract Document Skeletons

**Files:**
- Create: `docs/contracts/api.md`
- Create: `docs/contracts/ai-service.md`
- Create: `docs/contracts/data-model.md`
- Create: `docs/contracts/privacy.md`

- [x] **Step 1: Create `docs/contracts/api.md`**

```markdown
# Application API Contract

## Purpose

Defines the contract between the Flutter app and the NestJS server.

## Stable Error Categories

- `upload_invalid`
- `face_not_found`
- `face_detection_failed`
- `selection_invalid`
- `generation_failed`
- `result_unavailable`

## Implemented Endpoints

- `POST /photos/uploads`: upload a user photo.
- `GET /photos/uploads/:uploadId/faces`: fetch detected faces for an upload.
- `POST /photos/uploads/:uploadId/generations`: request ID-photo generation for one face or all faces.
- `GET /photos/generations/:generationId`: fetch generation status and results.
```

- [x] **Step 2: Create `docs/contracts/ai-service.md`**

```markdown
# AI Service Contract

## Purpose

Defines the internal contract between the NestJS server and the Python AI server.

## Operations

- `POST /detect-faces`: detect faces in one uploaded photo.
- `POST /generate-id-photo`: generate one ID-photo style result for one selected face.

## Stable Error Categories

- `face_not_found`
- `face_detection_failed`
- `generation_failed`
```

- [x] **Step 3: Create `docs/contracts/data-model.md`**

```markdown
# Data Model Contract

## Entities

- `photo_upload`
- `detected_face`
- `generation_job`
- `generated_photo`

## Status Values

- `pending`
- `processing`
- `succeeded`
- `failed`
- `deleted`
```

- [x] **Step 4: Create `docs/contracts/privacy.md`**

```markdown
# Privacy Contract

## Sensitive Data

- Source photos
- Detected face crops
- Generated ID-photo style images
- Face detection metadata
- Generation metadata
- Request logs that could identify a user or photo

## Rules

- Do not log raw images, face crops, generated images, credentials, tokens, or embeddings.
- Validate uploaded file type, size, and image dimensions before processing.
- Keep retention and deletion behavior explicit in user-facing language.
- Delete temporary processing files after each workflow step completes or fails.
```

- [x] **Step 5: Validate contract docs exist**

Run:

```bash
find docs/contracts -maxdepth 1 -type f | sort
```

Expected output includes:

```text
docs/contracts/ai-service.md
docs/contracts/api.md
docs/contracts/data-model.md
docs/contracts/privacy.md
```

### Task 2: Execute Subsystem Plans

**Files:**
- Read: `docs/superpowers/plans/2026-04-28-pick-photo-database.md`
- Read: `docs/superpowers/plans/2026-04-28-pick-photo-python-ai-server.md`
- Read: `docs/superpowers/plans/2026-04-28-pick-photo-nestjs-server.md`
- Read: `docs/superpowers/plans/2026-04-28-pick-photo-flutter-app.md`

- [x] **Step 1: Execute the database plan**

Start with `docs/superpowers/plans/2026-04-28-pick-photo-database.md` so entity names and statuses are stable before services are scaffolded.

- [x] **Step 2: Execute the Python AI server plan**

Use deterministic fake AI behavior first so the API and app can be integrated before model selection is final.

- [x] **Step 3: Execute the NestJS server plan**

Implement the public application API and connect it to the Python AI service contract.

- [x] **Step 4: Execute the Flutter app plan**

Build the user flow against the NestJS server contract.

### Task 3: Update Harness Facts After Scaffolding

**Files:**
- Modify: `AGENTS.md`

- [x] **Step 1: Replace unresolved technical decisions with verified repository facts**

After each project creates metadata and validation commands, update `AGENTS.md` sections:

```markdown
- Languages and runtimes: <verified from project metadata>
- App shape: <verified from source layout and entrypoints>
- Verified validation commands:
  - <command from project metadata>
```

- [x] **Step 2: Confirm no unresolved command is listed as verified**

Run:

```bash
rg -n "Decision needed|Verified validation commands" AGENTS.md
```

Expected: unresolved commands remain under decisions only; commands listed as verified exist in project metadata.

## Plan Self-Review

- Spec coverage: covers root structure, contracts, subsystem ordering, and harness updates.
- Placeholder scan: no unfinished placeholder markers are present.
- Type consistency: entity names and status names match the system design.
- Residual risk: result image serving/download, mobile result preview/save UX, production AI model selection, retention/deletion execution, operations documentation, Android build validation, and a production-grade migration workflow remain unresolved.

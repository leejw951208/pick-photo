# Pick Photo Master Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Establish the multi-project Pick Photo foundation and connect the first upload-to-result workflow through explicit contracts.

**Architecture:** Keep the Flutter app, NestJS server, Python AI server, and PostgreSQL assets in independent folders. Cross-project behavior is coordinated through documented contracts in `docs/contracts` rather than shared code.

**Tech Stack:** Flutter, NestJS, Python AI service, PostgreSQL. Exact versions and package managers must be selected during the first implementation task and then recorded in `AGENTS.md`.

---

## Plan Notes

- Current repository state: no source projects exist yet.
- Verified validation commands: No verified test command found.
- Commit steps are blocked until this directory is initialized as a Git repository or connected to an existing repository.
- Execute subsystem plans in this order unless a blocker appears:
  1. `docs/superpowers/plans/2026-04-28-pick-photo-database.md`
  2. `docs/superpowers/plans/2026-04-28-pick-photo-python-ai-server.md`
  3. `docs/superpowers/plans/2026-04-28-pick-photo-nestjs-server.md`
  4. `docs/superpowers/plans/2026-04-28-pick-photo-flutter-app.md`

## File Structure

- Create: `docs/contracts/api.md` for Flutter-to-NestJS contracts.
- Create: `docs/contracts/ai-service.md` for NestJS-to-Python AI contracts.
- Create: `docs/contracts/data-model.md` for entity and status definitions.
- Create: `docs/contracts/privacy.md` for sensitive photo handling rules.
- Create: `apps/mobile/` through the Flutter plan.
- Create: `apps/backend/` through the NestJS plan.
- Create: `apps/ai/` through the Python AI plan.
- Create: `database/` through the database plan.
- Modify: `AGENTS.md` after each project exists to record verified commands and decisions.

### Task 1: Create Contract Document Skeletons

**Files:**
- Create: `docs/contracts/api.md`
- Create: `docs/contracts/ai-service.md`
- Create: `docs/contracts/data-model.md`
- Create: `docs/contracts/privacy.md`

- [ ] **Step 1: Create `docs/contracts/api.md`**

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

## Endpoints To Implement

- `POST /photos/uploads`: upload a user photo.
- `GET /photos/uploads/:uploadId/faces`: fetch detected faces for an upload.
- `POST /photos/uploads/:uploadId/generations`: request ID-photo generation for one face or all faces.
- `GET /photos/generations/:generationId`: fetch generation status and results.
```

- [ ] **Step 2: Create `docs/contracts/ai-service.md`**

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

- [ ] **Step 3: Create `docs/contracts/data-model.md`**

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

- [ ] **Step 4: Create `docs/contracts/privacy.md`**

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

- [ ] **Step 5: Validate contract docs exist**

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

- [ ] **Step 1: Execute the database plan**

Start with `docs/superpowers/plans/2026-04-28-pick-photo-database.md` so entity names and statuses are stable before services are scaffolded.

- [ ] **Step 2: Execute the Python AI server plan**

Use deterministic fake AI behavior first so the API and app can be integrated before model selection is final.

- [ ] **Step 3: Execute the NestJS server plan**

Implement the public application API and connect it to the Python AI service contract.

- [ ] **Step 4: Execute the Flutter app plan**

Build the user flow against the NestJS server contract.

### Task 3: Update Harness Facts After Scaffolding

**Files:**
- Modify: `AGENTS.md`

- [ ] **Step 1: Replace unresolved technical decisions with verified repository facts**

After each project creates metadata and validation commands, update `AGENTS.md` sections:

```markdown
- Languages and runtimes: <verified from project metadata>
- App shape: <verified from source layout and entrypoints>
- Verified validation commands:
  - <command from project metadata>
```

- [ ] **Step 2: Confirm no unresolved command is listed as verified**

Run:

```bash
rg -n "No verified test command found|Decision needed|Verified validation commands" AGENTS.md
```

Expected: unresolved commands remain under decisions only; commands listed as verified exist in project metadata.

## Plan Self-Review

- Spec coverage: covers root structure, contracts, subsystem ordering, and harness updates.
- Placeholder scan: no unfinished placeholder markers are present.
- Type consistency: entity names and status names match the system design.
- Residual risk: exact runtime versions remain unresolved until project scaffolding begins.

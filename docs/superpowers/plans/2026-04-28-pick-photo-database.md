# Pick Photo Database Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

## 진행 현황 (2026-04-28)

- 완료: database 폴더 문서, seed 정책 문서, PostgreSQL 초기 스키마, 데이터 모델 계약 문서 정렬.
- 남은 작업: 마이그레이션 러너 선택, 로컬 PostgreSQL SQL 검증 명령 확정, 운영/트랜잭션/fixture 정책 구체화.

**Goal:** Create the PostgreSQL data foundation for uploads, detected faces, generation jobs, generated photos, and lifecycle states.

**Architecture:** Keep database assets in an independent `database/` folder with SQL migrations and schema documentation. Store metadata and file references in PostgreSQL; do not store raw image bytes in relational tables.

**Tech Stack:** PostgreSQL SQL migrations. Migration runner is not selected yet; start with plain SQL files that can later be consumed by the chosen tool.

---

## File Structure

- Create: `database/README.md`
- Create: `database/migrations/001_initial_schema.sql`
- Create: `database/seeds/README.md`
- Modify: `docs/contracts/data-model.md`

### Task 1: Create Database Folder Documentation

**Files:**
- Create: `database/README.md`
- Create: `database/seeds/README.md`

- [x] **Step 1: Create `database/README.md`**

```markdown
# Pick Photo Database

This folder contains PostgreSQL schema assets for Pick Photo.

## Storage Policy

PostgreSQL stores workflow metadata and file references. Raw source photos, detected face crops, and generated image bytes must be stored outside relational tables using the storage policy selected for the environment.

## Migration Order

1. `migrations/001_initial_schema.sql`

## Status Values

- `pending`
- `processing`
- `succeeded`
- `failed`
- `deleted`
```

- [x] **Step 2: Create `database/seeds/README.md`**

```markdown
# Database Seeds

No seed data is required for the initial Pick Photo workflow.

Add deterministic seed data only when it supports local development, contract tests, or reproducible demos without storing real personal photos.
```

### Task 2: Create Initial PostgreSQL Schema

**Files:**
- Create: `database/migrations/001_initial_schema.sql`

- [x] **Step 1: Write the initial schema**

```sql
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TYPE workflow_status AS ENUM (
  'pending',
  'processing',
  'succeeded',
  'failed',
  'deleted'
);

CREATE TABLE photo_uploads (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  original_filename text NOT NULL,
  content_type text NOT NULL,
  byte_size bigint NOT NULL CHECK (byte_size > 0),
  storage_key text NOT NULL,
  status workflow_status NOT NULL DEFAULT 'pending',
  error_category text,
  error_message text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

CREATE TABLE detected_faces (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  photo_upload_id uuid NOT NULL REFERENCES photo_uploads(id) ON DELETE CASCADE,
  face_index integer NOT NULL CHECK (face_index >= 0),
  bounding_box_left integer NOT NULL CHECK (bounding_box_left >= 0),
  bounding_box_top integer NOT NULL CHECK (bounding_box_top >= 0),
  bounding_box_width integer NOT NULL CHECK (bounding_box_width > 0),
  bounding_box_height integer NOT NULL CHECK (bounding_box_height > 0),
  confidence numeric(5, 4) NOT NULL CHECK (confidence >= 0 AND confidence <= 1),
  preview_storage_key text,
  status workflow_status NOT NULL DEFAULT 'succeeded',
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (photo_upload_id, face_index)
);

CREATE TABLE generation_jobs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  photo_upload_id uuid NOT NULL REFERENCES photo_uploads(id) ON DELETE CASCADE,
  selection_mode text NOT NULL CHECK (selection_mode IN ('single_face', 'all_faces')),
  status workflow_status NOT NULL DEFAULT 'pending',
  error_category text,
  error_message text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  completed_at timestamptz
);

CREATE TABLE generation_job_faces (
  generation_job_id uuid NOT NULL REFERENCES generation_jobs(id) ON DELETE CASCADE,
  detected_face_id uuid NOT NULL REFERENCES detected_faces(id) ON DELETE CASCADE,
  PRIMARY KEY (generation_job_id, detected_face_id)
);

CREATE TABLE generated_photos (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  generation_job_id uuid NOT NULL REFERENCES generation_jobs(id) ON DELETE CASCADE,
  detected_face_id uuid NOT NULL REFERENCES detected_faces(id) ON DELETE CASCADE,
  storage_key text NOT NULL,
  width integer NOT NULL CHECK (width > 0),
  height integer NOT NULL CHECK (height > 0),
  content_type text NOT NULL,
  byte_size bigint NOT NULL CHECK (byte_size > 0),
  status workflow_status NOT NULL DEFAULT 'succeeded',
  created_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

CREATE INDEX idx_detected_faces_upload_id ON detected_faces(photo_upload_id);
CREATE INDEX idx_generation_jobs_upload_id ON generation_jobs(photo_upload_id);
CREATE INDEX idx_generated_photos_job_id ON generated_photos(generation_job_id);
CREATE INDEX idx_generated_photos_face_id ON generated_photos(detected_face_id);
```

- [ ] **Step 2: Validate SQL syntax with PostgreSQL tooling after tooling exists**

No verified command exists yet. Once PostgreSQL local tooling is selected, run the chosen SQL validation command and record it in `AGENTS.md`.

### Task 3: Align Data Contract Documentation

**Files:**
- Modify: `docs/contracts/data-model.md`

- [x] **Step 1: Replace the entity list with schema-backed names**

```markdown
# Data Model Contract

## Entities

- `photo_uploads`: one uploaded source photo and its workflow state.
- `detected_faces`: faces found in one uploaded source photo.
- `generation_jobs`: one request to generate ID-photo style images.
- `generation_job_faces`: selected faces for one generation job.
- `generated_photos`: generated result images and metadata.

## Status Values

- `pending`
- `processing`
- `succeeded`
- `failed`
- `deleted`

## Storage Rule

PostgreSQL stores metadata and file references. Raw image bytes are stored outside relational tables.
```

## Plan Self-Review

- Spec coverage: supports upload records, detected faces, generation jobs, generated outputs, and retention state.
- Placeholder scan: no unfinished placeholder markers are present.
- Type consistency: table names match contract entities.
- Residual risk: migration runner and local PostgreSQL command remain unverified until project tooling is selected.

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

## Integrity Rules

- Selected faces for a generation job must belong to the same uploaded source photo as the job.
- Generated photos must correspond to a face selected for their generation job.

## Storage Rule

PostgreSQL stores metadata and file references. Raw image bytes are stored outside relational tables.

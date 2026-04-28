# AI Service Contract

## Purpose

Defines the internal contract between the NestJS server and the Python AI server.

## Operations

### `POST /detect-faces`

Detect faces in one uploaded photo.

Request fields:

- `upload_id`
- `storage_key`

Response fields:

- `upload_id`
- `faces`

Each item in `faces` contains:

- `face_id`
- `face_index`
- `box`
- `confidence`

Each `box` contains:

- `left`
- `top`
- `width`
- `height`

### `POST /generate-id-photo`

Generate one ID-photo style result for one selected face.

Request fields:

- `upload_id`
- `face_id`
- `source_storage_key`
- `box`

Each `box` contains:

- `left`
- `top`
- `width`
- `height`

Response fields:

- `upload_id`
- `face_id`
- `result_storage_key`
- `width`
- `height`
- `content_type`

## Runtime Storage Semantics

- `storage_key` and `source_storage_key` are relative file references.
- The Python AI server resolves those keys inside its configured local storage root.
- The local storage root is configured with `PICK_PHOTO_AI_STORAGE_DIR`.
- Storage keys must not be absolute paths or escape the configured storage root.
- The default AI mode is local image processing. `PICK_PHOTO_AI_MODE=fake` preserves deterministic fake behavior for local fallback and tests.

## Stable Error Categories

- `face_not_found`
- `face_detection_failed`
- `generation_failed`

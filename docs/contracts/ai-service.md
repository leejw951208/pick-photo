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
- `faces[]`

Each `faces[]` item contains:

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

## Stable Error Categories

- `face_not_found`
- `face_detection_failed`
- `generation_failed`

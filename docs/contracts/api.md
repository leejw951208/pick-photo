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

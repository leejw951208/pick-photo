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

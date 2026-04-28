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

## Workflow Status Values

- `pending`
- `processing`
- `succeeded`
- `failed`
- `deleted`

## Endpoints

### `POST /photos/uploads`

Uploads a user photo.

Request:

- Multipart field `photo`: uploaded image file.

Response fields:

- `uploadId`: string identifier for the upload.
- `status`: one of the workflow status values.

### `GET /photos/uploads/:uploadId/faces`

Fetches detected faces for an upload.

Path fields:

- `uploadId`: string identifier for the upload.

Response fields:

- `uploadId`: string identifier for the upload.
- `faces`: array of detected face objects.

Each item in `faces`:

- `id`: string identifier for the detected face.
- `faceIndex`: zero-based number for the detected face order.
- `box`: bounding box object for the detected face.
- `confidence`: numeric face detection confidence.

Each `box`:

- `left`: number.
- `top`: number.
- `width`: number.
- `height`: number.

### `POST /photos/uploads/:uploadId/generations`

Requests ID-photo generation for one face or all faces.

Path fields:

- `uploadId`: string identifier for the upload.

Request fields:

- `selectionMode`: one of `single_face` or `all_faces`.
- `faceId`: optional string identifier for the selected face; required when `selectionMode` is `single_face`.

Response fields:

- `generationId`: string identifier for the generation.
- `status`: one of the workflow status values.

### `GET /photos/generations/:generationId`

Fetches generation status and results.

Path fields:

- `generationId`: string identifier for the generation.

Response fields:

- `generationId`: string identifier for the generation.
- `status`: one of the workflow status values.
- `results`: array of generated photo result objects.
- `errorCategory`: optional stable error category.

Each item in `results`:

- `generatedPhotoId`: string identifier for the generated photo.
- `faceId`: string identifier for the source face.
- `resultUrl`: string URL path for the generated result.

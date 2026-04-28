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

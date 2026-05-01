# Security

Use this reference as soon as work touches security-sensitive behavior. Use it during product thinking, planning, plan review, implementation review, and testing.

## Security-Sensitive Areas

Treat these as security-sensitive:

- authentication
- authorization
- secrets
- env/config
- filesystem access
- command execution
- network exposure
- external APIs
- payment
- personal data
- token, session, or cookie handling
- file upload or download
- logging of sensitive data
- CORS
- server-side execution boundaries
- webhooks
- background jobs

## Pick Photo Sensitive Data

Treat these as personal or sensitive data unless a future policy says otherwise:

- source photos
- detected faces and face boxes
- face crops or previews
- generated ID-photo style images
- workflow metadata and generation metadata
- embeddings or model outputs if introduced later
- logs that could identify a user, source photo, face, or generated result

## Existing Controls And Boundaries

- Flutter calls the NestJS backend rather than the AI server directly.
- Backend uploads are stored through local storage by default; `PHOTO_STORAGE_DIR` can override the path.
- AI reads and writes through storage keys rooted at `PICK_PHOTO_AI_STORAGE_DIR`.
- PostgreSQL stores workflow metadata and file references, not raw image bytes, according to database documentation.
- Backend falls back to deterministic fake AI when `AI_SERVICE_BASE_URL` is absent.
- Backend falls back to in-memory workflow storage when `DATABASE_URL` is absent.
- Local CORS is enabled in the backend; production CORS policy remains a decision.
- Privacy contract says not to log raw images, face crops, generated images, credentials, tokens, or embeddings.
- Privacy contract says upload file type, size, and image dimensions must be validated before processing.
- Privacy contract says retention and deletion behavior must be explicit in user-facing language.

## Required Checks

- Identify trust boundaries and external inputs.
- Do not trust external input unless a verified repository validation pattern applies.
- Preserve existing authentication, authorization, and validation controls.
- Do not weaken type safety, validation, tests, or security controls for convenience.
- Do not build shell command strings from user input.
- Prefer argument-array command execution.
- For filesystem access, check path scope, traversal risk, permissions, temporary files, cleanup, and symlinks.
- For network calls, check timeout, retry, rate limit, error mapping, and secret handling.
- For env/config changes, validate required values and update env examples when present.
- For tokens, sessions, cookies, credentials, and personal data, check storage, transport, expiry, logging, and redaction.
- For uploads/downloads, check file type, size, path, authorization, scanning expectations, and cleanup.
- For background jobs, check idempotency, retry behavior, cancellation, concurrency, and data exposure.
- For UI copy, do not promise retention, deletion, compliance, or official ID-photo support while those decisions remain open.

## Current Open Security Decisions

- Decision needed: authentication and authorization policy.
- Decision needed: production upload storage and result serving authorization.
- Decision needed: image retention, deletion, expiration, and user consent policy.
- Decision needed: logging redaction and privacy/compliance policy.
- Decision needed: production CORS policy.
- Decision needed: production job orchestration, retry, cancellation, and partial-success exposure.

## Output

Record:

- Security-sensitive areas touched
- Existing controls preserved
- New or changed controls
- Residual risks
- Tests or manual checks performed

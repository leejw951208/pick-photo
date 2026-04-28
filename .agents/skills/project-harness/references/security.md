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

## Output

Record:

- Security-sensitive areas touched
- Existing controls preserved
- New or changed controls
- Residual risks
- Tests or manual checks performed

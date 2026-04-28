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

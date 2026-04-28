CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TYPE workflow_status AS ENUM (
  'pending',
  'processing',
  'succeeded',
  'failed',
  'deleted'
);

CREATE TABLE photo_uploads (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  original_filename text NOT NULL,
  content_type text NOT NULL,
  byte_size bigint NOT NULL CHECK (byte_size > 0),
  storage_key text NOT NULL,
  status workflow_status NOT NULL DEFAULT 'pending',
  error_category text,
  error_message text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

CREATE TABLE detected_faces (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  photo_upload_id uuid NOT NULL REFERENCES photo_uploads(id) ON DELETE CASCADE,
  face_index integer NOT NULL CHECK (face_index >= 0),
  bounding_box_left integer NOT NULL CHECK (bounding_box_left >= 0),
  bounding_box_top integer NOT NULL CHECK (bounding_box_top >= 0),
  bounding_box_width integer NOT NULL CHECK (bounding_box_width > 0),
  bounding_box_height integer NOT NULL CHECK (bounding_box_height > 0),
  confidence numeric(5, 4) NOT NULL CHECK (confidence >= 0 AND confidence <= 1),
  preview_storage_key text,
  status workflow_status NOT NULL DEFAULT 'succeeded',
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (id, photo_upload_id),
  UNIQUE (photo_upload_id, face_index)
);

CREATE TABLE generation_jobs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  photo_upload_id uuid NOT NULL REFERENCES photo_uploads(id) ON DELETE CASCADE,
  selection_mode text NOT NULL CHECK (selection_mode IN ('single_face', 'all_faces')),
  status workflow_status NOT NULL DEFAULT 'pending',
  error_category text,
  error_message text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  completed_at timestamptz,
  UNIQUE (id, photo_upload_id)
);

CREATE TABLE generation_job_faces (
  generation_job_id uuid NOT NULL,
  detected_face_id uuid NOT NULL,
  photo_upload_id uuid NOT NULL,
  PRIMARY KEY (generation_job_id, detected_face_id),
  FOREIGN KEY (generation_job_id, photo_upload_id)
    REFERENCES generation_jobs(id, photo_upload_id)
    ON DELETE CASCADE,
  FOREIGN KEY (detected_face_id, photo_upload_id)
    REFERENCES detected_faces(id, photo_upload_id)
    ON DELETE CASCADE
);

CREATE TABLE generated_photos (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  generation_job_id uuid NOT NULL REFERENCES generation_jobs(id) ON DELETE CASCADE,
  detected_face_id uuid NOT NULL REFERENCES detected_faces(id) ON DELETE CASCADE,
  storage_key text NOT NULL,
  width integer NOT NULL CHECK (width > 0),
  height integer NOT NULL CHECK (height > 0),
  content_type text NOT NULL,
  byte_size bigint NOT NULL CHECK (byte_size > 0),
  status workflow_status NOT NULL DEFAULT 'succeeded',
  created_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  FOREIGN KEY (generation_job_id, detected_face_id)
    REFERENCES generation_job_faces(generation_job_id, detected_face_id)
    ON DELETE CASCADE
);

CREATE INDEX idx_detected_faces_upload_id ON detected_faces(photo_upload_id);
CREATE INDEX idx_generation_jobs_upload_id ON generation_jobs(photo_upload_id);
CREATE INDEX idx_generated_photos_job_id ON generated_photos(generation_job_id);
CREATE INDEX idx_generated_photos_face_id ON generated_photos(detected_face_id);

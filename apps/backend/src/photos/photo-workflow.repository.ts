import { Pool, type PoolClient } from 'pg';
import {
  CreateGenerationRequestDto,
  DetectedFaceDto,
  ErrorCategory,
  GenerationStatusResponseDto,
  WorkflowStatus,
} from './dto';

type EnvLike = Record<string, string | undefined>;

export const PHOTO_WORKFLOW_REPOSITORY = Symbol('PHOTO_WORKFLOW_REPOSITORY');

export interface StoredUpload {
  uploadId: string;
  storageKey: string;
  faces: DetectedFaceDto[];
  status: WorkflowStatus;
  errorCategory?: ErrorCategory;
}

export interface CreateUploadRecordInput {
  uploadId: string;
  originalFilename: string;
  contentType: string;
  byteSize: number;
  storageKey: string;
  status: WorkflowStatus;
}

export interface CompleteFaceDetectionInput {
  uploadId: string;
  status: WorkflowStatus;
  faces: DetectedFaceDto[];
  errorCategory?: ErrorCategory;
  errorMessage?: string;
}

export interface CreateGenerationRecordInput {
  generationId: string;
  uploadId: string;
  selectionMode: CreateGenerationRequestDto['selectionMode'];
  selectedFaces: DetectedFaceDto[];
  status: WorkflowStatus;
}

export interface GeneratedPhotoRecord {
  generatedPhotoId: string;
  faceId: string;
  resultUrl: string;
  storageKey: string;
  width: number;
  height: number;
  contentType: string;
  byteSize: number;
}

export interface CompleteGenerationInput {
  generationId: string;
  status: WorkflowStatus;
  results: GeneratedPhotoRecord[];
  errorCategory?: ErrorCategory;
  errorMessage?: string;
}

export interface PhotoWorkflowRepository {
  createUpload(input: CreateUploadRecordInput): Promise<void>;
  completeFaceDetection(input: CompleteFaceDetectionInput): Promise<void>;
  findUpload(uploadId: string): Promise<StoredUpload | undefined>;
  createGeneration(input: CreateGenerationRecordInput): Promise<void>;
  completeGeneration(input: CompleteGenerationInput): Promise<void>;
  findGeneration(
    generationId: string,
  ): Promise<GenerationStatusResponseDto | undefined>;
}

export class InMemoryPhotoWorkflowRepository implements PhotoWorkflowRepository {
  private readonly uploads = new Map<string, StoredUpload>();
  private readonly generations = new Map<string, GenerationStatusResponseDto>();

  async createUpload(input: CreateUploadRecordInput): Promise<void> {
    this.uploads.set(input.uploadId, {
      uploadId: input.uploadId,
      storageKey: input.storageKey,
      faces: [],
      status: input.status,
    });
  }

  async completeFaceDetection(
    input: CompleteFaceDetectionInput,
  ): Promise<void> {
    const upload = this.uploads.get(input.uploadId);
    if (!upload) {
      return;
    }

    this.uploads.set(input.uploadId, {
      ...upload,
      faces: input.faces,
      status: input.status,
      errorCategory: input.errorCategory,
    });
  }

  async findUpload(uploadId: string): Promise<StoredUpload | undefined> {
    const upload = this.uploads.get(uploadId);
    if (!upload) {
      return undefined;
    }

    return {
      ...upload,
      faces: upload.faces.map((face) => ({ ...face, box: { ...face.box } })),
    };
  }

  async createGeneration(input: CreateGenerationRecordInput): Promise<void> {
    this.generations.set(input.generationId, {
      generationId: input.generationId,
      status: input.status,
      results: [],
    });
  }

  async completeGeneration(input: CompleteGenerationInput): Promise<void> {
    this.generations.set(input.generationId, {
      generationId: input.generationId,
      status: input.status,
      results: input.results.map((result) => ({
        generatedPhotoId: result.generatedPhotoId,
        faceId: result.faceId,
        resultUrl: result.resultUrl,
      })),
      errorCategory: input.errorCategory,
    });
  }

  async findGeneration(
    generationId: string,
  ): Promise<GenerationStatusResponseDto | undefined> {
    const generation = this.generations.get(generationId);
    if (!generation) {
      return undefined;
    }

    return {
      generationId: generation.generationId,
      status: generation.status,
      results: generation.results.map((result) => ({ ...result })),
      errorCategory: generation.errorCategory,
    };
  }
}

export class PostgresPhotoWorkflowRepository implements PhotoWorkflowRepository {
  constructor(private readonly pool: Pool) {}

  async createUpload(input: CreateUploadRecordInput): Promise<void> {
    await this.pool.query(
      `
        INSERT INTO photo_uploads (
          id,
          original_filename,
          content_type,
          byte_size,
          storage_key,
          status
        )
        VALUES ($1, $2, $3, $4, $5, $6)
      `,
      [
        input.uploadId,
        input.originalFilename,
        input.contentType,
        input.byteSize,
        input.storageKey,
        input.status,
      ],
    );
  }

  async completeFaceDetection(
    input: CompleteFaceDetectionInput,
  ): Promise<void> {
    await this.withTransaction(async (client) => {
      await client.query(
        'DELETE FROM detected_faces WHERE photo_upload_id = $1',
        [input.uploadId],
      );

      for (const face of input.faces) {
        await client.query(
          `
            INSERT INTO detected_faces (
              id,
              photo_upload_id,
              face_index,
              bounding_box_left,
              bounding_box_top,
              bounding_box_width,
              bounding_box_height,
              confidence
            )
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
          `,
          [
            face.id,
            input.uploadId,
            face.faceIndex,
            face.box.left,
            face.box.top,
            face.box.width,
            face.box.height,
            face.confidence,
          ],
        );
      }

      await client.query(
        `
          UPDATE photo_uploads
          SET status = $2,
              error_category = $3,
              error_message = $4,
              updated_at = now()
          WHERE id = $1
        `,
        [
          input.uploadId,
          input.status,
          input.errorCategory ?? null,
          input.errorMessage ?? null,
        ],
      );
    });
  }

  async findUpload(uploadId: string): Promise<StoredUpload | undefined> {
    const uploadResult = await this.pool.query<{
      id: string;
      storage_key: string;
      status: WorkflowStatus;
      error_category: ErrorCategory | null;
    }>(
      `
        SELECT id, storage_key, status, error_category
        FROM photo_uploads
        WHERE id = $1 AND deleted_at IS NULL
      `,
      [uploadId],
    );

    const upload = uploadResult.rows[0];
    if (!upload) {
      return undefined;
    }

    const faceResult = await this.pool.query<{
      id: string;
      face_index: number;
      bounding_box_left: number;
      bounding_box_top: number;
      bounding_box_width: number;
      bounding_box_height: number;
      confidence: string;
    }>(
      `
        SELECT
          id,
          face_index,
          bounding_box_left,
          bounding_box_top,
          bounding_box_width,
          bounding_box_height,
          confidence
        FROM detected_faces
        WHERE photo_upload_id = $1
        ORDER BY face_index ASC
      `,
      [uploadId],
    );

    return {
      uploadId: upload.id,
      storageKey: upload.storage_key,
      status: upload.status,
      errorCategory: upload.error_category ?? undefined,
      faces: faceResult.rows.map((face) => ({
        id: face.id,
        faceIndex: face.face_index,
        box: {
          left: face.bounding_box_left,
          top: face.bounding_box_top,
          width: face.bounding_box_width,
          height: face.bounding_box_height,
        },
        confidence: Number(face.confidence),
      })),
    };
  }

  async createGeneration(input: CreateGenerationRecordInput): Promise<void> {
    await this.withTransaction(async (client) => {
      await client.query(
        `
          INSERT INTO generation_jobs (
            id,
            photo_upload_id,
            selection_mode,
            status
          )
          VALUES ($1, $2, $3, $4)
        `,
        [input.generationId, input.uploadId, input.selectionMode, input.status],
      );

      for (const face of input.selectedFaces) {
        await client.query(
          `
            INSERT INTO generation_job_faces (
              generation_job_id,
              detected_face_id,
              photo_upload_id
            )
            VALUES ($1, $2, $3)
          `,
          [input.generationId, face.id, input.uploadId],
        );
      }
    });
  }

  async completeGeneration(input: CompleteGenerationInput): Promise<void> {
    await this.withTransaction(async (client) => {
      await client.query(
        'DELETE FROM generated_photos WHERE generation_job_id = $1',
        [input.generationId],
      );

      for (const result of input.results) {
        await client.query(
          `
            INSERT INTO generated_photos (
              id,
              generation_job_id,
              detected_face_id,
              storage_key,
              width,
              height,
              content_type,
              byte_size
            )
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
          `,
          [
            result.generatedPhotoId,
            input.generationId,
            result.faceId,
            result.storageKey,
            result.width,
            result.height,
            result.contentType,
            result.byteSize,
          ],
        );
      }

      await client.query(
        `
          UPDATE generation_jobs
          SET status = $2,
              error_category = $3,
              error_message = $4,
              completed_at = CASE WHEN $2 IN ('succeeded', 'failed') THEN now() ELSE completed_at END,
              updated_at = now()
          WHERE id = $1
        `,
        [
          input.generationId,
          input.status,
          input.errorCategory ?? null,
          input.errorMessage ?? null,
        ],
      );
    });
  }

  async findGeneration(
    generationId: string,
  ): Promise<GenerationStatusResponseDto | undefined> {
    const jobResult = await this.pool.query<{
      id: string;
      status: WorkflowStatus;
      error_category: ErrorCategory | null;
    }>(
      `
        SELECT id, status, error_category
        FROM generation_jobs
        WHERE id = $1
      `,
      [generationId],
    );

    const job = jobResult.rows[0];
    if (!job) {
      return undefined;
    }

    const result = await this.pool.query<{
      id: string;
      detected_face_id: string;
      storage_key: string;
    }>(
      `
        SELECT id, detected_face_id, storage_key
        FROM generated_photos
        WHERE generation_job_id = $1 AND deleted_at IS NULL
        ORDER BY created_at ASC
      `,
      [generationId],
    );

    return {
      generationId: job.id,
      status: job.status,
      results: result.rows.map((row) => ({
        generatedPhotoId: row.id,
        faceId: row.detected_face_id,
        resultUrl: `/results/${row.storage_key}`,
      })),
      errorCategory: job.error_category ?? undefined,
    };
  }

  private async withTransaction<T>(
    operation: (client: PoolClient) => Promise<T>,
  ): Promise<T> {
    const client = await this.pool.connect();

    try {
      await client.query('BEGIN');
      const result = await operation(client);
      await client.query('COMMIT');
      return result;
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }
}

export function createWorkflowRepository(
  env: EnvLike = process.env,
): PhotoWorkflowRepository {
  if (env.DATABASE_URL) {
    return new PostgresPhotoWorkflowRepository(
      new Pool({ connectionString: env.DATABASE_URL }),
    );
  }

  return new InMemoryPhotoWorkflowRepository();
}

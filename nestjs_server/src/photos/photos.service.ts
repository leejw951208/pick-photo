import { Injectable } from '@nestjs/common';
import { FakeAiClient } from '../ai/ai-client';
import {
  CreateGenerationRequestDto,
  CreateGenerationResponseDto,
  DetectedFaceDto,
  DetectedFacesResponseDto,
  GenerationStatusResponseDto,
  UploadPhotoResponseDto,
} from './dto';

@Injectable()
export class PhotosService {
  private readonly aiClient = new FakeAiClient();
  private readonly uploads = new Map<string, { storageKey: string; faces: DetectedFaceDto[] }>();
  private readonly generations = new Map<string, GenerationStatusResponseDto>();

  async createUpload(filename: string): Promise<UploadPhotoResponseDto> {
    const uploadId = `upload-${this.uploads.size + 1}`;
    const storageKey = `uploads/${filename}`;
    const faces = await this.aiClient.detectFaces({ uploadId, storageKey });
    this.uploads.set(uploadId, { storageKey, faces });
    return { uploadId, status: faces.length === 0 ? 'failed' : 'succeeded' };
  }

  getFaces(uploadId: string): DetectedFacesResponseDto {
    const upload = this.uploads.get(uploadId);
    return { uploadId, faces: upload?.faces ?? [] };
  }

  async createGeneration(uploadId: string, request: CreateGenerationRequestDto): Promise<CreateGenerationResponseDto> {
    const upload = this.uploads.get(uploadId);
    const faces = upload?.faces ?? [];
    const selectedFaces =
      request.selectionMode === 'all_faces' ? faces : faces.filter((face) => face.id === request.faceId);

    const generationId = `generation-${this.generations.size + 1}`;
    const results: GenerationStatusResponseDto['results'] = [];

    for (const face of selectedFaces) {
      const result = await this.aiClient.generateIdPhoto({
        uploadId,
        faceId: face.id,
        sourceStorageKey: upload?.storageKey ?? '',
        box: face.box,
      });
      results.push({
        generatedPhotoId: `${generationId}-${face.id}`,
        faceId: face.id,
        resultUrl: `/results/${result.resultStorageKey}`,
      });
    }

    this.generations.set(generationId, {
      generationId,
      status: results.length === 0 ? 'failed' : 'succeeded',
      results,
      errorCategory: results.length === 0 ? 'selection_invalid' : undefined,
    });

    return { generationId, status: results.length === 0 ? 'failed' : 'succeeded' };
  }

  getGeneration(generationId: string): GenerationStatusResponseDto {
    return (
      this.generations.get(generationId) ?? {
        generationId,
        status: 'failed',
        results: [],
        errorCategory: 'result_unavailable',
      }
    );
  }
}

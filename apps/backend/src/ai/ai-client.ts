import { DetectedFaceDto, FaceBoxDto } from '../photos/dto';

type EnvLike = Record<string, string | undefined>;

type AiDetectedFaceResponse = {
  face_id: string;
  face_index: number;
  box: FaceBoxDto;
  confidence: number;
};

type AiGenerateIdPhotoResponse = {
  result_storage_key: string;
  width: number;
  height: number;
  content_type: string;
  byte_size?: number;
};

export const AI_CLIENT = Symbol('AI_CLIENT');

export interface AiClient {
  detectFaces(input: {
    uploadId: string;
    storageKey: string;
  }): Promise<DetectedFaceDto[]>;
  generateIdPhoto(input: {
    uploadId: string;
    faceId: string;
    sourceStorageKey: string;
    box: FaceBoxDto;
  }): Promise<{
    resultStorageKey: string;
    width: number;
    height: number;
    contentType: string;
    byteSize: number;
  }>;
}

export class FakeAiClient implements AiClient {
  async detectFaces(input: {
    uploadId: string;
    storageKey: string;
  }): Promise<DetectedFaceDto[]> {
    if (input.storageKey.includes('no-face')) {
      return [];
    }

    return [
      {
        id: `${input.uploadId}-face-0`,
        faceIndex: 0,
        box: { left: 80, top: 60, width: 240, height: 280 },
        confidence: 0.98,
      },
    ];
  }

  async generateIdPhoto(input: {
    uploadId: string;
    faceId: string;
    sourceStorageKey: string;
    box: FaceBoxDto;
  }): Promise<{
    resultStorageKey: string;
    width: number;
    height: number;
    contentType: string;
    byteSize: number;
  }> {
    return {
      resultStorageKey: `generated/${input.uploadId}/${input.faceId}.jpg`,
      width: 413,
      height: 531,
      contentType: 'image/jpeg',
      byteSize: 1,
    };
  }
}

export class HttpAiClient implements AiClient {
  private readonly baseUrl: string;

  constructor(
    baseUrl: string,
    private readonly timeoutMs = 10_000,
  ) {
    this.baseUrl = baseUrl.replace(/\/+$/, '');
  }

  async detectFaces(input: {
    uploadId: string;
    storageKey: string;
  }): Promise<DetectedFaceDto[]> {
    const response = await this.post<{
      faces: AiDetectedFaceResponse[];
    }>('/detect-faces', {
      upload_id: input.uploadId,
      storage_key: input.storageKey,
    });

    return response.faces.map((face) => ({
      id: face.face_id,
      faceIndex: face.face_index,
      box: face.box,
      confidence: face.confidence,
    }));
  }

  async generateIdPhoto(input: {
    uploadId: string;
    faceId: string;
    sourceStorageKey: string;
    box: FaceBoxDto;
  }): Promise<{
    resultStorageKey: string;
    width: number;
    height: number;
    contentType: string;
    byteSize: number;
  }> {
    const response = await this.post<AiGenerateIdPhotoResponse>(
      '/generate-id-photo',
      {
        upload_id: input.uploadId,
        face_id: input.faceId,
        source_storage_key: input.sourceStorageKey,
        box: input.box,
      },
    );

    return {
      resultStorageKey: response.result_storage_key,
      width: response.width,
      height: response.height,
      contentType: response.content_type,
      byteSize: response.byte_size ?? 1,
    };
  }

  private async post<T>(path: string, body: unknown): Promise<T> {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), this.timeoutMs);

    try {
      const response = await fetch(`${this.baseUrl}${path}`, {
        method: 'POST',
        headers: { 'content-type': 'application/json' },
        body: JSON.stringify(body),
        signal: controller.signal,
      });

      if (!response.ok) {
        const responseText = await response.text().catch(() => '');
        throw new Error(
          `AI service request failed with status ${response.status}${
            responseText ? `: ${responseText}` : ''
          }`,
        );
      }

      return (await response.json()) as T;
    } finally {
      clearTimeout(timeout);
    }
  }
}

export function createAiClient(env: EnvLike = process.env): AiClient {
  if (env.AI_SERVICE_BASE_URL) {
    return new HttpAiClient(env.AI_SERVICE_BASE_URL);
  }

  return new FakeAiClient();
}

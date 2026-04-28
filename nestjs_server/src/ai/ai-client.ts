import { DetectedFaceDto, FaceBoxDto } from '../photos/dto';

export interface AiClient {
  detectFaces(input: { uploadId: string; storageKey: string }): Promise<DetectedFaceDto[]>;
  generateIdPhoto(input: {
    uploadId: string;
    faceId: string;
    sourceStorageKey: string;
    box: FaceBoxDto;
  }): Promise<{ resultStorageKey: string; width: number; height: number; contentType: string }>;
}

export class FakeAiClient implements AiClient {
  async detectFaces(input: { uploadId: string; storageKey: string }): Promise<DetectedFaceDto[]> {
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
  }): Promise<{ resultStorageKey: string; width: number; height: number; contentType: string }> {
    return {
      resultStorageKey: `generated/${input.uploadId}/${input.faceId}.jpg`,
      width: 413,
      height: 531,
      contentType: 'image/jpeg',
    };
  }
}

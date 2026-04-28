# Pick Photo NestJS Server Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

## 진행 현황 (2026-04-28)

- 완료: NestJS 프로젝트 생성, 사진 업로드 API, 얼굴 목록 API, 생성 요청 API, 생성 결과 API, Swagger 문서, fake AI 기반 in-memory 워크플로.
- 완료: 업로드 파일 로컬 저장소, PostgreSQL 저장소 어댑터, Python AI 서버 HTTP 어댑터.
- 남은 작업: 실제 AI 모델 결과 저장, 결과 이미지 제공/다운로드, 보관/삭제 정책 실행, 로컬 PostgreSQL 검증 명령 확정.

**Goal:** Build the application server that owns public workflow APIs and coordinates upload, face detection, selection, generation, persistence, and AI service calls.

**Architecture:** Keep the NestJS server in `apps/backend/`. The server exposes public API endpoints to the Flutter app and calls the Python AI server through a narrow adapter.

**Tech Stack:** NestJS with TypeScript. Exact package manager and generated project metadata must be confirmed during scaffolding.

---

## File Structure

- Create: `apps/backend/` using NestJS project scaffolding.
- Create: `apps/backend/src/photos/photos.module.ts`
- Create: `apps/backend/src/photos/photos.controller.ts`
- Create: `apps/backend/src/photos/photos.service.ts`
- Create: `apps/backend/src/photos/dto.ts`
- Create: `apps/backend/src/ai/ai-client.ts`
- Create: `apps/backend/test/photos.e2e-spec.ts`
- Modify: `docs/contracts/api.md`

### Task 1: Scaffold NestJS Project

**Files:**
- Create: `apps/backend/`

- [ ] **Step 1: Generate project**

Run after Node.js tooling is available:

```bash
npx @nestjs/cli new apps/backend --package-manager npm --skip-git
```

Expected: NestJS project files are created under `apps/backend/`.

- [ ] **Step 2: Run generated tests**

Run:

```bash
cd apps/backend
npm test
```

Expected: generated tests pass.

### Task 2: Define Workflow DTOs

**Files:**
- Create: `apps/backend/src/photos/dto.ts`

- [ ] **Step 1: Create DTO definitions**

```typescript
export type WorkflowStatus = 'pending' | 'processing' | 'succeeded' | 'failed' | 'deleted';

export type ErrorCategory =
  | 'upload_invalid'
  | 'face_not_found'
  | 'face_detection_failed'
  | 'selection_invalid'
  | 'generation_failed'
  | 'result_unavailable';

export interface FaceBoxDto {
  left: number;
  top: number;
  width: number;
  height: number;
}

export interface DetectedFaceDto {
  id: string;
  faceIndex: number;
  box: FaceBoxDto;
  confidence: number;
}

export interface UploadPhotoResponseDto {
  uploadId: string;
  status: WorkflowStatus;
}

export interface DetectedFacesResponseDto {
  uploadId: string;
  faces: DetectedFaceDto[];
}

export interface CreateGenerationRequestDto {
  selectionMode: 'single_face' | 'all_faces';
  faceId?: string;
}

export interface CreateGenerationResponseDto {
  generationId: string;
  status: WorkflowStatus;
}

export interface GenerationStatusResponseDto {
  generationId: string;
  status: WorkflowStatus;
  results: Array<{
    generatedPhotoId: string;
    faceId: string;
    resultUrl: string;
  }>;
  errorCategory?: ErrorCategory;
}
```

### Task 3: Implement AI Client Adapter

**Files:**
- Create: `apps/backend/src/ai/ai-client.ts`

- [ ] **Step 1: Create adapter interface and fake implementation**

```typescript
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
```

### Task 4: Implement In-Memory Workflow Service

**Files:**
- Create: `apps/backend/src/photos/photos.service.ts`

- [ ] **Step 1: Create service with deterministic in-memory state**

```typescript
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
    const selectedFaces = request.selectionMode === 'all_faces'
      ? faces
      : faces.filter((face) => face.id === request.faceId);

    const generationId = `generation-${this.generations.size + 1}`;
    const results = [];

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
    return this.generations.get(generationId) ?? {
      generationId,
      status: 'failed',
      results: [],
      errorCategory: 'result_unavailable',
    };
  }
}
```

### Task 5: Implement Controller and Module

**Files:**
- Create: `apps/backend/src/photos/photos.controller.ts`
- Create: `apps/backend/src/photos/photos.module.ts`
- Modify: `apps/backend/src/app.module.ts`

- [ ] **Step 1: Create controller**

```typescript
import { Body, Controller, Get, Param, Post, UploadedFile, UseInterceptors } from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { CreateGenerationRequestDto } from './dto';
import { PhotosService } from './photos.service';

@Controller('photos')
export class PhotosController {
  constructor(private readonly photosService: PhotosService) {}

  @Post('uploads')
  @UseInterceptors(FileInterceptor('photo'))
  createUpload(@UploadedFile() file: Express.Multer.File) {
    return this.photosService.createUpload(file?.originalname ?? 'missing-photo.jpg');
  }

  @Get('uploads/:uploadId/faces')
  getFaces(@Param('uploadId') uploadId: string) {
    return this.photosService.getFaces(uploadId);
  }

  @Post('uploads/:uploadId/generations')
  createGeneration(@Param('uploadId') uploadId: string, @Body() body: CreateGenerationRequestDto) {
    return this.photosService.createGeneration(uploadId, body);
  }

  @Get('generations/:generationId')
  getGeneration(@Param('generationId') generationId: string) {
    return this.photosService.getGeneration(generationId);
  }
}
```

- [ ] **Step 2: Create module**

```typescript
import { Module } from '@nestjs/common';
import { PhotosController } from './photos.controller';
import { PhotosService } from './photos.service';

@Module({
  controllers: [PhotosController],
  providers: [PhotosService],
})
export class PhotosModule {}
```

- [ ] **Step 3: Register module in `app.module.ts`**

```typescript
import { Module } from '@nestjs/common';
import { PhotosModule } from './photos/photos.module';

@Module({
  imports: [PhotosModule],
})
export class AppModule {}
```

### Task 6: Validate API Contract

**Files:**
- Test: `apps/backend/test/photos.e2e-spec.ts`

- [ ] **Step 1: Add e2e contract test**

```typescript
import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import * as request from 'supertest';
import { AppModule } from '../src/app.module';

describe('Photos workflow', () => {
  let app: INestApplication;

  beforeEach(async () => {
    const moduleRef = await Test.createTestingModule({ imports: [AppModule] }).compile();
    app = moduleRef.createNestApplication();
    await app.init();
  });

  afterEach(async () => {
    await app.close();
  });

  it('uploads a photo, lists faces, generates all faces, and fetches results', async () => {
    const upload = await request(app.getHttpServer())
      .post('/photos/uploads')
      .attach('photo', Buffer.from('fake-image'), 'person.jpg')
      .expect(201);

    const uploadId = upload.body.uploadId;

    const faces = await request(app.getHttpServer())
      .get(`/photos/uploads/${uploadId}/faces`)
      .expect(200);

    expect(faces.body.faces).toHaveLength(1);

    const generation = await request(app.getHttpServer())
      .post(`/photos/uploads/${uploadId}/generations`)
      .send({ selectionMode: 'all_faces' })
      .expect(201);

    const result = await request(app.getHttpServer())
      .get(`/photos/generations/${generation.body.generationId}`)
      .expect(200);

    expect(result.body.results).toHaveLength(1);
  });
});
```

- [ ] **Step 2: Run tests**

Run:

```bash
cd apps/backend
npm test
npm run test:e2e
```

Expected: unit and e2e tests pass after dependencies are installed.

## Plan Self-Review

- Spec coverage: covers upload, face list, single/all generation, status/result retrieval, and stable error categories.
- Placeholder scan: no unfinished placeholder markers are present.
- Type consistency: DTO names match service and controller usage.
- Residual risk: this plan starts with in-memory state and fake AI; PostgreSQL and real storage integration should follow after the vertical slice works.

import { Module } from '@nestjs/common';
import { AI_CLIENT, createAiClient } from '../ai/ai-client';
import { PHOTO_STORAGE, createPhotoStorage } from './photo-storage';
import {
  PHOTO_WORKFLOW_REPOSITORY,
  createWorkflowRepository,
} from './photo-workflow.repository';
import { PhotosController } from './photos.controller';
import { PhotosService } from './photos.service';

@Module({
  controllers: [PhotosController],
  providers: [
    PhotosService,
    {
      provide: AI_CLIENT,
      useFactory: createAiClient,
    },
    {
      provide: PHOTO_STORAGE,
      useFactory: createPhotoStorage,
    },
    {
      provide: PHOTO_WORKFLOW_REPOSITORY,
      useFactory: createWorkflowRepository,
    },
  ],
})
export class PhotosModule {}

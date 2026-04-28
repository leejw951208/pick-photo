import { BadRequestException, Body, Controller, Get, Param, Post, UploadedFile, UseInterceptors } from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import type { CreateGenerationRequestDto } from './dto';
import { PhotosService } from './photos.service';

const MAX_UPLOAD_BYTES = 10 * 1024 * 1024;
const IMAGE_MIME_TYPE_PATTERN = /^image\/[a-z0-9.+-]+$/i;

type UploadedPhotoFile = {
  originalname?: string;
  mimetype?: string;
  size?: number;
};

@Controller('photos')
export class PhotosController {
  constructor(private readonly photosService: PhotosService) {}

  @Post('uploads')
  @UseInterceptors(FileInterceptor('photo'))
  createUpload(@UploadedFile() file: UploadedPhotoFile | undefined) {
    this.validateUpload(file);
    return this.photosService.createUpload(file.originalname ?? 'uploaded-photo');
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

  private validateUpload(file: UploadedPhotoFile | undefined): asserts file is UploadedPhotoFile {
    if (!file) {
      throw new BadRequestException({
        message: 'Multipart field photo is required.',
        errorCategory: 'upload_invalid',
      });
    }

    if (!file.mimetype || !IMAGE_MIME_TYPE_PATTERN.test(file.mimetype)) {
      throw new BadRequestException({
        message: 'Uploaded file must be an image.',
        errorCategory: 'upload_invalid',
      });
    }

    if (!file.size || file.size <= 0) {
      throw new BadRequestException({
        message: 'Uploaded file must not be empty.',
        errorCategory: 'upload_invalid',
      });
    }

    if (file.size > MAX_UPLOAD_BYTES) {
      throw new BadRequestException({
        message: 'Uploaded file is too large.',
        errorCategory: 'upload_invalid',
      });
    }
  }
}

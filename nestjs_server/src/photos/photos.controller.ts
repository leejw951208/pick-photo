import { Body, Controller, Get, Param, Post, UploadedFile, UseInterceptors } from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import type { CreateGenerationRequestDto } from './dto';
import { PhotosService } from './photos.service';

@Controller('photos')
export class PhotosController {
  constructor(private readonly photosService: PhotosService) {}

  @Post('uploads')
  @UseInterceptors(FileInterceptor('photo'))
  createUpload(@UploadedFile() file: { originalname?: string } | undefined) {
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

import {
  BadRequestException,
  Body,
  Controller,
  Get,
  Param,
  Post,
  UploadedFile,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import {
  ApiBadRequestResponse,
  ApiBody,
  ApiConsumes,
  ApiCreatedResponse,
  ApiNotFoundResponse,
  ApiOkResponse,
  ApiOperation,
  ApiParam,
  ApiTags,
} from '@nestjs/swagger';
import type { CreateGenerationRequestDto } from './dto';
import { PhotosService } from './photos.service';
import {
  badRequestResponseSchema,
  createGenerationBodySchema,
  createGenerationResponseSchema,
  detectedFacesResponseSchema,
  generationStatusResponseSchema,
  notFoundResponseSchema,
  uploadPhotoBodySchema,
  uploadPhotoResponseSchema,
} from './photos.swagger';

const MAX_UPLOAD_BYTES = 10 * 1024 * 1024;
const IMAGE_MIME_TYPE_PATTERN = /^image\/[a-z0-9.+-]+$/i;

type UploadedPhotoFile = {
  originalname?: string;
  mimetype?: string;
  size?: number;
  buffer?: Buffer;
};
type ValidUploadedPhotoFile = UploadedPhotoFile & {
  mimetype: string;
  size: number;
  buffer: Buffer;
};

@Controller('photos')
@ApiTags('photos')
export class PhotosController {
  constructor(private readonly photosService: PhotosService) {}

  @Post('uploads')
  @UseInterceptors(FileInterceptor('photo'))
  @ApiOperation({ summary: 'Upload a user photo and detect faces' })
  @ApiConsumes('multipart/form-data')
  @ApiBody({ schema: uploadPhotoBodySchema })
  @ApiCreatedResponse({
    description: 'Photo upload was accepted and face detection completed.',
    schema: uploadPhotoResponseSchema,
  })
  @ApiBadRequestResponse({
    description: 'Upload request is invalid.',
    schema: badRequestResponseSchema,
  })
  createUpload(@UploadedFile() file: UploadedPhotoFile | undefined) {
    this.validateUpload(file);
    return this.photosService.createUpload({
      originalName: file.originalname ?? 'uploaded-photo',
      contentType: file.mimetype,
      byteSize: file.size,
      bytes: file.buffer,
    });
  }

  @Get('uploads/:uploadId/faces')
  @ApiOperation({ summary: 'Fetch detected faces for an upload' })
  @ApiParam({
    name: 'uploadId',
    example: '8c6b41c8-6d4b-4a15-9ec7-c76978b3f1f2',
  })
  @ApiOkResponse({
    description: 'Detected face list for the upload.',
    schema: detectedFacesResponseSchema,
  })
  getFaces(@Param('uploadId') uploadId: string) {
    return this.photosService.getFaces(uploadId);
  }

  @Post('uploads/:uploadId/generations')
  @ApiOperation({
    summary:
      'Request ID-photo generation for one face, selected faces, or all faces',
  })
  @ApiParam({
    name: 'uploadId',
    example: '8c6b41c8-6d4b-4a15-9ec7-c76978b3f1f2',
  })
  @ApiBody({ schema: createGenerationBodySchema })
  @ApiCreatedResponse({
    description: 'Generation job was created.',
    schema: createGenerationResponseSchema,
  })
  @ApiBadRequestResponse({
    description: 'Generation request selection is invalid.',
    schema: badRequestResponseSchema,
  })
  @ApiNotFoundResponse({
    description: 'Upload was not found.',
    schema: notFoundResponseSchema,
  })
  createGeneration(
    @Param('uploadId') uploadId: string,
    @Body() body: CreateGenerationRequestDto,
  ) {
    return this.photosService.createGeneration(uploadId, body);
  }

  @Get('generations/:generationId')
  @ApiOperation({ summary: 'Fetch generation status and generated results' })
  @ApiParam({
    name: 'generationId',
    example: 'c421064e-5d0a-4aa8-8c70-bfb85fb8ecf6',
  })
  @ApiOkResponse({
    description: 'Generation status and result list.',
    schema: generationStatusResponseSchema,
  })
  getGeneration(@Param('generationId') generationId: string) {
    return this.photosService.getGeneration(generationId);
  }

  private validateUpload(
    file: UploadedPhotoFile | undefined,
  ): asserts file is ValidUploadedPhotoFile {
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

    if (!Buffer.isBuffer(file.buffer)) {
      throw new BadRequestException({
        message: 'Uploaded file bytes are required.',
        errorCategory: 'upload_invalid',
      });
    }
  }
}

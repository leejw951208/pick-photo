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
    return this.photosService.createUpload(
      file.originalname ?? 'uploaded-photo',
    );
  }

  @Get('uploads/:uploadId/faces')
  @ApiOperation({ summary: 'Fetch detected faces for an upload' })
  @ApiParam({ name: 'uploadId', example: 'upload-1' })
  @ApiOkResponse({
    description: 'Detected face list for the upload.',
    schema: detectedFacesResponseSchema,
  })
  getFaces(@Param('uploadId') uploadId: string) {
    return this.photosService.getFaces(uploadId);
  }

  @Post('uploads/:uploadId/generations')
  @ApiOperation({
    summary: 'Request ID-photo generation for one face or all faces',
  })
  @ApiParam({ name: 'uploadId', example: 'upload-1' })
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
  @ApiParam({ name: 'generationId', example: 'generation-1' })
  @ApiOkResponse({
    description: 'Generation status and result list.',
    schema: generationStatusResponseSchema,
  })
  getGeneration(@Param('generationId') generationId: string) {
    return this.photosService.getGeneration(generationId);
  }

  private validateUpload(
    file: UploadedPhotoFile | undefined,
  ): asserts file is UploadedPhotoFile {
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

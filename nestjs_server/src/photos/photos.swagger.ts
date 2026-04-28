import type { SchemaObject } from '@nestjs/swagger/dist/interfaces/open-api-spec.interface';

const workflowStatusValues = [
  'pending',
  'processing',
  'succeeded',
  'failed',
  'deleted',
] as string[];
const errorCategoryValues = [
  'upload_invalid',
  'face_not_found',
  'face_detection_failed',
  'selection_invalid',
  'generation_failed',
  'result_unavailable',
] as string[];

export const uploadPhotoBodySchema: SchemaObject = {
  type: 'object',
  required: ['photo'],
  properties: {
    photo: {
      type: 'string',
      format: 'binary',
      description: 'Image file to process.',
    },
  },
};

export const uploadPhotoResponseSchema: SchemaObject = {
  type: 'object',
  required: ['uploadId', 'status'],
  properties: {
    uploadId: {
      type: 'string',
      example: 'upload-1',
    },
    status: {
      type: 'string',
      enum: workflowStatusValues,
      example: 'succeeded',
    },
  },
};

export const detectedFacesResponseSchema: SchemaObject = {
  type: 'object',
  required: ['uploadId', 'faces'],
  properties: {
    uploadId: {
      type: 'string',
      example: 'upload-1',
    },
    faces: {
      type: 'array',
      items: {
        type: 'object',
        required: ['id', 'faceIndex', 'box', 'confidence'],
        properties: {
          id: {
            type: 'string',
            example: 'upload-1-face-0',
          },
          faceIndex: {
            type: 'number',
            example: 0,
          },
          box: {
            type: 'object',
            required: ['left', 'top', 'width', 'height'],
            properties: {
              left: {
                type: 'number',
                example: 0.35,
              },
              top: {
                type: 'number',
                example: 0.2,
              },
              width: {
                type: 'number',
                example: 0.3,
              },
              height: {
                type: 'number',
                example: 0.4,
              },
            },
          },
          confidence: {
            type: 'number',
            example: 0.98,
          },
        },
      },
    },
  },
};

export const createGenerationBodySchema: SchemaObject = {
  type: 'object',
  required: ['selectionMode'],
  properties: {
    selectionMode: {
      type: 'string',
      enum: ['single_face', 'all_faces'] as string[],
      example: 'all_faces',
    },
    faceId: {
      type: 'string',
      description: 'Required when selectionMode is single_face.',
      example: 'upload-1-face-0',
    },
  },
};

export const createGenerationResponseSchema: SchemaObject = {
  type: 'object',
  required: ['generationId', 'status'],
  properties: {
    generationId: {
      type: 'string',
      example: 'generation-1',
    },
    status: {
      type: 'string',
      enum: workflowStatusValues,
      example: 'succeeded',
    },
  },
};

export const generationStatusResponseSchema: SchemaObject = {
  type: 'object',
  required: ['generationId', 'status', 'results'],
  properties: {
    generationId: {
      type: 'string',
      example: 'generation-1',
    },
    status: {
      type: 'string',
      enum: workflowStatusValues,
      example: 'succeeded',
    },
    results: {
      type: 'array',
      items: {
        type: 'object',
        required: ['generatedPhotoId', 'faceId', 'resultUrl'],
        properties: {
          generatedPhotoId: {
            type: 'string',
            example: 'generation-1-upload-1-face-0',
          },
          faceId: {
            type: 'string',
            example: 'upload-1-face-0',
          },
          resultUrl: {
            type: 'string',
            example: '/results/generated/upload-1-face-0.jpg',
          },
        },
      },
    },
    errorCategory: {
      type: 'string',
      enum: errorCategoryValues,
      example: 'selection_invalid',
    },
  },
};

export const badRequestResponseSchema: SchemaObject = {
  type: 'object',
  properties: {
    statusCode: {
      type: 'number',
      example: 400,
    },
    message: {
      type: 'string',
      example: 'Invalid request.',
    },
    errorCategory: {
      type: 'string',
      enum: errorCategoryValues,
      example: 'upload_invalid',
    },
  },
};

export const notFoundResponseSchema: SchemaObject = {
  type: 'object',
  properties: {
    statusCode: {
      type: 'number',
      example: 404,
    },
    message: {
      type: 'string',
      example: 'Upload was not found.',
    },
    errorCategory: {
      type: 'string',
      enum: errorCategoryValues,
      example: 'result_unavailable',
    },
  },
};

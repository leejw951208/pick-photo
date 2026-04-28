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

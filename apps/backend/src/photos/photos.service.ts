import { randomUUID } from 'node:crypto'
import {
    BadRequestException,
    Inject,
    Injectable,
    NotFoundException,
} from '@nestjs/common'
import { AI_CLIENT } from '../ai/ai-client'
import type { AiClient } from '../ai/ai-client'
import {
    CreateGenerationRequestDto,
    CreateGenerationResponseDto,
    DetectedFaceDto,
    DetectedFacesResponseDto,
    GenerationStatusResponseDto,
    UploadPhotoResponseDto,
} from './dto'
import { PHOTO_STORAGE } from './photo-storage'
import type { PhotoStorage } from './photo-storage'
import { PHOTO_WORKFLOW_REPOSITORY } from './photo-workflow.repository'
import type {
    GeneratedPhotoRecord,
    PhotoWorkflowRepository,
} from './photo-workflow.repository'

export interface UploadPhotoFileInput {
    originalName: string
    contentType: string
    byteSize: number
    bytes: Buffer
}

@Injectable()
export class PhotosService {
    constructor(
        @Inject(AI_CLIENT) private readonly aiClient: AiClient,
        @Inject(PHOTO_STORAGE) private readonly photoStorage: PhotoStorage,
        @Inject(PHOTO_WORKFLOW_REPOSITORY)
        private readonly repository: PhotoWorkflowRepository,
    ) {}

    async createUpload(
        file: UploadPhotoFileInput,
    ): Promise<UploadPhotoResponseDto> {
        const uploadId = randomUUID()
        const storageKey = await this.photoStorage.saveUpload({
            uploadId,
            originalName: file.originalName,
            contentType: file.contentType,
            bytes: file.bytes,
        })

        await this.repository.createUpload({
            uploadId,
            originalFilename: file.originalName,
            contentType: file.contentType,
            byteSize: file.byteSize,
            storageKey,
            status: 'processing',
        })

        const detectedFaces = await this.detectFaces(uploadId, storageKey)
        if (!detectedFaces) {
            return { uploadId, status: 'failed' }
        }

        const faces = this.toStoredFaces(detectedFaces)
        const status = faces.length === 0 ? 'failed' : 'succeeded'

        await this.repository.completeFaceDetection({
            uploadId,
            status,
            faces,
            errorCategory: faces.length === 0 ? 'face_not_found' : undefined,
        })

        return { uploadId, status }
    }

    private async detectFaces(
        uploadId: string,
        storageKey: string,
    ): Promise<DetectedFaceDto[] | undefined> {
        try {
            return await this.aiClient.detectFaces({ uploadId, storageKey })
        } catch (error) {
            await this.repository.completeFaceDetection({
                uploadId,
                status: 'failed',
                faces: [],
                errorCategory: 'face_detection_failed',
                errorMessage:
                    error instanceof Error
                        ? error.message
                        : 'Face detection failed.',
            })
            return undefined
        }
    }

    async getFaces(uploadId: string): Promise<DetectedFacesResponseDto> {
        const upload = await this.repository.findUpload(uploadId)
        return { uploadId, faces: upload?.faces ?? [] }
    }

    async createGeneration(
        uploadId: string,
        request: CreateGenerationRequestDto,
    ): Promise<CreateGenerationResponseDto> {
        const upload = await this.repository.findUpload(uploadId)
        if (!upload) {
            throw new NotFoundException({
                message: 'Upload was not found.',
                errorCategory: 'result_unavailable',
            })
        }

        const selectedFaces = this.resolveSelectedFaces(upload.faces, request)

        const generationId = randomUUID()
        await this.repository.createGeneration({
            generationId,
            uploadId,
            selectionMode: request.selectionMode,
            selectedFaces,
            status: selectedFaces.length === 0 ? 'failed' : 'processing',
        })

        if (selectedFaces.length === 0) {
            await this.repository.completeGeneration({
                generationId,
                status: 'failed',
                results: [],
                errorCategory: 'selection_invalid',
            })

            return { generationId, status: 'failed' }
        }

        const generationResult = await this.generateResults(
            uploadId,
            upload.storageKey,
            selectedFaces,
        )

        if (!generationResult.results) {
            await this.repository.completeGeneration({
                generationId,
                status: 'failed',
                results: [],
                errorCategory: 'generation_failed',
                errorMessage: generationResult.errorMessage,
            })

            return { generationId, status: 'failed' }
        }

        await this.repository.completeGeneration({
            generationId,
            status: 'succeeded',
            results: generationResult.results,
        })

        return { generationId, status: 'succeeded' }
    }

    async getGeneration(
        generationId: string,
    ): Promise<GenerationStatusResponseDto> {
        return (
            (await this.repository.findGeneration(generationId)) ?? {
                generationId,
                status: 'failed',
                results: [],
                errorCategory: 'result_unavailable',
            }
        )
    }

    private resolveSelectedFaces(
        faces: DetectedFaceDto[],
        request: CreateGenerationRequestDto,
    ): DetectedFaceDto[] {
        if (
            request.selectionMode !== 'single_face' &&
            request.selectionMode !== 'selected_faces' &&
            request.selectionMode !== 'all_faces'
        ) {
            throw new BadRequestException({
                message:
                    'selectionMode must be single_face, selected_faces, or all_faces.',
                errorCategory: 'selection_invalid',
            })
        }

        if (request.selectionMode === 'all_faces') {
            return faces
        }

        if (request.selectionMode === 'single_face') {
            if (!request.faceId) {
                throw new BadRequestException({
                    message:
                        'faceId is required when selectionMode is single_face.',
                    errorCategory: 'selection_invalid',
                })
            }

            const selectedFace = faces.find((face) => face.id === request.faceId)
            if (!selectedFace) {
                throw new BadRequestException({
                    message: 'faceId does not belong to the upload.',
                    errorCategory: 'selection_invalid',
                })
            }

            return [selectedFace]
        }

        if (request.faceIds !== undefined && !Array.isArray(request.faceIds)) {
            throw new BadRequestException({
                message:
                    'faceIds must be an array when selectionMode is selected_faces.',
                errorCategory: 'selection_invalid',
            })
        }

        const requestedFaceIds = Array.from(new Set(request.faceIds ?? []))
        if (requestedFaceIds.length === 0) {
            throw new BadRequestException({
                message:
                    'faceIds must include at least one face when selectionMode is selected_faces.',
                errorCategory: 'selection_invalid',
            })
        }

        const selectedFaces = requestedFaceIds.map((faceId) => {
            const face = faces.find((candidate) => candidate.id === faceId)
            if (!face) {
                throw new BadRequestException({
                    message: 'faceIds must belong to the upload.',
                    errorCategory: 'selection_invalid',
                })
            }

            return face
        })

        return selectedFaces
    }

    private toStoredFaces(faces: DetectedFaceDto[]): DetectedFaceDto[] {
        return faces.map((face) => ({
            ...face,
            id: randomUUID(),
            box: { ...face.box },
        }))
    }

    private async generateResults(
        uploadId: string,
        sourceStorageKey: string,
        selectedFaces: DetectedFaceDto[],
    ): Promise<{ results?: GeneratedPhotoRecord[]; errorMessage?: string }> {
        const results: GeneratedPhotoRecord[] = []

        try {
            for (const face of selectedFaces) {
                const result = await this.aiClient.generateIdPhoto({
                    uploadId,
                    faceId: face.id,
                    sourceStorageKey,
                    box: face.box,
                })
                results.push({
                    generatedPhotoId: randomUUID(),
                    faceId: face.id,
                    resultUrl: `/results/${result.resultStorageKey}`,
                    storageKey: result.resultStorageKey,
                    width: result.width,
                    height: result.height,
                    contentType: result.contentType,
                    byteSize: result.byteSize,
                })
            }

            return { results }
        } catch (error) {
            return {
                errorMessage:
                    error instanceof Error
                        ? error.message
                        : 'Generation failed.',
            }
        }
    }
}

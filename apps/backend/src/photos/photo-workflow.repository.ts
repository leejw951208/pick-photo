import { PrismaPg } from '@prisma/adapter-pg'
import { Prisma, PrismaClient } from '../generated/prisma/client'
import {
    CreateGenerationRequestDto,
    DetectedFaceDto,
    ErrorCategory,
    GenerationStatusResponseDto,
    WorkflowStatus,
} from './dto'

type EnvLike = Record<string, string | undefined>

export const PHOTO_WORKFLOW_REPOSITORY = Symbol('PHOTO_WORKFLOW_REPOSITORY')

export interface StoredUpload {
    uploadId: string
    storageKey: string
    faces: DetectedFaceDto[]
    status: WorkflowStatus
    errorCategory?: ErrorCategory
}

export interface CreateUploadRecordInput {
    uploadId: string
    originalFilename: string
    contentType: string
    byteSize: number
    storageKey: string
    status: WorkflowStatus
}

export interface CompleteFaceDetectionInput {
    uploadId: string
    status: WorkflowStatus
    faces: DetectedFaceDto[]
    errorCategory?: ErrorCategory
    errorMessage?: string
}

export interface CreateGenerationRecordInput {
    generationId: string
    uploadId: string
    selectionMode: CreateGenerationRequestDto['selectionMode']
    selectedFaces: DetectedFaceDto[]
    status: WorkflowStatus
}

export interface GeneratedPhotoRecord {
    generatedPhotoId: string
    faceId: string
    resultUrl: string
    storageKey: string
    width: number
    height: number
    contentType: string
    byteSize: number
}

export interface CompleteGenerationInput {
    generationId: string
    status: WorkflowStatus
    results: GeneratedPhotoRecord[]
    errorCategory?: ErrorCategory
    errorMessage?: string
}

export interface PhotoWorkflowRepository {
    createUpload(input: CreateUploadRecordInput): Promise<void>
    completeFaceDetection(input: CompleteFaceDetectionInput): Promise<void>
    findUpload(uploadId: string): Promise<StoredUpload | undefined>
    createGeneration(input: CreateGenerationRecordInput): Promise<void>
    completeGeneration(input: CompleteGenerationInput): Promise<void>
    findGeneration(
        generationId: string,
    ): Promise<GenerationStatusResponseDto | undefined>
}

export class InMemoryPhotoWorkflowRepository implements PhotoWorkflowRepository {
    private readonly uploads = new Map<string, StoredUpload>()
    private readonly generations = new Map<
        string,
        GenerationStatusResponseDto
    >()

    async createUpload(input: CreateUploadRecordInput): Promise<void> {
        this.uploads.set(input.uploadId, {
            uploadId: input.uploadId,
            storageKey: input.storageKey,
            faces: [],
            status: input.status,
        })
    }

    async completeFaceDetection(
        input: CompleteFaceDetectionInput,
    ): Promise<void> {
        const upload = this.uploads.get(input.uploadId)
        if (!upload) {
            return
        }

        this.uploads.set(input.uploadId, {
            ...upload,
            faces: input.faces,
            status: input.status,
            errorCategory: input.errorCategory,
        })
    }

    async findUpload(uploadId: string): Promise<StoredUpload | undefined> {
        const upload = this.uploads.get(uploadId)
        if (!upload) {
            return undefined
        }

        return {
            ...upload,
            faces: upload.faces.map((face) => ({
                ...face,
                box: { ...face.box },
            })),
        }
    }

    async createGeneration(input: CreateGenerationRecordInput): Promise<void> {
        this.generations.set(input.generationId, {
            generationId: input.generationId,
            status: input.status,
            results: [],
        })
    }

    async completeGeneration(input: CompleteGenerationInput): Promise<void> {
        this.generations.set(input.generationId, {
            generationId: input.generationId,
            status: input.status,
            results: input.results.map((result) => ({
                generatedPhotoId: result.generatedPhotoId,
                faceId: result.faceId,
                resultUrl: result.resultUrl,
            })),
            errorCategory: input.errorCategory,
        })
    }

    async findGeneration(
        generationId: string,
    ): Promise<GenerationStatusResponseDto | undefined> {
        const generation = this.generations.get(generationId)
        if (!generation) {
            return undefined
        }

        return {
            generationId: generation.generationId,
            status: generation.status,
            results: generation.results.map((result) => ({ ...result })),
            errorCategory: generation.errorCategory,
        }
    }
}

export class PrismaPhotoWorkflowRepository implements PhotoWorkflowRepository {
    constructor(private readonly prisma: PrismaClient) {}

    async createUpload(input: CreateUploadRecordInput): Promise<void> {
        await this.prisma.photoUpload.create({
            data: {
                id: input.uploadId,
                originalFilename: input.originalFilename,
                contentType: input.contentType,
                byteSize: BigInt(input.byteSize),
                storageKey: input.storageKey,
                status: input.status,
            },
        })
    }

    async completeFaceDetection(
        input: CompleteFaceDetectionInput,
    ): Promise<void> {
        await this.withTransaction(async (client) => {
            await client.detectedFace.deleteMany({
                where: { photoUploadId: input.uploadId },
            })

            if (input.faces.length > 0) {
                await client.detectedFace.createMany({
                    data: input.faces.map((face) => ({
                        id: face.id,
                        photoUploadId: input.uploadId,
                        faceIndex: face.faceIndex,
                        boundingBoxLeft: face.box.left,
                        boundingBoxTop: face.box.top,
                        boundingBoxWidth: face.box.width,
                        boundingBoxHeight: face.box.height,
                        confidence: face.confidence,
                    })),
                })
            }

            await client.photoUpload.updateMany({
                where: { id: input.uploadId },
                data: {
                    status: input.status,
                    errorCategory: input.errorCategory ?? null,
                    errorMessage: input.errorMessage ?? null,
                    updatedAt: new Date(),
                },
            })
        })
    }

    async findUpload(uploadId: string): Promise<StoredUpload | undefined> {
        const upload = await this.prisma.photoUpload.findFirst({
            where: { id: uploadId, deletedAt: null },
            select: {
                id: true,
                storageKey: true,
                status: true,
                errorCategory: true,
            },
        })

        if (!upload) {
            return undefined
        }

        const faces = await this.prisma.detectedFace.findMany({
            where: { photoUploadId: uploadId },
            orderBy: { faceIndex: 'asc' },
            select: {
                id: true,
                faceIndex: true,
                boundingBoxLeft: true,
                boundingBoxTop: true,
                boundingBoxWidth: true,
                boundingBoxHeight: true,
                confidence: true,
            },
        })

        return {
            uploadId: upload.id,
            storageKey: upload.storageKey,
            status: upload.status as WorkflowStatus,
            errorCategory:
                (upload.errorCategory as ErrorCategory | null) ?? undefined,
            faces: faces.map((face) => ({
                id: face.id,
                faceIndex: face.faceIndex,
                box: {
                    left: face.boundingBoxLeft,
                    top: face.boundingBoxTop,
                    width: face.boundingBoxWidth,
                    height: face.boundingBoxHeight,
                },
                confidence: Number(face.confidence),
            })),
        }
    }

    async createGeneration(input: CreateGenerationRecordInput): Promise<void> {
        await this.withTransaction(async (client) => {
            await client.generationJob.create({
                data: {
                    id: input.generationId,
                    photoUploadId: input.uploadId,
                    selectionMode: input.selectionMode,
                    status: input.status,
                },
            })

            if (input.selectedFaces.length > 0) {
                await client.generationJobFace.createMany({
                    data: input.selectedFaces.map((face) => ({
                        generationJobId: input.generationId,
                        detectedFaceId: face.id,
                        photoUploadId: input.uploadId,
                    })),
                })
            }
        })
    }

    async completeGeneration(input: CompleteGenerationInput): Promise<void> {
        await this.withTransaction(async (client) => {
            await client.generatedPhoto.deleteMany({
                where: { generationJobId: input.generationId },
            })

            if (input.results.length > 0) {
                await client.generatedPhoto.createMany({
                    data: input.results.map((result) => ({
                        id: result.generatedPhotoId,
                        generationJobId: input.generationId,
                        detectedFaceId: result.faceId,
                        storageKey: result.storageKey,
                        width: result.width,
                        height: result.height,
                        contentType: result.contentType,
                        byteSize: BigInt(result.byteSize),
                    })),
                })
            }

            await client.generationJob.updateMany({
                where: { id: input.generationId },
                data: {
                    status: input.status,
                    errorCategory: input.errorCategory ?? null,
                    errorMessage: input.errorMessage ?? null,
                    completedAt: isTerminalStatus(input.status)
                        ? new Date()
                        : undefined,
                    updatedAt: new Date(),
                },
            })
        })
    }

    async findGeneration(
        generationId: string,
    ): Promise<GenerationStatusResponseDto | undefined> {
        const job = await this.prisma.generationJob.findFirst({
            where: { id: generationId },
            select: {
                id: true,
                status: true,
                errorCategory: true,
            },
        })

        if (!job) {
            return undefined
        }

        const results = await this.prisma.generatedPhoto.findMany({
            where: { generationJobId: generationId, deletedAt: null },
            orderBy: { createdAt: 'asc' },
            select: {
                id: true,
                detectedFaceId: true,
                storageKey: true,
            },
        })

        return {
            generationId: job.id,
            status: job.status as WorkflowStatus,
            results: results.map((row) => ({
                generatedPhotoId: row.id,
                faceId: row.detectedFaceId,
                resultUrl: `/results/${row.storageKey}`,
            })),
            errorCategory:
                (job.errorCategory as ErrorCategory | null) ?? undefined,
        }
    }

    private async withTransaction<T>(
        operation: (client: Prisma.TransactionClient) => Promise<T>,
    ): Promise<T> {
        return this.prisma.$transaction(operation)
    }

    async onModuleDestroy(): Promise<void> {
        await this.prisma.$disconnect()
    }
}

function isTerminalStatus(status: WorkflowStatus): boolean {
    return status === 'succeeded' || status === 'failed'
}

export function createWorkflowRepository(
    env: EnvLike = process.env,
): PhotoWorkflowRepository {
    if (env.DATABASE_URL) {
        const adapter = new PrismaPg({ connectionString: env.DATABASE_URL })
        return new PrismaPhotoWorkflowRepository(new PrismaClient({ adapter }))
    }

    return new InMemoryPhotoWorkflowRepository()
}

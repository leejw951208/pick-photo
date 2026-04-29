import {
    createWorkflowRepository,
    InMemoryPhotoWorkflowRepository,
} from './photo-workflow.repository'

describe('InMemoryPhotoWorkflowRepository', () => {
    it('persists upload, detected face, generation, and result metadata', async () => {
        const repository = new InMemoryPhotoWorkflowRepository()
        const face = {
            id: 'face-id',
            faceIndex: 0,
            box: { left: 80, top: 60, width: 240, height: 280 },
            confidence: 0.98,
        }

        await repository.createUpload({
            uploadId: 'upload-id',
            originalFilename: 'person.jpg',
            contentType: 'image/jpeg',
            byteSize: 10,
            storageKey: 'uploads/upload-id/person.jpg',
            status: 'processing',
        })
        await repository.completeFaceDetection({
            uploadId: 'upload-id',
            status: 'succeeded',
            faces: [face],
        })

        await expect(repository.findUpload('upload-id')).resolves.toEqual({
            uploadId: 'upload-id',
            storageKey: 'uploads/upload-id/person.jpg',
            faces: [face],
            status: 'succeeded',
        })

        await repository.createGeneration({
            generationId: 'generation-id',
            uploadId: 'upload-id',
            selectionMode: 'all_faces',
            selectedFaces: [face],
            status: 'processing',
        })
        await repository.completeGeneration({
            generationId: 'generation-id',
            status: 'succeeded',
            results: [
                {
                    generatedPhotoId: 'generated-photo-id',
                    faceId: 'face-id',
                    resultUrl: '/results/generated/upload-id/face-id.jpg',
                    storageKey: 'generated/upload-id/face-id.jpg',
                    width: 413,
                    height: 531,
                    contentType: 'image/jpeg',
                    byteSize: 1,
                },
            ],
        })

        await expect(
            repository.findGeneration('generation-id'),
        ).resolves.toEqual({
            generationId: 'generation-id',
            status: 'succeeded',
            results: [
                {
                    generatedPhotoId: 'generated-photo-id',
                    faceId: 'face-id',
                    resultUrl: '/results/generated/upload-id/face-id.jpg',
                },
            ],
            errorCategory: undefined,
        })
    })
})

describe('createWorkflowRepository', () => {
    it('uses the in-memory repository when DATABASE_URL is not configured', () => {
        const repository = createWorkflowRepository({})

        expect(repository).toBeInstanceOf(InMemoryPhotoWorkflowRepository)
    })

    it('uses the Prisma repository when DATABASE_URL is configured', () => {
        const repository = createWorkflowRepository({
            DATABASE_URL:
                'postgresql://pick_photo:pick_photo_dev@localhost:5432/pick_photo',
        })

        expect(repository.constructor.name).toBe(
            'PrismaPhotoWorkflowRepository',
        )
    })
})

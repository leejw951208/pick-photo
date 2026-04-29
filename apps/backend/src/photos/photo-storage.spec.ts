import { mkdtemp, readFile, rm } from 'node:fs/promises'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import { LocalPhotoStorage } from './photo-storage'

describe('LocalPhotoStorage', () => {
    let rootDir: string

    beforeEach(async () => {
        rootDir = await mkdtemp(join(tmpdir(), 'pick-photo-storage-'))
    })

    afterEach(async () => {
        await rm(rootDir, { force: true, recursive: true })
    })

    it('stores upload bytes under an upload-scoped safe storage key', async () => {
        const storage = new LocalPhotoStorage(rootDir)

        const storageKey = await storage.saveUpload({
            uploadId: 'upload-123',
            originalName: '../Face Shot.jpg',
            contentType: 'image/jpeg',
            bytes: Buffer.from('image-bytes'),
        })

        expect(storageKey).toBe('uploads/upload-123/face-shot.jpg')
        await expect(readFile(join(rootDir, storageKey), 'utf8')).resolves.toBe(
            'image-bytes',
        )
    })
})

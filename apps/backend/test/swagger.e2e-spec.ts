import { INestApplication } from '@nestjs/common'
import { Test } from '@nestjs/testing'
import request from 'supertest'
import { AppModule } from '../src/app.module'
import { setupOpenApi } from '../src/openapi'

describe('OpenAPI documentation', () => {
    let app: INestApplication

    beforeEach(async () => {
        const moduleRef = await Test.createTestingModule({
            imports: [AppModule],
        }).compile()
        app = moduleRef.createNestApplication()
        setupOpenApi(app)
        await app.init()
    })

    afterEach(async () => {
        await app.close()
    })

    it('serves the Swagger UI', async () => {
        const response = await request(app.getHttpServer())
            .get('/docs')
            .expect(200)

        expect(response.headers['content-type']).toContain('text/html')
        expect(response.text).toContain('Pick Photo API Docs')
    })

    it('serves an OpenAPI JSON document for the photo workflow', async () => {
        const response = await request(app.getHttpServer())
            .get('/docs-json')
            .expect(200)

        expect(response.body.info.title).toBe('Pick Photo API')
        expect(response.body.paths).toEqual(
            expect.objectContaining({
                '/photos/uploads': expect.any(Object),
                '/photos/uploads/{uploadId}/faces': expect.any(Object),
                '/photos/uploads/{uploadId}/generations': expect.any(Object),
                '/photos/generations/{generationId}': expect.any(Object),
            }),
        )
        expect(
            response.body.paths['/photos/uploads'].post.requestBody.content,
        ).toHaveProperty('multipart/form-data')
        expect(
            response.body.paths['/photos/uploads/{uploadId}/generations'].post
                .requestBody.content,
        ).toHaveProperty('application/json')
    })
})

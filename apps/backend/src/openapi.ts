import { INestApplication } from '@nestjs/common'
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger'

export function setupOpenApi(app: INestApplication) {
    const config = new DocumentBuilder()
        .setTitle('Pick Photo API')
        .setDescription(
            'Application API for uploading photos, reviewing detected faces, and requesting ID-photo generation.',
        )
        .setVersion('0.1.0')
        .addTag(
            'photos',
            'Photo upload, face review, and ID-photo generation workflow',
        )
        .build()

    const document = SwaggerModule.createDocument(app, config)

    SwaggerModule.setup('docs', app, document, {
        jsonDocumentUrl: 'docs-json',
        customSiteTitle: 'Pick Photo API Docs',
    })
}

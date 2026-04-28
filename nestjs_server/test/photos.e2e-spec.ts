import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { AppModule } from '../src/app.module';

describe('Photos workflow', () => {
  let app: INestApplication;

  beforeEach(async () => {
    const moduleRef = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();
    app = moduleRef.createNestApplication();
    await app.init();
  });

  afterEach(async () => {
    await app.close();
  });

  it('uploads a photo, lists faces, generates all faces, and fetches results', async () => {
    const upload = await request(app.getHttpServer())
      .post('/photos/uploads')
      .attach('photo', Buffer.from('fake-image'), 'person.jpg')
      .expect(201);

    const uploadId = upload.body.uploadId;

    const faces = await request(app.getHttpServer())
      .get(`/photos/uploads/${uploadId}/faces`)
      .expect(200);

    expect(faces.body.faces).toHaveLength(1);

    const generation = await request(app.getHttpServer())
      .post(`/photos/uploads/${uploadId}/generations`)
      .send({ selectionMode: 'all_faces' })
      .expect(201);

    const result = await request(app.getHttpServer())
      .get(`/photos/generations/${generation.body.generationId}`)
      .expect(200);

    expect(result.body.results).toHaveLength(1);
  });
});

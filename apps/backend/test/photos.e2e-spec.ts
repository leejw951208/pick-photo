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

  it('rejects a missing upload file', async () => {
    const response = await request(app.getHttpServer())
      .post('/photos/uploads')
      .expect(400);

    expect(response.body.errorCategory).toBe('upload_invalid');
  });

  it('rejects an upload with an invalid MIME type', async () => {
    const response = await request(app.getHttpServer())
      .post('/photos/uploads')
      .attach('photo', Buffer.from('not-an-image'), {
        filename: 'notes.txt',
        contentType: 'text/plain',
      })
      .expect(400);

    expect(response.body.errorCategory).toBe('upload_invalid');
  });

  it('marks a no-face upload as failed and returns no faces', async () => {
    const upload = await request(app.getHttpServer())
      .post('/photos/uploads')
      .attach('photo', Buffer.from('fake-image'), 'no-face.jpg')
      .expect(201);

    expect(upload.body.status).toBe('failed');

    const faces = await request(app.getHttpServer())
      .get(`/photos/uploads/${upload.body.uploadId}/faces`)
      .expect(200);

    expect(faces.body.faces).toEqual([]);
  });

  it('rejects an invalid generation selection mode', async () => {
    const upload = await request(app.getHttpServer())
      .post('/photos/uploads')
      .attach('photo', Buffer.from('fake-image'), 'person.jpg')
      .expect(201);

    const response = await request(app.getHttpServer())
      .post(`/photos/uploads/${upload.body.uploadId}/generations`)
      .send({
        selectionMode: 'primary_face',
        faceId: `${upload.body.uploadId}-face-0`,
      })
      .expect(400);

    expect(response.body.errorCategory).toBe('selection_invalid');
  });

  it('rejects single-face generation without a face id', async () => {
    const upload = await request(app.getHttpServer())
      .post('/photos/uploads')
      .attach('photo', Buffer.from('fake-image'), 'person.jpg')
      .expect(201);

    const response = await request(app.getHttpServer())
      .post(`/photos/uploads/${upload.body.uploadId}/generations`)
      .send({ selectionMode: 'single_face' })
      .expect(400);

    expect(response.body.errorCategory).toBe('selection_invalid');
  });

  it('rejects single-face generation when the face id does not belong to the upload', async () => {
    const upload = await request(app.getHttpServer())
      .post('/photos/uploads')
      .attach('photo', Buffer.from('fake-image'), 'person.jpg')
      .expect(201);

    const response = await request(app.getHttpServer())
      .post(`/photos/uploads/${upload.body.uploadId}/generations`)
      .send({ selectionMode: 'single_face', faceId: 'another-upload-face-0' })
      .expect(400);

    expect(response.body.errorCategory).toBe('selection_invalid');
  });

  it('rejects generation for an unknown upload', async () => {
    const response = await request(app.getHttpServer())
      .post('/photos/uploads/upload-missing/generations')
      .send({ selectionMode: 'all_faces' })
      .expect(404);

    expect(response.body.errorCategory).toBe('result_unavailable');
  });

  it('returns failed result unavailable status for an unknown generation lookup', async () => {
    const result = await request(app.getHttpServer())
      .get('/photos/generations/generation-missing')
      .expect(200);

    expect(result.body).toEqual({
      generationId: 'generation-missing',
      status: 'failed',
      results: [],
      errorCategory: 'result_unavailable',
    });
  });
});

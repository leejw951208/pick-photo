import { FakeAiClient, HttpAiClient, createAiClient } from './ai-client';

describe('HttpAiClient', () => {
  const originalFetch = global.fetch;

  afterEach(() => {
    global.fetch = originalFetch;
    jest.restoreAllMocks();
  });

  it('maps detect-faces HTTP responses into backend face DTOs', async () => {
    const fetchMock = jest.fn().mockResolvedValue({
      ok: true,
      json: async () => ({
        upload_id: 'upload-id',
        faces: [
          {
            face_id: 'remote-face-id',
            face_index: 2,
            box: { left: 11, top: 22, width: 33, height: 44 },
            confidence: 0.91,
          },
        ],
      }),
    });
    global.fetch = fetchMock as unknown as typeof fetch;

    const client = new HttpAiClient('http://ai.local');
    const faces = await client.detectFaces({
      uploadId: 'upload-id',
      storageKey: 'uploads/upload-id/person.jpg',
    });

    expect(faces).toEqual([
      {
        id: 'remote-face-id',
        faceIndex: 2,
        box: { left: 11, top: 22, width: 33, height: 44 },
        confidence: 0.91,
      },
    ]);
    expect(fetchMock).toHaveBeenCalledWith(
      'http://ai.local/detect-faces',
      expect.objectContaining({
        method: 'POST',
        headers: { 'content-type': 'application/json' },
        body: JSON.stringify({
          upload_id: 'upload-id',
          storage_key: 'uploads/upload-id/person.jpg',
        }),
      }),
    );
  });

  it('maps generate-id-photo HTTP responses into backend result metadata', async () => {
    const fetchMock = jest.fn().mockResolvedValue({
      ok: true,
      json: async () => ({
        upload_id: 'upload-id',
        face_id: 'face-id',
        result_storage_key: 'generated/upload-id/face-id.jpg',
        width: 413,
        height: 531,
        content_type: 'image/jpeg',
      }),
    });
    global.fetch = fetchMock as unknown as typeof fetch;

    const client = new HttpAiClient('http://ai.local/');
    const result = await client.generateIdPhoto({
      uploadId: 'upload-id',
      faceId: 'face-id',
      sourceStorageKey: 'uploads/upload-id/person.jpg',
      box: { left: 1, top: 2, width: 3, height: 4 },
    });

    expect(result).toEqual({
      resultStorageKey: 'generated/upload-id/face-id.jpg',
      width: 413,
      height: 531,
      contentType: 'image/jpeg',
      byteSize: 1,
    });
    expect(fetchMock).toHaveBeenCalledWith(
      'http://ai.local/generate-id-photo',
      expect.objectContaining({
        method: 'POST',
        body: JSON.stringify({
          upload_id: 'upload-id',
          face_id: 'face-id',
          source_storage_key: 'uploads/upload-id/person.jpg',
          box: { left: 1, top: 2, width: 3, height: 4 },
        }),
      }),
    );
  });

  it('raises a clear error when the AI service rejects a request', async () => {
    const fetchMock = jest.fn().mockResolvedValue({
      ok: false,
      status: 503,
      text: async () => 'unavailable',
    });
    global.fetch = fetchMock as unknown as typeof fetch;

    const client = new HttpAiClient('http://ai.local');

    await expect(
      client.detectFaces({
        uploadId: 'upload-id',
        storageKey: 'uploads/a.jpg',
      }),
    ).rejects.toThrow('AI service request failed with status 503');
  });
});

describe('createAiClient', () => {
  it('uses the HTTP adapter only when an AI service URL is configured', () => {
    expect(
      createAiClient({ AI_SERVICE_BASE_URL: 'http://ai.local' }),
    ).toBeInstanceOf(HttpAiClient);
    expect(createAiClient({})).toBeInstanceOf(FakeAiClient);
  });
});

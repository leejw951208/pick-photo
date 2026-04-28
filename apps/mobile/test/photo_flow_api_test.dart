import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pick_photo/features/photo_flow/photo_flow_api.dart';

void main() {
  test(
      'NestPhotoFlowApi uploads, fetches faces, generates, and fetches results',
      () async {
    final requests = <String>[];
    final api = NestPhotoFlowApi(
      baseUrl: 'http://server.test',
      client: MockClient((request) async {
        requests.add('${request.method} ${request.url.path}');

        if (request.url.path == '/photos/uploads') {
          expect(
              request.headers['content-type'], contains('multipart/form-data'));
          expect(request, isA<http.Request>());
          expect((request as http.Request).bodyBytes, isNotEmpty);
          return http.Response(
            '{"uploadId":"upload-1","status":"succeeded"}',
            201,
          );
        }

        if (request.url.path == '/photos/uploads/upload-1/faces') {
          return http.Response(
            '''
            {
              "uploadId": "upload-1",
              "faces": [
                {
                  "id": "upload-1-face-0",
                  "faceIndex": 0,
                  "box": {"left": 80, "top": 60, "width": 240, "height": 280},
                  "confidence": 0.98
                }
              ]
            }
            ''',
            200,
          );
        }

        if (request.url.path == '/photos/uploads/upload-1/generations') {
          expect(request, isA<http.Request>());
          expect((request as http.Request).body,
              '{"selectionMode":"single_face","faceId":"upload-1-face-0"}');
          return http.Response(
            '{"generationId":"generation-1","status":"succeeded"}',
            201,
          );
        }

        if (request.url.path == '/photos/generations/generation-1') {
          return http.Response(
            '''
            {
              "generationId": "generation-1",
              "status": "succeeded",
              "results": [
                {
                  "generatedPhotoId": "generation-1-upload-1-face-0",
                  "faceId": "upload-1-face-0",
                  "resultUrl": "/results/generated/upload-1/upload-1-face-0.jpg"
                }
              ]
            }
            ''',
            200,
          );
        }

        return http.Response('not found', 404);
      }),
    );

    final detection = await api.uploadAndDetectFaces(
      LocalPhotoFile(
        name: 'person.jpg',
        bytes: Uint8List.fromList([1, 2, 3]),
        contentType: 'image/jpeg',
      ),
    );
    final results = await api.generateForFaces(
      detection.uploadId,
      {detection.faces.single.id},
    );

    expect(detection.uploadId, 'upload-1');
    expect(detection.faces.single.id, 'upload-1-face-0');
    expect(results.single.url,
        'http://server.test/results/generated/upload-1/upload-1-face-0.jpg');
    expect(requests, [
      'POST /photos/uploads',
      'GET /photos/uploads/upload-1/faces',
      'POST /photos/uploads/upload-1/generations',
      'GET /photos/generations/generation-1',
    ]);
  });
}

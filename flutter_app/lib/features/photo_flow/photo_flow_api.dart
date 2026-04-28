import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'photo_flow_state.dart';

class LocalPhotoFile {
  const LocalPhotoFile({
    required this.name,
    required this.bytes,
    required this.contentType,
  });

  final String name;
  final Uint8List bytes;
  final String contentType;
}

class FaceDetectionResult {
  const FaceDetectionResult({
    required this.uploadId,
    required this.faces,
  });

  final String uploadId;
  final List<DetectedFace> faces;
}

class PhotoFlowApiException implements Exception {
  const PhotoFlowApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract class PhotoFlowApi {
  Future<FaceDetectionResult> uploadAndDetectFaces(LocalPhotoFile photo);
  Future<List<GeneratedPhoto>> generateForFaces(
    String uploadId,
    Set<String> faceIds,
  );
}

class NestPhotoFlowApi implements PhotoFlowApi {
  NestPhotoFlowApi({
    String baseUrl = const String.fromEnvironment(
      'PICK_PHOTO_API_BASE_URL',
      defaultValue: 'http://localhost:3000',
    ),
    http.Client? client,
  })  : _baseUrl = baseUrl.endsWith('/')
            ? baseUrl.substring(0, baseUrl.length - 1)
            : baseUrl,
        _client = client ?? http.Client();

  final String _baseUrl;
  final http.Client _client;

  @override
  Future<FaceDetectionResult> uploadAndDetectFaces(LocalPhotoFile photo) async {
    final uploadRequest = http.MultipartRequest(
      'POST',
      _uri('/photos/uploads'),
    );
    uploadRequest.files.add(
      http.MultipartFile.fromBytes(
        'photo',
        photo.bytes,
        filename: photo.name,
        contentType: MediaType.parse(photo.contentType),
      ),
    );

    final uploadResponse = await http.Response.fromStream(
      await _client.send(uploadRequest),
    );
    final uploadBody = _decodeObject(uploadResponse);
    final uploadId = uploadBody['uploadId'] as String?;

    if (uploadId == null || uploadId.isEmpty) {
      throw const PhotoFlowApiException(
          'Upload response did not include uploadId.');
    }

    final facesResponse = await _client.get(
      _uri('/photos/uploads/$uploadId/faces'),
    );
    final facesBody = _decodeObject(facesResponse);
    final faces = (facesBody['faces'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(_detectedFaceFromJson)
        .toList();

    return FaceDetectionResult(uploadId: uploadId, faces: faces);
  }

  @override
  Future<List<GeneratedPhoto>> generateForFaces(
    String uploadId,
    Set<String> faceIds,
  ) async {
    if (faceIds.isEmpty) {
      return const [];
    }

    final createResponse = await _client.post(
      _uri('/photos/uploads/$uploadId/generations'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(
        faceIds.length == 1
            ? {'selectionMode': 'single_face', 'faceId': faceIds.single}
            : {'selectionMode': 'all_faces'},
      ),
    );
    final createBody = _decodeObject(createResponse);
    final generationId = createBody['generationId'] as String?;

    if (generationId == null || generationId.isEmpty) {
      throw const PhotoFlowApiException(
        'Generation response did not include generationId.',
      );
    }

    final generationResponse = await _client.get(
      _uri('/photos/generations/$generationId'),
    );
    final generationBody = _decodeObject(generationResponse);

    return (generationBody['results'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(_generatedPhotoFromJson)
        .toList();
  }

  Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  Map<String, dynamic> _decodeObject(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw PhotoFlowApiException(
        'Request failed with status ${response.statusCode}.',
      );
    }

    final body = jsonDecode(response.body);
    if (body is! Map<String, dynamic>) {
      throw const PhotoFlowApiException('Response body was not an object.');
    }

    return body;
  }

  DetectedFace _detectedFaceFromJson(Map<String, dynamic> json) {
    return DetectedFace(
      id: json['id'] as String,
      faceIndex: json['faceIndex'] as int,
      confidence: (json['confidence'] as num).toDouble(),
    );
  }

  GeneratedPhoto _generatedPhotoFromJson(Map<String, dynamic> json) {
    return GeneratedPhoto(
      id: json['generatedPhotoId'] as String,
      faceId: json['faceId'] as String,
      url: '$_baseUrl${json['resultUrl'] as String}',
    );
  }
}

class FakePhotoFlowApi implements PhotoFlowApi {
  @override
  Future<FaceDetectionResult> uploadAndDetectFaces(LocalPhotoFile photo) async {
    if (photo.name.contains('no-face')) {
      return const FaceDetectionResult(uploadId: 'upload-1', faces: []);
    }

    return const FaceDetectionResult(
      uploadId: 'upload-1',
      faces: [
        DetectedFace(id: 'face-1', faceIndex: 0, confidence: 0.98),
      ],
    );
  }

  @override
  Future<List<GeneratedPhoto>> generateForFaces(
    String uploadId,
    Set<String> faceIds,
  ) async {
    return faceIds
        .map(
          (faceId) => GeneratedPhoto(
            id: 'generated-$faceId',
            faceId: faceId,
            url: 'https://example.invalid/results/$faceId.jpg',
          ),
        )
        .toList();
  }
}

import 'photo_flow_state.dart';

abstract class PhotoFlowApi {
  Future<List<DetectedFace>> uploadAndDetectFaces(String localPhotoPath);
  Future<List<GeneratedPhoto>> generateForFaces(Set<String> faceIds);
}

class FakePhotoFlowApi implements PhotoFlowApi {
  @override
  Future<List<DetectedFace>> uploadAndDetectFaces(String localPhotoPath) async {
    if (localPhotoPath.contains('no-face')) {
      return const [];
    }

    return const [
      DetectedFace(id: 'face-1', faceIndex: 0, confidence: 0.98),
    ];
  }

  @override
  Future<List<GeneratedPhoto>> generateForFaces(Set<String> faceIds) async {
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

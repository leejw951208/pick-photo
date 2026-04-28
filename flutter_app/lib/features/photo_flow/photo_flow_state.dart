enum PhotoFlowStage {
  waitingForUpload,
  uploading,
  reviewingFaces,
  generating,
  completed,
  failed,
}

class DetectedFace {
  const DetectedFace({
    required this.id,
    required this.faceIndex,
    required this.confidence,
  });

  final String id;
  final int faceIndex;
  final double confidence;
}

class GeneratedPhoto {
  const GeneratedPhoto({
    required this.id,
    required this.faceId,
    required this.url,
  });

  final String id;
  final String faceId;
  final String url;
}

class PhotoFlowState {
  PhotoFlowState({
    required this.stage,
    required List<DetectedFace> faces,
    required Set<String> selectedFaceIds,
    required List<GeneratedPhoto> results,
    this.message,
  })  : faces = List.unmodifiable(faces),
        selectedFaceIds = Set.unmodifiable(selectedFaceIds),
        results = List.unmodifiable(results);

  const PhotoFlowState.initial()
      : stage = PhotoFlowStage.waitingForUpload,
        faces = const [],
        selectedFaceIds = const {},
        results = const [],
        message = null;

  final PhotoFlowStage stage;
  final List<DetectedFace> faces;
  final Set<String> selectedFaceIds;
  final List<GeneratedPhoto> results;
  final String? message;

  PhotoFlowState copyWith({
    PhotoFlowStage? stage,
    List<DetectedFace>? faces,
    Set<String>? selectedFaceIds,
    List<GeneratedPhoto>? results,
    String? message,
    bool clearMessage = false,
  }) {
    return PhotoFlowState(
      stage: stage ?? this.stage,
      faces: faces ?? this.faces,
      selectedFaceIds: selectedFaceIds ?? this.selectedFaceIds,
      results: results ?? this.results,
      message: clearMessage ? null : message ?? this.message,
    );
  }
}

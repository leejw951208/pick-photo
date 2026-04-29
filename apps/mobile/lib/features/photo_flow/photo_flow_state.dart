import 'dart:typed_data';

enum PhotoFlowStage {
  waitingForUpload,
  uploading,
  reviewingFaces,
  generating,
  completed,
  failed,
}

class FaceBox {
  const FaceBox({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  final double left;
  final double top;
  final double width;
  final double height;
}

class DetectedFace {
  const DetectedFace({
    required this.id,
    required this.faceIndex,
    required this.box,
    required this.confidence,
  });

  final String id;
  final int faceIndex;
  final FaceBox box;
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
    this.uploadId,
    Uint8List? sourcePhotoBytes,
    this.message,
  })  : faces = List.unmodifiable(faces),
        selectedFaceIds = Set.unmodifiable(selectedFaceIds),
        results = List.unmodifiable(results),
        _sourcePhotoBytes = sourcePhotoBytes == null
            ? null
            : Uint8List.fromList(sourcePhotoBytes);

  const PhotoFlowState.initial()
      : stage = PhotoFlowStage.waitingForUpload,
        faces = const [],
        selectedFaceIds = const {},
        results = const [],
        uploadId = null,
        _sourcePhotoBytes = null,
        message = null;

  final PhotoFlowStage stage;
  final String? uploadId;
  final Uint8List? _sourcePhotoBytes;
  final List<DetectedFace> faces;
  final Set<String> selectedFaceIds;
  final List<GeneratedPhoto> results;
  final String? message;

  Uint8List? get sourcePhotoBytes {
    final bytes = _sourcePhotoBytes;
    return bytes == null ? null : Uint8List.fromList(bytes);
  }

  PhotoFlowState copyWith({
    PhotoFlowStage? stage,
    List<DetectedFace>? faces,
    Set<String>? selectedFaceIds,
    List<GeneratedPhoto>? results,
    String? uploadId,
    Uint8List? sourcePhotoBytes,
    String? message,
    bool clearUploadId = false,
    bool clearSourcePhotoBytes = false,
    bool clearMessage = false,
  }) {
    return PhotoFlowState(
      stage: stage ?? this.stage,
      faces: faces ?? this.faces,
      selectedFaceIds: selectedFaceIds ?? this.selectedFaceIds,
      results: results ?? this.results,
      uploadId: clearUploadId ? null : uploadId ?? this.uploadId,
      sourcePhotoBytes: clearSourcePhotoBytes
          ? null
          : sourcePhotoBytes ?? this.sourcePhotoBytes,
      message: clearMessage ? null : message ?? this.message,
    );
  }
}

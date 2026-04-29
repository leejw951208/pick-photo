import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pick_photo/features/photo_flow/face_selection_canvas.dart';
import 'package:pick_photo/features/photo_flow/photo_flow_api.dart';
import 'package:pick_photo/features/photo_flow/photo_flow_screen.dart';
import 'package:pick_photo/features/photo_flow/photo_flow_state.dart';
import 'package:pick_photo/features/photo_flow/photo_picker.dart';

void main() {
  testWidgets('shows face selection after upload', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PhotoFlowScreen(
          api: FakePhotoFlowApi(),
          photoPicker: FixedPhotoPicker('person.jpg'),
        ),
      ),
    );

    await tester.tap(find.text('Upload photo'));
    await tester.pumpAndSettle();

    expect(find.text('Face 1'), findsOneWidget);
  });

  testWidgets('shows failure message when upload has no faces', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PhotoFlowScreen(
          api: FakePhotoFlowApi(),
          photoPicker: FixedPhotoPicker('no-face.jpg'),
        ),
      ),
    );

    await tester.tap(find.text('Upload photo'));
    await tester.pumpAndSettle();

    expect(find.text('No face found'), findsOneWidget);
    expect(find.text('Face 1'), findsNothing);
    expect(find.text('Generate all faces'), findsNothing);
  });

  testWidgets('shows retryable failure message when upload throws',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PhotoFlowScreen(
          api: FailingUploadPhotoFlowApi(),
          photoPicker: FixedPhotoPicker('person.jpg'),
        ),
      ),
    );

    await tester.tap(find.text('Upload photo'));
    await tester.pumpAndSettle();

    expect(find.text('Upload failed. Try again'), findsOneWidget);
    expect(find.text('Face 1'), findsNothing);
    expect(find.text('Generate all faces'), findsNothing);
    expect(find.textContaining('Generated result'), findsNothing);
  });

  testWidgets('shows generated result after selecting a face', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PhotoFlowScreen(
          api: FakePhotoFlowApi(),
          photoPicker: FixedPhotoPicker('person.jpg'),
        ),
      ),
    );

    await tester.tap(find.text('Upload photo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Face 1'));
    await tester.pumpAndSettle();

    expect(find.text('Generation complete'), findsOneWidget);
    expect(find.text('Generated result for face-1'), findsOneWidget);
    expect(
      find.text('https://example.invalid/results/face-1.jpg'),
      findsOneWidget,
    );
  });

  testWidgets('shows retryable failure message when generation throws',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PhotoFlowScreen(
          api: FailingGenerationPhotoFlowApi(),
          photoPicker: FixedPhotoPicker('person.jpg'),
        ),
      ),
    );

    await tester.tap(find.text('Upload photo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Face 1'));
    await tester.pumpAndSettle();

    expect(find.text('Generation failed. Try again'), findsOneWidget);
    expect(find.text('Face 1'), findsOneWidget);
    expect(find.textContaining('Generated result'), findsNothing);
  });

  testWidgets('generates results for all detected faces', (tester) async {
    final api = MultiFacePhotoFlowApi();
    await tester.pumpWidget(
      MaterialApp(
        home: PhotoFlowScreen(
          api: api,
          photoPicker: FixedPhotoPicker('person.jpg'),
        ),
      ),
    );

    await tester.tap(find.text('Upload photo'));
    await tester.pumpAndSettle();

    expect(find.text('Face 1'), findsOneWidget);
    expect(find.text('Face 2'), findsOneWidget);

    await tester.tap(find.text('Generate all faces'));
    await tester.pumpAndSettle();

    expect(api.generatedFaceIds, unorderedEquals(['face-1', 'face-2']));
    expect(find.text('Generation complete'), findsOneWidget);
    expect(find.text('Generated result for face-1'), findsOneWidget);
    expect(find.text('Generated result for face-2'), findsOneWidget);
    expect(find.text('https://example.invalid/results/face-1.jpg'),
        findsOneWidget);
    expect(find.text('https://example.invalid/results/face-2.jpg'),
        findsOneWidget);
  });

  testWidgets('toggles a face from the direct selection canvas',
      (tester) async {
    var selectedFaceIds = <String>{};

    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 240,
            child: StatefulBuilder(
              builder: (context, setState) {
                return FaceSelectionCanvas(
                  photoBytes: onePixelPngBytes(),
                  faces: const [
                    DetectedFace(
                      id: 'face-1',
                      faceIndex: 0,
                      box: FaceBox(
                        left: 0.1,
                        top: 0.1,
                        width: 0.8,
                        height: 0.8,
                      ),
                      confidence: 0.98,
                    ),
                  ],
                  selectedFaceIds: selectedFaceIds,
                  onFaceToggled: (faceId) {
                    setState(() {
                      selectedFaceIds = selectedFaceIds.contains(faceId)
                          ? <String>{}
                          : {faceId};
                    });
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('얼굴 1 제외됨'), findsOneWidget);
    expect(find.text('선택한 얼굴 0명'), findsOneWidget);

    await tester.tap(find.text('얼굴 1 제외됨'));
    await tester.pumpAndSettle();

    expect(find.text('얼굴 1 선택됨'), findsOneWidget);
    expect(find.text('선택한 얼굴 1명'), findsOneWidget);
  });
}

class FixedPhotoPicker implements PhotoPicker {
  const FixedPhotoPicker(this.name);

  final String name;

  @override
  Future<LocalPhotoFile?> pickPhoto() async {
    return LocalPhotoFile(
      name: name,
      bytes: onePixelPngBytes(),
      contentType: 'image/png',
    );
  }
}

Uint8List onePixelPngBytes() {
  return Uint8List.fromList([
    137,
    80,
    78,
    71,
    13,
    10,
    26,
    10,
    0,
    0,
    0,
    13,
    73,
    72,
    68,
    82,
    0,
    0,
    0,
    1,
    0,
    0,
    0,
    1,
    8,
    2,
    0,
    0,
    0,
    144,
    119,
    83,
    222,
    0,
    0,
    0,
    13,
    73,
    68,
    65,
    84,
    120,
    218,
    99,
    252,
    207,
    192,
    80,
    15,
    0,
    5,
    131,
    2,
    127,
    148,
    173,
    208,
    95,
    0,
    0,
    0,
    0,
    73,
    69,
    78,
    68,
    174,
    66,
    96,
    130,
  ]);
}

class FailingUploadPhotoFlowApi implements PhotoFlowApi {
  @override
  Future<FaceDetectionResult> uploadAndDetectFaces(LocalPhotoFile photo) async {
    throw StateError('upload failed');
  }

  @override
  Future<List<GeneratedPhoto>> generateForFaces(
    String uploadId,
    Set<String> faceIds,
  ) async {
    return const [];
  }
}

class FailingGenerationPhotoFlowApi implements PhotoFlowApi {
  static const _faceBox = FaceBox(left: 40, top: 30, width: 80, height: 96);

  @override
  Future<FaceDetectionResult> uploadAndDetectFaces(LocalPhotoFile photo) async {
    return const FaceDetectionResult(
      uploadId: 'upload-1',
      faces: [
        DetectedFace(
          id: 'face-1',
          faceIndex: 0,
          box: _faceBox,
          confidence: 0.98,
        ),
      ],
    );
  }

  @override
  Future<List<GeneratedPhoto>> generateForFaces(
    String uploadId,
    Set<String> faceIds,
  ) async {
    throw StateError('generation failed');
  }
}

class MultiFacePhotoFlowApi implements PhotoFlowApi {
  static const _faceOneBox = FaceBox(left: 40, top: 30, width: 80, height: 96);
  static const _faceTwoBox = FaceBox(left: 160, top: 30, width: 80, height: 96);

  Set<String> generatedFaceIds = const {};

  @override
  Future<FaceDetectionResult> uploadAndDetectFaces(LocalPhotoFile photo) async {
    return const FaceDetectionResult(
      uploadId: 'upload-1',
      faces: [
        DetectedFace(
          id: 'face-1',
          faceIndex: 0,
          box: _faceOneBox,
          confidence: 0.98,
        ),
        DetectedFace(
          id: 'face-2',
          faceIndex: 1,
          box: _faceTwoBox,
          confidence: 0.94,
        ),
      ],
    );
  }

  @override
  Future<List<GeneratedPhoto>> generateForFaces(
    String uploadId,
    Set<String> faceIds,
  ) async {
    generatedFaceIds = Set.unmodifiable(faceIds);
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

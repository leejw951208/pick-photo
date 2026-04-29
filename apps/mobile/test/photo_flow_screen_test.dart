import 'dart:async';
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

    await tester.tap(find.text('사진 선택'));
    await tester.pumpAndSettle();

    expect(find.text('사진에서 얼굴을 선택해 주세요'), findsOneWidget);
    expect(find.text('얼굴 1 제외됨'), findsOneWidget);
    expect(find.text('선택한 얼굴 0명 / 전체 1명'), findsOneWidget);
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

    await tester.tap(find.text('사진 선택'));
    await tester.pumpAndSettle();

    expect(find.text('얼굴을 찾지 못했습니다'), findsOneWidget);
    expect(find.text('얼굴 1 제외됨'), findsNothing);
    expect(find.text('선택한 얼굴 생성'), findsNothing);
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

    await tester.tap(find.text('사진 선택'));
    await tester.pumpAndSettle();

    expect(find.text('업로드에 실패했습니다. 다시 시도해 주세요'), findsOneWidget);
    expect(find.text('얼굴 1 제외됨'), findsNothing);
    expect(find.text('선택한 얼굴 생성'), findsNothing);
    expect(find.textContaining('Generated result'), findsNothing);
  });

  testWidgets('shows generated result after selecting a face', (tester) async {
    final api = MultiFacePhotoFlowApi();
    await tester.pumpWidget(
      MaterialApp(
        home: PhotoFlowScreen(
          api: api,
          photoPicker: FixedPhotoPicker('person.jpg'),
        ),
      ),
    );

    await tester.tap(find.text('사진 선택'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('얼굴 1 제외됨'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('선택한 얼굴 생성'));
    await tester.pumpAndSettle();

    expect(api.generatedFaceIds, {'face-1'});
    expect(find.text('생성이 완료되었습니다'), findsOneWidget);
    expect(find.text('Generated result for face-1'), findsOneWidget);
    expect(find.text('Generated result for face-2'), findsNothing);
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

    await tester.tap(find.text('사진 선택'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('얼굴 1 제외됨'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('선택한 얼굴 생성'));
    await tester.pumpAndSettle();

    expect(find.text('생성에 실패했습니다. 다시 시도해 주세요'), findsOneWidget);
    expect(find.text('선택한 얼굴 1명 / 전체 1명'), findsOneWidget);
    expect(find.textContaining('Generated result'), findsNothing);
  });

  testWidgets('generates only directly selected faces', (tester) async {
    final api = MultiFacePhotoFlowApi();
    await tester.pumpWidget(
      MaterialApp(
        home: PhotoFlowScreen(
          api: api,
          photoPicker: FixedPhotoPicker('person.jpg'),
        ),
      ),
    );

    await tester.tap(find.text('사진 선택'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('얼굴 1 제외됨'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('선택한 얼굴 생성'));
    await tester.pumpAndSettle();

    expect(api.generatedFaceIds, {'face-1'});
    expect(find.text('생성이 완료되었습니다'), findsOneWidget);
    expect(find.text('Generated result for face-1'), findsOneWidget);
    expect(find.text('Generated result for face-2'), findsNothing);
  });

  testWidgets(
      'shows selection message before generating without selected faces',
      (tester) async {
    final api = MultiFacePhotoFlowApi();
    await tester.pumpWidget(
      MaterialApp(
        home: PhotoFlowScreen(
          api: api,
          photoPicker: FixedPhotoPicker('person.jpg'),
        ),
      ),
    );

    await tester.tap(find.text('사진 선택'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('선택한 얼굴 생성'));
    await tester.pumpAndSettle();

    expect(api.generatedFaceIds, isEmpty);
    expect(find.text('생성할 얼굴을 먼저 선택해 주세요'), findsOneWidget);
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

    await tester.tap(find.text('사진 선택'));
    await tester.pumpAndSettle();

    expect(find.text('얼굴 1 제외됨'), findsOneWidget);
    expect(find.text('얼굴 2 제외됨'), findsOneWidget);

    await tester.tap(find.text('전체 선택'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('선택한 얼굴 생성'));
    await tester.pumpAndSettle();

    expect(api.generatedFaceIds, unorderedEquals(['face-1', 'face-2']));
    expect(find.text('생성이 완료되었습니다'), findsOneWidget);
    expect(find.text('Generated result for face-1'), findsOneWidget);
    expect(find.text('Generated result for face-2'), findsOneWidget);
    expect(find.text('https://example.invalid/results/face-1.jpg'),
        findsOneWidget);
    expect(find.text('https://example.invalid/results/face-2.jpg'),
        findsOneWidget);
  });

  testWidgets('stale first upload does not override a later upload',
      (tester) async {
    final api = ControllablePhotoFlowApi();
    await tester.pumpWidget(
      MaterialApp(
        home: PhotoFlowScreen(
          api: api,
          photoPicker: SequencePhotoPicker(['first.jpg', 'second.jpg']),
        ),
      ),
    );

    await tester.tap(find.text('사진 선택'));
    await tester.pump();
    await tester.tap(find.text('사진 선택'));
    await tester.pump();

    api.completeUpload(
      'second.jpg',
      const FaceDetectionResult(
        uploadId: 'upload-second',
        faces: [
          DetectedFace(
            id: 'face-second',
            faceIndex: 1,
            box: FaceBox(left: 0.65, top: 0.1, width: 0.25, height: 0.35),
            confidence: 0.96,
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('얼굴 2 제외됨'), findsOneWidget);

    api.completeUpload(
      'first.jpg',
      const FaceDetectionResult(
        uploadId: 'upload-first',
        faces: [
          DetectedFace(
            id: 'face-first',
            faceIndex: 0,
            box: FaceBox(left: 0.05, top: 0.1, width: 0.25, height: 0.35),
            confidence: 0.98,
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('얼굴 2 제외됨'), findsOneWidget);
    expect(find.text('얼굴 1 제외됨'), findsNothing);
  });

  testWidgets('stale generation does not populate results after a new upload',
      (tester) async {
    final api = ControllablePhotoFlowApi();
    await tester.pumpWidget(
      MaterialApp(
        home: PhotoFlowScreen(
          api: api,
          photoPicker: SequencePhotoPicker(['first.jpg', 'second.jpg']),
        ),
      ),
    );

    await tester.tap(find.text('사진 선택'));
    await tester.pump();
    api.completeUpload(
      'first.jpg',
      const FaceDetectionResult(
        uploadId: 'upload-first',
        faces: [
          DetectedFace(
            id: 'face-first',
            faceIndex: 0,
            box: FaceBox(left: 0.05, top: 0.1, width: 0.25, height: 0.35),
            confidence: 0.98,
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('얼굴 1 제외됨'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('선택한 얼굴 생성'));
    await tester.pump();

    await tester.tap(find.text('사진 선택'));
    await tester.pump();
    api.completeUpload(
      'second.jpg',
      const FaceDetectionResult(
        uploadId: 'upload-second',
        faces: [
          DetectedFace(
            id: 'face-second',
            faceIndex: 1,
            box: FaceBox(left: 0.65, top: 0.1, width: 0.25, height: 0.35),
            confidence: 0.96,
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    api.completeGeneration(
      'upload-first',
      const [
        GeneratedPhoto(
          id: 'generated-face-first',
          faceId: 'face-first',
          url: 'https://example.invalid/results/face-first.jpg',
        ),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.text('얼굴 2 제외됨'), findsOneWidget);
    expect(find.text('Generated result for face-first'), findsNothing);
    expect(find.text('생성이 완료되었습니다'), findsNothing);
  });

  testWidgets('locks selection controls while generation is pending',
      (tester) async {
    final api = ControllablePhotoFlowApi();
    await tester.pumpWidget(
      MaterialApp(
        home: PhotoFlowScreen(
          api: api,
          photoPicker: SequencePhotoPicker(['person.jpg']),
        ),
      ),
    );

    await tester.tap(find.text('사진 선택'));
    await tester.pump();
    api.completeUpload(
      'person.jpg',
      const FaceDetectionResult(
        uploadId: 'upload-1',
        faces: [
          DetectedFace(
            id: 'face-1',
            faceIndex: 0,
            box: FaceBox(left: 0.05, top: 0.1, width: 0.25, height: 0.35),
            confidence: 0.98,
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('얼굴 1 제외됨'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('선택한 얼굴 생성'));
    await tester.pump();

    await tester.tap(find.text('선택 초기화'), warnIfMissed: false);
    await tester.pump();

    expect(find.text('선택한 얼굴 1명 / 전체 1명'), findsOneWidget);

    api.completeGeneration(
      'upload-1',
      const [
        GeneratedPhoto(
          id: 'generated-face-1',
          faceId: 'face-1',
          url: 'https://example.invalid/results/face-1.jpg',
        ),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.text('Generated result for face-1'), findsOneWidget);
    expect(find.text('선택한 얼굴 1명 / 전체 1명'), findsOneWidget);
  });

  testWidgets('keeps canvas zoom when selection changes', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PhotoFlowScreen(
          api: FakePhotoFlowApi(),
          photoPicker: FixedPhotoPicker('person.jpg'),
        ),
      ),
    );

    await tester.tap(find.text('사진 선택'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('확대'));
    await tester.pump();

    final zoomedScale = canvasScale(tester);

    await tester.tap(find.text('전체 선택'));
    await tester.pump();

    expect(canvasScale(tester), zoomedScale);
  });

  testWidgets('shows many generated results without small viewport overflow',
      (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final api = ManyFacePhotoFlowApi(faceCount: 8);
    await tester.pumpWidget(
      MaterialApp(
        home: PhotoFlowScreen(
          api: api,
          photoPicker: FixedPhotoPicker('person.jpg'),
        ),
      ),
    );

    await tester.tap(find.text('사진 선택'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('전체 선택'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('선택한 얼굴 생성'));
    await tester.pumpAndSettle();

    expect(find.text('생성이 완료되었습니다'), findsOneWidget);
    expect(find.text('Generated result for face-1'), findsOneWidget);
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

    await tester.tap(find.text('얼굴 1 제외됨'));
    await tester.pumpAndSettle();

    expect(find.text('얼굴 1 선택됨'), findsOneWidget);
  });

  testWidgets('keeps small face labels readable', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 240,
            child: FaceSelectionCanvas(
              photoBytes: onePixelPngBytes(),
              faces: const [
                DetectedFace(
                  id: 'face-1',
                  faceIndex: 0,
                  box: FaceBox(left: 0.4, top: 0.4, width: 0.05, height: 0.05),
                  confidence: 0.98,
                ),
              ],
              selectedFaceIds: const {},
              onFaceToggled: (_) {},
            ),
          ),
        ),
      ),
    );
    await pumpDecodedCanvas(tester);

    final label = find.text('얼굴 1 제외됨');

    expect(label, findsOneWidget);
    expect(tester.getSize(label).width, greaterThan(44));
  });

  testWidgets('clamps zoom controls to gesture scale range', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 240,
            child: FaceSelectionCanvas(
              photoBytes: onePixelPngBytes(),
              faces: const [],
              selectedFaceIds: const {},
              onFaceToggled: (_) {},
            ),
          ),
        ),
      ),
    );
    await pumpDecodedCanvas(tester);

    for (var index = 0; index < 12; index += 1) {
      await tester.tap(find.text('확대'));
      await tester.pump();
    }
    expect(canvasScale(tester), closeTo(6, 0.001));

    for (var index = 0; index < 20; index += 1) {
      await tester.tap(find.text('축소'));
      await tester.pump();
    }
    expect(canvasScale(tester), closeTo(1, 0.001));
  });

  testWidgets('clears stale canvas state when image bytes become invalid',
      (tester) async {
    var photoBytes = onePixelPngBytes();

    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 240,
            child: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          photoBytes = invalidImageBytes();
                        });
                      },
                      child: const Text('Use invalid image'),
                    ),
                    FaceSelectionCanvas(
                      photoBytes: photoBytes,
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
                      selectedFaceIds: const {},
                      onFaceToggled: (_) {},
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
    await pumpDecodedCanvas(tester);

    expect(find.text('얼굴 1 제외됨'), findsOneWidget);

    await tester.tap(find.text('Use invalid image'));
    await tester.pump();
    await pumpDecodedCanvas(tester);

    expect(find.text('사진 미리보기를 표시할 수 없습니다'), findsOneWidget);
    expect(find.text('얼굴 1 제외됨'), findsNothing);
  });

  testWidgets('does not show face markers over undecodable PNG bytes',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 240,
            child: FaceSelectionCanvas(
              photoBytes: invalidPngImageBytes(),
              faces: const [
                DetectedFace(
                  id: 'face-1',
                  faceIndex: 0,
                  box: FaceBox(left: 0.1, top: 0.1, width: 0.8, height: 0.8),
                  confidence: 0.98,
                ),
              ],
              selectedFaceIds: const {},
              onFaceToggled: (_) {},
            ),
          ),
        ),
      ),
    );
    await pumpDecodedCanvas(tester);

    expect(find.text('사진 미리보기를 표시할 수 없습니다'), findsOneWidget);
    expect(find.text('얼굴 1 제외됨'), findsNothing);
  });
}

Future<void> pumpDecodedCanvas(WidgetTester tester) async {
  await tester.runAsync(() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
  });
  await tester.pump();
  await tester.pumpAndSettle();
}

double canvasScale(WidgetTester tester) {
  final transform = tester.widget<Transform>(find.byType(Transform).last);
  return transform.transform.getMaxScaleOnAxis();
}

Uint8List invalidImageBytes() {
  return Uint8List.fromList([1, 2, 3]);
}

Uint8List invalidPngImageBytes() {
  final bytes = onePixelPngBytes();
  bytes[40] = 0;
  bytes[41] = 0;
  bytes[42] = 0;
  return bytes;
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

class SequencePhotoPicker implements PhotoPicker {
  SequencePhotoPicker(this.names);

  final List<String> names;
  int _nextIndex = 0;

  @override
  Future<LocalPhotoFile?> pickPhoto() async {
    final name = names[_nextIndex];
    _nextIndex += 1;
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
    6,
    0,
    0,
    0,
    31,
    21,
    196,
    137,
    0,
    0,
    0,
    11,
    73,
    68,
    65,
    84,
    120,
    156,
    99,
    248,
    15,
    4,
    0,
    9,
    251,
    3,
    253,
    251,
    94,
    107,
    43,
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
  static const _faceBox = FaceBox(left: 0.1, top: 0.1, width: 0.8, height: 0.8);

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
  static const _faceOneBox =
      FaceBox(left: 0.05, top: 0.1, width: 0.25, height: 0.35);
  static const _faceTwoBox =
      FaceBox(left: 0.65, top: 0.1, width: 0.25, height: 0.35);

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

class ManyFacePhotoFlowApi implements PhotoFlowApi {
  ManyFacePhotoFlowApi({required this.faceCount});

  final int faceCount;

  @override
  Future<FaceDetectionResult> uploadAndDetectFaces(LocalPhotoFile photo) async {
    return FaceDetectionResult(
      uploadId: 'upload-1',
      faces: [
        for (var index = 0; index < faceCount; index += 1)
          DetectedFace(
            id: 'face-${index + 1}',
            faceIndex: index,
            box: FaceBox(
              left: 0.05 + (index % 4) * 0.22,
              top: 0.1 + (index ~/ 4) * 0.3,
              width: 0.16,
              height: 0.22,
            ),
            confidence: 0.9,
          ),
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

class ControllablePhotoFlowApi implements PhotoFlowApi {
  final Map<String, Completer<FaceDetectionResult>> _uploadCompleters = {};
  final Map<String, Completer<List<GeneratedPhoto>>> _generationCompleters = {};

  @override
  Future<FaceDetectionResult> uploadAndDetectFaces(LocalPhotoFile photo) {
    final completer = Completer<FaceDetectionResult>();
    _uploadCompleters[photo.name] = completer;
    return completer.future;
  }

  @override
  Future<List<GeneratedPhoto>> generateForFaces(
    String uploadId,
    Set<String> faceIds,
  ) {
    final completer = Completer<List<GeneratedPhoto>>();
    _generationCompleters[uploadId] = completer;
    return completer.future;
  }

  void completeUpload(String photoName, FaceDetectionResult result) {
    _uploadCompleters[photoName]!.complete(result);
  }

  void completeGeneration(String uploadId, List<GeneratedPhoto> results) {
    _generationCompleters[uploadId]!.complete(results);
  }
}

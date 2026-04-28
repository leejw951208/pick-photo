import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pick_photo/features/photo_flow/photo_flow_api.dart';
import 'package:pick_photo/features/photo_flow/photo_flow_screen.dart';
import 'package:pick_photo/features/photo_flow/photo_flow_state.dart';

void main() {
  testWidgets('shows face selection after upload', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: PhotoFlowScreen(api: FakePhotoFlowApi())),
    );

    await tester.tap(find.text('Upload sample photo'));
    await tester.pumpAndSettle();

    expect(find.text('Face 1'), findsOneWidget);
  });

  testWidgets('shows failure message when upload has no faces', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: PhotoFlowScreen(api: FakePhotoFlowApi())),
    );

    await tester.tap(find.text('Upload no-face sample'));
    await tester.pumpAndSettle();

    expect(find.text('No face found'), findsOneWidget);
    expect(find.text('Face 1'), findsNothing);
    expect(find.text('Generate all faces'), findsNothing);
  });

  testWidgets('shows retryable failure message when upload throws',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: PhotoFlowScreen(api: FailingUploadPhotoFlowApi())),
    );

    await tester.tap(find.text('Upload sample photo'));
    await tester.pumpAndSettle();

    expect(find.text('Upload failed. Try again'), findsOneWidget);
    expect(find.text('Face 1'), findsNothing);
    expect(find.text('Generate all faces'), findsNothing);
    expect(find.textContaining('Generated result'), findsNothing);
  });

  testWidgets('shows generated result after selecting a face', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: PhotoFlowScreen(api: FakePhotoFlowApi())),
    );

    await tester.tap(find.text('Upload sample photo'));
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
      MaterialApp(home: PhotoFlowScreen(api: FailingGenerationPhotoFlowApi())),
    );

    await tester.tap(find.text('Upload sample photo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Face 1'));
    await tester.pumpAndSettle();

    expect(find.text('Generation failed. Try again'), findsOneWidget);
    expect(find.text('Face 1'), findsOneWidget);
    expect(find.textContaining('Generated result'), findsNothing);
  });

  testWidgets('generates results for all detected faces', (tester) async {
    final api = MultiFacePhotoFlowApi();
    await tester.pumpWidget(MaterialApp(home: PhotoFlowScreen(api: api)));

    await tester.tap(find.text('Upload sample photo'));
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
}

class FailingUploadPhotoFlowApi implements PhotoFlowApi {
  @override
  Future<List<DetectedFace>> uploadAndDetectFaces(String localPhotoPath) async {
    throw StateError('upload failed');
  }

  @override
  Future<List<GeneratedPhoto>> generateForFaces(Set<String> faceIds) async {
    return const [];
  }
}

class FailingGenerationPhotoFlowApi implements PhotoFlowApi {
  @override
  Future<List<DetectedFace>> uploadAndDetectFaces(String localPhotoPath) async {
    return const [
      DetectedFace(id: 'face-1', faceIndex: 0, confidence: 0.98),
    ];
  }

  @override
  Future<List<GeneratedPhoto>> generateForFaces(Set<String> faceIds) async {
    throw StateError('generation failed');
  }
}

class MultiFacePhotoFlowApi implements PhotoFlowApi {
  Set<String> generatedFaceIds = const {};

  @override
  Future<List<DetectedFace>> uploadAndDetectFaces(String localPhotoPath) async {
    return const [
      DetectedFace(id: 'face-1', faceIndex: 0, confidence: 0.98),
      DetectedFace(id: 'face-2', faceIndex: 1, confidence: 0.94),
    ];
  }

  @override
  Future<List<GeneratedPhoto>> generateForFaces(Set<String> faceIds) async {
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

# Pick Photo Flutter App Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the first Flutter user flow for uploading a photo, reviewing detected faces, selecting one or all faces, generating ID-photo style results, and displaying outcomes.

**Architecture:** Keep the app isolated in `flutter_app/`. Use a small feature module for the photo workflow and call only the NestJS application API.

**Tech Stack:** Flutter and Dart. Exact Flutter/Dart versions must be recorded from generated project metadata after scaffolding.

---

## File Structure

- Create: `flutter_app/` using Flutter project scaffolding.
- Create: `flutter_app/lib/features/photo_flow/photo_flow_state.dart`
- Create: `flutter_app/lib/features/photo_flow/photo_flow_api.dart`
- Create: `flutter_app/lib/features/photo_flow/photo_flow_screen.dart`
- Modify: `flutter_app/lib/main.dart`
- Test: `flutter_app/test/photo_flow_state_test.dart`
- Test: `flutter_app/test/photo_flow_screen_test.dart`

### Task 1: Scaffold Flutter App

**Files:**
- Create: `flutter_app/`

- [ ] **Step 1: Generate project**

Run after Flutter tooling is available:

```bash
flutter create --org com.pickphoto --project-name pick_photo flutter_app
```

Expected: Flutter project files are created under `flutter_app/`.

- [ ] **Step 2: Run generated tests**

Run:

```bash
cd flutter_app
flutter test
```

Expected: generated Flutter tests pass.

### Task 2: Define Photo Flow State

**Files:**
- Create: `flutter_app/lib/features/photo_flow/photo_flow_state.dart`
- Test: `flutter_app/test/photo_flow_state_test.dart`

- [ ] **Step 1: Write state tests**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:pick_photo/features/photo_flow/photo_flow_state.dart';

void main() {
  test('initial state waits for upload', () {
    const state = PhotoFlowState.initial();

    expect(state.stage, PhotoFlowStage.waitingForUpload);
    expect(state.faces, isEmpty);
  });

  test('selected face state tracks one face', () {
    const face = DetectedFace(id: 'face-1', faceIndex: 0, confidence: 0.98);
    final state = const PhotoFlowState.initial().copyWith(
      stage: PhotoFlowStage.reviewingFaces,
      faces: [face],
      selectedFaceIds: {'face-1'},
    );

    expect(state.selectedFaceIds, {'face-1'});
  });
}
```

- [ ] **Step 2: Implement state types**

```dart
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
  const PhotoFlowState({
    required this.stage,
    required this.faces,
    required this.selectedFaceIds,
    required this.results,
    this.message,
  });

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
  }) {
    return PhotoFlowState(
      stage: stage ?? this.stage,
      faces: faces ?? this.faces,
      selectedFaceIds: selectedFaceIds ?? this.selectedFaceIds,
      results: results ?? this.results,
      message: message ?? this.message,
    );
  }
}
```

### Task 3: Create API Boundary

**Files:**
- Create: `flutter_app/lib/features/photo_flow/photo_flow_api.dart`

- [ ] **Step 1: Implement client interface and fake client**

```dart
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
```

### Task 4: Build First Flow Screen

**Files:**
- Create: `flutter_app/lib/features/photo_flow/photo_flow_screen.dart`
- Modify: `flutter_app/lib/main.dart`
- Test: `flutter_app/test/photo_flow_screen_test.dart`

- [ ] **Step 1: Implement screen**

```dart
import 'package:flutter/material.dart';

import 'photo_flow_api.dart';
import 'photo_flow_state.dart';

class PhotoFlowScreen extends StatefulWidget {
  const PhotoFlowScreen({super.key, required this.api});

  final PhotoFlowApi api;

  @override
  State<PhotoFlowScreen> createState() => _PhotoFlowScreenState();
}

class _PhotoFlowScreenState extends State<PhotoFlowScreen> {
  PhotoFlowState state = const PhotoFlowState.initial();

  Future<void> _simulateUpload(String path) async {
    setState(() {
      state = state.copyWith(stage: PhotoFlowStage.uploading, message: 'Uploading photo');
    });

    final faces = await widget.api.uploadAndDetectFaces(path);
    setState(() {
      state = faces.isEmpty
          ? state.copyWith(stage: PhotoFlowStage.failed, faces: faces, message: 'No face found')
          : state.copyWith(stage: PhotoFlowStage.reviewingFaces, faces: faces, message: 'Choose a face');
    });
  }

  Future<void> _generate(Set<String> faceIds) async {
    setState(() {
      state = state.copyWith(stage: PhotoFlowStage.generating, selectedFaceIds: faceIds, message: 'Generating');
    });

    final results = await widget.api.generateForFaces(faceIds);
    setState(() {
      state = state.copyWith(stage: PhotoFlowStage.completed, results: results, message: 'Generation complete');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pick Photo')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(state.message ?? 'Upload a photo to begin'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _simulateUpload('person.jpg'),
              child: const Text('Upload sample photo'),
            ),
            ElevatedButton(
              onPressed: () => _simulateUpload('no-face.jpg'),
              child: const Text('Upload no-face sample'),
            ),
            const SizedBox(height: 16),
            for (final face in state.faces)
              CheckboxListTile(
                value: state.selectedFaceIds.contains(face.id),
                title: Text('Face ${face.faceIndex + 1}'),
                subtitle: Text('Confidence ${face.confidence.toStringAsFixed(2)}'),
                onChanged: (_) => _generate({face.id}),
              ),
            if (state.faces.length > 1)
              ElevatedButton(
                onPressed: () => _generate(state.faces.map((face) => face.id).toSet()),
                child: const Text('Generate all faces'),
              ),
            for (final result in state.results)
              ListTile(
                title: Text('Generated result for ${result.faceId}'),
                subtitle: Text(result.url),
              ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Register screen in `main.dart`**

```dart
import 'package:flutter/material.dart';

import 'features/photo_flow/photo_flow_api.dart';
import 'features/photo_flow/photo_flow_screen.dart';

void main() {
  runApp(const PickPhotoApp());
}

class PickPhotoApp extends StatelessWidget {
  const PickPhotoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pick Photo',
      theme: ThemeData(useMaterial3: true),
      home: PhotoFlowScreen(api: FakePhotoFlowApi()),
    );
  }
}
```

- [ ] **Step 3: Add widget test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pick_photo/features/photo_flow/photo_flow_api.dart';
import 'package:pick_photo/features/photo_flow/photo_flow_screen.dart';

void main() {
  testWidgets('shows face selection after upload', (tester) async {
    await tester.pumpWidget(MaterialApp(home: PhotoFlowScreen(api: FakePhotoFlowApi())));

    await tester.tap(find.text('Upload sample photo'));
    await tester.pumpAndSettle();

    expect(find.text('Face 1'), findsOneWidget);
  });
}
```

- [ ] **Step 4: Run Flutter tests**

Run:

```bash
cd flutter_app
flutter test
```

Expected: all Flutter tests pass.

## Plan Self-Review

- Spec coverage: covers upload, no-face state, face review, selection, generation, and result review.
- Placeholder scan: no unfinished placeholder markers are present.
- Type consistency: state, API, screen, and tests use matching type names.
- Residual risk: this first flow uses sample buttons and fake API behavior; real file picker and HTTP integration should follow after the NestJS contract is stable.

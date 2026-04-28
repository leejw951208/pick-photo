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
      state = state.copyWith(
        stage: PhotoFlowStage.uploading,
        faces: const [],
        selectedFaceIds: const {},
        results: const [],
        message: 'Uploading photo',
      );
    });

    final List<DetectedFace> faces;
    try {
      faces = await widget.api.uploadAndDetectFaces(path);
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        state = state.copyWith(
          stage: PhotoFlowStage.failed,
          faces: const [],
          selectedFaceIds: const {},
          results: const [],
          message: 'Upload failed. Try again',
        );
      });
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      state = faces.isEmpty
          ? state.copyWith(
              stage: PhotoFlowStage.failed,
              faces: faces,
              selectedFaceIds: const {},
              results: const [],
              message: 'No face found',
            )
          : state.copyWith(
              stage: PhotoFlowStage.reviewingFaces,
              faces: faces,
              selectedFaceIds: const {},
              results: const [],
              message: 'Choose a face',
            );
    });
  }

  Future<void> _generate(Set<String> faceIds) async {
    setState(() {
      state = state.copyWith(
        stage: PhotoFlowStage.generating,
        selectedFaceIds: faceIds,
        results: const [],
        message: 'Generating',
      );
    });

    final List<GeneratedPhoto> results;
    try {
      results = await widget.api.generateForFaces(faceIds);
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        state = state.copyWith(
          stage: PhotoFlowStage.failed,
          results: const [],
          message: 'Generation failed. Try again',
        );
      });
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      state = state.copyWith(
        stage: PhotoFlowStage.completed,
        results: results,
        message: 'Generation complete',
      );
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
                subtitle: Text(
                  'Confidence ${face.confidence.toStringAsFixed(2)}',
                ),
                onChanged: (_) => _generate({face.id}),
              ),
            if (state.faces.length > 1)
              ElevatedButton(
                onPressed: () => _generate(
                  state.faces.map((face) => face.id).toSet(),
                ),
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

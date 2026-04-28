import 'package:flutter/material.dart';

import 'photo_flow_api.dart';
import 'photo_picker.dart';
import 'photo_flow_state.dart';

class PhotoFlowScreen extends StatefulWidget {
  const PhotoFlowScreen({
    super.key,
    required this.api,
    required this.photoPicker,
  });

  final PhotoFlowApi api;
  final PhotoPicker photoPicker;

  @override
  State<PhotoFlowScreen> createState() => _PhotoFlowScreenState();
}

class _PhotoFlowScreenState extends State<PhotoFlowScreen> {
  PhotoFlowState state = const PhotoFlowState.initial();

  Future<void> _pickAndUploadPhoto() async {
    final photo = await widget.photoPicker.pickPhoto();
    if (!mounted || photo == null) {
      return;
    }

    await _uploadPhoto(photo);
  }

  Future<void> _uploadPhoto(LocalPhotoFile photo) async {
    setState(() {
      state = state.copyWith(
        stage: PhotoFlowStage.uploading,
        faces: const [],
        selectedFaceIds: const {},
        results: const [],
        clearUploadId: true,
        message: 'Uploading photo',
      );
    });

    final FaceDetectionResult detectionResult;
    try {
      detectionResult = await widget.api.uploadAndDetectFaces(photo);
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
          clearUploadId: true,
          message: 'Upload failed. Try again',
        );
      });
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      state = detectionResult.faces.isEmpty
          ? state.copyWith(
              stage: PhotoFlowStage.failed,
              faces: detectionResult.faces,
              selectedFaceIds: const {},
              results: const [],
              uploadId: detectionResult.uploadId,
              message: 'No face found',
            )
          : state.copyWith(
              stage: PhotoFlowStage.reviewingFaces,
              faces: detectionResult.faces,
              selectedFaceIds: const {},
              results: const [],
              uploadId: detectionResult.uploadId,
              message: 'Choose a face',
            );
    });
  }

  Future<void> _generate(Set<String> faceIds) async {
    final uploadId = state.uploadId;
    if (uploadId == null) {
      setState(() {
        state = state.copyWith(
          stage: PhotoFlowStage.failed,
          results: const [],
          message: 'Upload a photo before generating',
        );
      });
      return;
    }

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
      results = await widget.api.generateForFaces(uploadId, faceIds);
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
              onPressed: _pickAndUploadPhoto,
              child: const Text('Upload photo'),
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

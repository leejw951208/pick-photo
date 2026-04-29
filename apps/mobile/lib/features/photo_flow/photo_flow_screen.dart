import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'face_selection_canvas.dart';
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
        clearSourcePhotoBytes: true,
        message: '사진을 업로드하고 있습니다',
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
          clearSourcePhotoBytes: true,
          message: '업로드에 실패했습니다. 다시 시도해 주세요',
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
              sourcePhotoBytes: photo.bytes,
              message: '얼굴을 찾지 못했습니다',
            )
          : state.copyWith(
              stage: PhotoFlowStage.reviewingFaces,
              faces: detectionResult.faces,
              selectedFaceIds: const {},
              results: const [],
              uploadId: detectionResult.uploadId,
              sourcePhotoBytes: photo.bytes,
              message: '사진에서 얼굴을 선택해 주세요',
            );
    });
  }

  void _toggleFace(String faceId) {
    final selectedFaceIds = Set<String>.from(state.selectedFaceIds);
    if (selectedFaceIds.contains(faceId)) {
      selectedFaceIds.remove(faceId);
    } else {
      selectedFaceIds.add(faceId);
    }

    setState(() {
      state = state.copyWith(
        selectedFaceIds: selectedFaceIds,
        clearMessage: true,
      );
    });
  }

  void _selectAllFaces() {
    setState(() {
      state = state.copyWith(
        selectedFaceIds: state.faces.map((face) => face.id).toSet(),
        clearMessage: true,
      );
    });
  }

  void _clearSelection() {
    setState(() {
      state = state.copyWith(
        selectedFaceIds: const {},
        clearMessage: true,
      );
    });
  }

  Future<void> _generateSelectedFaces() async {
    if (state.selectedFaceIds.isEmpty) {
      setState(() {
        state = state.copyWith(message: '생성할 얼굴을 먼저 선택해 주세요');
      });
      return;
    }

    await _generate(state.selectedFaceIds);
  }

  Future<void> _generate(Set<String> faceIds) async {
    final uploadId = state.uploadId;
    if (uploadId == null) {
      setState(() {
        state = state.copyWith(
          stage: PhotoFlowStage.failed,
          results: const [],
          message: '업로드에 실패했습니다. 다시 시도해 주세요',
        );
      });
      return;
    }

    setState(() {
      state = state.copyWith(
        stage: PhotoFlowStage.generating,
        selectedFaceIds: faceIds,
        results: const [],
        message: '증명사진을 생성하고 있습니다',
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
          message: '생성에 실패했습니다. 다시 시도해 주세요',
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
        message: '생성이 완료되었습니다',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final sourcePhotoBytes = state.sourcePhotoBytes;

    return Scaffold(
      appBar: AppBar(title: const Text('Pick Photo')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(state.message ?? '사진을 선택해 시작하세요'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _pickAndUploadPhoto,
                child: const Text('사진 선택'),
              ),
              const SizedBox(height: 12),
              if (state.stage == PhotoFlowStage.reviewingFaces &&
                  sourcePhotoBytes != null)
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final canvasHeight =
                          math.max(120.0, constraints.maxHeight - 120);
                      final canvasWidth = math.min(
                        constraints.maxWidth,
                        canvasHeight * 4 / 5,
                      );

                      return Align(
                        alignment: Alignment.topCenter,
                        child: SizedBox(
                          width: canvasWidth,
                          child: FaceSelectionCanvas(
                            photoBytes: sourcePhotoBytes,
                            faces: state.faces,
                            selectedFaceIds: state.selectedFaceIds,
                            onFaceToggled: _toggleFace,
                          ),
                        ),
                      );
                    },
                  ),
                )
              else
                const Spacer(),
              if (state.faces.isNotEmpty)
                _SelectionSummary(
                  selectedCount: state.selectedFaceIds.length,
                  totalCount: state.faces.length,
                  onSelectAll: _selectAllFaces,
                  onClear: _clearSelection,
                  onGenerate: _generateSelectedFaces,
                ),
              for (final result in state.results)
                ListTile(
                  title: Text('Generated result for ${result.faceId}'),
                  subtitle: Text(result.url),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectionSummary extends StatelessWidget {
  const _SelectionSummary({
    required this.selectedCount,
    required this.totalCount,
    required this.onSelectAll,
    required this.onClear,
    required this.onGenerate,
  });

  final int selectedCount;
  final int totalCount;
  final VoidCallback onSelectAll;
  final VoidCallback onClear;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('선택한 얼굴 $selectedCount명 / 전체 $totalCount명'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                onPressed: onSelectAll,
                child: const Text('전체 선택'),
              ),
              OutlinedButton(
                onPressed: onClear,
                child: const Text('선택 초기화'),
              ),
              FilledButton(
                onPressed: onGenerate,
                child: const Text('선택한 얼굴 생성'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

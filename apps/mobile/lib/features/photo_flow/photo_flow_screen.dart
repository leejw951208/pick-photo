import 'dart:math' as math;
import 'dart:typed_data';

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
  int _uploadSequence = 0;
  int _generationSequence = 0;
  Uint8List? _sourcePhotoBytes;

  Future<void> _pickAndUploadPhoto() async {
    final photo = await widget.photoPicker.pickPhoto();
    if (!mounted || photo == null) {
      return;
    }

    await _uploadPhoto(photo);
  }

  Future<void> _uploadPhoto(LocalPhotoFile photo) async {
    final uploadSequence = _uploadSequence + 1;
    _uploadSequence = uploadSequence;
    _generationSequence += 1;

    setState(() {
      _sourcePhotoBytes = null;
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
      if (!mounted || !_isCurrentUpload(uploadSequence)) {
        return;
      }

      setState(() {
        _sourcePhotoBytes = null;
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

    if (!mounted || !_isCurrentUpload(uploadSequence)) {
      return;
    }

    setState(() {
      _sourcePhotoBytes = Uint8List.fromList(photo.bytes);
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

  bool _isCurrentUpload(int uploadSequence) {
    return uploadSequence == _uploadSequence;
  }

  bool _isCurrentGeneration(int generationSequence, String uploadId) {
    return generationSequence == _generationSequence &&
        state.uploadId == uploadId;
  }

  void _toggleFace(String faceId) {
    if (state.stage == PhotoFlowStage.generating) {
      return;
    }

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
    if (state.stage == PhotoFlowStage.generating) {
      return;
    }

    setState(() {
      state = state.copyWith(
        selectedFaceIds: state.faces.map((face) => face.id).toSet(),
        clearMessage: true,
      );
    });
  }

  void _clearSelection() {
    if (state.stage == PhotoFlowStage.generating) {
      return;
    }

    setState(() {
      state = state.copyWith(
        selectedFaceIds: const {},
        clearMessage: true,
      );
    });
  }

  Future<void> _generateSelectedFaces() async {
    if (state.stage == PhotoFlowStage.generating) {
      return;
    }

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

    final generationSequence = _generationSequence + 1;
    _generationSequence = generationSequence;

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
      if (!mounted || !_isCurrentGeneration(generationSequence, uploadId)) {
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

    if (!mounted || !_isCurrentGeneration(generationSequence, uploadId)) {
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
    final sourcePhotoBytes = _sourcePhotoBytes;

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
                      final canvasWidth = math.min(
                        constraints.maxWidth,
                        360.0,
                      );

                      return SingleChildScrollView(
                        child: Align(
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
                        ),
                      );
                    },
                  ),
                )
              else if (state.results.isNotEmpty)
                Expanded(
                  child: ListView(
                    children: [
                      for (final result in state.results)
                        ListTile(
                          title: Text('Generated result for ${result.faceId}'),
                          subtitle: Text(result.url),
                        ),
                    ],
                  ),
                )
              else
                const Spacer(),
              if (state.faces.isNotEmpty)
                _SelectionSummary(
                  selectedCount: state.selectedFaceIds.length,
                  totalCount: state.faces.length,
                  enabled: state.stage != PhotoFlowStage.generating,
                  onSelectAll: _selectAllFaces,
                  onClear: _clearSelection,
                  onGenerate: _generateSelectedFaces,
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
    required this.enabled,
    required this.onSelectAll,
    required this.onClear,
    required this.onGenerate,
  });

  final int selectedCount;
  final int totalCount;
  final bool enabled;
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
                onPressed: enabled ? onSelectAll : null,
                child: const Text('전체 선택'),
              ),
              OutlinedButton(
                onPressed: enabled ? onClear : null,
                child: const Text('선택 초기화'),
              ),
              FilledButton(
                onPressed: enabled ? onGenerate : null,
                child: const Text('선택한 얼굴 생성'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

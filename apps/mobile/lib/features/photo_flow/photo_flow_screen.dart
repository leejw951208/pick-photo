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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final contentWidth = math.min(constraints.maxWidth, 760.0);

            return Center(
              child: SizedBox(
                width: contentWidth,
                height: constraints.maxHeight,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _FlowHeader(
                        stage: state.stage,
                        faceCount: state.faces.length,
                        message: state.message,
                        onPickPhoto: _pickAndUploadPhoto,
                      ),
                      const SizedBox(height: 12),
                      Expanded(child: _buildMainContent(sourcePhotoBytes)),
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
          },
        ),
      ),
    );
  }

  Widget _buildMainContent(Uint8List? sourcePhotoBytes) {
    if (state.stage == PhotoFlowStage.reviewingFaces &&
        sourcePhotoBytes != null) {
      return _ReviewPanel(
        photoBytes: sourcePhotoBytes,
        faces: state.faces,
        selectedFaceIds: state.selectedFaceIds,
        onFaceToggled: _toggleFace,
      );
    }

    if (state.results.isNotEmpty) {
      return _ResultsPanel(
        results: state.results,
        titleForResult: _titleForResult,
      );
    }

    if (state.stage == PhotoFlowStage.uploading ||
        state.stage == PhotoFlowStage.generating) {
      return const _ProgressPanel();
    }

    if (state.stage == PhotoFlowStage.failed) {
      return const _FailurePanel();
    }

    return const _StartGuidance();
  }

  String _titleForResult(GeneratedPhoto result) {
    for (final face in state.faces) {
      if (face.id == result.faceId) {
        return '얼굴 ${face.faceIndex + 1} 결과';
      }
    }

    return '선택 얼굴 결과';
  }
}

class _FlowHeader extends StatelessWidget {
  const _FlowHeader({
    required this.stage,
    required this.faceCount,
    required this.message,
    required this.onPickPhoto,
  });

  final PhotoFlowStage stage;
  final int faceCount;
  final String? message;
  final VoidCallback onPickPhoto;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final message = this.message;
    final compact = stage != PhotoFlowStage.waitingForUpload;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 10 : 16),
        child: compact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _StageRail(stage: stage, faceCount: faceCount),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: onPickPhoto,
                        icon: const Icon(Icons.add_photo_alternate_outlined),
                        label: const Text('사진 선택'),
                      ),
                    ],
                  ),
                  if (message != null) ...[
                    const SizedBox(height: 8),
                    _StatusBanner(stage: stage, message: message),
                  ],
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _InfoPill(
                        icon: Icons.verified_user_outlined,
                        label: '선택한 얼굴만 생성됩니다',
                        color: theme.colorScheme.primary,
                      ),
                      const _InfoPill(
                        icon: Icons.lock_outline,
                        label: '저장 전 결과 확인',
                        color: Color(0xFF2FBF71),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '사진 한 장으로 증명사진 스타일 결과를 만드세요',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: const Color(0xFF020617),
                      fontWeight: FontWeight.w800,
                      height: 1.18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '원본 사진 위에서 얼굴을 직접 선택하고, 선택한 얼굴만 결과 생성 대상으로 보냅니다.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF475569),
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _StageRail(stage: stage, faceCount: faceCount),
                  if (message != null) ...[
                    const SizedBox(height: 10),
                    _StatusBanner(stage: stage, message: message),
                  ],
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    onPressed: onPickPhoto,
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: const Text('사진 선택'),
                  ),
                ],
              ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: const Color(0xFF0F172A),
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StageRail extends StatelessWidget {
  const _StageRail({required this.stage, required this.faceCount});

  final PhotoFlowStage stage;
  final int faceCount;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _StageChip(
          label: '업로드',
          active: stage == PhotoFlowStage.waitingForUpload ||
              stage == PhotoFlowStage.uploading,
        ),
        _StageChip(
          label: faceCount > 0 ? '얼굴 선택 $faceCount명' : '얼굴 선택',
          active: stage == PhotoFlowStage.reviewingFaces,
        ),
        _StageChip(
          label: '결과 확인',
          active: stage == PhotoFlowStage.generating ||
              stage == PhotoFlowStage.completed,
        ),
      ],
    );
  }
}

class _StageChip extends StatelessWidget {
  const _StageChip({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFF0369A1) : const Color(0xFF64748B);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: active ? const Color(0xFFE0F2FE) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.stage, required this.message});

  final PhotoFlowStage stage;
  final String message;

  @override
  Widget build(BuildContext context) {
    final color = switch (stage) {
      PhotoFlowStage.failed => const Color(0xFFB45309),
      PhotoFlowStage.completed => const Color(0xFF047857),
      _ => const Color(0xFF0369A1),
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        border: Border.all(color: color.withOpacity(0.18)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(_statusIcon(stage), color: color, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF0F172A),
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _statusIcon(PhotoFlowStage stage) {
    return switch (stage) {
      PhotoFlowStage.failed => Icons.error_outline,
      PhotoFlowStage.completed => Icons.check_circle_outline,
      PhotoFlowStage.uploading || PhotoFlowStage.generating => Icons.sync,
      _ => Icons.info_outline,
    };
  }
}

class _StartGuidance extends StatelessWidget {
  const _StartGuidance();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        _GuidanceRow(
          icon: Icons.photo_library_outlined,
          title: '사진 업로드',
          description: '한 장의 사진을 선택하면 얼굴 인식을 시작합니다.',
        ),
        _GuidanceRow(
          icon: Icons.ads_click_outlined,
          title: '원본 위 직접 선택',
          description: '사진 속 얼굴 박스를 눌러 생성할 사람만 고릅니다.',
        ),
        _GuidanceRow(
          icon: Icons.fact_check_outlined,
          title: '결과 확인',
          description: '생성된 결과를 얼굴별로 확인한 뒤 사용할 수 있습니다.',
        ),
      ],
    );
  }
}

class _GuidanceRow extends StatelessWidget {
  const _GuidanceRow({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: const Color(0xFF0369A1)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: const Color(0xFF0F172A),
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF475569),
                            height: 1.4,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewPanel extends StatelessWidget {
  const _ReviewPanel({
    required this.photoBytes,
    required this.faces,
    required this.selectedFaceIds,
    required this.onFaceToggled,
  });

  final Uint8List photoBytes;
  final List<DetectedFace> faces;
  final Set<String> selectedFaceIds;
  final ValueChanged<String> onFaceToggled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionHeading(
          title: '얼굴을 직접 선택하세요',
          description: '작게 보이는 얼굴은 확대와 이동으로 확인한 뒤 선택할 수 있습니다.',
        ),
        const SizedBox(height: 10),
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxHeight < 220) {
                    final canvasWidth = math.min(constraints.maxWidth, 180.0);

                    return SingleChildScrollView(
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: SizedBox(
                          width: canvasWidth,
                          child: FaceSelectionCanvas(
                            photoBytes: photoBytes,
                            faces: faces,
                            selectedFaceIds: selectedFaceIds,
                            onFaceToggled: onFaceToggled,
                          ),
                        ),
                      ),
                    );
                  }

                  final heightBound = constraints.maxHeight.isFinite
                      ? math.max(96.0, (constraints.maxHeight - 112) * 0.8)
                      : 440.0;
                  final canvasWidth = math.min(
                    math.min(constraints.maxWidth, heightBound),
                    440.0,
                  );

                  return Align(
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      width: canvasWidth,
                      child: FaceSelectionCanvas(
                        photoBytes: photoBytes,
                        faces: faces,
                        selectedFaceIds: selectedFaceIds,
                        onFaceToggled: onFaceToggled,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: const Color(0xFF0F172A),
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF475569),
                height: 1.4,
              ),
        ),
      ],
    );
  }
}

class _ResultsPanel extends StatelessWidget {
  const _ResultsPanel({
    required this.results,
    required this.titleForResult,
  });

  final List<GeneratedPhoto> results;
  final String Function(GeneratedPhoto result) titleForResult;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionHeading(
          title: '생성 결과',
          description: '저장하거나 사용하기 전에 선택한 얼굴의 결과가 맞는지 확인하세요.',
        ),
        const SizedBox(height: 10),
        Expanded(
          child: ListView.separated(
            itemCount: results.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final result = results[index];
              return _GeneratedResultCard(
                result: result,
                title: titleForResult(result),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _GeneratedResultCard extends StatelessWidget {
  const _GeneratedResultCard({
    required this.result,
    required this.title,
  });

  final GeneratedPhoto result;
  final String title;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 72,
                height: 92,
                child: Image.network(
                  result.url,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const ColoredBox(
                      color: Color(0xFFE0F2FE),
                      child: Icon(
                        Icons.portrait_outlined,
                        color: Color(0xFF0369A1),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: const Color(0xFF0F172A),
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '선택된 얼굴 기준으로 생성된 증명사진 스타일 결과입니다.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF475569),
                          height: 1.4,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    result.url,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF0369A1),
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressPanel extends StatelessWidget {
  const _ProgressPanel();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 36,
        height: 36,
        child: CircularProgressIndicator(strokeWidth: 3),
      ),
    );
  }
}

class _FailurePanel extends StatelessWidget {
  const _FailurePanel();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.image_not_supported_outlined,
                color: Color(0xFFB45309),
                size: 36,
              ),
              const SizedBox(height: 10),
              Text(
                '새 사진으로 다시 시도하세요',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: const Color(0xFF0F172A),
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                '얼굴이 더 또렷한 사진으로 다시 시도해 주세요.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF475569),
                    ),
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
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A0F172A),
              blurRadius: 14,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.how_to_reg_outlined,
                    color: Color(0xFF0369A1),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '선택한 얼굴 $selectedCount명 / 전체 $totalCount명',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: const Color(0xFF0F172A),
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: enabled ? onSelectAll : null,
                    icon: const Icon(Icons.select_all_outlined),
                    label: const Text('전체 선택'),
                  ),
                  OutlinedButton.icon(
                    onPressed: enabled ? onClear : null,
                    icon: const Icon(Icons.close_outlined),
                    label: const Text('선택 초기화'),
                  ),
                  FilledButton.icon(
                    onPressed: enabled ? onGenerate : null,
                    icon: const Icon(Icons.auto_awesome_outlined),
                    label: const Text('선택한 얼굴 생성'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'photo_flow_state.dart';

class FaceSelectionCanvas extends StatefulWidget {
  const FaceSelectionCanvas({
    super.key,
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
  State<FaceSelectionCanvas> createState() => _FaceSelectionCanvasState();
}

class _FaceSelectionCanvasState extends State<FaceSelectionCanvas> {
  static const _minScale = 1.0;
  static const _maxScale = 6.0;

  final TransformationController _controller = TransformationController();
  Size? _imageSize;
  Object? _decodeError;
  int _decodeGeneration = 0;

  @override
  void initState() {
    super.initState();
    _decodeImage();
  }

  @override
  void didUpdateWidget(covariant FaceSelectionCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.photoBytes != widget.photoBytes) {
      _imageSize = null;
      _decodeError = null;
      _controller.value = Matrix4.identity();
      _decodeImage();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _decodeImage() async {
    final generation = _decodeGeneration + 1;
    _decodeGeneration = generation;
    final photoBytes = widget.photoBytes;

    try {
      final pngSize = _tryReadPngSize(photoBytes);
      if (pngSize != null && _isCurrentDecode(generation, photoBytes)) {
        setState(() {
          _imageSize = pngSize;
          _decodeError = null;
        });
      }

      final codec = await ui.instantiateImageCodec(photoBytes);
      final frame = await codec.getNextFrame();
      if (!_isCurrentDecode(generation, photoBytes)) {
        frame.image.dispose();
        codec.dispose();
        return;
      }
      setState(() {
        _imageSize = Size(
          frame.image.width.toDouble(),
          frame.image.height.toDouble(),
        );
        _decodeError = null;
      });
      frame.image.dispose();
      codec.dispose();
    } catch (error) {
      if (!_isCurrentDecode(generation, photoBytes)) {
        return;
      }
      setState(() {
        _imageSize = null;
        _decodeError = error;
      });
    }
  }

  bool _isCurrentDecode(int generation, Uint8List photoBytes) {
    return mounted &&
        generation == _decodeGeneration &&
        identical(photoBytes, widget.photoBytes);
  }

  Size? _tryReadPngSize(Uint8List bytes) {
    const pngSignature = [137, 80, 78, 71, 13, 10, 26, 10];
    if (bytes.length < 24) {
      return null;
    }
    for (var index = 0; index < pngSignature.length; index += 1) {
      if (bytes[index] != pngSignature[index]) {
        return null;
      }
    }

    final data = ByteData.sublistView(bytes);
    return Size(
      data.getUint32(16).toDouble(),
      data.getUint32(20).toDouble(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageSize = _imageSize;
    if (_decodeError != null) {
      return const _CanvasMessage('사진 미리보기를 표시할 수 없습니다');
    }
    if (imageSize == null) {
      return const _CanvasMessage('사진 미리보기를 준비 중입니다');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ZoomControls(
          onZoomIn: () => _scaleBy(1.25),
          onZoomOut: () => _scaleBy(0.8),
          onFit: _resetZoom,
          onOriginal: _resetZoom,
        ),
        const SizedBox(height: 8),
        AspectRatio(
          aspectRatio: 4 / 5,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFF101820),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final viewport = Size(
                    constraints.maxWidth,
                    constraints.maxHeight,
                  );
                  final fitted = _containRect(viewport, imageSize);

                  return InteractiveViewer(
                    transformationController: _controller,
                    minScale: _minScale,
                    maxScale: _maxScale,
                    child: SizedBox(
                      width: viewport.width,
                      height: viewport.height,
                      child: Stack(
                        children: [
                          Positioned.fromRect(
                            rect: fitted,
                            child: Image.memory(
                              widget.photoBytes,
                              fit: BoxFit.fill,
                              gaplessPlayback: true,
                              errorBuilder: (context, error, stackTrace) {
                                return const SizedBox.expand();
                              },
                            ),
                          ),
                          for (final face in widget.faces)
                            _FaceMarker(
                              face: face,
                              rect: _faceRect(fitted, imageSize, face.box),
                              selected:
                                  widget.selectedFaceIds.contains(face.id),
                              onTap: () => widget.onFaceToggled(face.id),
                            ),
                        ],
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

  Rect _containRect(Size viewport, Size imageSize) {
    final scale = math.min(
      viewport.width / imageSize.width,
      viewport.height / imageSize.height,
    );
    final width = imageSize.width * scale;
    final height = imageSize.height * scale;
    return Rect.fromLTWH(
      (viewport.width - width) / 2,
      (viewport.height - height) / 2,
      width,
      height,
    );
  }

  Rect _faceRect(Rect imageRect, Size imageSize, FaceBox box) {
    final scaleX = imageRect.width / imageSize.width;
    final scaleY = imageRect.height / imageSize.height;
    return Rect.fromLTWH(
      imageRect.left + box.left * scaleX,
      imageRect.top + box.top * scaleY,
      box.width * scaleX,
      box.height * scaleY,
    );
  }

  void _scaleBy(double factor) {
    final currentScale = _controller.value.getMaxScaleOnAxis();
    if (currentScale <= 0) {
      _resetZoom();
      return;
    }

    final targetScale = (currentScale * factor).clamp(_minScale, _maxScale);
    final appliedFactor = targetScale / currentScale;
    _controller.value = _controller.value.scaled(
      appliedFactor,
      appliedFactor,
      1,
    );
  }

  void _resetZoom() {
    _controller.value = Matrix4.identity();
  }
}

class _FaceMarker extends StatelessWidget {
  const _FaceMarker({
    required this.face,
    required this.rect,
    required this.selected,
    required this.onTap,
  });

  final DetectedFace face;
  final Rect rect;
  final bool selected;
  final VoidCallback onTap;

  static const _minTapTargetSize = 44.0;
  static const _minLabelWidth = 132.0;

  @override
  Widget build(BuildContext context) {
    final label = '얼굴 ${face.faceIndex + 1} ${selected ? '선택됨' : '제외됨'}';
    final borderColor =
        selected ? const Color(0xFF2FBF71) : const Color(0xFFE5E7EB);

    return Positioned(
      left: rect.left - 8,
      top: rect.top - 8,
      width: math.max(
        math.max(rect.width + 16, _minTapTargetSize),
        _minLabelWidth,
      ),
      height: math.max(rect.height + 16, _minTapTargetSize),
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              children: [
                Positioned.fromRect(
                  rect: Rect.fromLTWH(
                    8,
                    8,
                    math.max(rect.width, 28),
                    math.max(rect.height, 28),
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(color: borderColor, width: 3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.topLeft,
                  child: GestureDetector(
                    onTap: onTap,
                    behavior: HitTestBehavior.opaque,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFF2FBF71)
                            : const Color(0xFF111827),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Text(
                          label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ZoomControls extends StatelessWidget {
  const _ZoomControls({
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onFit,
    required this.onOriginal,
  });

  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onFit;
  final VoidCallback onOriginal;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          OutlinedButton.icon(
            onPressed: onZoomIn,
            icon: const Icon(Icons.zoom_in_outlined),
            label: const Text('확대'),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: onZoomOut,
            icon: const Icon(Icons.zoom_out_outlined),
            label: const Text('축소'),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: onFit,
            icon: const Icon(Icons.fit_screen_outlined),
            label: const Text('맞춤'),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: onOriginal,
            icon: const Icon(Icons.center_focus_strong_outlined),
            label: const Text('원본'),
          ),
        ],
      ),
    );
  }
}

class _CanvasMessage extends StatelessWidget {
  const _CanvasMessage(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(message));
  }
}

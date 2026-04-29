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
  final TransformationController _controller = TransformationController();
  Size? _imageSize;
  Object? _decodeError;

  @override
  void initState() {
    super.initState();
    _decodeImage();
  }

  @override
  void didUpdateWidget(covariant FaceSelectionCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.photoBytes != widget.photoBytes) {
      _decodeImage();
      _controller.value = Matrix4.identity();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _decodeImage() async {
    try {
      final pngSize = _tryReadPngSize(widget.photoBytes);
      if (pngSize != null && mounted) {
        setState(() {
          _imageSize = pngSize;
          _decodeError = null;
        });
      }

      final codec = await ui.instantiateImageCodec(widget.photoBytes);
      final frame = await codec.getNextFrame();
      if (!mounted) {
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
      if (!mounted) {
        return;
      }
      if (_imageSize != null) {
        return;
      }
      setState(() {
        _imageSize = null;
        _decodeError = error;
      });
    }
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
                    minScale: 1,
                    maxScale: 6,
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
    _controller.value = _controller.value.scaled(factor, factor, 1);
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

  @override
  Widget build(BuildContext context) {
    final label = '얼굴 ${face.faceIndex + 1} ${selected ? '선택됨' : '제외됨'}';
    final borderColor =
        selected ? const Color(0xFF2FBF71) : const Color(0xFFE5E7EB);

    return Positioned(
      left: rect.left - 8,
      top: rect.top - 8,
      width: math.max(rect.width + 16, 44),
      height: math.max(rect.height + 16, 44),
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
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        OutlinedButton(
          onPressed: onZoomIn,
          child: const Text('확대'),
        ),
        OutlinedButton(
          onPressed: onZoomOut,
          child: const Text('축소'),
        ),
        OutlinedButton(
          onPressed: onFit,
          child: const Text('맞춤'),
        ),
        OutlinedButton(
          onPressed: onOriginal,
          child: const Text('원본'),
        ),
      ],
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

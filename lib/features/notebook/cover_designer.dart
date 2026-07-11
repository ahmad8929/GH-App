import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_tokens.dart';

/// One photo placed on the cover: normalized centre position (0..1 within the
/// canvas), uniform scale and rotation. Serialised into the order payload so
/// production can reproduce the layout exactly.
class CoverLayer {
  final Uint8List bytes;
  Offset center; // normalized 0..1
  double scale;
  double rotation; // radians

  CoverLayer({
    required this.bytes,
    this.center = const Offset(0.5, 0.45),
    this.scale = 1,
    this.rotation = 0,
  });

  Map<String, dynamic> toJson() => {
        'x': center.dx,
        'y': center.dy,
        'scale': scale,
        'rotation': rotation,
      };
}

/// Interactive cover canvas: tap to select a photo, drag to move, pinch to
/// scale/rotate. The whole canvas sits in a RepaintBoundary so the finished
/// design can be captured as a PNG and baked onto the 3D model / order.
class CoverDesigner extends StatefulWidget {
  final Color background;
  final String name;
  final String badge; // template label, e.g. "Classic"
  final List<CoverLayer> layers;
  final VoidCallback onChanged;

  const CoverDesigner({
    super.key,
    required this.background,
    required this.name,
    required this.badge,
    required this.layers,
    required this.onChanged,
  });

  @override
  State<CoverDesigner> createState() => CoverDesignerState();
}

class CoverDesignerState extends State<CoverDesigner> {
  final _boundaryKey = GlobalKey();
  final _picker = ImagePicker();
  int? _selected;

  // Pinch bookkeeping: gesture deltas apply on top of the layer's start state.
  double _startScale = 1;
  double _startRotation = 0;

  Future<void> addPhoto() async {
    final picked =
        await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1200);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      widget.layers.add(CoverLayer(bytes: bytes));
      _selected = widget.layers.length - 1;
    });
    widget.onChanged();
  }

  void removeSelected() {
    if (_selected == null) return;
    setState(() {
      widget.layers.removeAt(_selected!);
      _selected = null;
    });
    widget.onChanged();
  }

  bool get hasSelection => _selected != null;

  /// Renders the current design to a PNG (used as the 3D cover texture and
  /// uploaded with the order). Deselects first so the highlight isn't baked in.
  Future<Uint8List?> capturePng({double pixelRatio = 3}) async {
    if (_selected != null) {
      setState(() => _selected = null);
      await WidgetsBinding.instance.endOfFrame;
    }
    final boundary = _boundaryKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data?.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AspectRatio(
      aspectRatio: 150 / 210, // matches the GLB cover proportions
      child: LayoutBuilder(builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return RepaintBoundary(
          key: _boundaryKey,
          child: ClipRRect(
            borderRadius: AppTokens.brMd,
            child: GestureDetector(
              onTap: () => setState(() => _selected = null),
              child: Container(
                color: widget.background,
                child: Stack(
                  children: [
                    for (var i = 0; i < widget.layers.length; i++)
                      _buildLayer(i, size),
                    // Name + badge stay on top of photos, like the print will.
                    Positioned(
                      left: AppTokens.s3,
                      top: AppTokens.s3,
                      child: Text(widget.badge,
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: Colors.white70)),
                    ),
                    if (widget.name.isNotEmpty)
                      Positioned(
                        left: AppTokens.s3,
                        right: AppTokens.s3,
                        bottom: AppTokens.s3,
                        child: Text(
                          widget.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            shadows: const [
                              Shadow(blurRadius: 6, color: Colors.black38)
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildLayer(int index, Size canvas) {
    final layer = widget.layers[index];
    final selected = _selected == index;
    final side = canvas.width * 0.55 * layer.scale;

    return Positioned(
      left: layer.center.dx * canvas.width - side / 2,
      top: layer.center.dy * canvas.height - side / 2,
      width: side,
      height: side,
      child: GestureDetector(
        onTap: () => setState(() => _selected = index),
        onScaleStart: (_) {
          _startScale = layer.scale;
          _startRotation = layer.rotation;
          setState(() => _selected = index);
        },
        onScaleUpdate: (details) {
          setState(() {
            layer.center += Offset(
              details.focalPointDelta.dx / canvas.width,
              details.focalPointDelta.dy / canvas.height,
            );
            layer.center = Offset(
              layer.center.dx.clamp(0.0, 1.0),
              layer.center.dy.clamp(0.0, 1.0),
            );
            layer.scale = (_startScale * details.scale).clamp(0.25, 2.5);
            layer.rotation = _startRotation + details.rotation;
          });
        },
        onScaleEnd: (_) => widget.onChanged(),
        child: Transform.rotate(
          angle: layer.rotation,
          child: Container(
            decoration: BoxDecoration(
              border: selected
                  ? Border.all(color: AppTokens.gold, width: 2)
                  : null,
              boxShadow: const [
                BoxShadow(blurRadius: 8, color: Colors.black26)
              ],
            ),
            child: Image.memory(layer.bytes, fit: BoxFit.cover),
          ),
        ),
      ),
    );
  }
}

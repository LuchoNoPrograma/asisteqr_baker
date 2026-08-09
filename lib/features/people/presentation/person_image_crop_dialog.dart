import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_dialog_header.dart';
import '../application/person_image_picker.dart';

Future<String?> showPersonImageCropDialog(
  BuildContext context, {
  required PersonImageSource source,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => PersonImageCropDialog(source: source),
  );
}

class PersonImageCropDialog extends StatefulWidget {
  const PersonImageCropDialog({super.key, required this.source});

  final PersonImageSource source;

  @override
  State<PersonImageCropDialog> createState() => _PersonImageCropDialogState();
}

class _PersonImageCropDialogState extends State<PersonImageCropDialog> {
  static const _minimumZoom = 1.0;
  static const _maximumZoom = 4.0;

  late Offset _center;
  double _zoom = _minimumZoom;
  double _gestureStartZoom = _minimumZoom;
  Offset _gestureSourceFocalPoint = Offset.zero;
  Size _viewportSize = Size.zero;
  bool _encoding = false;

  double get _shortestSourceSide =>
      math.min(widget.source.width, widget.source.height).toDouble();

  @override
  void initState() {
    super.initState();
    _center = Offset(widget.source.width / 2, widget.source.height / 2);
  }

  @override
  Widget build(BuildContext context) {
    final mediaSize = MediaQuery.sizeOf(context);
    final cropSide = math
        .min(440.0, math.min(mediaSize.width - 72, mediaSize.height - 360))
        .clamp(220.0, 440.0);
    return AlertDialog(
      key: const ValueKey('person_image_crop_dialog'),
      title: const AppDialogHeader(
        title: 'Ajustar fotografía',
        subtitle: 'Centra el rostro dentro del recorte cuadrado',
      ),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: cropSide,
              height: cropSide,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.navyDark,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.navy, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x29000000),
                    blurRadius: 18,
                    offset: Offset(0, 7),
                  ),
                ],
              ),
              child: _buildCropViewport(),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(
                  Icons.crop_square_rounded,
                  size: 18,
                  color: AppColors.navy,
                ),
                const SizedBox(width: 7),
                Text(
                  'Formato 1:1',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const Spacer(),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 140),
                  child: Text(
                    '${(_zoom * 100).round()}%',
                    key: ValueKey((_zoom * 100).round()),
                    style: Theme.of(
                      context,
                    ).textTheme.labelLarge?.copyWith(color: AppColors.inkMuted),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: _encoding ? null : _reset,
                  icon: const Icon(
                    Icons.center_focus_strong_outlined,
                    size: 19,
                  ),
                  label: const Text('Centrar'),
                ),
              ],
            ),
            Row(
              children: [
                const Icon(
                  Icons.zoom_out_rounded,
                  size: 20,
                  color: AppColors.inkMuted,
                ),
                Expanded(
                  child: Slider(
                    key: const ValueKey('person_image_crop_zoom'),
                    value: _zoom,
                    min: _minimumZoom,
                    max: _maximumZoom,
                    divisions: 30,
                    onChanged: _encoding ? null : _setZoom,
                  ),
                ),
                const Icon(
                  Icons.zoom_in_rounded,
                  size: 20,
                  color: AppColors.inkMuted,
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _encoding ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          key: const ValueKey('use_person_image_crop'),
          onPressed: _encoding ? null : _submit,
          icon: _encoding
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.crop),
          label: const Text('Usar recorte'),
        ),
      ],
    );
  }

  Widget _buildCropViewport() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.biggest.shortestSide;
        _viewportSize = Size.square(side);
        final pixelsPerSourcePixel = side * _zoom / _shortestSourceSide;
        final imageWidth = widget.source.width * pixelsPerSourcePixel;
        final imageHeight = widget.source.height * pixelsPerSourcePixel;
        final left = side / 2 - _center.dx * pixelsPerSourcePixel;
        final top = side / 2 - _center.dy * pixelsPerSourcePixel;
        return Semantics(
          label: 'Recorte cuadrado de fotografía',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onScaleStart: _encoding ? null : _onScaleStart,
            onScaleUpdate: _encoding ? null : _onScaleUpdate,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: ColoredBox(
                color: const Color(0xFFF4F2F6),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Positioned(
                      left: left,
                      top: top,
                      width: imageWidth,
                      height: imageHeight,
                      child: Image.memory(
                        widget.source.previewBytes,
                        fit: BoxFit.fill,
                        filterQuality: FilterQuality.high,
                        gaplessPlayback: true,
                      ),
                    ),
                    const IgnorePointer(
                      child: CustomPaint(painter: _PersonCropOverlayPainter()),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _onScaleStart(ScaleStartDetails details) {
    if (_viewportSize.isEmpty) return;
    _gestureStartZoom = _zoom;
    final scale = _viewportSize.width * _zoom / _shortestSourceSide;
    _gestureSourceFocalPoint =
        _center +
        (details.localFocalPoint - _viewportSize.center(Offset.zero)) / scale;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (_viewportSize.isEmpty) return;
    final zoom = (_gestureStartZoom * details.scale).clamp(
      _minimumZoom,
      _maximumZoom,
    );
    final scale = _viewportSize.width * zoom / _shortestSourceSide;
    final center =
        _gestureSourceFocalPoint -
        (details.localFocalPoint - _viewportSize.center(Offset.zero)) / scale;
    setState(() {
      _zoom = zoom;
      _center = _clampCenter(center, zoom);
    });
  }

  void _setZoom(double value) {
    setState(() {
      _zoom = value;
      _center = _clampCenter(_center, value);
    });
  }

  void _reset() {
    setState(() {
      _zoom = _minimumZoom;
      _center = Offset(widget.source.width / 2, widget.source.height / 2);
    });
  }

  Offset _clampCenter(Offset value, double zoom) {
    final halfCrop = _shortestSourceSide / zoom / 2;
    return Offset(
      value.dx.clamp(halfCrop, widget.source.width - halfCrop).toDouble(),
      value.dy.clamp(halfCrop, widget.source.height - halfCrop).toDouble(),
    );
  }

  Future<void> _submit() async {
    setState(() => _encoding = true);
    await Future<void>.delayed(Duration.zero);
    final result = widget.source.encodeSquare(
      centerX: _center.dx,
      centerY: _center.dy,
      zoom: _zoom,
    );
    if (!mounted) return;
    Navigator.pop(context, result);
  }
}

class _PersonCropOverlayPainter extends CustomPainter {
  const _PersonCropOverlayPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final gridShadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.28)
      ..strokeWidth = 2;
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.72)
      ..strokeWidth = 1;
    for (final fraction in const [1 / 3, 2 / 3]) {
      final x = size.width * fraction;
      final y = size.height * fraction;
      canvas
        ..drawLine(Offset(x, 0), Offset(x, size.height), gridShadowPaint)
        ..drawLine(Offset(0, y), Offset(size.width, y), gridShadowPaint)
        ..drawLine(Offset(x, 0), Offset(x, size.height), gridPaint)
        ..drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    const cornerLength = 26.0;
    const inset = 2.0;
    final cornerPaint = Paint()
      ..color = AppColors.navy
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.square;
    final right = size.width - inset;
    final bottom = size.height - inset;
    for (final path in [
      Path()
        ..moveTo(inset, inset + cornerLength)
        ..lineTo(inset, inset)
        ..lineTo(inset + cornerLength, inset),
      Path()
        ..moveTo(right - cornerLength, inset)
        ..lineTo(right, inset)
        ..lineTo(right, inset + cornerLength),
      Path()
        ..moveTo(right, bottom - cornerLength)
        ..lineTo(right, bottom)
        ..lineTo(right - cornerLength, bottom),
      Path()
        ..moveTo(inset + cornerLength, bottom)
        ..lineTo(inset, bottom)
        ..lineTo(inset, bottom - cornerLength),
    ]) {
      canvas.drawPath(path, cornerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _PersonCropOverlayPainter oldDelegate) => false;
}

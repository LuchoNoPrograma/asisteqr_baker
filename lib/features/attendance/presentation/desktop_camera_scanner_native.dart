import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv;

class DesktopCameraScanner extends StatefulWidget {
  const DesktopCameraScanner({
    super.key,
    required this.onDetect,
    required this.onManual,
    required this.overlay,
  });

  final Future<void> Function(String token) onDetect;
  final VoidCallback onManual;
  final Widget overlay;

  @override
  State<DesktopCameraScanner> createState() => _DesktopCameraScannerState();
}

class _DesktopCameraScannerState extends State<DesktopCameraScanner>
    with WidgetsBindingObserver {
  cv.VideoCapture? _camera;
  cv.QRCodeDetector? _detector;
  Timer? _frameTimer;
  Uint8List? _preview;
  Object? _error;
  bool _initializing = false;
  bool _readingFrame = false;
  int _frameNumber = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    if (_initializing) return;
    _initializing = true;
    _frameTimer?.cancel();
    _camera?.dispose();
    _camera = null;
    _detector?.dispose();
    _detector = null;
    if (mounted) {
      setState(() {
        _error = null;
        _preview = null;
      });
    }

    try {
      final camera = await cv.VideoCaptureAsync.fromDeviceAsync(0);
      if (!camera.isOpened) {
        camera.dispose();
        throw StateError('No se encontró una cámara disponible.');
      }
      camera
        ..set(cv.CAP_PROP_FRAME_WIDTH, 1280)
        ..set(cv.CAP_PROP_FRAME_HEIGHT, 720)
        ..set(cv.CAP_PROP_FPS, 20);
      final detector = cv.QRCodeDetector.empty();
      if (!mounted) {
        camera.dispose();
        detector.dispose();
        return;
      }
      _camera = camera;
      _detector = detector;
      _startFrameLoop();
    } on Object catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      _initializing = false;
    }
  }

  void _startFrameLoop() {
    _frameTimer?.cancel();
    _frameTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (_) => unawaited(_readFrame()),
    );
  }

  Future<void> _readFrame() async {
    final camera = _camera;
    final detector = _detector;
    if (_readingFrame || camera == null || detector == null) return;
    _readingFrame = true;

    cv.Mat? frame;
    cv.VecPoint? points;
    cv.Mat? straightCode;
    try {
      final capture = await camera.readAsync();
      frame = capture.$2;
      if (!capture.$1 || frame.isEmpty) return;

      final encoded = await cv.imencodeAsync('.jpg', frame);
      if (encoded.$1 && mounted) setState(() => _preview = encoded.$2);

      _frameNumber++;
      if (_frameNumber % 3 != 0) return;
      final decoded = await detector.detectAndDecodeAsync(frame);
      final token = decoded.$1.trim();
      points = decoded.$2;
      straightCode = decoded.$3;
      if (token.isNotEmpty && mounted) {
        _frameTimer?.cancel();
        await widget.onDetect(token);
        if (mounted) _startFrameLoop();
      }
    } on Object catch (error) {
      _frameTimer?.cancel();
      if (mounted) setState(() => _error = error);
    } finally {
      points?.dispose();
      straightCode?.dispose();
      frame?.dispose();
      _readingFrame = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        if (_camera == null) {
          unawaited(_initialize());
        } else {
          _startFrameLoop();
        }
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        _frameTimer?.cancel();
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _frameTimer?.cancel();
    _camera?.dispose();
    _detector?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return _DesktopCameraError(
        message: _cameraErrorMessage(_error!),
        onRetry: _initialize,
        onManual: widget.onManual,
      );
    }
    final preview = _preview;
    if (preview == null) {
      return const ColoredBox(
        color: Color(0xFF182433),
        child: Center(
          child: SizedBox.square(
            dimension: 30,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 3,
            ),
          ),
        ),
      );
    }

    return ColoredBox(
      color: const Color(0xFF182433),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.memory(
            preview,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            filterQuality: FilterQuality.low,
          ),
          widget.overlay,
        ],
      ),
    );
  }
}

String _cameraErrorMessage(Object error) {
  final message = error.toString().replaceFirst('Bad state: ', '').trim();
  return message.isEmpty ? 'No se pudo abrir la cámara del equipo.' : message;
}

class _DesktopCameraError extends StatelessWidget {
  const _DesktopCameraError({
    required this.message,
    required this.onRetry,
    required this.onManual,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onManual;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: const Color(0xFF182433),
    child: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.cameraOff, color: Colors.white, size: 40),
              const SizedBox(height: 14),
              Text(
                'No se pudo iniciar la cámara',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, height: 1.45),
              ),
              const SizedBox(height: 20),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 10,
                children: [
                  FilledButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(LucideIcons.refreshCw, size: 17),
                    label: const Text('Reintentar'),
                  ),
                  OutlinedButton.icon(
                    onPressed: onManual,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54),
                    ),
                    icon: const Icon(LucideIcons.keyboard, size: 17),
                    label: const Text('Ingreso manual'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

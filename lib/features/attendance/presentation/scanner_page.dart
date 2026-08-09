import 'dart:async';

import 'package:asisteqr_baker/app/providers.dart';
import 'package:asisteqr_baker/app/theme/app_colors.dart';
import 'package:asisteqr_baker/core/widgets/adaptive_shell.dart';
import 'package:asisteqr_baker/core/widgets/app_dialog_header.dart';
import 'package:asisteqr_baker/core/widgets/app_feedback.dart';
import 'package:asisteqr_baker/core/widgets/status_badge.dart';
import 'package:asisteqr_baker/features/attendance/domain/attendance_models.dart';
import 'package:asisteqr_baker/features/attendance/presentation/desktop_camera_scanner_stub.dart'
    if (dart.library.io) 'package:asisteqr_baker/features/attendance/presentation/desktop_camera_scanner_native.dart';
import 'package:asisteqr_baker/features/attendance/presentation/scanner_view_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

final scannerViewModelProvider = ChangeNotifierProvider.autoDispose(
  (ref) => ScannerViewModel(ref.watch(attendanceRepositoryProvider)),
);

class ScannerPage extends ConsumerStatefulWidget {
  const ScannerPage({super.key});
  @override
  ConsumerState<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends ConsumerState<ScannerPage>
    with WidgetsBindingObserver {
  final _scanner = MobileScannerController(
    autoStart: false,
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [BarcodeFormat.qrCode],
  );
  bool _handling = false;
  bool _startingCamera = false;
  Timer? _readabilityTimer;

  bool get _usesMobileScanner =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;

  @override
  void initState() {
    super.initState();
    if (_usesMobileScanner) {
      WidgetsBinding.instance.addObserver(this);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_usesMobileScanner) unawaited(_startScanner());
      _scheduleReadabilityHint();
    });
  }

  void _scheduleReadabilityHint() {
    _readabilityTimer?.cancel();
    _readabilityTimer = Timer(const Duration(seconds: 12), () {
      if (!mounted || _handling) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: const Text(
              'No se pudo leer el código. Reubica la credencial y vuelve a intentarlo.',
            ),
            action: SnackBarAction(
              label: 'Reintentar',
              onPressed: _scheduleReadabilityHint,
            ),
          ),
        );
    });
  }

  Future<void> _startScanner() async {
    if (!_usesMobileScanner ||
        !mounted ||
        _startingCamera ||
        _scanner.value.isRunning) {
      return;
    }
    _startingCamera = true;
    try {
      await _scanner.start();
    } finally {
      _startingCamera = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_usesMobileScanner || !_scanner.value.hasCameraPermission) return;
    switch (state) {
      case AppLifecycleState.resumed:
        unawaited(_startScanner());
        _scheduleReadabilityHint();
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        _readabilityTimer?.cancel();
        unawaited(_scanner.stop());
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  void dispose() {
    _readabilityTimer?.cancel();
    if (_usesMobileScanner) WidgetsBinding.instance.removeObserver(this);
    unawaited(_scanner.dispose());
    super.dispose();
  }

  Future<void> _submit(String token) async {
    if (_handling) return;
    _readabilityTimer?.cancel();
    _handling = true;
    if (_usesMobileScanner) await _scanner.stop();
    final result = await ref.read(scannerViewModelProvider).submit(token);
    if (!mounted) return;
    if (result != null) {
      await HapticFeedback.mediumImpact();
      if (!mounted) return;
      await context.push('/resultado', extra: result);
      if (!mounted) return;
      _handling = false;
      ref.read(scannerViewModelProvider).retry();
      await _startScanner();
      _scheduleReadabilityHint();
    } else {
      await HapticFeedback.vibrate();
      if (!mounted) return;
      await _showFailure();
      _handling = false;
      ref.read(scannerViewModelProvider).retry();
      await _startScanner();
      _scheduleReadabilityHint();
    }
  }

  Future<void> _showFailure() async {
    final failure = ref.read(scannerViewModelProvider).failure!;
    final title = switch (failure.kind) {
      AttendanceFailureKind.unreadableQr => 'Código ilegible',
      AttendanceFailureKind.inactiveStudent => 'Credencial inactiva',
      AttendanceFailureKind.unauthorized => 'Acceso denegado',
      AttendanceFailureKind.network => 'Sin conexión',
      _ => 'QR no registrado',
    };
    await showAppErrorDialog(
      context,
      title: title,
      message: failure.message,
      actionLabel: 'Escanear nuevamente',
    );
  }

  Future<void> _manualEntry() async {
    _readabilityTimer?.cancel();
    final controller = TextEditingController();
    final token = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const AppDialogHeader(
          title: 'Ingreso manual',
          subtitle: 'Valida una credencial sin utilizar la cámara',
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Código de credencial',
            prefixIcon: Icon(LucideIcons.keyboard, size: 18),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, controller.text),
            icon: const Icon(LucideIcons.badgeCheck, size: 17),
            label: const Text('Validar'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (token != null && token.trim().isNotEmpty) {
      await _submit(token);
    } else {
      _scheduleReadabilityHint();
    }
  }

  @override
  Widget build(BuildContext context) {
    final model = ref.watch(scannerViewModelProvider);
    return AdaptiveShell(
      location: '/escaner',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 840;
          final camera = _cameraWorkspace();
          final workspace = wide
              ? Row(
                  children: [
                    Expanded(flex: 3, child: camera),
                    const VerticalDivider(width: 1),
                    SizedBox(
                      width: 360,
                      child: _RecentScans(onManual: _manualEntry),
                    ),
                  ],
                )
              : Column(
                  children: [
                    Expanded(flex: 3, child: camera),
                    Expanded(
                      flex: 2,
                      child: _RecentScans(onManual: _manualEntry),
                    ),
                  ],
                );
          return Stack(
            children: [
              Positioned.fill(child: workspace),
              if (model.phase == ScanPhase.validating)
                Positioned.fill(
                  child: ColoredBox(
                    color: Colors.black45,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 12),
                            Text('Validando credencial…'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _cameraWorkspace() {
    if (!_usesMobileScanner) {
      return DesktopCameraScanner(
        onDetect: _submit,
        onManual: _manualEntry,
        overlay: const IgnorePointer(child: _ScannerOverlay()),
      );
    }
    return ColoredBox(
      color: const Color(0xFF182433),
      child: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _scanner,
            tapToFocus: true,
            onDetect: (capture) {
              final value = capture.barcodes.firstOrNull?.rawValue;
              if (value != null) _submit(value);
            },
            placeholderBuilder: (context) => const _CameraLoading(),
            errorBuilder: (context, error) => _CameraUnavailable(
              error: error,
              onRetry: _startScanner,
              onManual: _manualEntry,
            ),
          ),
          ValueListenableBuilder<MobileScannerState>(
            valueListenable: _scanner,
            builder: (context, state, _) {
              if (!state.isRunning || state.error != null) {
                return const SizedBox.shrink();
              }
              final canSwitch = (state.availableCameras ?? 0) > 1;
              return Stack(
                fit: StackFit.expand,
                children: [
                  const IgnorePointer(child: _ScannerOverlay()),
                  SafeArea(
                    child: Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (state.torchState != TorchState.unavailable)
                              _CameraButton(
                                tooltip: 'Linterna',
                                icon: LucideIcons.flashlight,
                                onPressed: _scanner.toggleTorch,
                              ),
                            if (state.torchState != TorchState.unavailable &&
                                canSwitch)
                              const SizedBox(height: 8),
                            if (canSwitch)
                              _CameraButton(
                                tooltip: 'Cambiar cámara',
                                icon: LucideIcons.switchCamera,
                                onPressed: _scanner.switchCamera,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ScannerOverlay extends StatefulWidget {
  const _ScannerOverlay();
  @override
  State<_ScannerOverlay> createState() => _ScannerOverlayState();
}

class _ScannerOverlayState extends State<_ScannerOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;
  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) =>
        CustomPaint(painter: _ScannerPainter(controller.value)),
  );
}

class _ScannerPainter extends CustomPainter {
  const _ScannerPainter(this.progress);
  final double progress;
  @override
  void paint(Canvas canvas, Size size) {
    final shortest = size.shortestSide;
    final frame = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: shortest * .62,
      height: shortest * .62,
    );
    final overlay = Path()
      ..addRect(Offset.zero & size)
      ..addRRect(RRect.fromRectAndRadius(frame, const Radius.circular(10)))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(
      overlay,
      Paint()..color = Colors.black.withValues(alpha: .48),
    );
    final corner = Paint()
      ..color = const Color(0xFF52F3B0)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const length = 28.0;
    canvas.drawPath(
      Path()
        ..moveTo(frame.left, frame.top + length)
        ..lineTo(frame.left, frame.top)
        ..lineTo(frame.left + length, frame.top),
      corner,
    );
    canvas.drawPath(
      Path()
        ..moveTo(frame.right - length, frame.top)
        ..lineTo(frame.right, frame.top)
        ..lineTo(frame.right, frame.top + length),
      corner,
    );
    canvas.drawPath(
      Path()
        ..moveTo(frame.right, frame.bottom - length)
        ..lineTo(frame.right, frame.bottom)
        ..lineTo(frame.right - length, frame.bottom),
      corner,
    );
    canvas.drawPath(
      Path()
        ..moveTo(frame.left + length, frame.bottom)
        ..lineTo(frame.left, frame.bottom)
        ..lineTo(frame.left, frame.bottom - length),
      corner,
    );
    final y = frame.top + 12 + (frame.height - 24) * progress;
    canvas.drawLine(
      Offset(frame.left + 12, y),
      Offset(frame.right - 12, y),
      Paint()
        ..color = const Color(0xFF52F3B0).withValues(alpha: .75)
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _ScannerPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _CameraButton extends StatelessWidget {
  const _CameraButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });
  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => IconButton.filledTonal(
    tooltip: tooltip,
    style: IconButton.styleFrom(
      backgroundColor: Colors.black54,
      foregroundColor: Colors.white,
    ),
    onPressed: onPressed,
    icon: Icon(icon, size: 20),
  );
}

class _CameraLoading extends StatelessWidget {
  const _CameraLoading();

  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: Color(0xFF182433),
    child: Center(
      child: SizedBox.square(
        dimension: 30,
        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
      ),
    ),
  );
}

class _CameraUnavailable extends StatelessWidget {
  const _CameraUnavailable({
    required this.error,
    required this.onManual,
    this.onRetry,
  });

  final MobileScannerException error;
  final VoidCallback onManual;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final (title, message) = switch (error.errorCode) {
      MobileScannerErrorCode.permissionDenied => (
        'Permiso de cámara bloqueado',
        'Autoriza la cámara para AsisteQR Baker y vuelve a intentar. En Web, abre la aplicación mediante HTTPS o localhost.',
      ),
      MobileScannerErrorCode.unsupported => (
        'Cámara no disponible',
        'No encontramos una cámara compatible en este equipo o navegador.',
      ),
      _ => (
        'No se pudo iniciar la cámara',
        'Cierra otras aplicaciones que usen la cámara y vuelve a intentar.',
      ),
    };
    return ColoredBox(
      color: Color(0xFF182433),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  LucideIcons.cameraOff,
                  color: Colors.white,
                  size: 40,
                ),
                const SizedBox(height: 14),
                Text(
                  title,
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
                    if (onRetry != null)
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
}

class _RecentScans extends StatelessWidget {
  const _RecentScans({required this.onManual});
  final VoidCallback onManual;
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final records = [
      AttendanceRecord(
        id: 'r1',
        student: const Student(
          id: '1',
          code: 'EST-01',
          fullName: 'García, Carlos',
          course: '4.º A · Matemáticas',
        ),
        timestamp: now,
        status: AttendanceStatus.punctual,
      ),
      AttendanceRecord(
        id: 'r2',
        student: const Student(
          id: '2',
          code: 'EST-02',
          fullName: 'Martínez, Ana',
          course: '4.º A · Matemáticas',
        ),
        timestamp: now,
        status: AttendanceStatus.late,
      ),
    ];
    return Material(
      color: AppColors.canvas,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 18),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Últimos registros',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              TextButton.icon(
                onPressed: onManual,
                icon: const Icon(LucideIcons.keyboard, size: 15),
                label: const Text('Ingreso manual'),
              ),
            ],
          ),
          for (final record in records)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.fromLTRB(9, 9, 9, 9),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Row(
                children: [
                  Container(
                    width: 3,
                    height: 44,
                    margin: const EdgeInsets.only(right: 9),
                    decoration: BoxDecoration(
                      color: record.status == AttendanceStatus.punctual
                          ? AppColors.green
                          : AppColors.amber,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const CircleAvatar(
                    radius: 17,
                    backgroundColor: AppColors.blueSoft,
                    child: Icon(
                      LucideIcons.userRound,
                      size: 16,
                      color: AppColors.navy,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.student.fullName,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${DateFormat('HH:mm').format(record.timestamp)} · ${record.student.course}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  StatusBadge(status: record.status),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

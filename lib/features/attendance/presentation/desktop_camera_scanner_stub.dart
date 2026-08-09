import 'package:flutter/material.dart';

class DesktopCameraScanner extends StatelessWidget {
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
  Widget build(BuildContext context) => const SizedBox.shrink();
}

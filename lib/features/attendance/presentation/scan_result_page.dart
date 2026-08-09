import 'package:asisteqr_baker/app/theme/app_colors.dart';
import 'package:asisteqr_baker/core/widgets/app_person_image.dart';
import 'package:asisteqr_baker/core/widgets/status_badge.dart';
import 'package:asisteqr_baker/features/attendance/domain/attendance_models.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ScanResultPage extends StatefulWidget {
  const ScanResultPage({super.key, required this.result});
  final ScanResult result;
  @override
  State<ScanResultPage> createState() => _ScanResultPageState();
}

class _ScanResultPageState extends State<ScanResultPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;
  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final record = result.record;
    final accent = result.duplicate
        ? AppColors.amber
        : record.status == AttendanceStatus.late
        ? AppColors.amber
        : AppColors.green;
    final title = result.duplicate
        ? 'Asistencia ya registrada'
        : record.status == AttendanceStatus.late
        ? 'Atraso registrado'
        : 'Registro exitoso';
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Volver',
          onPressed: () => context.pop(),
          icon: const Icon(LucideIcons.arrowLeft),
        ),
        title: const Text('Resultado del escaneo'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: FadeTransition(
                opacity: CurvedAnimation(
                  parent: controller,
                  curve: Curves.easeOut,
                ),
                child: SlideTransition(
                  position: Tween(begin: const Offset(0, .06), end: Offset.zero)
                      .animate(
                        CurvedAnimation(
                          parent: controller,
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                  child: Column(
                    children: [
                      ScaleTransition(
                        scale: Tween(begin: .7, end: 1.0).animate(
                          CurvedAnimation(
                            parent: controller,
                            curve: Curves.elasticOut,
                          ),
                        ),
                        child: Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: .12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            result.duplicate
                                ? LucideIcons.copyCheck
                                : LucideIcons.circleCheckBig,
                            color: accent,
                            size: 30,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      if (result.duplicate) ...[
                        const SizedBox(height: 8),
                        Text(
                          'No se creó un segundo registro. La asistencia original se conserva sin cambios.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                      const SizedBox(height: 22),
                      Hero(
                        tag: 'student-${record.student.id}',
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: AppPersonImage(
                            source: record.student.photoSource,
                            width: 150,
                            height: 180,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Transform.translate(
                        offset: const Offset(0, -13),
                        child: StatusBadge(status: record.status),
                      ),
                      Text(
                        record.student.fullName,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        record.student.course,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IntrinsicHeight(
                          child: Row(
                            children: [
                              Expanded(
                                child: _DataPoint(
                                  label: 'Código',
                                  value: record.student.code,
                                ),
                              ),
                              const VerticalDivider(),
                              Expanded(
                                child: _DataPoint(
                                  label: result.duplicate
                                      ? 'Registro original'
                                      : 'Hora de ingreso',
                                  value: DateFormat('HH:mm').format(
                                    result.originalTimestamp ??
                                        record.timestamp,
                                  ),
                                ),
                              ),
                              const VerticalDivider(),
                              Expanded(
                                child: _DataPoint(
                                  label: 'Fecha',
                                  value: DateFormat(
                                    'dd/MM/yyyy',
                                  ).format(record.timestamp),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => context.pop(),
                          icon: const Icon(LucideIcons.scanLine, size: 19),
                          label: const Text('Listo / Escanear siguiente'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => context.push(
                            '/historial',
                            extra: record.student.id,
                          ),
                          icon: const Icon(LucideIcons.history, size: 18),
                          label: const Text('Ver historial'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DataPoint extends StatelessWidget {
  const _DataPoint({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 6),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 9),
        ),
        const SizedBox(height: 5),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}

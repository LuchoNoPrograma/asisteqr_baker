import 'package:asisteqr_baker/app/providers.dart';
import 'package:asisteqr_baker/app/theme/app_colors.dart';
import 'package:asisteqr_baker/core/widgets/app_person_image.dart';
import 'package:asisteqr_baker/core/widgets/status_badge.dart';
import 'package:asisteqr_baker/features/attendance/domain/attendance_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class StudentHistoryPage extends ConsumerStatefulWidget {
  const StudentHistoryPage({super.key, required this.studentId});
  final String studentId;

  @override
  ConsumerState<StudentHistoryPage> createState() => _StudentHistoryPageState();
}

class _StudentHistoryPageState extends ConsumerState<StudentHistoryPage> {
  List<AttendanceRecord>? records;
  Object? loadError;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      loadError = null;
    });
    try {
      final loaded = await ref
          .read(attendanceRepositoryProvider)
          .getStudentHistory(widget.studentId);
      if (mounted) setState(() => records = loaded);
    } on Object catch (error) {
      if (mounted) setState(() => loadError = error);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Volver',
          onPressed: () => context.pop(),
          icon: const Icon(LucideIcons.arrowLeft),
        ),
        title: const Text('Historial del estudiante'),
      ),
      body: Builder(
        builder: (context) {
          if (loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (loadError != null) {
            return _HistoryMessage(
              icon: LucideIcons.cloudOff,
              title: 'No se pudo cargar el historial',
              actionLabel: 'Reintentar',
              onAction: _load,
            );
          }
          final loadedRecords = records ?? const <AttendanceRecord>[];
          if (loadedRecords.isEmpty) {
            return const _HistoryMessage(
              icon: LucideIcons.calendarX2,
              title: 'Este estudiante todavía no tiene registros.',
            );
          }
          final student = loadedRecords.first.student;
          final punctual = loadedRecords
              .where((record) => record.status == AttendanceStatus.punctual)
              .length;
          final late = loadedRecords
              .where((record) => record.status == AttendanceStatus.late)
              .length;
          final absent = loadedRecords
              .where((record) => record.status == AttendanceStatus.absent)
              .length;
          final punctuality = (punctual * 100 / loadedRecords.length).round();
          final period = DateFormat(
            'MMMM yyyy',
            'es',
          ).format(loadedRecords.first.timestamp);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Hero(
                      tag: 'student-${student.id}',
                      child: AppPersonAvatar(
                        source: student.photoSource,
                        fallback: student.fullName.characters.first,
                        size: 68,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            student.fullName,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            student.code,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            student.course,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      LucideIcons.badgeCheck,
                      color: AppColors.green,
                      size: 22,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _HistoryMetric(
                      value: '$punctuality%',
                      label: 'Puntualidad',
                      color: AppColors.green,
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: _HistoryMetric(
                      value: '$late',
                      label: 'Atrasos',
                      color: AppColors.amber,
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: _HistoryMetric(
                      value: '$absent',
                      label: 'Ausencia',
                      color: AppColors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Registros de $period',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              for (final record in loadedRecords)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 11,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(bottom: BorderSide(color: AppColors.border)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.canvas,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          DateFormat('dd').format(record.timestamp),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat(
                                'EEEE d',
                                'es',
                              ).format(record.timestamp),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              record.status == AttendanceStatus.absent
                                  ? 'Sin registro de ingreso'
                                  : 'Ingreso ${DateFormat('HH:mm').format(record.timestamp)}',
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
          );
        },
      ),
    );
  }
}

class _HistoryMessage extends StatelessWidget {
  const _HistoryMessage({
    required this.icon,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 36, color: AppColors.inkMuted),
          const SizedBox(height: 12),
          Text(title, textAlign: TextAlign.center),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onAction,
              icon: const Icon(LucideIcons.refreshCw, size: 18),
              label: Text(actionLabel!),
            ),
          ],
        ],
      ),
    ),
  );
}

class _HistoryMetric extends StatelessWidget {
  const _HistoryMetric({
    required this.value,
    required this.label,
    required this.color,
  });
  final String value, label;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 12),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color, color, Colors.white, Colors.white],
        stops: const [0, .04, .04, 1],
      ),
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(7),
    ),
    child: Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    ),
  );
}

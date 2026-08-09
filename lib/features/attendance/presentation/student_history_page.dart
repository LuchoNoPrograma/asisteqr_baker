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

class StudentHistoryPage extends ConsumerWidget {
  const StudentHistoryPage({super.key, required this.studentId});
  final String studentId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Volver',
          onPressed: () => context.pop(),
          icon: const Icon(LucideIcons.arrowLeft),
        ),
        title: const Text('Historial del estudiante'),
        actions: [
          IconButton(
            tooltip: 'Buscar estudiante',
            onPressed: () {},
            icon: const Icon(LucideIcons.search),
          ),
        ],
      ),
      body: FutureBuilder<List<AttendanceRecord>>(
        future: ref
            .read(attendanceRepositoryProvider)
            .getStudentHistory(studentId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final records = snapshot.data!;
          final student = records.first.student;
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
              DropdownButtonFormField<String>(
                initialValue: 'agosto',
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Periodo',
                  prefixIcon: Icon(LucideIcons.calendarDays, size: 18),
                ),
                items: const [
                  DropdownMenuItem(value: 'agosto', child: Text('Agosto 2026')),
                ],
                onChanged: (_) {},
              ),
              const SizedBox(height: 12),
              const Row(
                children: [
                  Expanded(
                    child: _HistoryMetric(
                      value: '92%',
                      label: 'Puntualidad',
                      color: AppColors.green,
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: _HistoryMetric(
                      value: '2',
                      label: 'Atrasos',
                      color: AppColors.amber,
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: _HistoryMetric(
                      value: '1',
                      label: 'Ausencia',
                      color: AppColors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Registros de agosto',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              for (final record in records)
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

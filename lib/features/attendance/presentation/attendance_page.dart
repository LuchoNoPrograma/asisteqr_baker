import 'package:asisteqr_baker/app/providers.dart';
import 'package:asisteqr_baker/app/theme/app_colors.dart';
import 'package:asisteqr_baker/core/widgets/adaptive_shell.dart';
import 'package:asisteqr_baker/core/widgets/app_data_table.dart';
import 'package:asisteqr_baker/core/widgets/app_person_image.dart';
import 'package:asisteqr_baker/core/widgets/status_badge.dart';
import 'package:asisteqr_baker/features/attendance/domain/attendance_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AttendancePage extends ConsumerStatefulWidget {
  const AttendancePage({super.key});
  @override
  ConsumerState<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends ConsumerState<AttendancePage> {
  List<AttendanceRecord>? records;
  AttendanceStatus? status;
  String? courseId;
  DateTime date = DateUtils.dateOnly(DateTime.now());
  String? loadError;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    setState(() {
      records = null;
      loadError = null;
    });
    try {
      final result = await ref
          .read(attendanceRepositoryProvider)
          .getDaily(date: date, courseId: courseId, status: status);
      if (mounted) setState(() => records = result);
    } on Object {
      if (mounted) {
        setState(() => loadError = 'No se pudo cargar la asistencia diaria.');
      }
    }
  }

  Future<void> _selectDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(2020),
      lastDate: DateUtils.dateOnly(DateTime.now()),
      helpText: 'Seleccionar jornada',
    );
    if (selected == null || !mounted) return;
    setState(() => date = DateUtils.dateOnly(selected));
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final courses = ref.watch(coursesViewModelProvider).courses;
    return AdaptiveShell(
      location: '/asistencia',
      title: 'Asistencia',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 840;
          if (wide) {
            return Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _pageHeader(wide: true),
                  const SizedBox(height: 18),
                  Expanded(
                    child: loadError != null
                        ? _AttendanceLoadError(onRetry: _load)
                        : records == null
                        ? const Center(child: CircularProgressIndicator())
                        : records!.isEmpty
                        ? const _EmptyAttendance()
                        : _AttendanceTable(records: records!),
                  ),
                ],
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(14),
            children: [
              _pageHeader(wide: false),
              const SizedBox(height: 18),
              _Filters(
                courses: [
                  for (final course in courses)
                    (id: course.id, name: course.name),
                ],
                courseId: courseId,
                status: status,
                date: date,
                onDatePressed: _selectDate,
                onCourseChanged: (value) {
                  courseId = value;
                  _load();
                },
                onStatusChanged: (value) {
                  status = value;
                  _load();
                },
                onClear: () {
                  courseId = null;
                  status = null;
                  date = DateUtils.dateOnly(DateTime.now());
                  _load();
                },
              ),
              const SizedBox(height: 14),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: loadError != null
                    ? _AttendanceLoadError(
                        key: const ValueKey('error'),
                        onRetry: _load,
                      )
                    : records == null
                    ? const LinearProgressIndicator(
                        key: ValueKey('loading'),
                        minHeight: 2,
                      )
                    : records!.isEmpty
                    ? const _EmptyAttendance(key: ValueKey('empty'))
                    : Column(
                        key: const ValueKey('list'),
                        children: records!
                            .map(
                              (record) => Padding(
                                padding: const EdgeInsets.only(bottom: 9),
                                child: _AttendanceCard(record: record),
                              ),
                            )
                            .toList(),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _pageHeader({required bool wide}) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gestión de asistencia diaria',
              style: wide
                  ? Theme.of(context).textTheme.headlineMedium
                  : Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 3),
            Text(
              'Registros de la jornada y estudiantes sin ingreso.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      if (wide)
        OutlinedButton.icon(
          onPressed: _selectDate,
          icon: const Icon(LucideIcons.calendarDays, size: 18),
          label: Text(DateFormat('dd/MM/yyyy').format(date)),
        ),
    ],
  );
}

class _Filters extends StatelessWidget {
  const _Filters({
    required this.courses,
    required this.courseId,
    required this.status,
    required this.date,
    required this.onDatePressed,
    required this.onCourseChanged,
    required this.onStatusChanged,
    required this.onClear,
  });
  final List<({String id, String name})> courses;
  final String? courseId;
  final AttendanceStatus? status;
  final DateTime date;
  final VoidCallback onDatePressed;
  final ValueChanged<String?> onCourseChanged;
  final ValueChanged<AttendanceStatus?> onStatusChanged;
  final VoidCallback onClear;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 230,
          child: OutlinedButton.icon(
            onPressed: onDatePressed,
            icon: const Icon(LucideIcons.calendarDays, size: 18),
            label: Text(DateFormat('dd/MM/yyyy').format(date)),
          ),
        ),
        SizedBox(
          width: 230,
          child: DropdownButtonFormField<String>(
            key: ValueKey(courseId),
            initialValue: courseId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Curso',
              prefixIcon: Icon(LucideIcons.school, size: 17),
            ),
            items: [
              for (final course in courses)
                DropdownMenuItem(
                  value: course.id,
                  child: Text(
                    course.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: onCourseChanged,
          ),
        ),
        SizedBox(
          width: 190,
          child: DropdownButtonFormField<AttendanceStatus>(
            key: ValueKey(status),
            initialValue: status,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Estado',
              prefixIcon: Icon(LucideIcons.listFilter, size: 17),
            ),
            items: AttendanceStatus.values
                .map(
                  (item) => DropdownMenuItem(
                    value: item,
                    child: Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: onStatusChanged,
          ),
        ),
        OutlinedButton.icon(
          onPressed: onClear,
          icon: const Icon(LucideIcons.filterX, size: 17),
          label: const Text('Limpiar filtros'),
        ),
      ],
    ),
  );
}

class _AttendanceCard extends StatelessWidget {
  const _AttendanceCard({required this.record});
  final AttendanceRecord record;
  @override
  Widget build(BuildContext context) {
    final color = switch (record.status) {
      AttendanceStatus.punctual => AppColors.green,
      AttendanceStatus.late => AppColors.amber,
      AttendanceStatus.absent => AppColors.red,
    };
    return Container(
      padding: const EdgeInsets.fromLTRB(9, 12, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 48,
            margin: const EdgeInsets.only(right: 9),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          AppPersonAvatar(
            source: record.student.photoSource,
            fallback: record.student.fullName.characters.first,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.student.fullName,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  '${record.student.code} · ${record.student.course}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 3),
                Text(
                  DateFormat('dd/MM/yyyy · HH:mm').format(record.timestamp),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          StatusBadge(status: record.status),
        ],
      ),
    );
  }
}

class _AttendanceTable extends StatelessWidget {
  const _AttendanceTable({required this.records});
  final List<AttendanceRecord> records;
  @override
  Widget build(BuildContext context) {
    final courses =
        records.map((record) => record.student.course).toSet().toList()..sort();
    return AppDataTable<AttendanceRecord>(
      items: records,
      searchHint: 'Buscar estudiante, código o curso',
      searchText: (record) => [
        record.student.code,
        record.student.fullName,
        record.student.course,
        record.status.label,
        DateFormat('HH:mm').format(record.timestamp),
      ].join(' '),
      filters: [
        AppDataFilter(
          label: 'Curso',
          options: [
            for (final course in courses)
              AppDataFilterOption(
                label: course,
                matches: (record) => record.student.course == course,
              ),
          ],
        ),
        AppDataFilter(
          label: 'Estado',
          options: [
            for (final status in AttendanceStatus.values)
              AppDataFilterOption(
                label: status.label,
                matches: (record) => record.status == status,
              ),
          ],
        ),
      ],
      columns: [
        AppDataColumn(
          label: 'Foto',
          cellBuilder: (context, record) => AppPersonAvatar(
            source: record.student.photoSource,
            fallback: record.student.fullName.characters.first,
            size: 32,
          ),
        ),
        AppDataColumn(
          label: 'Código',
          compare: (first, second) =>
              first.student.code.compareTo(second.student.code),
          cellBuilder: (context, record) => Text(record.student.code),
        ),
        AppDataColumn(
          label: 'Estudiante',
          compare: (first, second) =>
              first.student.fullName.compareTo(second.student.fullName),
          cellBuilder: (context, record) => Text(record.student.fullName),
        ),
        AppDataColumn(
          label: 'Curso',
          compare: (first, second) =>
              first.student.course.compareTo(second.student.course),
          cellBuilder: (context, record) => Text(record.student.course),
        ),
        AppDataColumn(
          label: 'Hora',
          compare: (first, second) =>
              first.timestamp.compareTo(second.timestamp),
          cellBuilder: (context, record) =>
              Text(DateFormat('HH:mm').format(record.timestamp)),
        ),
        AppDataColumn(
          label: 'Estado',
          compare: (first, second) =>
              first.status.index.compareTo(second.status.index),
          cellBuilder: (context, record) => StatusBadge(status: record.status),
        ),
      ],
    );
  }
}

class _AttendanceLoadError extends StatelessWidget {
  const _AttendanceLoadError({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.cloudAlert, size: 36, color: AppColors.red),
          const SizedBox(height: 10),
          const Text(
            'No se pudo cargar la asistencia diaria.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(LucideIcons.refreshCw, size: 17),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    ),
  );
}

class _EmptyAttendance extends StatelessWidget {
  const _EmptyAttendance({super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(36),
    child: Column(
      children: [
        const Icon(LucideIcons.searchX, size: 32, color: AppColors.inkMuted),
        const SizedBox(height: 10),
        Text(
          'No hay registros para estos filtros.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    ),
  );
}
